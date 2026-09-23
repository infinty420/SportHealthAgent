/*
 * 文件标注：AI 生成 —— 训练日志本地持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 训练日志存储
 * 基于系统 preferences（端侧本地键值存储，沙箱内，无网络请求）。
 * 预留 RDB 迁移接口：exportForMigration() 导出全量结构化数据，
 * 未来迁移本地关系型数据库时一次性导入，失败回滚即继续读 preferences。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { WorkoutLog, WorkoutSet } from '../model/WorkoutLog';
import { RdbAdapter } from './RdbAdapter';

/** 存储用的纯数据结构（WorkoutLog 的可 JSON 化形态） */
interface WorkoutLogRecord {
  timestamp: number;
  exerciseId: string;
  sets: WorkoutSet[];
}

export class WorkoutLogStore {
  private static readonly STORE_NAME: string = 'workout_log';
  private static readonly KEY_RECORDS: string = 'records';
  /** 最多保留条数（按每周 12 条计约三年） */
  private static readonly MAX_ENTRIES: number = 2000;
  private static readonly DAY_MS: number = 86400000;

  private readonly prefs: preferences.Preferences;
  private readonly rdb: RdbAdapter;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: WorkoutLogStore.STORE_NAME });
    this.rdb = RdbAdapter.shared(context);
    // RDB 迁移：首次将 preferences 整表导入，此后写路径双写、读路径 RDB 优先
    this.rdb.ensureImported(WorkoutLogStore.STORE_NAME, WorkoutLogStore.KEY_RECORDS, this.prefs, '[]');
  }

  /** 追加一条训练日志（新记录排在最前）；调用前请先通过 log.validate() */
  save(log: WorkoutLog): void {
    const record: WorkoutLogRecord = { timestamp: log.timestamp, exerciseId: log.exerciseId, sets: log.sets };
    const list: WorkoutLog[] = this.list();
    list.unshift(this.fromRecord(record));
    while (list.length > WorkoutLogStore.MAX_ENTRIES) {
      list.pop();
    }
    this.persist(list);
  }

  /** 读取全部日志（按时间倒序）；无数据或数据损坏时返回空数组 */
  list(): WorkoutLog[] {
    // 灰度双读：RDB 优先，未命中回退 preferences 并惰性回写
    let raw: string = '';
    const fromRdb: string | null = this.rdb.read(WorkoutLogStore.STORE_NAME, WorkoutLogStore.KEY_RECORDS);
    if (fromRdb !== null) {
      raw = fromRdb;
    } else {
      raw = this.prefs.getSync(WorkoutLogStore.KEY_RECORDS, '[]') as string;
      this.rdb.write(WorkoutLogStore.STORE_NAME, WorkoutLogStore.KEY_RECORDS, raw);
    }
    try {
      const parsed: WorkoutLogRecord[] = JSON.parse(raw) as WorkoutLogRecord[];
      const result: WorkoutLog[] = [];
      parsed.forEach((record: WorkoutLogRecord) => {
        result.push(this.fromRecord(record));
      });
      return result;
    } catch (err) {
      console.warn(`WorkoutLogStore parse failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /** 指定日期（YYYY-MM-DD）的全部日志，按时间正序 */
  listByDate(dateKey: string): WorkoutLog[] {
    const filtered: WorkoutLog[] = this.list().filter((log: WorkoutLog) => log.dateKey() === dateKey);
    filtered.reverse();
    return filtered;
  }

  /** 指定动作的全部日志，按时间正序（渐进超负荷对比用） */
  listByExercise(exerciseId: string): WorkoutLog[] {
    const filtered: WorkoutLog[] = this.list().filter((log: WorkoutLog) => log.exerciseId === exerciseId);
    filtered.reverse();
    return filtered;
  }

  /** 最近 7 天总容量（公斤） */
  weeklyVolume(): number {
    const since: number = Date.now() - 7 * WorkoutLogStore.DAY_MS;
    let volume: number = 0;
    this.list().forEach((log: WorkoutLog) => {
      if (log.timestamp >= since) {
        volume += log.totalVolume();
      }
    });
    return volume;
  }

  /** 最近 7 天全部日志（肌群容量热力与平衡分析用），按时间正序 */
  weeklyLogs(): WorkoutLog[] {
    const since: number = Date.now() - 7 * WorkoutLogStore.DAY_MS;
    const filtered: WorkoutLog[] = this.list().filter((log: WorkoutLog) => log.timestamp >= since);
    filtered.reverse();
    return filtered;
  }

  /**
   * RDB 迁移预留：导出全量日志（时间正序）。
   * 迁移到本地关系型数据库时读取本方法逐条 insert；导入失败则回滚、继续使用 preferences。
   */
  exportForMigration(): WorkoutLog[] {
    const all: WorkoutLog[] = this.list();
    all.reverse();
    return all;
  }

  /** 清空日志 */
  clear(): void {
    this.prefs.putSync(WorkoutLogStore.KEY_RECORDS, '[]');
    this.prefs.flush();
    this.rdb.write(WorkoutLogStore.STORE_NAME, WorkoutLogStore.KEY_RECORDS, '[]');
  }

  /** 纯数据结构 → 模型实例（恢复 dateKey/totalVolume 等方法；旧数据无 rir 字段时兜底为 -1 未填） */
  private fromRecord(record: WorkoutLogRecord): WorkoutLog {
    const log: WorkoutLog = new WorkoutLog();
    log.timestamp = record.timestamp;
    log.exerciseId = record.exerciseId;
    const sets: WorkoutSet[] = [];
    record.sets.forEach((set: WorkoutSet) => {
      const fixed: WorkoutSet = {
        setIndex: set.setIndex,
        reps: set.reps,
        weightKg: set.weightKg,
        rpe: set.rpe,
        rir: typeof set.rir !== 'number' ? -1 : set.rir
      };
      sets.push(fixed);
    });
    log.sets = sets;
    return log;
  }

  private persist(list: WorkoutLog[]): void {
    const records: WorkoutLogRecord[] = [];
    list.forEach((log: WorkoutLog) => {
      const record: WorkoutLogRecord = { timestamp: log.timestamp, exerciseId: log.exerciseId, sets: log.sets };
      records.push(record);
    });
    this.prefs.putSync(WorkoutLogStore.KEY_RECORDS, JSON.stringify(records));
    this.prefs.flush();
    this.rdb.write(WorkoutLogStore.STORE_NAME, WorkoutLogStore.KEY_RECORDS, JSON.stringify(records));
  }
}
