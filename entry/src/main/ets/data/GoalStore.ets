/*
 * 文件标注：AI 生成 —— 训练目标本地持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 目标设定存储
 * 保存周训练次数/周总时长/目标体重，首页与报表页按此计算达成率。
 * 基于系统 preferences，纯本地存储，无网络请求。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class TrainingGoal {
  /** 周训练次数目标 */
  weeklySessions: number = 4;
  /** 周总时长目标（分钟） */
  weeklyDurationMin: number = 180;
  /** 目标体重（kg，0 表示未设定） */
  targetWeightKg: number = 0;

  validate(): string[] {
    const errors: string[] = [];
    if (this.weeklySessions < 1 || this.weeklySessions > 14) {
      errors.push('周训练次数需在 1–14 之间');
    }
    if (this.weeklyDurationMin < 30 || this.weeklyDurationMin > 1500) {
      errors.push('周总时长需在 30–1500 分钟之间');
    }
    if (this.targetWeightKg !== 0 && (this.targetWeightKg < 30 || this.targetWeightKg > 250)) {
      errors.push('目标体重需在 30–250 公斤之间（0 表示不设定）');
    }
    return errors;
  }
}

export class GoalStore {
  private static readonly STORE_NAME: string = 'training_goal';
  private static readonly KEY_SESSIONS: string = 'weeklySessions';
  private static readonly KEY_DURATION: string = 'weeklyDurationMin';
  private static readonly KEY_WEIGHT: string = 'targetWeightKg';

  private readonly prefs: preferences.Preferences;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: GoalStore.STORE_NAME });
  }

  save(goal: TrainingGoal): void {
    this.prefs.putSync(GoalStore.KEY_SESSIONS, goal.weeklySessions);
    this.prefs.putSync(GoalStore.KEY_DURATION, goal.weeklyDurationMin);
    this.prefs.putSync(GoalStore.KEY_WEIGHT, goal.targetWeightKg);
    this.prefs.flush();
  }

  load(): TrainingGoal {
    const defaults: TrainingGoal = new TrainingGoal();
    const goal: TrainingGoal = new TrainingGoal();
    goal.weeklySessions = this.prefs.getSync(GoalStore.KEY_SESSIONS, defaults.weeklySessions) as number;
    goal.weeklyDurationMin = this.prefs.getSync(GoalStore.KEY_DURATION, defaults.weeklyDurationMin) as number;
    goal.targetWeightKg = this.prefs.getSync(GoalStore.KEY_WEIGHT, defaults.targetWeightKg) as number;
    return goal;
  }
}
