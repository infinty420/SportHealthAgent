/*
 * 文件标注：AI 生成 —— 规则设置本地持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 规则设置存储
 * 基于系统 preferences（端侧本地键值存储，无网络请求），
 * 保存「规则设置」面板调整的 RuleConfig 参数，下次启动自动恢复。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { RuleConfig } from '../agent/RuleConfig';

export class SettingsStore {
  private static readonly STORE_NAME: string = 'sport_settings';
  private static readonly KEY_HIGH: string = 'highThreshold';
  private static readonly KEY_NORMAL: string = 'normalThreshold';
  private static readonly KEY_PROTEIN: string = 'proteinPct';
  private static readonly KEY_CARB: string = 'carbPct';
  private static readonly KEY_FACTOR: string = 'overloadFactor';

  private readonly prefs: preferences.Preferences;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: SettingsStore.STORE_NAME });
  }

  save(config: RuleConfig): void {
    this.prefs.putSync(SettingsStore.KEY_HIGH, config.highThreshold);
    this.prefs.putSync(SettingsStore.KEY_NORMAL, config.normalThreshold);
    this.prefs.putSync(SettingsStore.KEY_PROTEIN, config.proteinPct);
    this.prefs.putSync(SettingsStore.KEY_CARB, config.carbPct);
    this.prefs.putSync(SettingsStore.KEY_FACTOR, config.overloadFactor);
    this.prefs.flush();
  }

  /** 读取设置；从未设置过时返回赛事默认配置 */
  load(): RuleConfig {
    const defaults: RuleConfig = RuleConfig.defaults();
    const config: RuleConfig = new RuleConfig();
    config.highThreshold = this.prefs.getSync(SettingsStore.KEY_HIGH, defaults.highThreshold) as number;
    config.normalThreshold = this.prefs.getSync(SettingsStore.KEY_NORMAL, defaults.normalThreshold) as number;
    config.proteinPct = this.prefs.getSync(SettingsStore.KEY_PROTEIN, defaults.proteinPct) as number;
    config.carbPct = this.prefs.getSync(SettingsStore.KEY_CARB, defaults.carbPct) as number;
    config.overloadFactor = this.prefs.getSync(SettingsStore.KEY_FACTOR, defaults.overloadFactor) as number;
    return config;
  }
}
