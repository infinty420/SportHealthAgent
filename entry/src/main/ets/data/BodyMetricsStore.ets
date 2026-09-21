/*
 * 文件标注：AI 生成 —— 体成分指标本地持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 体成分记录存储
 * 记录体重/体脂率/静息心率的时间序列（容量 365 条），供趋势展示。
 * 复用 HistoryStore 的 preferences 模式，纯本地存储，无网络请求。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

/** 一条体成分记录 */
export interface BodyMetricEntry {
  /** 记录时间戳（毫秒） */
  timestamp: number;
  weightKg: number;
  /** 体脂率（%，0 表示未测） */
  bodyFatPct: number;
  /** 静息心率（次/分，0 表示未测） */
  restingHr: number;
}

export class BodyMetricsStore {
  private static readonly STORE_NAME: string = 'body_metrics';
  private static readonly KEY_RECORDS: string = 'records';
  /** 最多保留条数（约一年） */
  private static readonly MAX_ENTRIES: number = 365;

  private readonly prefs: preferences.Preferences;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: BodyMetricsStore.STORE_NAME });
  }

  /** 追加一条记录（新记录排在最前） */
  save(entry: BodyMetricEntry): void {
    const list: BodyMetricEntry[] = this.list();
    list.unshift(entry);
    while (list.length > BodyMetricsStore.MAX_ENTRIES) {
      list.pop();
    }
    this.prefs.putSync(BodyMetricsStore.KEY_RECORDS, JSON.stringify(list));
    this.prefs.flush();
  }

  /** 读取全部记录（按时间倒序）；无数据或数据损坏时返回空数组 */
  list(): BodyMetricEntry[] {
    const raw: string = this.prefs.getSync(BodyMetricsStore.KEY_RECORDS, '[]') as string;
    try {
      const parsed: BodyMetricEntry[] = JSON.parse(raw) as BodyMetricEntry[];
      return parsed;
    } catch (err) {
      console.warn(`BodyMetricsStore parse failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /** 趋势数据：最近 count 条按时间正序（用于趋势图） */
  getTrend(count: number): BodyMetricEntry[] {
    const result: BodyMetricEntry[] = this.list().slice(0, count);
    result.reverse();
    return result;
  }
}
