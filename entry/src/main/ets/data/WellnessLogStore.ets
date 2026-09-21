/*
 * 文件标注：AI 生成 —— 每日状态（睡眠/酸痛/饮水）本地持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 每日状态存储
 * 按日期分桶记录睡眠时长/睡眠质量(1–5)/肌群酸痛度(1–5)/饮水量(ml)，
 * 基于系统 preferences（端侧本地键值存储，沙箱内，无网络请求）。
 * 同一日期重复保存时按字段合并，便于一天内多次补录。
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

/** 一天的自我状态记录（0/空值表示该项未填） */
export interface WellnessEntry {
  /** 所属日期键（YYYY-MM-DD，本地时区） */
  dateKey: string;
  /** 睡眠时长（小时，0 = 未填） */
  sleepHours: number;
  /** 睡眠质量 1–5（0 = 未填） */
  sleepQuality: number;
  /** 肌群酸痛度 1–5（0 = 未填） */
  soreness: number;
  /** 饮水量（毫升） */
  waterMl: number;
}

export class WellnessLogStore {
  private static readonly STORE_NAME: string = 'wellness_log';

  private readonly prefs: preferences.Preferences;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: WellnessLogStore.STORE_NAME });
  }

  /** 当前日期键（YYYY-MM-DD，本地时区） */
  static todayKey(now: number = Date.now()): string {
    const date: Date = new Date(now);
    const month: string = `${date.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${date.getDate()}`.padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  /** 保存（同日重复保存按字段合并：新值 > 0 才覆盖旧值） */
  save(entry: WellnessEntry): void {
    const existing: WellnessEntry | null = this.get(entry.dateKey);
    if (existing !== null) {
      if (entry.sleepHours <= 0) {
        entry.sleepHours = existing.sleepHours;
      }
      if (entry.sleepQuality <= 0) {
        entry.sleepQuality = existing.sleepQuality;
      }
      if (entry.soreness <= 0) {
        entry.soreness = existing.soreness;
      }
      if (entry.waterMl <= 0) {
        entry.waterMl = existing.waterMl;
      }
    }
    this.prefs.putSync(WellnessLogStore.storeKey(entry.dateKey), JSON.stringify(entry));
    this.prefs.flush();
  }

  /** 读取指定日期的状态；无记录返回 null */
  get(dateKey: string): WellnessEntry | null {
    const raw: string = this.prefs.getSync(WellnessLogStore.storeKey(dateKey), '') as string;
    if (raw.length === 0) {
      return null;
    }
    try {
      return JSON.parse(raw) as WellnessEntry;
    } catch (err) {
      console.warn(`WellnessLogStore parse failed: ${JSON.stringify(err)}`);
      return null;
    }
  }

  /** 今日状态；无记录返回 null */
  getToday(now: number = Date.now()): WellnessEntry | null {
    return this.get(WellnessLogStore.todayKey(now));
  }

  /** 最近 days 天的状态（含今天，按日期正序；无记录的日期跳过） */
  recent(days: number, now: number = Date.now()): WellnessEntry[] {
    const result: WellnessEntry[] = [];
    for (let i: number = days - 1; i >= 0; i--) {
      const key: string = WellnessLogStore.todayKey(now - i * 86400000);
      const entry: WellnessEntry | null = this.get(key);
      if (entry !== null) {
        result.push(entry);
      }
    }
    return result;
  }

  /** 存储键按天分桶，读单日记录无需遍历历史 */
  private static storeKey(dateKey: string): string {
    return `wellness_${dateKey}`;
  }
}
