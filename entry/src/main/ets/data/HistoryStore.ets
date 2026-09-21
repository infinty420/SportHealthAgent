/*
 * 文件标注：AI 生成 —— 本地历史记录持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 历史记录存储
 * 基于系统 preferences（端侧本地键值存储，沙箱内文件，无网络请求），
 * 保存每次分析的运动记录摘要，用于历史列表、负荷趋势图与周/月报表。
 * 扩展：容量 365 条、采纳反馈标记、周/月聚合统计、沙箱 JSON 导出。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';

/** 建议采纳状态：未标记 / 已采纳 / 已忽略 */
export type AdoptedState = 'unmarked' | 'adopted' | 'ignored';

/** 一条历史记录摘要（趋势图与列表共用） */
export interface HistoryEntry {
  /** 分析时间戳（毫秒） */
  timestamp: number;
  sportType: string;
  durationMin: number;
  calories: number;
  load: number;
  loadStatus: string;
  /** 建议恢复时长（小时，用于恢复倒计时） */
  recoveryHours: number;
  /** 建议采纳反馈（规则引擎按此微调下次建议强度） */
  adopted: AdoptedState;
}

/** 周期聚合统计（周/月报表共用） */
export interface PeriodStats {
  /** 训练次数 */
  sessions: number;
  /** 总时长（分钟） */
  totalDurationMin: number;
  /** 总热量（千卡） */
  totalCalories: number;
  /** 平均负荷（无记录时为 0） */
  avgLoad: number;
}

export class HistoryStore {
  private static readonly STORE_NAME: string = 'sport_history';
  private static readonly KEY_RECORDS: string = 'records';
  /** 最多保留条数（约一年），超出后淘汰最旧记录 */
  private static readonly MAX_ENTRIES: number = 365;
  private static readonly DAY_MS: number = 86400000;

  private readonly prefs: preferences.Preferences;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: HistoryStore.STORE_NAME });
  }

  /** 追加一条记录（新记录排在最前） */
  save(entry: HistoryEntry): void {
    const list: HistoryEntry[] = this.list();
    list.unshift(entry);
    while (list.length > HistoryStore.MAX_ENTRIES) {
      list.pop();
    }
    this.prefs.putSync(HistoryStore.KEY_RECORDS, JSON.stringify(list));
    this.prefs.flush();
  }

  /** 读取全部记录（按时间倒序）；无数据或数据损坏时返回空数组 */
  list(): HistoryEntry[] {
    const raw: string = this.prefs.getSync(HistoryStore.KEY_RECORDS, '[]') as string;
    try {
      const parsed: HistoryEntry[] = JSON.parse(raw) as HistoryEntry[];
      // 旧数据无 adopted 字段时兜底为未标记（不直接与 undefined 比较，规避 TS2367）
      parsed.forEach((entry: HistoryEntry) => {
        if (entry.adopted !== 'adopted' && entry.adopted !== 'ignored') {
          entry.adopted = 'unmarked';
        }
      });
      return parsed;
    } catch (err) {
      console.warn(`HistoryStore parse failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /** 更新一条记录的采纳反馈（按时间戳定位） */
  markAdopted(timestamp: number, state: AdoptedState): void {
    const list: HistoryEntry[] = this.list();
    for (let i = 0; i < list.length; i++) {
      if (list[i].timestamp === timestamp) {
        list[i].adopted = state;
        break;
      }
    }
    this.prefs.putSync(HistoryStore.KEY_RECORDS, JSON.stringify(list));
    this.prefs.flush();
  }

  /** 最近 days 天的聚合统计（总时长/总热量/平均负荷/频次） */
  private periodStats(days: number): PeriodStats {
    const since: number = Date.now() - days * HistoryStore.DAY_MS;
    const inRange: HistoryEntry[] = this.list().filter((e: HistoryEntry) => e.timestamp >= since);
    const stats: PeriodStats = { sessions: inRange.length, totalDurationMin: 0, totalCalories: 0, avgLoad: 0 };
    let loadSum: number = 0;
    inRange.forEach((e: HistoryEntry) => {
      stats.totalDurationMin += e.durationMin;
      stats.totalCalories += e.calories;
      loadSum += e.load;
    });
    if (inRange.length > 0) {
      stats.avgLoad = Math.round(loadSum / inRange.length);
    }
    return stats;
  }

  /** 最近 7 天聚合统计 */
  getWeeklyStats(): PeriodStats {
    return this.periodStats(7);
  }

  /** 最近 30 天聚合统计 */
  getMonthlyStats(): PeriodStats {
    return this.periodStats(30);
  }

  /**
   * 导出全部历史为 JSON 文件（沙箱 filesDir 下，不分享、不联网）。
   * 返回文件沙箱路径；失败时抛出 Error。
   */
  exportToFile(context: common.UIAbilityContext): string {
    const path: string = `${context.filesDir}/sport_history_export.json`;
    const file: fs.File = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(file.fd, JSON.stringify(this.list()));
    } finally {
      fs.closeSync(file);
    }
    return path;
  }

  /** 清空历史 */
  clear(): void {
    this.prefs.putSync(HistoryStore.KEY_RECORDS, '[]');
    this.prefs.flush();
  }
}
