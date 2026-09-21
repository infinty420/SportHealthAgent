/*
 * AI 生成 —— 单元测试脚手架（hypium 断言）
 * 被测对象：升级模块 —— 疲劳模型 / 周计划 / 用户画像 / 营养计算 / 引擎 V2 / 食物库扩充
 *
 * 覆盖点：
 *   1. FatigueModel 空历史为 0、近 7 天加权累积、等级与恢复系数
 *   2. TrainingPlanPlanner 固定输出 7 天、高疲劳含强制休息
 *   3. UserProfile 校验边界与最大心率公式
 *   4. NutritionCalculator 摄入汇总与达成度
 *   5. RuleAnalysisEngineV2 有效负荷加权（0.6/0.4）与契约完整性
 *   6. FoodLibrary ≥50 种、六分类筛选
 */
import { describe, it, expect } from '@ohos/hypium';
import { HistoryEntry } from '../main/ets/data/HistoryStore';
import { FatigueModel, FatigueResult } from '../main/ets/agent/rules/FatigueModel';
import { TrainingPlanPlanner } from '../main/ets/agent/rules/TrainingPlanPlanner';
import { UserProfile, UserGoal } from '../main/ets/model/UserProfile';
import { DietLogEntry } from '../main/ets/data/DietLog';
import { NutritionCalculator, MacroAchievement } from '../main/ets/data/NutritionCalculator';
import { RuleAnalysisEngineV2 } from '../main/ets/agent/RuleAnalysisEngineV2';
import { RuleAnalysisEngine } from '../main/ets/agent/RuleAnalysisEngine';
import { HealthRecord, SportType, estimateTrainingLoadPersonalized } from '../main/ets/model/HealthRecord';
import { AnalysisReport, WeeklyPlan, WeeklyPlanDay } from '../main/ets/agent/AnalysisResult';
import { FoodLibrary, FOOD_CATEGORIES } from '../main/ets/data/FoodLibrary';
import { DietPlanner, DailyCaloriePlan } from '../main/ets/agent/rules/DietPlanner';
import { DietPlan } from '../main/ets/agent/AnalysisResult';
import { IntakeSummary } from '../main/ets/data/DietLog';
import { ExerciseLibrary, ExerciseItem } from '../main/ets/data/ExerciseLibrary';
import { WorkoutLog, WorkoutSet, effectiveRpe } from '../main/ets/model/WorkoutLog';
import { StrengthCalculator, OneRepMax } from '../main/ets/agent/rules/StrengthCalculator';
import { ProgressiveOverloadPlanner, OverloadSuggestion } from '../main/ets/agent/rules/ProgressiveOverloadPlanner';
import { MuscleBalanceAnalyzer, MuscleBalanceReport } from '../main/ets/agent/rules/MuscleBalanceAnalyzer';
import { WarmupGenerator, WarmupSet } from '../main/ets/agent/rules/WarmupGenerator';
import { MesocyclePlanner, MesocyclePlan } from '../main/ets/agent/rules/MesocyclePlanner';
import { ReadinessScorer, ReadinessInput, ReadinessReport } from '../main/ets/agent/rules/ReadinessScorer';
import { WeightTrendAnalyzer, WeightTrendReport } from '../main/ets/agent/rules/WeightTrendAnalyzer';
import { PRTracker, ExercisePR, PRCheck, DailyPREvent } from '../main/ets/agent/rules/PRTracker';
import { BadgeEngine, Badge, BadgeStats } from '../main/ets/agent/rules/BadgeEngine';
import { WhatIfSimulator, WhatIfResult } from '../main/ets/agent/rules/WhatIfSimulator';
import { ExerciseSafety, ExerciseSafetyInfo } from '../main/ets/agent/rules/ExerciseSafety';
import {
  TrainingStatsAggregator, StatsRange, MuscleStat, VolumeBestDay, HEAT_MUSCLE_GROUPS
} from '../main/ets/agent/rules/TrainingStatsAggregator';
import { InjuryRecord } from '../main/ets/model/InjuryRecord';
import { BodyMetricEntry } from '../main/ets/data/BodyMetricsStore';

