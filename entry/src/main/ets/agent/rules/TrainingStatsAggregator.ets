/*
 * 文件标注：自主业务逻辑 —— 训练统计聚合规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 统计聚合模块
 * 为「发现」页提供按周/月/年的范围计算与聚合：
 *   部位频次 / 部位有效组数 / 部位容量最佳日 / 周期训练时长对比。
 * 全部基于本地 WorkoutLog 与 HistoryEntry 的确定性规则计算，无网络请求。
 */

import { WorkoutLog } from '../../model/WorkoutLog';
import { HistoryEntry } from '../../data/HistoryStore';
import { ExerciseItem, ExerciseLibrary } from '../../data/ExerciseLibrary';
import { StrengthCalculator } from './StrengthCalculator';

/** 统计周期类型 */
export type StatsPeriod = 'week' | 'month' | 'year';

/** 一个统计范围（左闭右开） */
export interface StatsRange {
  /** 起始时间戳（含，当日 0 点） */
  startMs: number;
  /** 结束时间戳（不含，下一周期 0 点） */
  endMs: number;
  /** 展示标签，如 2026年9月21日-9月27日 / 2026年9月 / 2026年 */
  label: string;
}

/** 单个部位组在范围内的聚合结果 */
export interface MuscleStat {
  /** 部位组名（胸/背/肩/腿/臀/腹/手臂） */
  muscle: string;
  /** 训练频次（含该部位的日志条数） */
  sessions: number;
  /** 有效组数合计（RPE≥7 的组） */
  effectiveSets: number;
  /** 容量合计（公斤） */
  volumeKg: number;
}

/** 某部位容量最高的一天 */
export interface VolumeBestDay {
  /** 日期键 YYYY-MM-DD */
  dateKey: string;
  /** 当日该部位容量（公斤） */
  volumeKg: number;
}

/** 人体热力图固定的 7 个部位组（顺序即图例顺序） */
export const HEAT_MUSCLE_GROUPS: string[] = ['胸', '背', '肩', '腿', '臀', '腹', '手臂'];

export class TrainingStatsAggregator {
  private static readonly DAY_MS: number = 86400000;

  /**
   * 原始部位 → 热力部位组映射。
   * 二头/三头/小臂并入「手臂」；有氧/拉伸/全身不参与人体部位统计，返回空串。
   */
  static groupOf(muscle: string): string {
    if (muscle === '二头' || muscle === '三头' || muscle === '小臂') {
      return '手臂';
    }
    if (muscle === '胸' || muscle === '背' || muscle === '肩' ||
      muscle === '腿' || muscle === '臀' || muscle === '腹') {
      return muscle;
    }
    return '';
  }

  /** 计算 anchor 所在周期的范围（周一为一周起点） */
  static rangeFor(period: StatsPeriod, anchorMs: number): StatsRange {
    const anchor: Date = new Date(anchorMs);
    const year: number = anchor.getFullYear();
    const month: number = anchor.getMonth();
    if (period === 'year') {
      const range: StatsRange = {
        startMs: new Date(year, 0, 1).getTime(),
        endMs: new Date(year + 1, 0, 1).getTime(),
        label: `${year}年`
      };
      return range;
    }
    if (period === 'month') {
      const range: StatsRange = {
        startMs: new Date(year, month, 1).getTime(),
        endMs: new Date(year, month + 1, 1).getTime(),
        label: `${year}年${month + 1}月`
      };
      return range;
    }
    // week：周一开头
    const weekday: number = (anchor.getDay() + 6) % 7;
    const monday: Date = new Date(year, month, anchor.getDate() - weekday);
    const sunday: Date = new Date(year, month, anchor.getDate() - weekday + 6);
    const range: StatsRange = {
      startMs: monday.getTime(),
      endMs: monday.getTime() + 7 * TrainingStatsAggregator.DAY_MS,
      label: `${monday.getFullYear()}年${monday.getMonth() + 1}月${monday.getDate()}日-` +
        `${sunday.getMonth() + 1}月${sunday.getDate()}日`
    };
    return range;
  }

