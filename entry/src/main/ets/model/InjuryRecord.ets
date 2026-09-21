/*
 * 文件标注：AI 生成 —— 伤病记录数据模型（通用数据模型脚手架）
 *
 * 数据接入层 · 伤病记录
 * 记录伤病部位（腰/膝/肩/腕）与起止日期，供动作禁忌过滤与计划调整使用。
 * 纯本地数据模型，无任何网络/系统 API 调用。
 */

/** 可记录的伤病部位 */
export const INJURY_PARTS: string[] = ['腰', '膝', '肩', '腕'];

/** 一条伤病记录 */
export class InjuryRecord {
  /** 部位（取值自 INJURY_PARTS） */
  part: string = '';
  /** 开始日期（YYYY-MM-DD） */
  startDate: string = '';
  /** 结束日期（YYYY-MM-DD；空串表示仍在恢复中） */
  endDate: string = '';
  /** 备注（可选） */
  note: string = '';

  /** 校验，返回中文错误列表（空 = 合法） */
  validate(): string[] {
    const errors: string[] = [];
    if (INJURY_PARTS.indexOf(this.part) < 0) {
      errors.push('伤病部位需为：腰/膝/肩/腕');
    }
    if (!/^\d{4}-\d{2}-\d{2}$/.test(this.startDate)) {
      errors.push('开始日期格式需为 YYYY-MM-DD');
    }
    if (this.endDate.length > 0 && !/^\d{4}-\d{2}-\d{2}$/.test(this.endDate)) {
      errors.push('结束日期格式需为 YYYY-MM-DD');
    }
    if (this.endDate.length > 0 && this.startDate.length === 10 && this.endDate < this.startDate) {
      errors.push('结束日期不能早于开始日期');
    }
    return errors;
  }

  /** 是否仍在恢复中（无结束日期，或结束日期晚于今天） */
  isActive(now: number): boolean {
    if (this.endDate.length === 0) {
      return true;
    }
    const today: Date = new Date(now);
    const month: string = `${today.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${today.getDate()}`.padStart(2, '0');
    const todayKey: string = `${today.getFullYear()}-${month}-${day}`;
    return this.endDate >= todayKey;
  }
}
