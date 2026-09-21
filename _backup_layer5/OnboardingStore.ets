/*
 * 文件标注：AI 生成 —— 新手引导状态本地持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 新手引导
 * 基于系统 preferences（端侧本地键值存储，无网络请求）：
 * 首次启动显示分页引导向导，「跳过/完成」后置标志，之后不再打扰。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class OnboardingStore {
  private static readonly STORE_NAME: string = 'onboarding';
  private static readonly KEY_DONE: string = 'guide_done';

  private readonly prefs: preferences.Preferences;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: OnboardingStore.STORE_NAME });
  }

  /** 是否已完成（或跳过）新手引导 */
  isDone(): boolean {
    return this.prefs.getSync(OnboardingStore.KEY_DONE, '0') as string === '1';
  }

  /** 标记引导完成 */
  markDone(): void {
    this.prefs.putSync(OnboardingStore.KEY_DONE, '1');
    this.prefs.flush();
  }
}
