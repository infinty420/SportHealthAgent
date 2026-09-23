/*
 * 文件标注：AI 生成 —— 饮食记录本地持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 饮食日志
 * 记录三餐（早餐/午餐/晚餐/加餐）的食物选择与份量（克），
 * 基于系统 preferences 按日期键存储，纯本地，无网络请求。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { RdbAdapter } from './RdbAdapter';

/** 餐次 */
export const MEAL_TYPES: string[] = ['早餐', '午餐', '晚餐', '加餐'];

/** 一条饮食记录 */
export interface DietLogEntry {
  /** 记录时间戳（毫秒） */
  timestamp: number;
  /** 餐次：早餐/午餐/晚餐/加餐 */
  meal: string;
  /** 食物名称（与 FoodLibrary 对应） */
  foodName: string;
  /** 份量（克） */
  grams: number;
}

/** 当日实际摄入汇总（宏量营养素） */
export interface IntakeSummary {
  kcal: number;
  proteinGrams: number;
  carbGrams: number;
  fatGrams: number;
}

export class DietLog {
  private static readonly STORE_NAME: string = 'diet_log';

  private readonly prefs: preferences.Preferences;
  private readonly rdb: RdbAdapter;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: DietLog.STORE_NAME });
    this.rdb = RdbAdapter.shared(context);
  }

  /** 追加一条饮食记录（preferences + RDB 双写） */
  logMeal(entry: DietLogEntry): void {
    const list: DietLogEntry[] = this.getAll();
    list.unshift(entry);
    this.persist(list);
  }

  /** 今日全部记录（按时间倒序） */
  getDailyLog(): DietLogEntry[] {
    const since: number = this.todayStart();
    return this.getAll().filter((e: DietLogEntry) => e.timestamp >= since);
  }

  /** 删除一条记录（按时间戳定位） */
  remove(timestamp: number): void {
    const list: DietLogEntry[] = this.getAll().filter((e: DietLogEntry) => e.timestamp !== timestamp);
    this.persist(list);
  }

  private persist(list: DietLogEntry[]): void {
    const json: string = JSON.stringify(list);
    const key: string = DietLog.storeKey();
    this.prefs.putSync(key, json);
    this.prefs.flush();
    this.rdb.write(DietLog.STORE_NAME, key, json);
  }

  private getAll(): DietLogEntry[] {
    // 灰度双读：RDB 优先，未命中回退 preferences 并惰性回写（按日期键自愈迁移）
    const key: string = DietLog.storeKey();
    let raw: string = '';
    const fromRdb: string | null = this.rdb.read(DietLog.STORE_NAME, key);
    if (fromRdb !== null) {
      raw = fromRdb;
    } else {
      raw = this.prefs.getSync(key, '[]') as string;
      this.rdb.write(DietLog.STORE_NAME, key, raw);
    }
    try {
      return JSON.parse(raw) as DietLogEntry[];
    } catch (err) {
      console.warn(`DietLog parse failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /** 存储键按天分桶，读今日记录无需遍历历史 */
  private static storeKey(): string {
    const now: Date = new Date();
    return `log_${now.getFullYear()}_${now.getMonth() + 1}_${now.getDate()}`;
  }

  private todayStart(): number {
    const now: Date = new Date();
    now.setHours(0, 0, 0, 0);
    return now.getTime();
  }
}
