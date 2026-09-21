/*
 * AI 生成 —— 单元测试脚手架（hypium 断言）
 * 被测对象：自主业务逻辑 —— agent/rules/ 三大规则模块 + 负荷估算公式 + 规则配置注入
 *
 * 覆盖点：
 *   1. 负荷估算公式（强度上限/下限、限幅 0–100）
 *   2. 模块① 负荷三档边界（80/79/50/49）与恢复时长
 *   3. 模块② 正常与超标（×0.6）两条路径的克数换算与免责声明
 *   4. 模块③ 互补映射全分支 + 超标强制主动恢复
 *   5. RuleConfig 自定义阈值注入引擎后生效
 */
import { describe, it, expect } from '@ohos/hypium';
import { HealthRecord, SportType, estimateTrainingLoad } from '../main/ets/model/HealthRecord';
import { TrainingEvaluator } from '../main/ets/agent/rules/TrainingEvaluator';
import { DietPlanner, DIET_DISCLAIMER } from '../main/ets/agent/rules/DietPlanner';
import { NextWorkoutPlanner } from '../main/ets/agent/rules/NextWorkoutPlanner';
import { RuleAnalysisEngine } from '../main/ets/agent/RuleAnalysisEngine';
import { RuleConfig } from '../main/ets/agent/RuleConfig';
import { DietPlan } from '../main/ets/agent/AnalysisResult';

/** 构造测试用运动记录 */
function makeRecord(load: number, sportType: string = SportType.RUN, calories: number = 400): HealthRecord {
  const record: HealthRecord = new HealthRecord();
  record.durationMin = 45;
  record.avgHeartRate = 140;
  record.pace = '6\'00"/km';
  record.calories = calories;
  record.sportType = sportType;
  record.trainingLoad = load;
  return record;
}

export default function ruleEngineTest(): void {
  describe('RuleEngineTest', () => {

    it('estimate_load_intensity_bounds', 0, () => {
      // 心率 200：强度 (200-60)/140 = 1（上限），负荷 = 时长
      expect(estimateTrainingLoad(45, 200)).assertEqual(45);
      // 心率 60：强度取下限 0.1，负荷 = round(45 × 0.1) = 5
      expect(estimateTrainingLoad(45, 60)).assertEqual(5);
      // 限幅：时长 300 × 强度 1 = 300 → 截断为 100
      expect(estimateTrainingLoad(300, 200)).assertEqual(100);
    });

    it('evaluator_three_bands_boundary', 0, () => {
      const evaluator: TrainingEvaluator = new TrainingEvaluator();
      expect(evaluator.evaluate(makeRecord(80)).loadStatus).assertEqual('超标');
      expect(evaluator.evaluate(makeRecord(80)).suggestedRecoveryHours).assertEqual(36);
      expect(evaluator.evaluate(makeRecord(79)).loadStatus).assertEqual('正常');
      expect(evaluator.evaluate(makeRecord(50)).suggestedRecoveryHours).assertEqual(18);
      expect(evaluator.evaluate(makeRecord(49)).loadStatus).assertEqual('偏低');
      expect(evaluator.evaluate(makeRecord(49)).suggestedRecoveryHours).assertEqual(8);
    });

    it('diet_normal_path', 0, () => {
      const planner: DietPlanner = new DietPlanner();
      const plan: DietPlan = planner.plan(makeRecord(60, SportType.RUN, 400));
      expect(plan.totalCalories).assertEqual(400);
      expect(plan.proteinGrams).assertEqual(30); // 400 × 30% / 4
      expect(plan.carbGrams).assertEqual(50);    // 400 × 50% / 4
      expect(plan.fatGrams).assertEqual(9);      // 400 × 20% / 9 ≈ 8.9 → 9
      expect(plan.note.length).assertEqual(0);
      expect(plan.disclaimer).assertEqual(DIET_DISCLAIMER);
    });

    it('diet_overload_path_calorie_reduced', 0, () => {
      const planner: DietPlanner = new DietPlanner();
      const plan: DietPlan = planner.plan(makeRecord(85, SportType.RUN, 400));
      expect(plan.totalCalories).assertEqual(240); // 400 × 0.6
      expect(plan.note.length > 0).assertTrue();
      expect(plan.disclaimer).assertEqual(DIET_DISCLAIMER);
    });

    it('next_workout_all_branches', 0, () => {
      const planner: NextWorkoutPlanner = new NextWorkoutPlanner();
      // 超标：强制主动恢复，优先于类型推导
      expect(planner.plan(makeRecord(85, SportType.STRENGTH)).workoutType).assertEqual('主动恢复（拉伸/散步）');
      expect(planner.plan(makeRecord(85)).durationMin).assertEqual(20);
      // 类型推导各分支
      expect(planner.plan(makeRecord(60, SportType.STRENGTH)).workoutType).assertEqual('有氧慢跑 + 全身拉伸');
      expect(planner.plan(makeRecord(60, SportType.RUN)).workoutType).assertEqual('力量/核心');
      expect(planner.plan(makeRecord(60, SportType.CYCLE)).workoutType).assertEqual('力量/核心');
      expect(planner.plan(makeRecord(60, SportType.SWIM)).workoutType).assertEqual('力量/核心');
      expect(planner.plan(makeRecord(60, SportType.HIIT)).workoutType).assertEqual('主动恢复');
      expect(planner.plan(makeRecord(60, SportType.YOGA)).workoutType).assertEqual('力量/有氧');
      expect(planner.plan(makeRecord(60, SportType.WALK)).durationMin).assertEqual(25);
      expect(planner.plan(makeRecord(60, SportType.OTHER)).workoutType).assertEqual('交替上下肢');
    });

    it('engine_applies_custom_config', 0, () => {
      const engine: RuleAnalysisEngine = new RuleAnalysisEngine();
      const config: RuleConfig = new RuleConfig();
      config.highThreshold = 70;
      engine.setConfig(config);
      // 默认阈值 80 时 75 为「正常」，自定义阈值 70 后应为「超标」
      expect(engine.analyze(makeRecord(75)).assessment.loadStatus).assertEqual('超标');
    });

    it('rule_config_validation', 0, () => {
      const bad: RuleConfig = new RuleConfig();
      bad.normalThreshold = 85; // 下限高于超标阈值
      expect(bad.validate().length > 0).assertTrue();
      const good: RuleConfig = new RuleConfig();
      expect(good.validate().length).assertEqual(0);
      expect(good.fatPct()).assertEqual(20);
    });
  });
}
