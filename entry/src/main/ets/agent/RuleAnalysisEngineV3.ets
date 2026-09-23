/*
 * 文件标注：自主业务逻辑 —— 规则引擎 V3（加权评分 + 趋势斜率 + 采纳反馈加权，参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 路线 A v3
 * 在 V2（加权评分表 + 历史趋势斜率）基础上引入「采纳反馈加权」：
 *   统计最近 10 条历史报告的采纳率（采纳 / 采纳+忽略），
 *   采纳率低于 40% 且样本 ≥3 时，判定用户对当前建议风格接受度低，
 *   自动将下次训练强度下调一档、恢复时长上浮 20%，并在建议中说明原因。
 * 输出契约与 V1/V2 完全一致（AnalysisReport），支持三引擎并列对比。
 * 纯规则计算，不接入任何模型 SDK 与网络。
 */
import { HealthRecord } from '../model/HealthRecord';
import { UserProfile } from '../model/UserProfile';
import { HistoryEntry } from '../data/HistoryStore';
import { AnalysisEngine } from './AnalysisEngine';
import { AnalysisReport } from './AnalysisResult';
import { RuleConfig } from './RuleConfig';
import { RuleAnalysisEngineV2 } from './RuleAnalysisEngineV2';

export class RuleAnalysisEngineV3 implements AnalysisEngine {
  /** 采纳率低于该值且样本足够时触发建议放宽 */
  private static readonly ADOPTION_LOW: number = 0.4;
  /** 采纳率统计所需的最小样本数 */
  private static readonly ADOPTION_MIN_SAMPLES: number = 3;
  /** 采纳率统计窗口（最近 N 条） */
  private static readonly ADOPTION_WINDOW: number = 10;
  /** 低采纳率时恢复时长上浮系数 */
  private static readonly RECOVERY_EASE: number = 1.2;

  private readonly v2: RuleAnalysisEngineV2 = new RuleAnalysisEngineV2();
  private history: HistoryEntry[] = [];

  setInjuries(parts: string[]): void {
    this.v2.setInjuries(parts);
  }

  setConfig(config: RuleConfig): void {
    this.v2.setConfig(config);
  }

  setUserProfile(profile: UserProfile | null): void {
    this.v2.setUserProfile(profile);
  }

  setHistory(entries: HistoryEntry[]): void {
    this.history = entries;
    this.v2.setHistory(entries);
  }

  /** 最近 10 条历史的采纳率（-1 = 样本不足，不做反馈加权） */
  private adoptionRate(): number {
    const recent: HistoryEntry[] = this.history.slice(0, RuleAnalysisEngineV3.ADOPTION_WINDOW);
    let adopted: number = 0;
    let marked: number = 0;
    recent.forEach((entry: HistoryEntry) => {
      if (entry.adopted === 'adopted') {
        adopted++;
        marked++;
      } else if (entry.adopted === 'ignored') {
        marked++;
      }
    });
    if (marked < RuleAnalysisEngineV3.ADOPTION_MIN_SAMPLES) {
      return -1;
    }
    return adopted / marked;
  }

  analyze(record: HealthRecord): AnalysisReport {
    const report: AnalysisReport = this.v2.analyze(record);
    const rate: number = this.adoptionRate();
    if (rate >= 0 && rate < RuleAnalysisEngineV3.ADOPTION_LOW) {
      // 采纳率偏低：建议风格放宽一档（强度降档 + 恢复上浮），并说明依据
      if (report.nextWorkout.intensity === '中') {
        report.nextWorkout.intensity = '低-中';
      } else if (report.nextWorkout.intensity === '中-高') {
        report.nextWorkout.intensity = '中';
      }
      report.assessment.suggestedRecoveryHours =
        Math.round(report.assessment.suggestedRecoveryHours * RuleAnalysisEngineV3.RECOVERY_EASE);
      report.assessment.advice +=
        ` V3：最近建议采纳率仅 ${Math.round(rate * 100)}%，已自动放宽强度与恢复要求，先易后难重建习惯。`;
    } else if (rate >= 0.8) {
      report.assessment.advice += ` V3：建议采纳率 ${Math.round(rate * 100)}%，执行良好，可维持当前进阶节奏。`;
    }
    return report;
  }
}
