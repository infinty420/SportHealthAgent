/*
 * 文件标注：AI 生成 —— 引擎装配（通用脚手架）
 *          自主业务逻辑 —— 被装配的规则模块见 agent/rules/ 目录，参数模型见 RuleConfig.ets
 *
 * 端侧 Agent 引擎 · 路线 A：纯规则引擎
 * 装配模块：① TrainingEvaluator 训练评估 ② DietPlanner 饮食方案
 *          ③ NextWorkoutPlanner 互补训练 ④ TrainingPlanPlanner 周计划 + FatigueModel 疲劳模型
 * 个性化：setUserProfile 后按画像动态调参（年龄修正心率区间、体重修正热量估算、目标微调配比）；
 *        setHistory 后按疲劳指数调整恢复时长、按采纳反馈微调建议强度。
 * 全部为确定性逻辑（if/else + 评分表），无网络请求、无云端大模型调用。
 */
import { HealthRecord } from '../model/HealthRecord';
import { UserGoal, UserProfile } from '../model/UserProfile';
import { HistoryEntry } from '../data/HistoryStore';
import { AnalysisEngine } from './AnalysisEngine';
import { AnalysisReport, NextWorkoutPlan, TrainingAssessment } from './AnalysisResult';
import { RuleConfig } from './RuleConfig';
import { TrainingEvaluator } from './rules/TrainingEvaluator';
import { DietPlanner } from './rules/DietPlanner';
import { NextWorkoutPlanner } from './rules/NextWorkoutPlanner';
import { TrainingPlanPlanner } from './rules/TrainingPlanPlanner';
import { FatigueModel, FatigueResult } from './rules/FatigueModel';

export class RuleAnalysisEngine implements AnalysisEngine {
  private config: RuleConfig = RuleConfig.defaults();
  private profile: UserProfile | null = null;
  private history: HistoryEntry[] = [];
  private injuredParts: string[] = [];

  /** 注入当前伤病部位（计划推荐动作经禁忌过滤） */
  setInjuries(parts: string[]): void {
    this.injuredParts = parts;
  }

  /** 更新规则参数（「规则设置」面板调整后调用，对下一次分析生效） */
  setConfig(config: RuleConfig): void {
    this.config = config;
  }

  getConfig(): RuleConfig {
    return this.config;
  }

  /** 注入用户画像（个性化调参开关；null 表示按通用参数运行） */
  setUserProfile(profile: UserProfile | null): void {
    this.profile = profile;
  }

  /** 注入历史记录（疲劳模型与采纳反馈的输入） */
  setHistory(entries: HistoryEntry[]): void {
    this.history = entries;
  }

  analyze(record: HealthRecord): AnalysisReport {
    // 热量缺失时按体重估算（画像已填写且用户未填热量）
    if (record.calories <= 0 && this.profile !== null && this.profile.filled) {
      record.calories = Math.round(record.durationMin * this.profile.weightKg * 0.12);
    }

    // 疲劳指数（近 7 天负荷加权）
    const fatigue: FatigueResult = FatigueModel.compute(this.history);

    // 按画像目标微调配比（减脂：蛋白↑碳水↓；增肌：碳水↑脂肪↓）
    const evaluator: TrainingEvaluator =
      new TrainingEvaluator(this.config.highThreshold, this.config.normalThreshold);
    let proteinPct: number = this.config.proteinPct;
    let carbPct: number = this.config.carbPct;
    if (this.profile !== null && this.profile.filled) {
      if (this.profile.goal === UserGoal.LOSE_FAT) {
        proteinPct += 5;
        carbPct -= 5;
      } else if (this.profile.goal === UserGoal.GAIN_MUSCLE) {
        carbPct += 5;
      }
    }
    const dietPlanner: DietPlanner = new DietPlanner(
      proteinPct / 100, carbPct / 100, this.config.overloadFactor, this.config.highThreshold);
    const workoutPlanner: NextWorkoutPlanner = new NextWorkoutPlanner(this.config.highThreshold);
    const planPlanner: TrainingPlanPlanner = new TrainingPlanPlanner();

    // 模块①：疲劳指数修正恢复时长
    const assessment: TrainingAssessment = evaluator.evaluate(record);
    assessment.suggestedRecoveryHours = Math.round(assessment.suggestedRecoveryHours * fatigue.recoveryFactor);
    if (fatigue.index >= 70) {
      assessment.advice += ` 注意：近 7 天疲劳指数 ${fatigue.index}（偏高），恢复时长已自动上调。`;
    }

    // 模块③：采纳反馈微调（近 10 条建议被忽略过半 → 强度降一档）
    const nextWorkout: NextWorkoutPlan = workoutPlanner.plan(record);
    const recent10: HistoryEntry[] = this.history.slice(0, 10);
    const ignored: number = recent10.filter((e: HistoryEntry) => e.adopted === 'ignored').length;
    if (recent10.length >= 4 && ignored * 2 >= recent10.length && nextWorkout.intensity === '中') {
      nextWorkout.intensity = '低-中';
      nextWorkout.durationMin = Math.max(15, nextWorkout.durationMin - 5);
      nextWorkout.reason += '（近期多条建议被忽略，本次已自动降低强度）';
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
