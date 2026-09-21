/*
 * 文件标注：AI 生成 —— Agent 引擎抽象接口（通用脚手架）
 *
 * 端侧 Agent 引擎 · 接口契约
 * 约束：任何实现都必须为纯端侧推理，严禁调用云端大模型 API、严禁引入网络请求。
 * 路线 A（本作）：RuleAnalysisEngine 纯规则引擎；
 * 路线 B（可选升级）：端侧小模型实现本接口，UI 与本接口保持不变。
 */
import { HealthRecord } from '../model/HealthRecord';
import { AnalysisReport } from './AnalysisResult';

/** 端侧分析引擎接口 */
export interface AnalysisEngine {
  /** 对一次运动记录做综合分析，输出三大模块建议 */
  analyze(record: HealthRecord): AnalysisReport;
}
