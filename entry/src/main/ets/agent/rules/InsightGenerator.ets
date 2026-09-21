/*
 * 文件标注：自主业务逻辑 —— 训练洞察生成规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 洞察模块
 * 把本地统计结果翻译成模板化中文结论句，每条附依据（输入值 + 命中规则名），
 * 保证可解释性：用户能看懂每条结论是怎么得出来的。
 * 确定性规则计算，无网络请求、无模型推理。
 */

/** 一条洞察 */
export interface Insight {
  /** 结论句 */
  text: string;
  /** 依据（输入值 + 命中规则名） */
  evidence: string;
  /** 倾向：正 / 负 / 中性 */
  sentiment: string;
}

/** 洞察输入（由调用方聚合后传入；缺测项传 0/false，对应洞察不产出） */
export interface InsightInput {
  /** 本周训练次数 */
  weeklySessions: number;
  /** 上周训练次数 */
  prevWeeklySessions: number;
  /** 本周容量（公斤，力量训练） */
  weeklyVolumeKg: number;
  /** 上周容量（公斤） */
  prevWeeklyVolumeKg: number;
  /** 当前连续训练天数 */
  streak: number;
  /** 准备度分数（0–100；-1 = 未计算） */
  readinessScore: number;
  /** 过度训练预警等级（无/黄/橙/红） */
  overtrainingLevel: string;
  /** 肌群失衡描述列表（来自 MuscleBalanceAnalyzer） */
  imbalances: string[];
  /** 处于平台期的动作数 */
  plateauExercises: number;
  /** 体重每周变化（公斤/周；0 = 未计算） */
  weightSlopeKgPerWeek: number;
  /** 训练目标（减脂/维持/增肌；空串 = 未知） */
  goal: string;
}

export class InsightGenerator {
  /** 生成洞察列表（按重要性排序：预警 > 负向 > 正向 > 中性） */
  static generate(input: InsightInput): Insight[] {
    const insights: Insight[] = [];

    if (input.overtrainingLevel === '红' || input.overtrainingLevel === '橙') {
      insights.push({
        text: `存在过度训练风险（${input.overtrainingLevel}色预警），建议立即安排休息或减载周`,
        evidence: `依据：预警等级=${input.overtrainingLevel}（规则：ReadinessScorer 过度训练三条件）`,
        sentiment: '负'
      });
    }
    if (input.readinessScore >= 0 && input.readinessScore < 40) {
      insights.push({
        text: '今日准备度偏低，建议选择低强度恢复性训练或休息',
        evidence: `依据：准备度 ${input.readinessScore} 分 < 40（规则：ReadinessScorer 强度档）`,
        sentiment: '负'
      });
    }
    if (input.prevWeeklySessions > 0 && input.weeklySessions < input.prevWeeklySessions) {
      insights.push({
        text: '本周训练频次低于上周，注意保持节奏',
        evidence: `依据：本周 ${input.weeklySessions} 次 vs 上周 ${input.prevWeeklySessions} 次（规则：频次环比）`,
        sentiment: '负'
      });
    }
    if (input.prevWeeklyVolumeKg > 0 && input.weeklyVolumeKg > input.prevWeeklyVolumeKg * 1.3) {
      insights.push({
        text: '本周容量较上周增长超 30%，增长过快，注意恢复',
        evidence: `依据：本周 ${Math.round(input.weeklyVolumeKg)}kg vs 上周 ${Math.round(input.prevWeeklyVolumeKg)}kg` +
          '（规则：容量周增幅 ≤ 30%）',
        sentiment: '负'
      });
    }
    input.imbalances.forEach((text: string) => {
      insights.push({
        text: `肌群失衡：${text}`,
        evidence: '依据：近 7 天有效组数分布（规则：MuscleBalanceAnalyzer 推拉腿阈值）',
        sentiment: '负'
      });
    });
    if (input.plateauExercises > 0) {
      insights.push({
        text: `${input.plateauExercises} 个动作进入平台期，建议加组或安排减载`,
        evidence: `依据：连续 2 次无进步动作 ${input.plateauExercises} 个（规则：ProgressiveOverloadPlanner 平台期）`,
        sentiment: '负'
      });
    }
    if (input.streak >= 7) {
      insights.push({
        text: `已连续训练 ${input.streak} 天，自律性出色，注意安排休息日`,
        evidence: `依据：连练 ${input.streak} 天 ≥ 7（规则：streak 里程碑）`,
        sentiment: '正'
      });
    }
    if (input.weeklySessions >= 3 && input.prevWeeklySessions >= 0) {
      insights.push({
        text: '本周训练频次达标，保持即可',
        evidence: `依据：本周 ${input.weeklySessions} 次 ≥ 3（规则：频次健康线）`,
        sentiment: '正'
      });
    }
    if (input.weightSlopeKgPerWeek !== 0 && input.goal === '减脂' && input.weightSlopeKgPerWeek < 0) {
      insights.push({
        text: `体重趋势符合减脂目标（每周 ${input.weightSlopeKgPerWeek}kg）`,
        evidence: `依据：14 天最小二乘斜率 ${input.weightSlopeKgPerWeek}kg/周（规则：WeightTrendAnalyzer 趋势）`,
        sentiment: '正'
      });
    }
    if (input.weightSlopeKgPerWeek > 0.5 && input.goal === '增肌') {
      insights.push({
        text: '体重增长偏快，增肌期建议控制在每周 +0.25~0.5kg',
        evidence: `依据：14 天最小二乘斜率 ${input.weightSlopeKgPerWeek}kg/周 > 0.5（规则：WeightTrendAnalyzer 增肌速率上限）`,
        sentiment: '负'
      });
    }
    if (insights.length === 0) {
      insights.push({
        text: '数据积累中：完成几次训练并记录每日状态后，这里会给出个性化结论',
        evidence: '依据：暂无可命中规则（规则：InsightGenerator 兜底）',
        sentiment: '中'
      });
    }
    return insights;
  }
}
