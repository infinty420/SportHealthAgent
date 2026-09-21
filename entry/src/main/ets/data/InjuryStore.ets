/*
 * 文件标注：AI 生成 —— 伤病记录本地持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 伤病记录存储
 * 基于系统 preferences（端侧本地键值存储，沙箱内，无网络请求）。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { InjuryRecord } from '../model/InjuryRecord';

export class InjuryStore {
  private static readonly STORE_NAME: string = 'injury_records';
  private static readonly KEY_RECORDS: string = 'records';

  private readonly prefs: preferences.Preferences;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: InjuryStore.STORE_NAME });
  }

  /** 追加一条伤病记录 */
  save(record: InjuryRecord): void {
    const list: InjuryRecord[] = this.list();
    list.unshift(record);
    this.prefs.putSync(InjuryStore.KEY_RECORDS, JSON.stringify(list));
    this.prefs.flush();
  }

  /** 全部记录（新记录在前）；重建为模型实例以恢复 isActive 等方法 */
  list(): InjuryRecord[] {
    const raw: string = this.prefs.getSync(InjuryStore.KEY_RECORDS, '[]') as string;
    try {
      const parsed: InjuryRecord[] = JSON.parse(raw) as InjuryRecord[];
      const result: InjuryRecord[] = [];
      parsed.forEach((plain: InjuryRecord) => {
        const record: InjuryRecord = new InjuryRecord();
        record.part = plain.part;
        record.startDate = plain.startDate;
        record.endDate = plain.endDate;
        record.note = plain.note;
        result.push(record);
      });
      return result;
    } catch (err) {
      console.warn(`InjuryStore parse failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /** 当前仍在恢复中的伤病部位（去重） */
  activeParts(): string[] {
    const now: number = Date.now();
    const parts: string[] = [];
    this.list().forEach((record: InjuryRecord) => {
      if (record.isActive(now) && parts.indexOf(record.part) < 0) {
        parts.push(record.part);
      }
    });
    return parts;
  }

  /** 删除指定部位的全部记录（伤愈后清除） */
  clearPart(part: string): void {
    const kept: InjuryRecord[] = this.list().filter((record: InjuryRecord) => record.part !== part);
    this.prefs.putSync(InjuryStore.KEY_RECORDS, JSON.stringify(kept));
    this.prefs.flush();
  }
}
