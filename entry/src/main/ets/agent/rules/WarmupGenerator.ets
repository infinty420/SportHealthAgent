/*
 * 文件标注：自主业务逻辑 —— 热身组生成规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 热身规划模块
 * 依据主项估算 1RM 生成热身组序列：空杆/轻重量激活 → 40% → 60% → 75% → 85% 递进，
 * 重量按 2.5kg 圆整。确定性规则计算，无网络请求、无模型推理。
 */

/** 一组热身安排 */
export interface WarmupSet {
  weightKg: number;
  reps: number;
  /** 说明（如「空杆激活」「60% 1RM」） */
  note: string;
}

/** 热身重量圆整步长（公斤） */
const ROUND_STEP_KG: number = 2.5;
/** 空杆基准重量（公斤） */
const EMPTY_BAR_KG: number = 20;

export class WarmupGenerator {
  /**
   * 依据主项 1RM 生成热身组序列（1RM ≤ 0 时返回空数组）。
   * 小重量（1RM < 60kg）省略中间档，避免热身疲劳。
   */
  static generate(oneRepMaxKg: number): WarmupSet[] {
    const sets: WarmupSet[] = [];
    if (oneRepMaxKg <= 0) {
      return sets;
    }

    const bar: WarmupSet = { weightKg: EMPTY_BAR_KG, reps: 10, note: '空杆/轻重量激活' };
    sets.push(bar);

    const percentages: number[] = oneRepMaxKg < 60 ? [0.6, 0.8] : [0.4, 0.6, 0.75, 0.85];
    const repsScheme: number[] = [5, 3, 2, 1];
    percentages.forEach((pct: number, idx: number) => {
      const weight: number = WarmupGenerator.roundToStep(oneRepMaxKg * pct);
      // 与空杆档重量重复时跳过
      if (weight > EMPTY_BAR_KG) {
        const set: WarmupSet = {
          weightKg: weight,
          reps: repsScheme[idx % repsScheme.length],
          note: `${Math.round(pct * 100)}% 1RM`
        };
        sets.push(set);
      }
    });
    return sets;
  }

  /** 按 2.5kg 步长圆整 */
  private static roundToStep(weightKg: number): number {
    return Math.round(weightKg / ROUND_STEP_KG) * ROUND_STEP_KG;
  }
}
