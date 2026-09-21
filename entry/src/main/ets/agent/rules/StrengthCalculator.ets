/*
 * 文件标注：自主业务逻辑 —— 力量估算规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 力量计算模块
 * Epley 与 Brzycki 双公式交叉估算 1RM（单次极限重量），
 * 并按 RPE 阈值统计有效组数与有效容量。
 * 确定性公式计算，无网络请求、无模型推理。
 */
import { WorkoutLog, WorkoutSet, effectiveRpe } from '../../model/WorkoutLog';

/** 计入"有效组"的 RPE 下限（RPE ≥ 7 视为接近力竭的工作组） */
export const EFFECTIVE_RPE_MIN: number = 7;

/** 双公式 1RM 估算结果 */
export interface OneRepMax {
  /** Epley 公式：重量 × (1 + 次数/30) */
  epley: number;
  /** Brzycki 公式：重量 × 36/(37 - 次数)（次数 ≥ 37 时退化为 Epley） */
  brzycki: number;
  /** 两公式均值（推荐采用值） */
  average: number;
}

export class StrengthCalculator {
  /**
   * 双公式估算 1RM。
   * 次数为 1 时直接取重量本身；重量 ≤ 0 或次数 ≤ 0 时返回全 0。
   */
  static estimateOneRepMax(weightKg: number, reps: number): OneRepMax {
    const result: OneRepMax = { epley: 0, brzycki: 0, average: 0 };
    if (weightKg <= 0 || reps <= 0) {
      return result;
    }
    if (reps === 1) {
      result.epley = weightKg;
      result.brzycki = weightKg;
      result.average = weightKg;
      return result;
    }
    result.epley = Math.round(weightKg * (1 + reps / 30) * 10) / 10;
    if (reps >= 37) {
      // Brzycki 分母趋零失效，退化为 Epley
      result.brzycki = result.epley;
    } else {
      result.brzycki = Math.round(weightKg * 36 / (37 - reps) * 10) / 10;
    }
    result.average = Math.round((result.epley + result.brzycki) / 2 * 10) / 10;
    return result;
  }

  /** 一条日志的估算 1RM：取各组估算值的最大值 */
  static bestOneRepMax(log: WorkoutLog): number {
    let best: number = 0;
    log.sets.forEach((set: WorkoutSet) => {
      const estimate: OneRepMax = StrengthCalculator.estimateOneRepMax(set.weightKg, set.reps);
      if (estimate.average > best) {
        best = estimate.average;
      }
    });
    return best;
  }

  /** 有效组数：有效强度（RPE/RIR 双轨折算）≥ 7 且次数 > 0 的组 */
  static effectiveSets(log: WorkoutLog): number {
    let count: number = 0;
    log.sets.forEach((set: WorkoutSet) => {
      if (effectiveRpe(set) >= EFFECTIVE_RPE_MIN && set.reps > 0) {
        count++;
      }
    });
    return count;
  }

  /** 有效容量（公斤）：仅统计有效组（有效强度 ≥ 7）的 次数 × 重量 */
  static effectiveVolume(log: WorkoutLog): number {
    let volume: number = 0;
    log.sets.forEach((set: WorkoutSet) => {
      if (effectiveRpe(set) >= EFFECTIVE_RPE_MIN && set.reps > 0) {
        volume += set.reps * set.weightKg;
      }
    });
    return volume;
  }

  /** 一批日志的有效组数合计（周组数统计用） */
  static totalEffectiveSets(logs: WorkoutLog[]): number {
    let count: number = 0;
    logs.forEach((log: WorkoutLog) => {
      count += StrengthCalculator.effectiveSets(log);
    });
    return count;
  }
}
