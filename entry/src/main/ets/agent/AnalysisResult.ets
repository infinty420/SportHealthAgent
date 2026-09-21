/*
 * 文件标注：AI 生成 —— 分析结果数据模型（通用数据结构）
 *
 * 端侧 Agent 引擎 · 输出契约
 * 三大分析模块的输出类型定义。UI 层只依赖本文件，
 * 后续若升级为「端侧小模型（路线 B）」，保持本契约不变即可整体替换 agent 实现。
 */

/** 模块① 本次训练评估结果 */
export interface TrainingAssessment {
  /** 训练负荷（0–100） */
  load: number;
  /** 负荷状态：超标 / 正常 / 偏低 */
  loadStatus: string;
  /** 恢复状态描述 */
  recoveryStatus: string;
  /** 建议恢复时长（小时） */
  suggestedRecoveryHours: number;
  /** 建议文案 */
  advice: string;
}

/** 模块② 饮食方案结果 */
export interface DietPlan {
  /** 用于配餐的总热量（千卡；负荷超标时为 calories × 0.6） */
  totalCalories: number;
  /** 三大宏量营养素克数与热量占比 */
  proteinGrams: number;
  carbGrams: number;
  fatGrams: number;
  proteinPct: number;
  carbPct: number;
  fatPct: number;
  /** 食材参考 */
  proteinFoods: string[];
  carbFoods: string[];
  fatFoods: string[];
  /** 热量下调说明（未下调时为空串） */
  note: string;
  /** 免责声明（必须展示） */
  disclaimer: string;
}

/** 模块③ 下一次互补训练规划结果 */
export interface NextWorkoutPlan {
  /** 建议训练类型 */
  workoutType: string;
  /** 强度（低 / 低-中 / 中） */
  intensity: string;
  /** 建议时长（分钟） */
  durationMin: number;
  /** 互补理由 */
  reason: string;
}

/** 周计划中的一天 */
export interface WeeklyPlanDay {
  /** 第几天（周一 ~ 周日） */
  dayLabel: string;
  /** 训练类型（上肢推 / 上肢拉 / 下肢 / 有氧 / 核心 / 主动恢复 / 休息） */
  workoutType: string;
  /** 强度（低 / 低-中 / 中 / 中-高） */
  intensity: string;
  /** 建议时长（分钟，0 表示休息） */
  durationMin: number;
  /** 推荐动作 id 列表（训练日指向动作库条目，UI 点击可跳详情页；休息日为 []） */
  exerciseIds: string[];
}

/** 7 天周期计划 */
export interface WeeklyPlan {
  days: WeeklyPlanDay[];
  /** 疲劳指数摘要（用于 UI 展示） */
  fatigueIndex: number;
  /** 计划说明 */
  note: string;
}

/** Agent 综合分析报告 */
export interface AnalysisReport {
  assessment: TrainingAssessment;
  diet: DietPlan;
  nextWorkout: NextWorkoutPlan;
  /** 7 天周期计划（扩展模块，由 TrainingPlanPlanner 生成） */
  weeklyPlan: WeeklyPlan;
  /** 疲劳指数（0–100，由 FatigueModel 计算） */
  fatigueIndex: number;
  /** 报告生成时间（本地时间字符串） */
  generatedAt: string;
}
