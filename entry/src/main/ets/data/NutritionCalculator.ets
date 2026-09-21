/*
 * 文件标注：自主业务逻辑 —— 营养达成度计算规则（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 营养闭环
 * 将当日饮食日志（DietLog）按食物库营养参考值折算为实际宏量摄入，
 * 与 DietPlan 的建议值对比，输出蛋白质/碳水/脂肪达成度（0–100%+）。
 * 确定性计算，无网络请求。
 */
import { DietLogEntry, IntakeSummary } from '../data/DietLog';
import { FoodItem, FoodLibrary } from '../data/FoodLibrary';
import { DietPlan } from '../agent/AnalysisResult';

/** 宏量达成度（实际 vs 建议，百分比） */
export interface MacroAchievement {
  /** 实际摄入汇总 */
  actual: IntakeSummary;
  /** 蛋白质达成率（%） */
  proteinPct: number;
  /** 碳水达成率（%） */
  carbPct: number;
  /** 脂肪达成率（%） */
  fatPct: number;
  /** 总达成率（三项均值，用于首页达成环） */
  overallPct: number;
}

export class NutritionCalculator {
  /** 汇总当日饮食记录的实际摄入（未收录食物按 0 计） */
  static summarize(entries: DietLogEntry[]): IntakeSummary {
    const sum: IntakeSummary = { kcal: 0, proteinGrams: 0, carbGrams: 0, fatGrams: 0 };
    entries.forEach((entry: DietLogEntry) => {
      const food: FoodItem | null = FoodLibrary.findByName(entry.foodName);
      if (food !== null) {
        const ratio: number = entry.grams / 100;
        sum.kcal += food.kcalPer100g * ratio;
        sum.proteinGrams += food.proteinPer100g * ratio;
        sum.carbGrams += food.carbPer100g * ratio;
        sum.fatGrams += food.fatPer100g * ratio;
      }
    });
    sum.kcal = Math.round(sum.kcal);
    sum.proteinGrams = Math.round(sum.proteinGrams);
    sum.carbGrams = Math.round(sum.carbGrams);
    sum.fatGrams = Math.round(sum.fatGrams);
    return sum;
  }

  /** 与饮食建议对比计算达成度（建议值为 0 时该项记 100%） */
  static achievement(entries: DietLogEntry[], plan: DietPlan): MacroAchievement {
    const actual: IntakeSummary = NutritionCalculator.summarize(entries);
    const pct = (actualValue: number, planValue: number): number => {
      if (planValue <= 0) {
        return 100;
      }
      return Math.min(999, Math.round(actualValue * 100 / planValue));
    };
    const result: MacroAchievement = {
      actual: actual,
      proteinPct: pct(actual.proteinGrams, plan.proteinGrams),
      carbPct: pct(actual.carbGrams, plan.carbGrams),
      fatPct: pct(actual.fatGrams, plan.fatGrams),
      overallPct: 0
    };
    result.overallPct = Math.round((result.proteinPct + result.carbPct + result.fatPct) / 3);
    return result;
  }
}
