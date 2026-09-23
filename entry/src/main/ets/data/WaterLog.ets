/*
 * 文件标注：AI 生成 —— 每日饮水量本地持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 饮水日志
 * 按日期分桶记录饮水量（ml），目标 = 35 ml × 体重 kg，训练日 +500 ml。
 * 基于系统 preferences（端侧本地键值存储，沙箱内，无网络请求）。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class WaterLog {
  private static readonly STORE_NAME: string = 'water_log';
  /** 每公斤体重日饮水目标（ml/kg） */
  private static readonly ML_PER_KG: number = 35;
  /** 训练日额外目标（ml） */
  private static readonly TRAINING_BONUS_ML: number = 500;

  private readonly prefs: preferences.Preferences;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: WaterLog.STORE_NAME });
  }

  /** 当前日期键（YYYY-MM-DD，本地时区） */
  private static todayKey(now: number = Date.now()): string {
    const date: Date = new Date(now);
    const month: string = `${date.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${date.getDate()}`.padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  /** 今日已饮水量（ml） */
  todayMl(now: number = Date.now()): number {
    return this.prefs.getSync(WaterLog.todayKey(now), 0) as number;
  }

  /** 追加饮水量，返回今日新总量（ml） */
  addMl(ml: number, now: number = Date.now()): number {
    const total: number = Math.max(0, this.todayMl(now) + ml);
    this.prefs.putSync(WaterLog.todayKey(now), total);
    this.prefs.flush();
    return total;
  }

  /** 直接设定今日总量（与「每日状态」卡的水量字段同步用） */
  setMl(ml: number, now: number = Date.now()): void {
    this.prefs.putSync(WaterLog.todayKey(now), Math.max(0, ml));
    this.prefs.flush();
  }

  /** 日饮水目标（ml）：35 ml/kg；训练日 +500 ml */
  static goalMl(weightKg: number, isTrainingDay: boolean): number {
    const base: number = Math.round(weightKg * WaterLog.ML_PER_KG);
    return isTrainingDay ? base + WaterLog.TRAINING_BONUS_ML : base;
  }
}
