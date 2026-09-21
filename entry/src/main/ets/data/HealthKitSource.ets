/*
 * 文件标注：AI 生成 —— Health Kit 数据源骨架类（含 TODO，真实 API 调用由参赛者后续补全）
 *
 * 数据接入层 · 路线①：对接智能手表（鸿蒙 Health Kit）
 * 前置条件：
 *   1. module.json5 已声明 ohos.permission.READ_HEALTH_DATA（见 entry/src/main/module.json5）；
 *   2. 首次使用前需通过 abilityAccessCtrl 动态向用户申请授权；
 *   3. 本骨架不包含任何网络请求，Health Kit 为系统端侧服务，符合「端侧推理、不联网」约束。
 */
import { HealthRecord, estimateTrainingLoad } from '../model/HealthRecord';
import { HealthDataSource } from './HealthDataSource';

export class HealthKitSource implements HealthDataSource {
  name(): string {
    return '鸿蒙 Health Kit（智能手表）';
  }

  /**
   * 向用户申请健康数据读取授权。
   * TODO(参赛者)：使用 @kit.AbilityKit 的 abilityAccessCtrl.AtManager
   *   requestPermissionsFromUser(context, ['ohos.permission.READ_HEALTH_DATA'])
   *   完成动态授权，并处理用户拒绝场景。
   */
  async requestAuthorization(): Promise<boolean> {
    // TODO: 接入真实授权流程后返回用户授权结果
    return false;
  }

  /**
   * 从 healthStore 读取最近一次运动记录。
   * TODO(参赛者)：接入鸿蒙 Health Kit 真实 API，映射以下字段：
   *   - 运动时长   → durationMin（分钟）
   *   - 平均心率   → avgHeartRate（次/分）
   *   - 配速       → pace（如 "6'00\"/km"）
   *   - 卡路里     → calories（千卡）
   *   - 运动类型   → sportType（映射到 SportType 枚举）
   *   - 训练负荷   → trainingLoad（0–100；手表未提供时置 -1，走本地估算）
   */
  async readLatest(): Promise<HealthRecord | null> {
    const record: HealthRecord | null = this.readRawRecord();
    if (record === null) {
      return null;
    }
    // 训练负荷缺失时，用本地公式估算（自主业务逻辑，见 model/HealthRecord.ets）
    if (record.trainingLoad < 0) {
      record.trainingLoad = estimateTrainingLoad(record.durationMin, record.avgHeartRate);
    }
    return record;
  }

  /**
   * TODO(参赛者)：在此接入真实 healthStore 查询并映射字段（当前为骨架桩，恒返回 null 表示暂无数据）。
   * 字段映射：运动时长→durationMin、平均心率→avgHeartRate、配速→pace、
   *          卡路里→calories、运动类型→sportType、训练负荷→trainingLoad（缺失置 -1）。
   */
  private readRawRecord(): HealthRecord | null {
    return null;
  }
}
