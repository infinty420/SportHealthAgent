/*
 * 文件标注：AI 生成 —— 训练日志数据模型与校验（通用数据模型脚手架）
 *
 * 数据接入层 · 训练日志模型
 * 按日期记录某一动作（关联 ExerciseLibrary.exerciseId）的每组表现：
 * 组数 × 次数 × 重量 × RPE（主观强度 6–10），供容量统计、1RM 估算与渐进超负荷规划使用。
 * 纯本地数据模型，无任何网络/系统 API 调用。
 */

/** 单组表现记录 */
export interface WorkoutSet {
  /** 组序（从 1 开始） */
  setIndex: number;
  /** 完成次数（时长类动作记 0，由上层以秒折算） */
  reps: number;
  /** 负重（公斤；自重/有氧动作为 0） */
  weightKg: number;
  /** 主观强度 RPE 6–10（10 为力竭） */
  rpe: number;
  /** 剩余次数 RIR 0–5；-1 表示未填写（双轨制：填了 RIR 则以 10-RIR 为准） */
  rir: number;
}

/** RPE 合法区间（RPE 6 以下对力量统计意义不大，拒收） */
export const RPE_MIN: number = 6;
export const RPE_MAX: number = 10;
/** RIR 合法区间（0 = 力竭，5 = 还能做 5 次；-1 = 未填） */
export const RIR_UNSET: number = -1;
export const RIR_MIN: number = 0;
export const RIR_MAX: number = 5;

/**
 * 组的有效强度（双轨制）：
 * 填了 RIR（≥ 0）时按 10 - RIR 折算为 RPE；否则用录入的 RPE。
 */
export function effectiveRpe(set: WorkoutSet): number {
  if (set.rir >= RIR_MIN && set.rir <= RIR_MAX) {
    return RPE_MAX - set.rir;
  }
  return set.rpe;
}
/** 单次训练组数上限（防误触录入） */
export const SETS_MAX: number = 20;
export const REPS_MAX: number = 200;
export const WEIGHT_MAX_KG: number = 500;

/** 一次训练中对某个动作的完整记录 */
export class WorkoutLog {
  /** 记录时间戳（毫秒，决定所属日期） */
  timestamp: number = 0;
  /** 动作 id（对应 ExerciseLibrary 条目；存在性校验由上层 store/页面完成） */
  exerciseId: string = '';
  /** 各组表现（至少 1 组） */
  sets: WorkoutSet[] = [];

  /**
   * 校验整条记录，返回中文错误信息列表（空列表 = 合法）。
   * 只校验字段自身合法性；exerciseId 是否存在由调用方查 ExerciseLibrary 判定。
   */
  validate(): string[] {
    const errors: string[] = [];
    if (this.timestamp <= 0) {
      errors.push('记录时间无效');
    }
    if (this.exerciseId.length === 0) {
      errors.push('未选择动作');
    }
    if (this.sets.length === 0) {
      errors.push('至少录入 1 组');
    }
    if (this.sets.length > SETS_MAX) {
      errors.push(`单次最多 ${SETS_MAX} 组`);
    }
    this.sets.forEach((set: WorkoutSet, idx: number) => {
      const label: string = `第 ${idx + 1} 组`;
      if (set.setIndex !== idx + 1) {
        errors.push(`${label}组序不连续`);
      }
      if (set.reps < 0 || set.reps > REPS_MAX) {
        errors.push(`${label}次数需在 0–${REPS_MAX} 之间`);
      }
      if (set.weightKg < 0 || set.weightKg > WEIGHT_MAX_KG) {
        errors.push(`${label}重量需在 0–${WEIGHT_MAX_KG} 公斤之间`);
      }
      if (set.rpe < RPE_MIN || set.rpe > RPE_MAX) {
        errors.push(`${label}RPE 需在 ${RPE_MIN}–${RPE_MAX} 之间`);
      }
      if (set.rir !== RIR_UNSET && (set.rir < RIR_MIN || set.rir > RIR_MAX)) {
        errors.push(`${label}RIR 需在 ${RIR_MIN}–${RIR_MAX} 之间，或留空`);
      }
    });
    return errors;
  }

  /** 总容量（公斤）= Σ 每组 次数 × 重量；自重动作恒为 0，由容量比公式单独折算 */
  totalVolume(): number {
    let volume: number = 0;
    this.sets.forEach((set: WorkoutSet) => {
      volume += set.reps * set.weightKg;
    });
    return volume;
  }

  /** 总次数 = Σ 每组次数（自重动作的容量代理指标） */
  totalReps(): number {
    let reps: number = 0;
    this.sets.forEach((set: WorkoutSet) => {
      reps += set.reps;
    });
    return reps;
  }

  /** 最佳组（重量最大，并列取次数更高者）；无组返回 null */
  bestSet(): WorkoutSet | null {
    let best: WorkoutSet | null = null;
    this.sets.forEach((set: WorkoutSet) => {
      if (best === null || set.weightKg > best.weightKg ||
        (set.weightKg === best.weightKg && set.reps > best.reps)) {
        best = set;
      }
    });
    return best;
  }

  /** 所属日期键（YYYY-MM-DD，本地时区，按天分桶用） */
  dateKey(): string {
    const date: Date = new Date(this.timestamp);
    const month: string = `${date.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${date.getDate()}`.padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }
}
