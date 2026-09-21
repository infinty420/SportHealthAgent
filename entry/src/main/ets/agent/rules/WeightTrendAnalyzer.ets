/*
 * 文件标注：自主业务逻辑 —— 体重趋势分析规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 体重趋势模块
 * 对最近 14 天体重做最小二乘线性拟合，输出每周变化速率与 4 周预测；
 * 最近 10 天体重波动 < 0.3kg 判定为平台期并提示。
 * 确定性规则计算，无网络请求、无模型推理。
 */
import { BodyMetricEntry } from '../../data/BodyMetricsStore';

/** 体重趋势报告 */
export interface WeightTrendReport {
  /** 数据点数量（<2 时其余字段为 0） */
  samples: number;
  /** 线性趋势斜率（公斤/周；负值=下降） */
  slopeKgPerWeek: number;
  /** 当前体重（最近一条记录；无数据为 0） */
  currentKg: number;
  /** 4 周后预测体重（公斤） */
  forecast4WeekKg: number;
  /** 是否平台期（最近 10 天波动 < 0.3kg） */
  plateau: boolean;
  /** 中文结论 */
  note: string;
}

export class WeightTrendAnalyzer {
  private static readonly DAY_MS: number = 86400000;
  /** 趋势拟合窗口（天） */
  private static readonly TREND_WINDOW_DAYS: number = 14;
  /** 平台期窗口（天）与波动阈值（公斤） */
  private static readonly PLATEAU_WINDOW_DAYS: number = 10;
  private static readonly PLATEAU_RANGE_KG: number = 0.3;

  /**
   * 分析体重趋势。
   * @param entries 体成分记录（任意顺序，内部按时间排序；weightKg ≤ 0 的记录忽略）
   */
  static analyze(entries: BodyMetricEntry[], now: number = Date.now()): WeightTrendReport {
    const valid: BodyMetricEntry[] = entries.filter((e: BodyMetricEntry) => e.weightKg > 0);
    valid.sort((a: BodyMetricEntry, b: BodyMetricEntry) => a.timestamp - b.timestamp);

    const empty: WeightTrendReport = {
      samples: valid.length, slopeKgPerWeek: 0, currentKg: 0, forecast4WeekKg: 0, plateau: false,
      note: '体重数据不足，记录几天后即可查看趋势'
    };
    if (valid.length === 0) {
      return empty;
    }
    const current: number = valid[valid.length - 1].weightKg;
    if (valid.length < 2) {
      empty.currentKg = current;
      return empty;
    }

    // 最近 14 天窗口最小二乘拟合（x = 距窗口起点的天数）
    const windowStart: number = now - WeightTrendAnalyzer.TREND_WINDOW_DAYS * WeightTrendAnalyzer.DAY_MS;
    const inWindow: BodyMetricEntry[] = valid.filter((e: BodyMetricEntry) => e.timestamp >= windowStart);
    const fitPoints: BodyMetricEntry[] = inWindow.length >= 2 ? inWindow : valid.slice(Math.max(0, valid.length - 3));
    const x0: number = fitPoints[0].timestamp;
    let sumX: number = 0;
    let sumY: number = 0;
    let sumXY: number = 0;
    let sumXX: number = 0;
    fitPoints.forEach((e: BodyMetricEntry) => {
      const x: number = (e.timestamp - x0) / WeightTrendAnalyzer.DAY_MS;
      sumX += x;
      sumY += e.weightKg;
      sumXY += x * e.weightKg;
      sumXX += x * x;
    });
    const n: number = fitPoints.length;
    const denom: number = n * sumXX - sumX * sumX;
    // 斜率（公斤/天）→ 公斤/周；分母为 0（所有点同一天）时视为 0
    const slopePerDay: number = denom === 0 ? 0 : (n * sumXY - sumX * sumY) / denom;
    const slopePerWeek: number = Math.round(slopePerDay * 7 * 100) / 100;
    const forecast: number = Math.round((current + slopePerWeek * 4) * 10) / 10;

    // 平台期：最近 10 天波动 < 0.3kg（至少 3 个数据点）
    const plateauStart: number = now - WeightTrendAnalyzer.PLATEAU_WINDOW_DAYS * WeightTrendAnalyzer.DAY_MS;
    const recentPoints: BodyMetricEntry[] = valid.filter((e: BodyMetricEntry) => e.timestamp >= plateauStart);
    let plateau: boolean = false;
    if (recentPoints.length >= 3) {
      let minW: number = recentPoints[0].weightKg;
      let maxW: number = recentPoints[0].weightKg;
      recentPoints.forEach((e: BodyMetricEntry) => {
        minW = Math.min(minW, e.weightKg);
        maxW = Math.max(maxW, e.weightKg);
      });
      plateau = maxW - minW < WeightTrendAnalyzer.PLATEAU_RANGE_KG;
    }

    let note: string;
    if (plateau) {
      note = `近 10 天体重波动不足 ${WeightTrendAnalyzer.PLATEAU_RANGE_KG}kg，进入平台期；建议复核热量摄入或调整训练容量`;
    } else if (slopePerWeek > 0.1) {
      note = `体重每周约 +${slopePerWeek}kg，4 周后预计 ${forecast}kg`;
    } else if (slopePerWeek < -0.1) {
      note = `体重每周约 ${slopePerWeek}kg，4 周后预计 ${forecast}kg`;
    } else {
      note = '体重基本稳定';
    }
    const report: WeightTrendReport = {
      samples: valid.length,
      slopeKgPerWeek: slopePerWeek,
      currentKg: current,
      forecast4WeekKg: forecast,
      plateau: plateau,
      note: note
    };
    return report;
  }
}
