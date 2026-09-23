/*
 * 文件标注：自主业务逻辑 —— 模块② 饮食方案规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 模块②
 * 确定性规则：按消耗热量分配宏量营养素，输出克数、占比与食材参考。
 * 规则表：
 *   配比：蛋白质 30% / 碳水 50% / 脂肪 20%（运动恢复配比，可改）
 *   换算：蛋白 4 kcal/g、碳水 4 kcal/g、脂肪 9 kcal/g
 *   修正：load ≥ 80 时，补充热量下调为 calories × 0.6
 *   必须附免责声明（非医疗诊断）。
 */
import { HealthRecord } from '../../model/HealthRecord';
import { DietPlan } from '../AnalysisResult';

/** 宏量营养素配比默认值（运动恢复配比，与赛事规则一致；可由 RuleConfig 覆盖） */
const DEFAULT_PROTEIN_PCT: number = 0.30;
const DEFAULT_CARB_PCT: number = 0.50;
/** 负荷超标时的热量下调系数默认值 */
const DEFAULT_OVERLOAD_FACTOR: number = 0.6;
const DEFAULT_LOAD_HIGH: number = 80;

/** 热量换算系数（kcal/g） */
const KCAL_PER_G_PROTEIN: number = 4;
const KCAL_PER_G_CARB: number = 4;
const KCAL_PER_G_FAT: number = 9;

/** 免责声明（合规要求，必须随饮食方案展示） */
export const DIET_DISCLAIMER: string =
  '以上为日常营养参考，非医疗诊断；如有基础疾病请遵医嘱。';

/**
 * 每日热量目标（Mifflin-St Jeor 公式）。
 * BMR = 10×体重kg + 6.25×身高cm − 5×年龄 +（男 5 / 女 −161）
 * TDEE = BMR × 活动系数；目标热量 = TDEE + 目标修正（增肌 +300 / 减脂 −500 / 维持 0）
 */
export interface DailyCaloriePlan {
  /** 基础代谢率（kcal） */
  bmr: number;
  /** 每日总消耗（kcal） */
  tdee: number;
  /** 目标日摄入（kcal，训练日口径） */
  targetKcal: number;
  /** 非训练日目标（kcal，碳水下调折算） */
  restKcal: number;
  /** 训练日碳水（克） */
  trainingCarbGrams: number;
  /** 非训练日碳水（克，较训练日 -50g） */
  restCarbGrams: number;
  /** 蛋白（克/日，按体重 1.6g/kg） */
  proteinGrams: number;
  /** 饮水目标（毫升/日，35ml/kg） */
  waterTargetMl: number;
  /** 训练前后餐时机建议 */
  timingTips: string[];
}

export class DietPlanner {
  private readonly proteinPct: number;
  private readonly carbPct: number;
  private readonly overloadFactor: number;
  private readonly loadHigh: number;

  constructor(proteinPct: number = DEFAULT_PROTEIN_PCT, carbPct: number = DEFAULT_CARB_PCT,
    overloadFactor: number = DEFAULT_OVERLOAD_FACTOR, loadHigh: number = DEFAULT_LOAD_HIGH) {
    this.proteinPct = proteinPct;
    this.carbPct = carbPct;
    this.overloadFactor = overloadFactor;
    this.loadHigh = loadHigh;
  }

  plan(record: HealthRecord): DietPlan {
    // 脂肪占比由蛋白/碳水推导，保证三者合计为 1
    const fatPct: number = 1 - this.proteinPct - this.carbPct;
    const overloaded: boolean = record.trainingLoad >= this.loadHigh;
    // 负荷超标时下调补充热量，避免恢复期过量摄入
    const totalCalories: number = overloaded ?
      Math.round(record.calories * this.overloadFactor) : Math.round(record.calories);

    return {
      totalCalories: totalCalories,
      proteinGrams: Math.round(totalCalories * this.proteinPct / KCAL_PER_G_PROTEIN),
      carbGrams: Math.round(totalCalories * this.carbPct / KCAL_PER_G_CARB),
      fatGrams: Math.round(totalCalories * fatPct / KCAL_PER_G_FAT),
      proteinPct: Math.round(this.proteinPct * 100),
      carbPct: Math.round(this.carbPct * 100),
      fatPct: Math.round(fatPct * 100),
      proteinFoods: ['鸡胸肉', '鸡蛋', '希腊酸奶', '豆腐'],
      carbFoods: ['燕麦', '糙米', '红薯', '全麦面包'],
      fatFoods: ['牛油果', '坚果', '橄榄油'],
      note: overloaded ?
        '本次负荷超标，额外补充热量已下调为消耗的 60%，以清淡易消化为主。' : '',
      disclaimer: DIET_DISCLAIMER
    };
  }

