/*
 * 文件标注：自主业务逻辑 —— What-if 情景模拟规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · What-if 模块
 * 输入「每周训练次数 / 每日热量调整」两个假设，推算 4 周与 8 周后的
 * 训练负荷累积与体重变化（7700 kcal ≈ 1kg 体脂经验公式）。
 * 确定性规则计算，无网络请求、无模型推理。
 */

/** What-if 模拟结果 */
export interface WhatIfResult {
  /** 4 周后预计体重（公斤） */
  weight4WeekKg: number;
  /** 8 周后预计体重（公斤） */
  weight8WeekKg: number;
  /** 4 周累计训练负荷（负荷点 = 次数 × 单次平均负荷） */
  load4Week: number;
  /** 8 周累计训练负荷 */
  load8Week: number;
  /** 中文解读 */
  note: string;
}

export class WhatIfSimulator {
  /** 每公斤体脂约对应的热量缺口（kcal/kg，经验值） */
  private static readonly KCAL_PER_KG: number = 7700;
  /** 减脂安全速率下限（kg/周，低于此速度过快给出提示） */
  private static readonly LOSS_RATE_WARN: number = -1.0;

  /**
   * 模拟未来趋势。
   * @param currentWeightKg 当前体重
   * @param newWeeklySessions 假设的每周训练次数
   * @param avgSessionLoad 当前单次平均负荷（由历史统计得出）
   * @param calorieDeltaPerDay 假设的每日热量增减（kcal；负 = 缺口）
   */
  static simulate(currentWeightKg: number, newWeeklySessions: number,
    avgSessionLoad: number, calorieDeltaPerDay: number): WhatIfResult {
    const dailyDeltaKg: number = calorieDeltaPerDay / WhatIfSimulator.KCAL_PER_KG;
    const weight4: number = Math.round((currentWeightKg + dailyDeltaKg * 28) * 10) / 10;
    const weight8: number = Math.round((currentWeightKg + dailyDeltaKg * 56) * 10) / 10;
    const weeklyLoad: number = newWeeklySessions * avgSessionLoad;
    const load4: number = Math.round(weeklyLoad * 4);
    const load8: number = Math.round(weeklyLoad * 8);

    const weeklyRate: number = dailyDeltaKg * 7;
    let note: string;
    if (weeklyRate < WhatIfSimulator.LOSS_RATE_WARN) {
      note = `减重速率 ${Math.round(weeklyRate * 100) / 100}kg/周 过快，建议缩小热量缺口，避免肌肉流失`;
    } else if (calorieDeltaPerDay < 0) {
      note = `每日缺口 ${-calorieDeltaPerDay} kcal：4 周约 ${weight4}kg，8 周约 ${weight8}kg`;
    } else if (calorieDeltaPerDay > 0) {
      note = `每日盈余 ${calorieDeltaPerDay} kcal：4 周约 ${weight4}kg，8 周约 ${weight8}kg（增肌期建议盈余 ≤ 300 kcal）`;
    } else {
      note = '热量维持现状：体重预计基本不变';
    }
    const result: WhatIfResult = {
      weight4WeekKg: weight4,
      weight8WeekKg: weight8,
      load4Week: load4,
      load8Week: load8,
      note: note
    };
    return result;
  }
}
