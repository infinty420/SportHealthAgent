/*
 * 文件标注：自主业务逻辑 —— 规则引擎 V2（加权评分 + 历史趋势斜率，参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 路线 A v2
 * 在 V1 确定性规则基础上引入：
 *   1. 加权评分表：本次负荷 0.6 权重 + 疲劳指数 0.4 权重，合成「有效负荷」再分档；
 *   2. 历史趋势斜率：最近 5 次负荷做一元线性回归，斜率显著上升/下降时调整建议强度；
 * 输出契约与 V1 完全一致（AnalysisReport），可与 V1 并行对比展示。
 * 纯规则计算，不接入任何模型 SDK 与网络。
 */
import { HealthRecord } from '../model/HealthRecord';
import { UserProfile } from '../model/UserProfile';
import { HistoryEntry } from '../data/HistoryStore';
import { AnalysisEngine } from './AnalysisEngine';
import { AnalysisReport, NextWorkoutPlan, TrainingAssessment } from './AnalysisResult';
import { RuleConfig } from './RuleConfig';
import { TrainingEvaluator } from './rules/TrainingEvaluator';
import { DietPlanner } from './rules/DietPlanner';
import { NextWorkoutPlanner } from './rules/NextWorkoutPlanner';
import { TrainingPlanPlanner } from './rules/TrainingPlanPlanner';
import { FatigueModel, FatigueResult } from './rules/FatigueModel';

export class RuleAnalysisEngineV2 implements AnalysisEngine {
  private config: RuleConfig = RuleConfig.defaults();
  private profile: UserProfile | null = null;
  private history: HistoryEntry[] = [];
  private injuredParts: string[] = [];

  /** 注入当前伤病部位（计划推荐动作经禁忌过滤） */
  setInjuries(parts: string[]): void {
    this.injuredParts = parts;
  }

  setConfig(config: RuleConfig): void {
    this.config = config;
  }

  setUserProfile(profile: UserProfile | null): void {
    this.profile = profile;
  }

  setHistory(entries: HistoryEntry[]): void {
    this.history = entries;
  }

  /**
   * 最近 5 次负荷的一元线性回归斜率（按时间正序）。
   * 斜率 > 5：负荷快速上升；< -5：快速下降；其间为平稳。
   */
  private loadSlope(): number {
    const recent: HistoryEntry[] = this.history.slice(0, 5);
    recent.reverse();
    const n: number = recent.length;
    if (n < 3) {
      return 0;
    }
    let sumX: number = 0;
    let sumY: number = 0;
    let sumXY: number = 0;
    let sumXX: number = 0;
    for (let i = 0; i < n; i++) {
      sumX += i;
      sumY += recent[i].load;
      sumXY += i * recent[i].load;
      sumXX += i * i;
    }
    const denominator: number = n * sumXX - sumX * sumX;
    if (denominator === 0) {
      return 0;
    }
    return (n * sumXY - sumX * sumY) / denominator;
  }

  analyze(record: HealthRecord): AnalysisReport {
    const fatigue: FatigueResult = FatigueModel.compute(this.history);

    // 加权评分表：有效负荷 = 0.6 × 本次负荷 + 0.4 × 疲劳指数
    const effectiveLoad: number = Math.round(record.trainingLoad * 0.6 + fatigue.index * 0.4);
    const weightedRecord: HealthRecord = new HealthRecord();
    weightedRecord.durationMin = record.durationMin;
    weightedRecord.avgHeartRate = record.avgHeartRate;
    weightedRecord.pace = record.pace;
    weightedRecord.calories = record.calories;
    weightedRecord.sportType = record.sportType;
    weightedRecord.trainingLoad = effectiveLoad;

    const evaluator: TrainingEvaluator =
      new TrainingEvaluator(this.config.highThreshold, this.config.normalThreshold);
    const dietPlanner: DietPlanner = new DietPlanner(
      this.config.proteinPct / 100, this.config.carbPct / 100,
      this.config.overloadFactor, this.config.highThreshold);
    const workoutPlanner: NextWorkoutPlanner = new NextWorkoutPlanner(this.config.highThreshold);
    const planPlanner: TrainingPlanPlanner = new TrainingPlanPlanner();

    const assessment: TrainingAssessment = evaluator.evaluate(weightedRecord);
    assessment.suggestedRecoveryHours = Math.round(assessment.suggestedRecoveryHours * fatigue.recoveryFactor);

    // 历史趋势斜率调整建议
    const slope: number = this.loadSlope();
    if (slope > 5) {
      assessment.advice += ` 负荷趋势连续上升（斜率 +${Math.round(slope)}/次），V2 建议本周内安排减量日。`;
    } else if (slope < -5) {
      assessment.advice += ` 负荷趋势连续下降（斜率 ${Math.round(slope)}/次），V2 建议逐步回升强度避免退化。`;
    }

    const nextWorkout: NextWorkoutPlan = workoutPlanner.plan(weightedRecord);
    if (slope > 5 && nextWorkout.intensity !== '低') {
      nextWorkout.intensity = '低-中';
      nextWorkout.reason += '（V2：负荷上升趋势，强度自动降一档）';
    }

    const profile: UserProfile = this.profile !== null ? this.profile : new UserProfile();
    return {
      assessment: assessment,
      diet: dietPlanner.plan(record),
      nextWorkout: nextWorkout,
      weeklyPlan: planPlanner.plan(record, this.history, profile, this.injuredParts),
      fatigueIndex: fatigue.index,
      generatedAt: new Date().toLocaleString()
    };
  }
}
