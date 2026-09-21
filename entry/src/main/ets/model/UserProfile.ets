/*
 * 文件标注：AI 生成 —— 用户画像数据模型与本地持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 用户画像
 * 保存性别/年龄/身高/体重/静息心率/目标/经验等级，供规则引擎个性化调参。
 * 基于系统 preferences（端侧本地键值存储），不接入任何真实 API。
 */

/** 训练目标 */
export enum UserGoal {
  LOSE_FAT = '减脂',
  MAINTAIN = '维持',
  GAIN_MUSCLE = '增肌'
}

/** 训练经验等级 */
export enum ExperienceLevel {
  BEGINNER = '新手',
  INTERMEDIATE = '进阶',
  ADVANCED = '高阶'
}

export const USER_GOAL_LIST: string[] = [UserGoal.LOSE_FAT, UserGoal.MAINTAIN, UserGoal.GAIN_MUSCLE];
export const EXPERIENCE_LEVEL_LIST: string[] =
  [ExperienceLevel.BEGINNER, ExperienceLevel.INTERMEDIATE, ExperienceLevel.ADVANCED];
export const GENDER_LIST: string[] = ['男', '女'];

/** 用户画像（全部字段有默认值，未填写时引擎按通用参数运行） */
export class UserProfile {
  gender: string = '男';
  age: number = 30;
  heightCm: number = 170;
  weightKg: number = 65;
  restingHr: number = 65;
  goal: string = UserGoal.MAINTAIN;
  experienceLevel: string = ExperienceLevel.BEGINNER;

  /** 是否已填写过（用于首页引导） */
  filled: boolean = false;

  /** 估算最大心率（220 - 年龄） */
  maxHeartRate(): number {
    return 220 - this.age;
  }

  /** 合法性校验，返回错误信息数组（空数组表示合法） */
  validate(): string[] {
    const errors: string[] = [];
    if (this.age < 10 || this.age > 100) {
      errors.push('年龄需在 10–100 岁之间');
    }
    if (this.heightCm < 100 || this.heightCm > 230) {
      errors.push('身高需在 100–230 厘米之间');
    }
    if (this.weightKg < 30 || this.weightKg > 250) {
      errors.push('体重需在 30–250 公斤之间');
    }
    if (this.restingHr < 35 || this.restingHr > 120) {
      errors.push('静息心率需在 35–120 次/分之间');
    }
    if (USER_GOAL_LIST.indexOf(this.goal) < 0) {
      errors.push('训练目标不合法');
    }
    if (EXPERIENCE_LEVEL_LIST.indexOf(this.experienceLevel) < 0) {
      errors.push('经验等级不合法');
    }
    return errors;
  }
}