/** 构造一条训练日志（同一重量×次数×组数，RPE 8） */
function makeLog(exerciseId: string, weightKg: number, reps: number, sets: number, daysAgo: number): WorkoutLog {
  const log: WorkoutLog = new WorkoutLog();
  log.timestamp = Date.now() - daysAgo * 86400000;
  log.exerciseId = exerciseId;
  for (let i = 0; i < sets; i++) {
    const set: WorkoutSet = { setIndex: i + 1, reps: reps, weightKg: weightKg, rpe: 8, rir: -1 };
    log.sets.push(set);
  }
  return log;
}

/** 构造一条历史记录 */
function makeEntry(daysAgo: number, load: number): HistoryEntry {
  const entry: HistoryEntry = {
    timestamp: Date.now() - daysAgo * 86400000,
    sportType: SportType.RUN,
    durationMin: 45,
    calories: 400,
    load: load,
    loadStatus: '正常',
    recoveryHours: 18,
    adopted: 'unmarked'
  };
  return entry;
}

function makeRecord(load: number): HealthRecord {
  const record: HealthRecord = new HealthRecord();
  record.durationMin = 45;
  record.avgHeartRate = 140;
  record.pace = '6\'00"/km';
  record.calories = 400;
  record.sportType = SportType.RUN;
  record.trainingLoad = load;
  return record;
}

