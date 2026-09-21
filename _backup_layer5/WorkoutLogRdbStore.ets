/*
 * 文件标注：AI 生成 —— 训练日志 RDB 迁移（通用数据访问脚手架）
 *
 * 数据接入层 · preferences → 本地关系型数据库迁移
 * 迁移契约（第五层可选包）：
 *   1. 版本号：meta 表记录 schema_version，当前为 1；
 *   2. 旧数据一次性导入：WorkoutLogStore.exportForMigration() 全量逐条 insert；
 *   3. 失败回滚：任一步骤失败即删除 RDB 文件、不置迁移标志，应用继续读 preferences；
 *   4. 幂等：标志位已置则跳过；迁移成功后 save() 同步镜像写入 RDB。
 * 全部为端侧本地存储（沙箱内 .db 文件），无网络请求。
 */
import { preferences, relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { WorkoutLog } from '../model/WorkoutLog';
import { WorkoutLogStore } from './WorkoutLogStore';

/** 迁移结果说明 */
export interface MigrationResult {
  /** 是否成功（或已成功过） */
  ok: boolean;
  /** 导入条数（跳过/失败时为 0） */
  imported: number;
  /** 中文说明 */
  message: string;
}

export class WorkoutLogRdbStore {
  private static readonly DB_NAME: string = 'workout_log.db';
  private static readonly TABLE: string = 'workout_log';
  private static readonly META_TABLE: string = 'meta';
  /** 数据库结构版本号（结构变更时递增并编写升级脚本） */
  private static readonly SCHEMA_VERSION: number = 1;
  private static readonly FLAG_STORE: string = 'workout_log';
  private static readonly FLAG_KEY: string = 'rdb_migrated';

  private static dbConfig(): relationalStore.StoreConfig {
    const config: relationalStore.StoreConfig = {
      name: WorkoutLogRdbStore.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    return config;
  }

  /** 是否已完成迁移（preferences 标志位） */
  static isMigrated(context: common.UIAbilityContext): boolean {
    const prefs: preferences.Preferences =
      preferences.getPreferencesSync(context, { name: WorkoutLogRdbStore.FLAG_STORE });
    const flag: string = prefs.getSync(WorkoutLogRdbStore.FLAG_KEY, '0') as string;
    return flag === '1';
  }

  /**
   * 执行一次性迁移（幂等）。失败自动回滚：删除 RDB、不置标志。
   * 结果通过回调返回（异步 API 的 Promise 封装，UI 无需 await）。
   */
  static migrate(context: common.UIAbilityContext, callback: (result: MigrationResult) => void): void {
    if (WorkoutLogRdbStore.isMigrated(context)) {
      const skipped: MigrationResult = { ok: true, imported: 0, message: '已完成迁移，跳过' };
      callback(skipped);
      return;
    }
    const source: WorkoutLog[] = new WorkoutLogStore(context).exportForMigration();
    const config: relationalStore.StoreConfig = WorkoutLogRdbStore.dbConfig();
    relationalStore.getRdbStore(context, config).then((store: relationalStore.RdbStore) => {
      store.executeSql(`CREATE TABLE IF NOT EXISTS ${WorkoutLogRdbStore.TABLE} (` +
        'id INTEGER PRIMARY KEY AUTOINCREMENT, ts INTEGER NOT NULL, ' +
        'exercise_id TEXT NOT NULL, sets_json TEXT NOT NULL)')
        .then(() => store.executeSql(`CREATE TABLE IF NOT EXISTS ${WorkoutLogRdbStore.META_TABLE} (` +
          'key TEXT PRIMARY KEY, value TEXT NOT NULL)'))
        .then(() => WorkoutLogRdbStore.insertAll(store, source, 0))
        .then((inserted: number) => WorkoutLogRdbStore.verify(store, source.length, inserted))
        .then((verified: boolean) => {
          if (!verified) {
            WorkoutLogRdbStore.rollback(context, callback, '导入校验失败，已回滚');
            return;
          }
          const bucket: relationalStore.ValuesBucket = {
            'key': 'schema_version',
            'value': `${WorkoutLogRdbStore.SCHEMA_VERSION}`
          };
          store.insert(WorkoutLogRdbStore.META_TABLE, bucket).then(() => {
            const prefs: preferences.Preferences =
              preferences.getPreferencesSync(context, { name: WorkoutLogRdbStore.FLAG_STORE });
            prefs.putSync(WorkoutLogRdbStore.FLAG_KEY, '1');
            prefs.flush();
            const done: MigrationResult = {
              ok: true, imported: source.length,
              message: `迁移完成：${source.length} 条日志已导入 RDB（schema v${WorkoutLogRdbStore.SCHEMA_VERSION}）`
            };
            callback(done);
          }).catch(() => {
            WorkoutLogRdbStore.rollback(context, callback, '写入版本号失败，已回滚');
          });
        })
        .catch(() => {
          WorkoutLogRdbStore.rollback(context, callback, '导入失败，已回滚');
        });
    }).catch(() => {
      const failed: MigrationResult = { ok: false, imported: 0, message: '打开数据库失败，继续读 preferences' };
      callback(failed);
    });
  }

  /** 逐条插入（递归 Promise 链，避免并发写冲突）；返回成功条数 */
  private static insertAll(store: relationalStore.RdbStore, logs: WorkoutLog[], index: number): Promise<number> {
    if (index >= logs.length) {
      return Promise.resolve(0);
    }
    const log: WorkoutLog = logs[index];
    const bucket: relationalStore.ValuesBucket = {
      'ts': log.timestamp,
      'exercise_id': log.exerciseId,
      'sets_json': JSON.stringify(log.sets)
    };
    return store.insert(WorkoutLogRdbStore.TABLE, bucket).then(() => {
      return WorkoutLogRdbStore.insertAll(store, logs, index + 1).then((rest: number) => rest + 1);
    });
  }

  /** 导入校验：RDB 行数必须等于导出条数且逐条插入无失败 */
  private static verify(store: relationalStore.RdbStore, expected: number, inserted: number): Promise<boolean> {
    if (inserted !== expected) {
      return Promise.resolve(false);
    }
    return store.querySql(`SELECT COUNT(*) FROM ${WorkoutLogRdbStore.TABLE}`)
      .then((resultSet: relationalStore.ResultSet) => {
        let count: number = -1;
        if (resultSet.goToFirstRow()) {
          count = resultSet.getLong(0);
        }
        resultSet.close();
        return count === expected;
      });
  }

  /** 回滚：删除 RDB 文件，保持 preferences 为唯一数据源 */
  private static rollback(context: common.UIAbilityContext, callback: (result: MigrationResult) => void,
    message: string): void {
    relationalStore.deleteRdbStore(context, WorkoutLogRdbStore.dbConfig())
      .then(() => {
        const result: MigrationResult = { ok: false, imported: 0, message: message };
        callback(result);
      })
      .catch(() => {
        const result: MigrationResult = { ok: false, imported: 0, message: `${message}（清理残留失败）` };
        callback(result);
      });
  }

  /**
   * 迁移完成后的镜像写入：WorkoutLogStore.save() 成功后在 RDB 追加同一条。
   * 未迁移或写入失败均静默忽略（preferences 仍是主存储）。
   */
  static mirrorInsert(context: common.UIAbilityContext, log: WorkoutLog): void {
    if (!WorkoutLogRdbStore.isMigrated(context)) {
      return;
    }
    const bucket: relationalStore.ValuesBucket = {
      'ts': log.timestamp,
      'exercise_id': log.exerciseId,
      'sets_json': JSON.stringify(log.sets)
    };
    relationalStore.getRdbStore(context, WorkoutLogRdbStore.dbConfig())
      .then((store: relationalStore.RdbStore) => {
        store.insert(WorkoutLogRdbStore.TABLE, bucket).catch(() => {
          console.warn('WorkoutLogRdbStore mirror insert failed');
        });
      })
      .catch(() => {
        console.warn('WorkoutLogRdbStore mirror open failed');
      });
  }
}
