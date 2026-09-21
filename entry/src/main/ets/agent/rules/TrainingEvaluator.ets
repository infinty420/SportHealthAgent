/*
 * 文件标注：自主业务逻辑 —— 模块① 本次训练评估规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 模块①
 * 确定性规则（if/else + 评分表），不调用任何云端大模型 API。
 * 规则表：
 *   load ≥ 80        → 状态「超标」，需充分恢复，建议 24–48h（取 36h）
 *   50 ≤ load < 80   → 状态「正常」，建议 12–24h（取 18h）
 *   load < 50        → 状态「偏低」，建议 <12h（取 8h）
 */
import { HealthRecord } from '../../model/HealthRecord';
import { TrainingAssessment } from '../AnalysisResult';

/** 负荷分档阈值默认值（评分表，与赛事规则一致；可由 RuleConfig 覆盖） */
const DEFAULT_LOAD_HIGH: number = 80;
const DEFAULT_LOAD_NORMAL: number = 50;

export class TrainingEvaluator {
  private readonly loadHigh: number;
  private readonly loadNormal: number;

  constructor(loadHigh: number = DEFAULT_LOAD_HIGH, loadNormal: number = DEFAULT_LOAD_NORMAL) {
    this.loadHigh = loadHigh;
    this.loadNormal = loadNormal;
  }

  evaluate(record: HealthRecord): TrainingAssessment {
    const load: number = record.trainingLoad;

    if (load >= this.loadHigh) {
      return {
        load: load,
        loadStatus: '超标',
        recoveryStatus: '需充分恢复',
        suggestedRecoveryHours: 36,
        advice: '本次训练负荷超标，身体处于高疲劳状态。建议 24–48 小时内避免高强度训练，' +
          '优先睡眠与主动恢复（拉伸、散步），并关注静息心率变化。'
      };
    }
    if (load >= this.loadNormal) {
      return {
        load: load,
        loadStatus: '正常',
        recoveryStatus: '常规恢复',
        suggestedRecoveryHours: 18,
        advice: '本次训练负荷正常。建议 12–24 小时常规恢复，补充水分与营养，' +
          '下一次训练可按计划进行。'
      };
    }
    return {
      load: load,
      loadStatus: '偏低',
      recoveryStatus: '快速恢复',
      suggestedRecoveryHours: 8,
      advice: '本次训练负荷偏低，身体可快速恢复（<12 小时）。' +
        '若目标是提升体能，可适当提高下次训练的强度或时长。'
    };
  }
}
