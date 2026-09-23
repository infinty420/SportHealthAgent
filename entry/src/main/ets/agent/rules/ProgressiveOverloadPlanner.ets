/*
 * 文件标注：自主业务逻辑 —— 渐进超负荷规划规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 渐进超负荷模块
 * 对比同一动作的历史最佳表现（估算 1RM / 总次数），输出下一次训练的
 * 加重 / 加次 / 加组建议；连续 2 次无进步标记平台期。
 * 确定性规则计算，无网络请求、无模型推理。
 */
import { WorkoutLog, WorkoutSet } from '../../model/WorkoutLog';
import { StrengthCalculator } from './StrengthCalculator';

/** 单次加重步长（公斤） */
const WEIGHT_STEP_KG: number = 2.5;
/** 加次步长（每组次数） */
const REPS_STEP: number = 1;
/** 平台期阈值：连续无进步次数 */
const PLATEAU_STREAK: number = 2;

/** 渐进超负荷建议 */
export interface OverloadSuggestion {
  /** 建议动作：首次记录 / 加重 / 加次 / 加组（平台期） */
  action: string;
  suggestedWeightKg: number;
  suggestedReps: number;
  suggestedSets: number;
  /** 是否处于平台期（连续 2 次无进步） */
  plateau: boolean;
  /** 中文说明（含命中依据） */
  message: string;
}

export class ProgressiveOverloadPlanner {
  /** 单次加重步长（公斤），可由规则表 JSON 配置覆盖，默认 2.5 */
  static weightStepKg: number = WEIGHT_STEP_KG;

  /**
   * 基于某动作的历史日志（时间正序）给出下一次训练建议。
   * 负重动作以估算 1RM 为进步标尺；自重动作（重量全 0）以总次数为标尺。
   */
  static suggest(history: WorkoutLog[]): OverloadSuggestion {
    const first: OverloadSuggestion = {
      action: '首次记录', suggestedWeightKg: 0, suggestedReps: 0, suggestedSets: 0, plateau: false,
      message: '这是该动作的第一次记录，完成后将作为后续进步的基准。'
    };
    if (history.length === 0) {
      return first;
    }

    const last: WorkoutLog = history[history.length - 1];
    const bestSet: WorkoutSet | null = last.bestSet();
    if (bestSet === null) {
      return first;
    }
    const bodyweight: boolean = last.totalVolume() === 0;
    const lastScore: number = bodyweight ? last.totalReps() : StrengthCalculator.bestOneRepMax(last);

    // 连续无进步次数（从最近往前数）
    let noProgress: number = 0;
    for (let i = history.length - 1; i > 0; i--) {
      const newer: number = bodyweight ? history[i].totalReps() : StrengthCalculator.bestOneRepMax(history[i]);
      const older: number = bodyweight ? history[i - 1].totalReps() : StrengthCalculator.bestOneRepMax(history[i - 1]);
      if (newer > older) {
        break;
      }
      noProgress++;
    }

    const suggestion: OverloadSuggestion = {
      action: '保持',
      suggestedWeightKg: bestSet.weightKg,
      suggestedReps: bestSet.reps,
      suggestedSets: last.sets.length,
      plateau: noProgress >= PLATEAU_STREAK,
      message: ''
    };

    if (suggestion.plateau) {
      suggestion.action = '加组';
      suggestion.suggestedSets = last.sets.length + 1;
      suggestion.message = `连续 ${noProgress} 次无进步，已进入平台期：建议下次增加 1 组` +
        `（${suggestion.suggestedSets} 组），或在下周计划中安排减载。`;
      return suggestion;
    }

    if (noProgress === 0 && history.length > 1) {
      // 上次有进步 → 继续加重（自重动作加次）
      if (bodyweight) {
        suggestion.action = '加次';
        suggestion.suggestedReps = Math.round(last.totalReps() / last.sets.length) + REPS_STEP;
        suggestion.message = '上次总次数有进步，本次每组次数 +1，继续累积。';
      } else {
        suggestion.action = '加重';
        suggestion.suggestedWeightKg = bestSet.weightKg + ProgressiveOverloadPlanner.weightStepKg;
        suggestion.message = `上次估算 1RM 提升至 ${Math.round(lastScore)}kg，本次重量 +${ProgressiveOverloadPlanner.weightStepKg}kg。`;
      }
      return suggestion;
    }

    // 首次无进步 → 同重量加次
    suggestion.action = '加次';
    suggestion.suggestedReps = bestSet.reps + REPS_STEP;
    suggestion.message = bodyweight ? '总次数与上次持平，本次每组次数 +1 尝试突破。' :
      `估算 1RM 与上次持平（${Math.round(lastScore)}kg），保持重量、每组次数 +1 尝试突破。`;
    return suggestion;
  }
}