  /** Mifflin-St Jeor 基础代谢率（kcal）：10×kg + 6.25×cm − 5×age +（男 5 / 女 −161） */
  static mifflinBmr(gender: string, weightKg: number, heightCm: number, age: number): number {
    const base: number = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return Math.round(base + (gender === '女' ? -161 : 5));
  }

  /** 饮水目标（毫升/日）：35 ml × 体重 kg */
  static waterTargetMl(weightKg: number): number {
    return Math.round(weightKg * 35);
  }

  /**
   * 周期化饮食（cycling carbs）：按当日是否训练日切换碳水占比。
   * 训练日碳水占总热量 55%，非训练日 40%；返回碳水克数。
   */
  static cyclingCarbGrams(targetKcal: number, isTrainingDay: boolean): number {
    const pct: number = isTrainingDay ? 0.55 : 0.40;
    return Math.round(targetKcal * pct / KCAL_PER_G_CARB);
  }

  /**
   * 训练前后餐时机时间轴（纯规则文案，首页时间轴卡展示）。
   * 训练日强调训前碳水与训后 30 分钟恢复窗口；非训练日提示碳水下调。
   */
  static mealTiming(isTrainingDay: boolean): string[] {
    const tips: string[] = [];
    if (isTrainingDay) {
      tips.push('训练前 1–2 小时：碳水为主的正餐（约占当日碳水 25%–30%），低脂低纤维避免肠胃负担');
      tips.push('训练后 30 分钟内：蛋白质约 30g + 碳水约 40g 的恢复窗口，优先快吸收食材');
      tips.push('其余餐次：蛋白质均摊每餐 20–40g，睡前可补缓释蛋白');
    } else {
      tips.push('非训练日：碳水占比按 40% 执行，蛋白质保持不变');
      tips.push('正餐以蛋白质 + 蔬菜为主，碳水集中在早餐与午餐');
      tips.push('晚间减少精制碳水，避免热量盈余转化为脂肪');
    }
    return tips;
  }

  /**
   * 每日热量与双碳水方案。
   * 目标修正：增肌 +300 / 减脂 −500 / 维持 0；非训练日碳水较训练日下调 50g（−200 kcal）。
   */
  static dailyPlan(gender: string, weightKg: number, heightCm: number, age: number,
    goal: string, activityFactor: number = 1.4): DailyCaloriePlan {
    const bmr: number = DietPlanner.mifflinBmr(gender, weightKg, heightCm, age);
    const tdee: number = Math.round(bmr * activityFactor);
    let adjust: number = 0;
    if (goal === '增肌') {
      adjust = 300;
    } else if (goal === '减脂') {
      adjust = -500;
    }
    const target: number = Math.max(1200, tdee + adjust);
    const proteinGrams: number = Math.round(weightKg * 1.6);
    const fatGrams: number = Math.round(target * 0.25 / KCAL_PER_G_FAT);
    const trainingCarb: number = Math.max(0,
      Math.round((target - proteinGrams * KCAL_PER_G_PROTEIN - fatGrams * KCAL_PER_G_FAT) / KCAL_PER_G_CARB));
    const restCarb: number = Math.max(0, trainingCarb - 50);
    const restKcal: number = Math.max(1000, target - 200);
    const tips: string[] = [
      '训练前 1–2 小时：以碳水为主的正餐（约当日碳水的 25%）',
      '训练后 30 分钟内：蛋白质 20–40g + 快吸收碳水，促进恢复',
      '非训练日：碳水下调约 50g，蛋白质保持不变',
      `全天饮水目标约 ${DietPlanner.waterTargetMl(weightKg)} ml，训练中每 15–20 分钟补水 150–250 ml`
    ];
    const plan: DailyCaloriePlan = {
      bmr: bmr,
      tdee: tdee,
      targetKcal: target,
      restKcal: restKcal,
      trainingCarbGrams: trainingCarb,
      restCarbGrams: restCarb,
      proteinGrams: proteinGrams,
      waterTargetMl: DietPlanner.waterTargetMl(weightKg),
      timingTips: tips
    };
    return plan;
  }
}
