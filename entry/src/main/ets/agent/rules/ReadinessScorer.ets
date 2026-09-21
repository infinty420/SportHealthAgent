/*
 * 文件标注：自主业务逻辑 —— 训练准备度评分规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 准备度模块
 * 综合 疲劳指数 / 睡眠 / 肌群酸痛 / 距上次训练时长，
 * 输出 0–100 准备度分数与当日强度档（高/中/低/休息），
 * 并按三条件（疲劳≥70、准备度<40、连续训练≥6 天）给出过度训练 黄/橙/红 三级预警。
 * 确定性规则计算，无网络请求、无模型推理。
 */

/** 准备度评估结果 */
export interface ReadinessReport {
  /** 准备度分数（0–100，越高越适合训练） */
  score: number;
  /** 当日建议强度档：高 / 中 / 低 / 休息 */
  tier: string;
  /** 过度训练预警等级：无 / 黄 / 橙 / 红 */
  overtrainingLevel: string;
  /** 各扣分项的中文说明（可解释性） */
  notes: string[];
}

/** 评分输入（缺测项传 0，该维度不扣分） */
export interface ReadinessInput {
  /** 疲劳指数（FatigueModel 输出，0–100） */
  fatigueIndex: number;
  /** 昨晚睡眠时长（小时；0 = 未填） */
  sleepHours: number;
  /** 睡眠质量 1–5（0 = 未填） */
  sleepQuality: number;
  /** 肌群酸痛度 1–5（0 = 未填） */
  soreness: number;
  /** 距上次训练的小时数（<0 = 未知，不扣分） */
  hoursSinceLastTraining: number;
  /** 连续训练天数（含今天；用于过度训练判定） */
  consecutiveTrainingDays: number;
}

export class ReadinessScorer {
  /** 疲劳指数扣分权重（满分 40） */
  private static readonly FATIGUE_WEIGHT: number = 0.4;
  /** 过度训练：疲劳指数阈值 */
  private static readonly OT_FATIGUE_MIN: number = 70;
  /** 过度训练：准备度阈值 */
  private static readonly OT_SCORE_MAX: number = 40;
  /** 过度训练：连续训练天数阈值 */
  private static readonly OT_STREAK_MIN: number = 6;

  /** 计算准备度报告 */
  static score(input: ReadinessInput): ReadinessReport {
    let total: number = 100;
    const notes: string[] = [];

    // 疲劳指数：最多扣 40 分
    const fatigueCut: number = Math.round(Math.max(0, Math.min(100, input.fatigueIndex)) *
      ReadinessScorer.FATIGUE_WEIGHT);
    if (fatigueCut > 0) {
      total -= fatigueCut;
      notes.push(`疲劳指数 ${input.fatigueIndex}，-${fatigueCut} 分`);
    }

    // 睡眠时长：8h 不扣，7h 扣 5，6h 扣 12，<6h 扣 20
    if (input.sleepHours > 0) {
      let sleepCut: number = 0;
      if (input.sleepHours < 6) {
        sleepCut = 20;
      } else if (input.sleepHours < 7) {
        sleepCut = 12;
      } else if (input.sleepHours < 8) {
        sleepCut = 5;
      }
      if (sleepCut > 0) {
        total -= sleepCut;
        notes.push(`睡眠 ${input.sleepHours} 小时不足，-${sleepCut} 分`);
      }
      // 睡眠质量：每低一档扣 3 分
      if (input.sleepQuality > 0 && input.sleepQuality < 5) {
        const qualityCut: number = (5 - input.sleepQuality) * 3;
        total -= qualityCut;
        notes.push(`睡眠质量 ${input.sleepQuality}/5，-${qualityCut} 分`);
      }
    }

    // 肌群酸痛：每级扣 4 分
    if (input.soreness > 0) {
      const soreCut: number = input.soreness * 4;
      total -= soreCut;
      notes.push(`肌群酸痛 ${input.soreness}/5，-${soreCut} 分`);
    }

    // 距上次训练不足 24h 扣 10，不足 48h 扣 4
    if (input.hoursSinceLastTraining >= 0 && input.hoursSinceLastTraining < 24) {
      total -= 10;
      notes.push(`距上次训练不足 24 小时，-10 分`);
    } else if (input.hoursSinceLastTraining >= 24 && input.hoursSinceLastTraining < 48) {
      total -= 4;
      notes.push(`距上次训练不足 48 小时，-4 分`);
    }

    const score: number = Math.max(0, Math.min(100, Math.round(total)));

    // 强度档
    let tier: string = '休息';
    if (score >= 75) {
      tier = '高';
    } else if (score >= 50) {
      tier = '中';
    } else if (score >= 30) {
      tier = '低';
    }

    // 过度训练预警：命中条件数 → 黄(1)/橙(2)/红(3)
    let hits: number = 0;
    if (input.fatigueIndex >= ReadinessScorer.OT_FATIGUE_MIN) {
      hits++;
    }
    if (score < ReadinessScorer.OT_SCORE_MAX) {
      hits++;
    }
    if (input.consecutiveTrainingDays >= ReadinessScorer.OT_STREAK_MIN) {
      hits++;
    }
    let overtraining: string = '无';
    if (hits === 1) {
      overtraining = '黄';
      notes.push('过度训练黄色预警：建议降低强度或安排休息');
    } else if (hits === 2) {
      overtraining = '橙';
      notes.push('过度训练橙色预警：建议今天只做低强度恢复性训练');
    } else if (hits >= 3) {
      overtraining = '红';
      notes.push('过度训练红色预警：建议完全休息 1–2 天');
    }
    if (notes.length === 0) {
      notes.push('状态良好，可按计划训练');
    }

    const report: ReadinessReport = {
      score: score,
      tier: tier,
      overtrainingLevel: overtraining,
      notes: notes
    };
    return report;
  }
}
