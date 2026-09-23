/*
 * 文件标注：AI 生成 —— 规则 DSL 本地规则表持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 规则表（规则 DSL）
 * 将引擎可调参数与互补训练映射外置为 JSON 规则表，本地持久化；
 * 加载后通过 applyStatics 注入各规则引擎的静态配置，实现「改规则不改代码」。
 * 基于系统 preferences（端侧本地键值存储，沙箱内，无网络请求）。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { ProgressiveOverloadPlanner } from '../agent/rules/ProgressiveOverloadPlanner';
import { NextWorkoutPlanner } from '../agent/rules/NextWorkoutPlanner';

/** 单条互补映射：运动类型中文名 → 自定义下一次训练类型 */
export interface ComplementaryRule {
  sportType: string;
  workoutType: string;
}

/** 规则表结构（version=1） */
export interface RuleTable {
  version: number;
  /** 渐进超负荷单次加重步长（公斤） */
  weightStepKg: number;
  /** 自定义互补映射列表（空列表走内置规则） */
  complementary: ComplementaryRule[];
}

export class RuleTableStore {
  private static readonly STORE_NAME: string = 'rule_table';
  private static readonly KEY_TABLE: string = 'table';
  private static readonly VERSION: number = 1;
  /** 加重步长允许范围（公斤），防止误输入极端值 */
  private static readonly MIN_STEP_KG: number = 0.5;
  private static readonly MAX_STEP_KG: number = 10;

  private readonly prefs: preferences.Preferences;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: RuleTableStore.STORE_NAME });
  }

  /** 默认规则表：与内置算法常量一致 */
  static defaults(): RuleTable {
    const table: RuleTable = {
      version: RuleTableStore.VERSION,
      weightStepKg: 2.5,
      complementary: []
    };
    return table;
  }

  /** 读取规则表；版本不符或解析失败回退默认表 */
  load(): RuleTable {
    const raw: string = this.prefs.getSync(RuleTableStore.KEY_TABLE, '') as string;
    if (raw.length === 0) {
      return RuleTableStore.defaults();
    }
    try {
      const parsed = JSON.parse(raw) as RuleTable;
      if (parsed.version !== RuleTableStore.VERSION || typeof parsed.weightStepKg !== 'number' ||
        !Array.isArray(parsed.complementary)) {
        return RuleTableStore.defaults();
      }
      return parsed;
    } catch (e) {
      return RuleTableStore.defaults();
    }
  }

  /** 保存规则表（先做范围与结构清洗） */
  save(table: RuleTable): void {
    const clean: RuleTable = {
      version: RuleTableStore.VERSION,
      weightStepKg: Math.min(RuleTableStore.MAX_STEP_KG, Math.max(RuleTableStore.MIN_STEP_KG, table.weightStepKg)),
      complementary: table.complementary.filter((rule: ComplementaryRule): boolean =>
        rule.sportType.length > 0 && rule.workoutType.length > 0)
    };
    this.prefs.putSync(RuleTableStore.KEY_TABLE, JSON.stringify(clean));
    this.prefs.flush();
  }

  /** 将规则表注入各规则引擎的静态配置（改规则不改代码） */
  static applyStatics(table: RuleTable): void {
    ProgressiveOverloadPlanner.weightStepKg = table.weightStepKg;
    const map: Map<string, string> = new Map<string, string>();
    table.complementary.forEach((rule: ComplementaryRule): void => {
      map.set(rule.sportType, rule.workoutType);
    });
    NextWorkoutPlanner.overrides = map;
  }
}
