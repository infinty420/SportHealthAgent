/*
 * 文件标注：AI 生成 —— 数据模型与合法性校验（通用数据结构）
 *          自主业务逻辑 —— estimateTrainingLoad() 训练负荷本地估算公式（参赛者知识产权）
 *
 * 数据接入层 · 核心数据模型
 * HealthRecord：一次运动记录，字段与鸿蒙 Health Kit（healthStore）读取字段一一对应：
 * 运动时长、平均心率、配速、卡路里、运动类型、训练负荷。
 */

/** 运动类型枚举（与模块③互补训练规划的推导分支对应） */
export enum SportType {
  STRENGTH = '力量训练',
  RUN = '跑步',
  CYCLE = '骑行',
  SWIM = '游泳',
  HIIT = '高强度间歇',
  YOGA = '瑜伽/拉伸',
  WALK = '步行',
  /** 有氧动作库接入：跳绳（中高冲击有氧） */
  JUMP_ROPE = '跳绳',
  /** 有氧动作库接入：椭圆机（低冲击有氧） */
  ELLIPTICAL = '椭圆机',
  /** 有氧动作库接入：动感单车（低冲击有氧） */
  SPINNING = '动感单车',
  /** 有氧动作库接入：爬楼机（中高冲击有氧） */
  STAIR = '爬楼机',
  OTHER = '其他'
}

/** 全部运动类型列表，供 UI 下拉选择使用（慢跑/快走分别对应 跑步/步行） */
export const SPORT_TYPE_LIST: string[] = [
  SportType.STRENGTH,
  SportType.RUN,
  SportType.CYCLE,
  SportType.SWIM,
  SportType.HIIT,
  SportType.YOGA,
  SportType.WALK,
  SportType.JUMP_ROPE,
  SportType.ELLIPTICAL,
  SportType.SPINNING,
  SportType.STAIR,
  SportType.OTHER
];

/**
 * 一次运动的健康数据记录。
 * trainingLoad 为可选：手表未提供时，由 estimateTrainingLoad() 本地估算。
 */
export class HealthRecord {
  /** 运动时长（分钟） */
  durationMin: number = 0;
  /** 平均心率（次/分） */
  avgHeartRate: number = 0;
  /** 配速（自由文本，如 "6'00\"/km"；力量类训练可填 '-'） */
  pace: string = '-';
  /** 消耗热量（千卡） */
  calories: number = 0;
  /** 运动类型 */
  sportType: string = SportType.RUN;
  /** 训练负荷（0–100；<0 表示缺失，需本地估算） */
  trainingLoad: number = -1;

  /**
   * 合法性校验（手动录入路径②使用）。
   * 返回错误信息数组，空数组表示合法。
   */
  validate(): string[] {
    const errors: string[] = [];
    if (this.durationMin <= 0 || this.durationMin > 600) {
      errors.push('运动时长需在 1–600 分钟之间');
    }
    if (this.avgHeartRate < 40 || this.avgHeartRate > 220) {
      errors.push('平均心率需在 40–220 次/分之间');
    }
    if (this.calories < 0 || this.calories > 5000) {
      errors.push('消耗热量需在 0–5000 千卡之间');
    }
    if (this.pace.trim().length === 0) {
      errors.push('配速不能为空（无配速概念的训练请填 -）');
    }
    if (SPORT_TYPE_LIST.indexOf(this.sportType) < 0) {
      errors.push('运动类型不合法');
    }
    if (this.trainingLoad >= 0 && (this.trainingLoad > 100)) {
      errors.push('训练负荷需在 0–100 之间');
    }
    return errors;
  }
}

/* ==================== 自主业务逻辑（规则算法，参赛者知识产权） ==================== */

/**
 * 训练负荷本地估算公式（当手表数据缺失训练负荷字段时使用）。
 * 公式：负荷 = round(时长 × min(1, max(0.1, (平均心率 - 60) / 140)))，限幅 0–100。
 * 含义：以心率相对静息水平的偏移衡量强度，再与时长相乘得到本次训练负荷。
 */
export function estimateTrainingLoad(durationMin: number, avgHeartRate: number): number {
  const intensity: number = Math.min(1, Math.max(0.1, (avgHeartRate - 60) / 140));
  const raw: number = Math.round(durationMin * intensity);
  return Math.min(100, Math.max(0, raw));
}

/**
 * 个性化训练负荷估算（已填写用户画像时使用）。
 * 与通用公式同构，但心率区间按画像修正：
 * 静息心率取下限、最大心率（220 - 年龄）取上限，强度 = (心率 - 静息) / (最大 - 静息)。
 */
export function estimateTrainingLoadPersonalized(
  durationMin: number, avgHeartRate: number, restingHr: number, maxHr: number): number {
  const span: number = Math.max(1, maxHr - restingHr);
  const intensity: number = Math.min(1, Math.max(0.1, (avgHeartRate - restingHr) / span));
  const raw: number = Math.round(durationMin * intensity);
  return Math.min(100, Math.max(0, raw));
}
