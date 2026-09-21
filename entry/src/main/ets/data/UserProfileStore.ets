/*
 * 文件标注：AI 生成 —— 用户画像本地持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 用户画像存储
 * 基于系统 preferences（端侧本地键值存储，沙箱内文件，无网络请求），
 * 保存与恢复 UserProfile，下次启动自动加载。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { UserProfile } from '../model/UserProfile';

export class UserProfileStore {
  private static readonly STORE_NAME: string = 'user_profile';
  private static readonly KEY_PROFILE: string = 'profile';

  private readonly prefs: preferences.Preferences;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: UserProfileStore.STORE_NAME });
  }

  save(profile: UserProfile): void {
    this.prefs.putSync(UserProfileStore.KEY_PROFILE, JSON.stringify(profile));
    this.prefs.flush();
  }

  /** 读取画像；从未保存过或数据损坏时返回带默认值的画像（filled=false） */
  load(): UserProfile {
    const raw: string = this.prefs.getSync(UserProfileStore.KEY_PROFILE, '') as string;
    const profile: UserProfile = new UserProfile();
    if (raw.length === 0) {
      return profile;
    }
    try {
      const parsed: UserProfile = JSON.parse(raw) as UserProfile;
      profile.gender = parsed.gender;
      profile.age = parsed.age;
      profile.heightCm = parsed.heightCm;
      profile.weightKg = parsed.weightKg;
      profile.restingHr = parsed.restingHr;
      profile.goal = parsed.goal;
      profile.experienceLevel = parsed.experienceLevel;
      profile.filled = parsed.filled;
    } catch (err) {
      console.warn(`UserProfileStore parse failed: ${JSON.stringify(err)}`);
      profile.filled = false;
    }
    return profile;
  }
}
