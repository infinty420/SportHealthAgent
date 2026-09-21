/*
 * 文件标注：AI 生成 —— 模拟健康数据源（演示流程用脚手架）
 *
 * 数据接入层 · 模拟 Health Kit 数据源
 * 实现 HealthDataSource 接口，本地生成随机但合理的运动记录（时长/心率/卡路里/类型），
 * 仅用于演示流程与联调，不调用任何真实 Health Kit / 传感器 API。
 * HealthKitSource.ets 真实骨架保持不动。
 */
import { HealthRecord, SportType, SPORT_TYPE_LIST, estimateTrainingLoad } from '../model/HealthRecord';
import { HealthDataSource } from './HealthDataSource';

export class MockHealthKitSource implements HealthDataSource {
  name(): string {
    return '模拟手表数据';
  }

  /** 生成一条随机但合理的运动记录（负荷留空，交由估算公式） */
  async readLatest(): Promise<HealthRecord | null> {
    const record: HealthRecord = new HealthRecord();
    const typeIndex: number = Math.floor(Math.random() * SPORT_TYPE_LIST.length);
    record.sportType = SPORT_TYPE_LIST[typeIndex];
    record.durationMin = 20 + Math.floor(Math.random() * 60);
    record.avgHeartRate = 100 + Math.floor(Math.random() * 60);
    // 热量 ≈ 时长 × (6–10) kcal/min 的粗略区间
    record.calories = Math.round(record.durationMin * (6 + Math.random() * 4));
    if (record.sportType === SportType.RUN) {
      record.pace = `5'${30 + Math.floor(Math.random() * 50)}"/km`;
    } else {
      record.pace = '-';
    }
    record.trainingLoad = estimateTrainingLoad(record.durationMin, record.avgHeartRate);
    return record;
  }
}