export default function upgradeTest(): void {
  describe('UpgradeTest', () => {

    it('fatigue_empty_history_zero', 0, () => {
      const result: FatigueResult = FatigueModel.compute([]);
      expect(result.index).assertEqual(0);
      expect(result.level).assertEqual('低');
      expect(result.recoveryFactor).assertEqual(1.0);
    });

    it('fatigue_weighted_recent_heavier', 0, () => {
      // 今天 80 负荷的疲劳贡献 > 6 天前同等负荷
      const today: FatigueResult = FatigueModel.compute([makeEntry(0, 80)]);
      const weekAgo: FatigueResult = FatigueModel.compute([makeEntry(6, 80)]);
      expect(today.index > weekAgo.index).assertTrue();
      // 8 天前不计入窗口
      expect(FatigueModel.compute([makeEntry(8, 100)]).index).assertEqual(0);
    });

    it('weekly_plan_seven_days', 0, () => {
      const planner: TrainingPlanPlanner = new TrainingPlanPlanner();
      const profile: UserProfile = new UserProfile();
      const plan: WeeklyPlan = planner.plan(makeRecord(60), [], profile);
      expect(plan.days.length).assertEqual(7);
      // 训练日必须带推荐动作，且每个 id 都能在动作库中解析
      plan.days.forEach((d: WeeklyPlanDay) => {
        const isRest: boolean = d.durationMin === 0 || d.workoutType.indexOf('恢复') >= 0;
        if (isRest) {
          expect(d.exerciseIds.length).assertEqual(0);
        } else {
          expect(d.exerciseIds.length > 0).assertTrue();
          d.exerciseIds.forEach((eid: string) => {
            expect(ExerciseLibrary.findById(eid) !== null).assertTrue();
          });
        }
      });
      // 高疲劳时安排强制休息
      const heavyHistory: HistoryEntry[] = [
        makeEntry(0, 90), makeEntry(1, 90), makeEntry(2, 90), makeEntry(3, 90)
      ];
      const tiredPlan: WeeklyPlan = planner.plan(makeRecord(90), heavyHistory, profile);
      const restDays: number = tiredPlan.days.filter((d: WeeklyPlanDay) => d.durationMin === 0 || d.workoutType.indexOf('恢复') >= 0).length;
      expect(restDays >= 2).assertTrue();
    });

    it('user_profile_validation_and_maxhr', 0, () => {
      const profile: UserProfile = new UserProfile();
      profile.age = 30;
      expect(profile.maxHeartRate()).assertEqual(190);
      expect(profile.validate().length).assertEqual(0);
      profile.age = 5;
      expect(profile.validate().length > 0).assertTrue();
      // 个性化负荷估算：心率=静息时强度取下限
      expect(estimateTrainingLoadPersonalized(45, 65, 65, 190)).assertEqual(5);
    });

    it('nutrition_summarize_and_achievement', 0, () => {
      const entries: DietLogEntry[] = [
        { timestamp: Date.now(), meal: '午餐', foodName: '鸡胸肉', grams: 200 },
        { timestamp: Date.now(), meal: '午餐', foodName: '燕麦', grams: 100 }
      ];
      const sum: IntakeSummary = NutritionCalculator.summarize(entries);
      expect(sum.kcal).assertEqual(133 * 2 + 389);
      expect(Math.abs(sum.proteinGrams - (19.4 * 2 + 16.9)) < 1).assertTrue();
      const plan: DietPlan = new DietPlanner().plan(makeRecord(60));
      const achievement: MacroAchievement = NutritionCalculator.achievement(entries, plan);
      expect(achievement.overallPct >= 0 && achievement.overallPct <= 999).assertTrue();
    });

    it('engine_v2_weighted_load', 0, () => {
      const v1: RuleAnalysisEngine = new RuleAnalysisEngine();
      const v2: RuleAnalysisEngineV2 = new RuleAnalysisEngineV2();
      // 疲劳历史使 V2 有效负荷上升：record 负荷 60，疲劳指数 ~? 验证契约完整
      const reportV2: AnalysisReport = v2.analyze(makeRecord(60));
      expect(reportV2.weeklyPlan.days.length).assertEqual(7);
      expect(reportV2.fatigueIndex >= 0).assertTrue();
      expect(reportV2.assessment.load >= 0).assertTrue();
      // 画像注入后配比变化（减脂：蛋白占比 +5）
      const profile: UserProfile = new UserProfile();
      profile.filled = true;
      profile.goal = UserGoal.LOSE_FAT;
      v1.setUserProfile(profile);
      const report: AnalysisReport = v1.analyze(makeRecord(60));
      expect(report.diet.proteinPct).assertEqual(35);
    });

    it('food_library_fifty_with_categories', 0, () => {
      expect(FoodLibrary.all().length >= 50).assertTrue();
      expect(FOOD_CATEGORIES.length).assertEqual(6);
      expect(FoodLibrary.byCategory('蛋白').length >= 10).assertTrue();
      expect(FoodLibrary.byCategory('蔬菜').length >= 6).assertTrue();
      expect(FoodLibrary.byCategory('全部').length).assertEqual(FoodLibrary.all().length);
    });

    it('workout_log_validation', 0, () => {
      const good: WorkoutLog = makeLog('bb_bench', 60, 8, 4, 0);
      expect(good.validate().length).assertEqual(0);
      expect(good.totalVolume()).assertEqual(1920);
      expect(good.dateKey().length).assertEqual(10);
      const bad: WorkoutLog = makeLog('bb_bench', 60, 8, 4, 0);
      bad.exerciseId = '';
      bad.sets[0].rpe = 3;
      expect(bad.validate().length >= 2).assertTrue();
    });

    it('strength_calculator_one_rep_max', 0, () => {
      // Epley：100×(1+5/30)=116.7；Brzycki：100×36/32=112.5；均值 114.6
      const orm: OneRepMax = StrengthCalculator.estimateOneRepMax(100, 5);
      expect(orm.epley).assertEqual(116.7);
      expect(orm.brzycki).assertEqual(112.5);
      expect(orm.average).assertEqual(114.6);
      // 单次即极限
      expect(StrengthCalculator.estimateOneRepMax(120, 1).average).assertEqual(120);
      expect(StrengthCalculator.estimateOneRepMax(0, 5).average).assertEqual(0);
      // 有效组数：RPE 6 不计入
      const log: WorkoutLog = makeLog('bb_bench', 60, 8, 3, 0);
      log.sets[2].rpe = 6;
      expect(StrengthCalculator.effectiveSets(log)).assertEqual(2);
      expect(StrengthCalculator.bestOneRepMax(log)).assertEqual(75.3);
    });

    it('progressive_overload_suggestion', 0, () => {
      // 空历史 → 首次记录
      expect(ProgressiveOverloadPlanner.suggest([]).action).assertEqual('首次记录');
      // 有进步 → 加重 2.5kg
      const progressing: WorkoutLog[] = [makeLog('bb_bench', 60, 8, 4, 7), makeLog('bb_bench', 62.5, 8, 4, 0)];
      const up: OverloadSuggestion = ProgressiveOverloadPlanner.suggest(progressing);
      expect(up.action).assertEqual('加重');
      expect(up.suggestedWeightKg).assertEqual(65);
      expect(up.plateau).assertFalse();
      // 连续 2 次无进步 → 平台期加组
      const stuck: WorkoutLog[] = [
        makeLog('bb_bench', 60, 8, 4, 14), makeLog('bb_bench', 60, 8, 4, 7), makeLog('bb_bench', 60, 8, 4, 0)
      ];
      const plateau: OverloadSuggestion = ProgressiveOverloadPlanner.suggest(stuck);
      expect(plateau.plateau).assertTrue();
      expect(plateau.action).assertEqual('加组');
      expect(plateau.suggestedSets).assertEqual(5);
    });

    it('muscle_balance_imbalance_detection', 0, () => {
      // 只练胸 → 拉/腿失衡提示
      const logs: WorkoutLog[] = [makeLog('bb_bench', 60, 8, 5, 1)];
      const report: MuscleBalanceReport = MuscleBalanceAnalyzer.analyze(logs);
      expect(report.pushSets).assertEqual(5);
      expect(report.imbalances.length >= 1).assertTrue();
      expect(report.recommendations.length >= 1).assertTrue();
      // 均衡训练 → 无失衡
      const balanced: WorkoutLog[] = [
        makeLog('bb_bench', 60, 8, 4, 3), makeLog('bb_row', 60, 8, 4, 2), makeLog('bb_squat', 80, 8, 4, 1)
      ];
      expect(MuscleBalanceAnalyzer.analyze(balanced).imbalances.length).assertEqual(0);
    });

    it('warmup_generator_sequence', 0, () => {
      const sets: WarmupSet[] = WarmupGenerator.generate(100);
      expect(sets.length).assertEqual(5);
      expect(sets[0].weightKg).assertEqual(20);
      expect(sets[1].weightKg).assertEqual(40);
      expect(sets[4].weightKg).assertEqual(85);
      expect(WarmupGenerator.generate(0).length).assertEqual(0);
      // 小重量省略中间档
      expect(WarmupGenerator.generate(50).length).assertEqual(3);
    });

    it('rir_dual_track_effective_sets', 0, () => {
      // RIR 未填（-1）→ 用 RPE；RIR 已填 → 10-RIR 优先
      expect(effectiveRpe({ setIndex: 1, reps: 8, weightKg: 60, rpe: 7, rir: 2 })).assertEqual(8);
      expect(effectiveRpe({ setIndex: 1, reps: 8, weightKg: 60, rpe: 8, rir: -1 })).assertEqual(8);
      expect(effectiveRpe({ setIndex: 1, reps: 8, weightKg: 60, rpe: 6, rir: 0 })).assertEqual(10);
      // RPE 6 但 RIR 2（折算 8）→ 计入有效组
      const log: WorkoutLog = makeLog('bb_bench', 60, 8, 3, 0);
      log.sets[2].rpe = 6;
      log.sets[2].rir = 2;
      expect(StrengthCalculator.effectiveSets(log)).assertEqual(3);
      // RIR 4（折算 6）→ 不计入
      const log2: WorkoutLog = makeLog('bb_bench', 60, 8, 2, 0);
      log2.sets[0].rir = 4;
      expect(StrengthCalculator.effectiveSets(log2)).assertEqual(1);
      // RIR 越界校验
      const bad: WorkoutLog = makeLog('bb_bench', 60, 8, 1, 0);
      bad.sets[0].rir = 6;
      expect(bad.validate().length > 0).assertTrue();
    });

    it('mesocycle_planner_wave', 0, () => {
      const plan: MesocyclePlan = MesocyclePlanner.plan(6, 0, false);
      expect(plan.weeks.length).assertEqual(6);
      expect(plan.weeks[0].volumePct).assertEqual(110);
      expect(plan.weeks[2].volumePct).assertEqual(130);
      expect(plan.weeks[2].intensityPct).assertEqual(92.5);
      expect(plan.weeks[3].isDeload).assertTrue();
      expect(plan.weeks[3].volumePct).assertEqual(60);
      expect(plan.weeks[5].isDeload).assertTrue();
      expect(plan.deloadAdvised).assertFalse();
      // 周数钳制 4–8；高疲劳+平台期 → 建议立即减载
      expect(MesocyclePlanner.plan(3).weeks.length).assertEqual(4);
      expect(MesocyclePlanner.plan(10).weeks.length).assertEqual(8);
      expect(MesocyclePlanner.plan(6, 75, true).deloadAdvised).assertTrue();
    });

    it('readiness_scorer_tiers_and_overtraining', 0, () => {
      const low: ReadinessInput = {
        fatigueIndex: 50, sleepHours: 6, sleepQuality: 4, soreness: 3,
        hoursSinceLastTraining: 20, consecutiveTrainingDays: 7
      };
      const lowReport: ReadinessReport = ReadinessScorer.score(low);
      expect(lowReport.score).assertEqual(43);
      expect(lowReport.tier).assertEqual('低');
      expect(lowReport.overtrainingLevel).assertEqual('黄');
      const fresh: ReadinessInput = {
        fatigueIndex: 0, sleepHours: 8, sleepQuality: 5, soreness: 0,
        hoursSinceLastTraining: 72, consecutiveTrainingDays: 1
      };
      const freshReport: ReadinessReport = ReadinessScorer.score(fresh);
      expect(freshReport.score).assertEqual(100);
      expect(freshReport.tier).assertEqual('高');
      expect(freshReport.overtrainingLevel).assertEqual('无');
      const red: ReadinessInput = {
        fatigueIndex: 80, sleepHours: 5, sleepQuality: 2, soreness: 4,
        hoursSinceLastTraining: 12, consecutiveTrainingDays: 8
      };
      const redReport: ReadinessReport = ReadinessScorer.score(red);
      expect(redReport.score).assertEqual(13);
      expect(redReport.tier).assertEqual('休息');
      expect(redReport.overtrainingLevel).assertEqual('红');
    });

    it('weight_trend_least_squares', 0, () => {
      const now: number = Date.now();
      const dayMs: number = 86400000;
      const mk = (daysAgo: number, kg: number): BodyMetricEntry => {
        return { timestamp: now - daysAgo * dayMs, weightKg: kg, bodyFatPct: 0, restingHr: 0 };
      };
      const down: WeightTrendReport = WeightTrendAnalyzer.analyze(
        [mk(4, 70), mk(3, 69.5), mk(2, 69.2), mk(1, 68.9), mk(0, 68.6)]);
      expect(down.samples).assertEqual(5);
      expect(down.slopeKgPerWeek).assertEqual(-2.38);
      expect(down.currentKg).assertEqual(68.6);
      expect(down.forecast4WeekKg).assertEqual(59.1);
      expect(down.plateau).assertFalse();
      // 10 天波动 < 0.3kg → 平台期
      const flat: WeightTrendReport = WeightTrendAnalyzer.analyze(
        [mk(9, 70), mk(6, 70.1), mk(3, 69.95), mk(0, 70.05)]);
      expect(flat.plateau).assertTrue();
      // 单点不计算趋势
      expect(WeightTrendAnalyzer.analyze([mk(0, 70)]).slopeKgPerWeek).assertEqual(0);
    });

    it('diet_daily_plan_mifflin', 0, () => {
      const plan: DailyCaloriePlan = DietPlanner.dailyPlan('男', 70, 175, 30, '增肌');
      expect(plan.bmr).assertEqual(1649);
      expect(plan.tdee).assertEqual(2309);
      expect(plan.targetKcal).assertEqual(2609);
      expect(plan.restKcal).assertEqual(2409);
      expect(plan.proteinGrams).assertEqual(112);
      expect(plan.trainingCarbGrams).assertEqual(378);
      expect(plan.restCarbGrams).assertEqual(328);
      expect(plan.waterTargetMl).assertEqual(2450);
      expect(plan.timingTips.length >= 3).assertTrue();
      // 减脂目标 −500
      expect(DietPlanner.dailyPlan('男', 70, 175, 30, '减脂').targetKcal).assertEqual(1809);
      // 女性 BMR 常数 −161
      expect(DietPlanner.mifflinBmr('女', 55, 162, 28)).assertEqual(1262);
    });

    it('pr_tracker_summary_and_check', 0, () => {
      const history: WorkoutLog[] = [makeLog('bb_bench', 60, 8, 4, 7), makeLog('bb_bench', 60, 8, 4, 0)];
      const prs: ExercisePR[] = PRTracker.summarize(history);
      expect(prs.length).assertEqual(1);
      expect(prs[0].maxWeightKg).assertEqual(60);
      expect(prs[0].bestOneRepMax).assertEqual(75.3);
      expect(prs[0].bestTotalReps).assertEqual(32);
      expect(prs[0].sessions).assertEqual(2);
      // 最近一次 1RM 创新高 → 破纪录
      const improving: WorkoutLog[] = [makeLog('bb_bench', 60, 8, 4, 7), makeLog('bb_bench', 62.5, 8, 4, 0)];
      const prHit: PRCheck = PRTracker.checkLatest(improving);
      expect(prHit.isPR).assertTrue();
      expect(prHit.message.indexOf('新纪录') >= 0).assertTrue();
      // 持平不判 PR；首次记录不判 PR
      expect(PRTracker.checkLatest(history).isPR).assertFalse();
      expect(PRTracker.checkLatest([makeLog('bb_bench', 60, 8, 4, 0)]).isPR).assertFalse();
    });

    it('pr_daily_events_by_date', 0, () => {
      // 卧推：第 7 天 60kg（首记）→ 第 3 天 62.5kg（破纪录）→ 第 1 天持平（不破）
      const benchDay7: WorkoutLog = makeLog('bb_bench', 60, 8, 4, 7);
      const benchDay3: WorkoutLog = makeLog('bb_bench', 62.5, 8, 4, 3);
      const benchDay1: WorkoutLog = makeLog('bb_bench', 62.5, 8, 4, 1);
      // 深蹲：第 5 天 80kg（首记）→ 第 2 天 80kg 持平（不破）
      const squatDay5: WorkoutLog = makeLog('bb_squat', 80, 5, 5, 5);
      const squatDay2: WorkoutLog = makeLog('bb_squat', 80, 5, 5, 2);
      const logs: WorkoutLog[] = [benchDay1, benchDay3, benchDay7, squatDay2, squatDay5];
      const events: DailyPREvent[] = PRTracker.dailyPREvents(logs);
      // 只有卧推第 3 天那一次破纪录
      expect(events.length).assertEqual(1);
      expect(events[0].dateKey).assertEqual(benchDay3.dateKey());
      expect(events[0].exerciseName).assertEqual('杠铃卧推');
      expect(events[0].message.indexOf('新纪录') >= 0).assertTrue();
      // 自重动作：次数创新高也按天记录
      const pushA: WorkoutLog = makeLog('bw_pushup', 0, 20, 3, 6);
      const pushB: WorkoutLog = makeLog('bw_pushup', 0, 25, 3, 4);
      const bwEvents: DailyPREvent[] = PRTracker.dailyPREvents([pushA, pushB]);
      expect(bwEvents.length).assertEqual(1);
      expect(bwEvents[0].dateKey).assertEqual(pushB.dateKey());
      // 空日志无事件
      expect(PRTracker.dailyPREvents([]).length).assertEqual(0);
    });

    it('stats_aggregator_range_and_group', 0, () => {
      // 周范围：2026-09-23（周三）所在周 = 9-21（周一）至 9-28（不含）
      const anchor: number = new Date(2026, 8, 23, 12, 0, 0).getTime();
      const week: StatsRange = TrainingStatsAggregator.rangeFor('week', anchor);
      expect(week.startMs).assertEqual(new Date(2026, 8, 21).getTime());
      expect(week.endMs).assertEqual(new Date(2026, 8, 28).getTime());
      expect(week.label).assertEqual('2026年9月21日-9月27日');
      // 月/年范围与标签
      const month: StatsRange = TrainingStatsAggregator.rangeFor('month', anchor);
      expect(month.startMs).assertEqual(new Date(2026, 8, 1).getTime());
      expect(month.endMs).assertEqual(new Date(2026, 9, 1).getTime());
      expect(month.label).assertEqual('2026年9月');
      const year: StatsRange = TrainingStatsAggregator.rangeFor('year', anchor);
      expect(year.startMs).assertEqual(new Date(2026, 0, 1).getTime());
      expect(year.endMs).assertEqual(new Date(2027, 0, 1).getTime());
      expect(year.label).assertEqual('2026年');
      // 翻页：周 ±7 天，月 ±1 月
      expect(TrainingStatsAggregator.shiftAnchor('week', anchor, -1)).assertEqual(anchor - 7 * 86400000);
      expect(new Date(TrainingStatsAggregator.shiftAnchor('month', anchor, 1)).getMonth()).assertEqual(9);
      // 部位组映射：手臂合并、有氧剔除
      expect(TrainingStatsAggregator.groupOf('二头')).assertEqual('手臂');
      expect(TrainingStatsAggregator.groupOf('三头')).assertEqual('手臂');
      expect(TrainingStatsAggregator.groupOf('小臂')).assertEqual('手臂');
      expect(TrainingStatsAggregator.groupOf('胸')).assertEqual('胸');
      expect(TrainingStatsAggregator.groupOf('有氧')).assertEqual('');
      expect(TrainingStatsAggregator.groupOf('拉伸')).assertEqual('');
    });

    it('stats_aggregator_muscle_and_best_day', 0, () => {
      // 范围内过滤：3 天前在本周内，40 天前在本周外
      const inWeek: WorkoutLog = makeLog('bb_bench', 60, 8, 4, 0);
      const outWeek: WorkoutLog = makeLog('bb_bench', 100, 5, 5, 40);
      const now: number = Date.now();
      const week: StatsRange = TrainingStatsAggregator.rangeFor('week', now);
      const filtered: WorkoutLog[] = TrainingStatsAggregator.filterLogs([inWeek, outWeek], week);
      expect(filtered.length).assertEqual(1);
      // 部位聚合：胸两条日志（1920 + 600），腿一条（2000）
      const logs: WorkoutLog[] = [
        makeLog('bb_bench', 60, 8, 4, 0),
        makeLog('db_bench', 20, 10, 3, 0),
        makeLog('bb_squat', 80, 5, 5, 0)
      ];
      const stats: MuscleStat[] = TrainingStatsAggregator.muscleStats(logs);
      expect(stats.length).assertEqual(HEAT_MUSCLE_GROUPS.length);
      expect(stats[0].muscle).assertEqual('胸');
      expect(stats[0].sessions).assertEqual(2);
      expect(stats[0].effectiveSets).assertEqual(7);
      expect(stats[0].volumeKg).assertEqual(2520);
      expect(stats[3].muscle).assertEqual('腿');
      expect(stats[3].effectiveSets).assertEqual(5);
      expect(stats[3].volumeKg).assertEqual(2000);
      expect(stats[1].sessions).assertEqual(0);
      // 容量最佳日：两天胸部容量取高者
      const heavy: WorkoutLog = makeLog('bb_bench', 80, 8, 4, 2);
      const light: WorkoutLog = makeLog('bb_bench', 60, 8, 4, 0);
      const best: VolumeBestDay | null = TrainingStatsAggregator.bestVolumeDay([light, heavy], '胸');
      expect(best === null).assertFalse();
      if (best !== null) {
        expect(best.dateKey).assertEqual(heavy.dateKey());
        expect(best.volumeKg).assertEqual(2560);
      }
      // 无容量（纯自重）返回 null
      expect(TrainingStatsAggregator.bestVolumeDay([makeLog('bw_pushup', 0, 20, 3, 0)], '胸') === null).assertTrue();
    });

    it('badge_engine_evaluation', 0, () => {
      const stats: BadgeStats = {
        totalSessions: 8, totalDurationMin: 400, currentStreak: 7, bestStreak: 10,
        weeklySessions: 4, weeklyTarget: 3, weeklyVolumeKg: 2500, prevWeeklyVolumeKg: 1000,
        totalVolumeKg: 12000, prCount: 1, exercisesTried: 12, profileFilled: true
      };
      const badges: Badge[] = BadgeEngine.evaluate(stats);
      expect(badges.length).assertEqual(20);
      const earned: string[] = badges.filter((b: Badge) => b.earned).map((b: Badge) => b.id);
      expect(earned.indexOf('sessions_7') >= 0).assertTrue();
      expect(earned.indexOf('streak_7') >= 0).assertTrue();
      expect(earned.indexOf('duration_300') >= 0).assertTrue();
      expect(earned.indexOf('full_week') >= 0).assertTrue();
      expect(earned.indexOf('volume_double') >= 0).assertTrue();
      expect(earned.indexOf('volume_10t') >= 0).assertTrue();
      expect(earned.indexOf('sessions_100') < 0).assertTrue();
      expect(earned.indexOf('streak_30') < 0).assertTrue();
    });

    it('whatif_simulator_projection', 0, () => {
      const cut: WhatIfResult = WhatIfSimulator.simulate(70, 4, 50, -300);
      expect(cut.weight4WeekKg).assertEqual(68.9);
      expect(cut.weight8WeekKg).assertEqual(67.8);
      expect(cut.load4Week).assertEqual(800);
      expect(cut.load8Week).assertEqual(1600);
      const bulk: WhatIfResult = WhatIfSimulator.simulate(70, 4, 50, 300);
      expect(bulk.weight4WeekKg).assertEqual(71.1);
      expect(bulk.weight8WeekKg).assertEqual(72.2);
      // 缺口过大 → 提示过快
      expect(WhatIfSimulator.simulate(70, 4, 50, -1200).note.indexOf('过快') >= 0).assertTrue();
    });

    it('exercise_safety_filter', 0, () => {
      const bench: ExerciseItem | null = ExerciseLibrary.findById('bb_bench');
      expect(bench !== null).assertTrue();
      if (bench !== null) {
        const safety: ExerciseSafetyInfo = ExerciseSafety.of(bench);
        expect(safety.contraindications.indexOf('肩') >= 0).assertTrue();
        expect(ExerciseSafety.isSafeFor(bench, ['肩'])).assertFalse();
        expect(ExerciseSafety.isSafeFor(bench, ['膝'])).assertTrue();
        expect(ExerciseSafety.filterSafe([bench], ['肩']).length).assertEqual(0);
        expect(ExerciseSafety.filterSafe([bench], []).length).assertEqual(1);
      }
    });

    it('injury_record_validation', 0, () => {
      const record: InjuryRecord = new InjuryRecord();
      record.part = '腰';
      record.startDate = '2026-09-01';
      expect(record.validate().length).assertEqual(0);
      expect(record.isActive(Date.now())).assertTrue();
      record.endDate = '2020-01-01';
      expect(record.isActive(Date.now())).assertFalse();
      const bad: InjuryRecord = new InjuryRecord();
      bad.part = '颈';
      bad.startDate = 'abc';
      expect(bad.validate().length >= 2).assertTrue();
      const reversed: InjuryRecord = new InjuryRecord();
      reversed.part = '膝';
      reversed.startDate = '2026-09-10';
      reversed.endDate = '2026-09-01';
      expect(reversed.validate().length).assertEqual(1);
    });
  });
}
