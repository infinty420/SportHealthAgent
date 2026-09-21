/*
 * 文件标注：自主业务逻辑 —— 规则参数配置模型（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 规则配置
 * 将三大模块的可调参数集中管理：负荷分档阈值、宏量营养素配比、超标热量下调系数。
 * 默认值与赛事规则表一致；用户可在「规则设置」面板调整，配置经 SettingsStore 本地持久化。
 */

export class RuleConfig {
  /** 负荷「超标」阈值（默认 80） */
  highThreshold: number = 80;
  /** 负荷「正常」下限（默认 50） */
  normalThreshold: number = 50;
  /** 蛋白质占比（%，默认 30） */
  proteinPct: number = 30;
  /** 碳水占比（%，默认 50） */
  carbPct: number = 50;
  /** 负荷超标时的热量下调系数（默认 0.6） */
  overloadFactor: number = 0.6;

  /** 脂肪占比（%，由蛋白/碳水推导，保证三者合计 100） */
  fatPct(): number {
    return 100 - this.proteinPct - this.carbPct;
  }

  /** 参数合法性校验，返回错误信息数组（空数组表示合法） */
  validate(): string[] {
    const errors: string[] = [];
    if (this.normalThreshold >= this.highThreshold) {
      errors.push('「正常」下限必须小于「超标」阈值');
    }
    if (this.fatPct() < 10) {
      errors.push('脂肪占比不能低于 10%（请降低蛋白或碳水占比）');
    }
    if (this.overloadFactor <= 0 || this.overloadFactor > 1) {
      errors.push('热量下调系数需在 (0, 1] 之间');
    }
    return errors;
  }

  /** 赛事规则表默认配置 */
  static defaults(): RuleConfig {
    return new RuleConfig();
  }
}