  /** 范围翻页：把 anchor 移到上/下一周期同一天 */
  static shiftAnchor(period: StatsPeriod, anchorMs: number, direction: number): number {
    const anchor: Date = new Date(anchorMs);
    if (period === 'year') {
      return new Date(anchor.getFullYear() + direction, anchor.getMonth(), anchor.getDate()).getTime();
    }
    if (period === 'month') {
      return new Date(anchor.getFullYear(), anchor.getMonth() + direction, anchor.getDate()).getTime();
    }
    return anchorMs + direction * 7 * TrainingStatsAggregator.DAY_MS;
  }

  /** 过滤范围内的日志（保持传入顺序） */
  static filterLogs(logs: WorkoutLog[], range: StatsRange): WorkoutLog[] {
    return logs.filter((log: WorkoutLog) => log.timestamp >= range.startMs && log.timestamp < range.endMs);
  }

  /** 过滤范围内的历史记录并求总时长（分钟） */
  static durationMin(entries: HistoryEntry[], range: StatsRange): number {
    let total: number = 0;
    entries.forEach((entry: HistoryEntry) => {
      if (entry.timestamp >= range.startMs && entry.timestamp < range.endMs) {
        total += entry.durationMin;
      }
    });
    return total;
  }

  /**
   * 按部位组聚合频次/有效组数/容量。
   * 只统计 HEAT_MUSCLE_GROUPS 内的部位；返回顺序与 HEAT_MUSCLE_GROUPS 一致。
   */
  static muscleStats(logs: WorkoutLog[]): MuscleStat[] {
    const sessions: Map<string, number> = new Map<string, number>();
    const sets: Map<string, number> = new Map<string, number>();
    const volume: Map<string, number> = new Map<string, number>();
    logs.forEach((log: WorkoutLog) => {
      const item: ExerciseItem | null = ExerciseLibrary.findById(log.exerciseId);
      if (item === null) {
        return;
      }
      const group: string = TrainingStatsAggregator.groupOf(item.muscle);
      if (group.length === 0) {
        return;
      }
      sessions.set(group, (sessions.get(group) ?? 0) + 1);
      sets.set(group, (sets.get(group) ?? 0) + StrengthCalculator.effectiveSets(log));
      volume.set(group, (volume.get(group) ?? 0) + log.totalVolume());
    });
    const result: MuscleStat[] = [];
    HEAT_MUSCLE_GROUPS.forEach((group: string) => {
      const stat: MuscleStat = {
        muscle: group,
        sessions: sessions.get(group) ?? 0,
        effectiveSets: sets.get(group) ?? 0,
        volumeKg: volume.get(group) ?? 0
      };
      result.push(stat);
    });
    return result;
  }

  /** 某部位组在（已按范围过滤的）日志中容量最高的一天；无容量记录返回 null */
  static bestVolumeDay(logs: WorkoutLog[], muscleGroup: string): VolumeBestDay | null {
    const byDate: Map<string, number> = new Map<string, number>();
    logs.forEach((log: WorkoutLog) => {
      const item: ExerciseItem | null = ExerciseLibrary.findById(log.exerciseId);
      if (item === null || TrainingStatsAggregator.groupOf(item.muscle) !== muscleGroup) {
        return;
      }
      const vol: number = log.totalVolume();
      if (vol <= 0) {
        return;
      }
      const key: string = log.dateKey();
      byDate.set(key, (byDate.get(key) ?? 0) + vol);
    });
    let best: VolumeBestDay | null = null;
    byDate.forEach((vol: number, key: string) => {
      if (best === null || vol > best.volumeKg) {
        best = { dateKey: key, volumeKg: vol };
      }
    });
    return best;
  }
}
