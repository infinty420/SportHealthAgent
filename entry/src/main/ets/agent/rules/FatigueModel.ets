/*
 * 文件标注：自主业务逻辑 —— 疲劳累积模型规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 疲劳模型
 * 最近 3–7 天训练负荷按时间加权累积（越近权重越高），输出疲劳指数（0–100）。
 * 疲劳指数用于：动态调整恢复时长、互补训练强度与周计划休息日安排。
 * 确定性规则计算，无网络请求、无云端大模型调用。
 */
import { HistoryEntry } from '../../data/HistoryStore';

/** 疲劳评估结果 */
export interface FatigueResult {
  /** 疲劳指数（0–100） */
  index: number;
  /** 疲劳等级：低 / 中 / 高 */
  level: string;
  /** 恢复时长修正系数（1.0 不调整；高疲劳最大 1.5） */
  recoveryFactor: number;
}

export class FatigueModel {
  private static readonly DAY_MS: number = 86400000;

  /**
   * 计算疲劳指数。
   * 规则：近 7 天负荷按权重 [7,6,5,4,3,2,1]（越近越大）加权求和，
   * 以「7 天每天中等负荷 50」为满分基准（350）归一化到 0–100。
   */
  static compute(history: HistoryEntry[], now: number = Date.now()): FatigueResult {
    let weighted: number = 0;
    history.forEach((entry: HistoryEntry) => {
      const ageDays: number = Math.floor((now - entry.timestamp) / FatigueModel.DAY_MS);
      if (ageDays >= 0 && ageDays < 7) {
        weighted += entry.load * (7 - ageDays);
      }
    });
    const index: number = Math.min(100, Math.round(weighted / 14));

    let level: string = '低';
    let factor: number = 1.0;
    if (index >= 70) {
      level = '高';
      factor = 1.5;
    } else if (index >= 40) {
      level = '中';
      factor = 1.2;
    }
    const result: FatigueResult = { index: index, level: level, recoveryFactor: factor };
    return result;
  }
}
