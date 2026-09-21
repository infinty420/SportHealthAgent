/*
 * 文件标注：AI 生成 —— 手动录入数据源（表单装配脚手架）
 *          自主业务逻辑 —— 训练负荷缺失时调用 estimateTrainingLoad() 本地估算
 *
 * 数据接入层 · 路线②：手动录入
 * 将表单输入装配为 HealthRecord，并做合法性校验；
 * 本作演示主流程采用手动录入驱动，Health Kit 接入后两者可互换（同一 HealthDataSource 接口）。
 */
import { HealthRecord, estimateTrainingLoad, estimateTrainingLoadPersonalized } from '../model/HealthRecord';
import { UserProfile } from '../model/UserProfile';
import { HealthDataSource } from './HealthDataSource';

/** 手动录入结果：成功时 record 非空；失败时 errors 非空 */
export class ManualInputResult {
  record: HealthRecord | null = null;
  errors: string[] = [];
}

export class ManualInputSource implements HealthDataSource {
  private latest: HealthRecord | null = null;
  private profile: UserProfile | null = null;

  name(): string {
    return '手动录入';
  }

  /** 注入用户画像：负荷估算按年龄修正心率区间 */
  setUserProfile(profile: UserProfile | null): void {
    this.profile = profile;
  }

  /**
   * 提交表单数据。
   * @param trainingLoadText 训练负荷输入框原文；留空表示缺失，将本地估算
   */
  submit(durationMin: number, avgHeartRate: number, pace: string,
    calories: number, sportType: string, trainingLoadText: string): ManualInputResult {
    const result: ManualInputResult = new ManualInputResult();
    const record: HealthRecord = new HealthRecord();
    record.durationMin = durationMin;
    record.avgHeartRate = avgHeartRate;
    record.pace = pace;
    record.calories = calories;
    record.sportType = sportType;
    record.trainingLoad = trainingLoadText.trim().length === 0 ? -1 : Number(trainingLoadText);

    // 数字合法性兜底（UI 层已限制输入类型，这里防御非数字场景）
    if (Number.isNaN(record.durationMin) || Number.isNaN(record.avgHeartRate) ||
      Number.isNaN(record.calories) || Number.isNaN(record.trainingLoad)) {
      result.errors.push('存在非法数字输入，请检查各数值字段');
      return result;
    }

    // 模型层合法性校验
    result.errors = record.validate();
    if (result.errors.length > 0) {
      return result;
    }

    /* ===== 自主业务逻辑：训练负荷缺失时本地估算（画像已填写则按年龄修正心率区间） ===== */
    if (record.trainingLoad < 0) {
      if (this.profile !== null && this.profile.filled) {
        record.trainingLoad = estimateTrainingLoadPersonalized(
          record.durationMin, record.avgHeartRate, this.profile.restingHr, this.profile.maxHeartRate());
      } else {
        record.trainingLoad = estimateTrainingLoad(record.durationMin, record.avgHeartRate);
      }
    }

    this.latest = record;
    result.record = record;
    return result;
  }

  async readLatest(): Promise<HealthRecord | null> {
    return this.latest;
  }
}
