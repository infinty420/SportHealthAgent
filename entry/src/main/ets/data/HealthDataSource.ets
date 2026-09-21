/*
 * 文件标注：AI 生成 —— 数据接入层抽象接口（通用脚手架）
 *
 * 数据接入层 · 数据源抽象
 * 统一两类数据来源：① 鸿蒙 Health Kit（智能手表）；② 手动录入。
 * Agent 引擎只依赖本接口，不关心数据来自手表还是表单，便于赛前切换与测试。
 */
import { HealthRecord } from '../model/HealthRecord';

/** 健康数据源接口 */
export interface HealthDataSource {
  /** 数据源名称（用于 UI 展示与日志） */
  name(): string;

  /** 读取最近一次运动记录；无数据时返回 null */
  readLatest(): Promise<HealthRecord | null>;
}
