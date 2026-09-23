/*
 * 文件标注：AI 生成 —— 本地 RDB 适配器（通用数据访问脚手架）
 *
 * 数据接入层 · RDB 迁移适配器
 * 将四大日志存储从 preferences 平滑迁移到系统关系型数据库（RDB，沙箱内 henglian.db）：
 * kv 表按 (store_name, data_key) 存放与原 preferences 完全一致的 JSON 字符串，
 * meta 表记录单键迁移标记。所有写路径双写（preferences + RDB），读路径 RDB 优先、
 * preferences 兜底并惰性回写（灰度双读）；RDB 初始化失败时全程回退 preferences，
 * 功能不受影响。纯端侧本地存储，无网络请求。
 */
import { relationalStore, preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class RdbAdapter {
  private static readonly DB_NAME: string = 'henglian.db';
  private static instance: RdbAdapter | null = null;

  /** RDB 句柄；初始化失败为 null，此后所有操作静默回退 preferences */
  private readonly store: relationalStore.RdbStore | null = null;

  private constructor(context: common.UIAbilityContext) {
    let handle: relationalStore.RdbStore | null = null;
    try {
      const config: relationalStore.StoreConfig = {
        name: RdbAdapter.DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      };
      handle = relationalStore.getRdbStoreSync(context, config);
      handle.executeSync('CREATE TABLE IF NOT EXISTS kv (' +
        'store_name TEXT NOT NULL, data_key TEXT NOT NULL, data_value TEXT, ' +
        'PRIMARY KEY (store_name, data_key))');
      handle.executeSync('CREATE TABLE IF NOT EXISTS meta (' +
        'flag TEXT PRIMARY KEY NOT NULL, done INTEGER NOT NULL)');
    } catch (err) {
      console.warn(`RdbAdapter init failed, fallback to preferences: ${JSON.stringify(err)}`);
      handle = null;
    }
    this.store = handle;
  }

  /** 单例（全应用共用一个 RDB 连接） */
  static shared(context: common.UIAbilityContext): RdbAdapter {
    if (RdbAdapter.instance === null) {
      RdbAdapter.instance = new RdbAdapter(context);
    }
    return RdbAdapter.instance;
  }

  /** RDB 是否可用（false 时调用方应只走 preferences） */
  available(): boolean {
    return this.store !== null;
  }

  /** 读取一个键；无记录或出错返回 null（调用方回退 preferences） */
  read(storeName: string, key: string): string | null {
    if (this.store === null) {
      return null;
    }
    try {
      const resultSet: relationalStore.ResultSet = this.store.querySqlSync(
        'SELECT data_value FROM kv WHERE store_name = ? AND data_key = ?', [storeName, key]);
      try {
        if (resultSet.rowCount > 0 && resultSet.goToRow(0)) {
          return resultSet.getString(0);
        }
        return null;
      } finally {
        resultSet.close();
      }
    } catch (err) {
      console.warn(`RdbAdapter read failed (${storeName}/${key}): ${JSON.stringify(err)}`);
      return null;
    }
  }

  /** 写入一个键（INSERT OR REPLACE 幂等） */
  write(storeName: string, key: string, value: string): void {
    if (this.store === null) {
      return;
    }
    try {
      this.store.executeSync(
        'INSERT OR REPLACE INTO kv (store_name, data_key, data_value) VALUES (?, ?, ?)',
        [storeName, key, value]);
    } catch (err) {
      console.warn(`RdbAdapter write failed (${storeName}/${key}): ${JSON.stringify(err)}`);
    }
  }

  /**
   * 一次性导入单键存储：preferences → RDB（meta 表记迁移标记，只执行一次）。
   * 适用于整表单键的存储（历史记录 / 训练日志）。
   */
  ensureImported(storeName: string, key: string, prefs: preferences.Preferences, def: string): void {
    if (this.store === null) {
      return;
    }
    const flag: string = `${storeName}/${key}`;
    try {
      const resultSet: relationalStore.ResultSet = this.store.querySqlSync(
        'SELECT done FROM meta WHERE flag = ?', [flag]);
      let migrated: boolean = false;
      try {
        migrated = resultSet.rowCount > 0 && resultSet.goToRow(0) && resultSet.getLong(0) === 1;
      } finally {
        resultSet.close();
      }
      if (migrated) {
        return;
      }
      if (this.read(storeName, key) === null) {
        const raw: string = prefs.getSync(key, def) as string;
        this.write(storeName, key, raw);
      }
      this.store.executeSync('INSERT OR REPLACE INTO meta (flag, done) VALUES (?, 1)', [flag]);
    } catch (err) {
      console.warn(`RdbAdapter import failed (${flag}): ${JSON.stringify(err)}`);
    }
  }
}
