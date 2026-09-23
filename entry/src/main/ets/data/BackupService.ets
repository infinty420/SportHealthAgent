/*
 * 文件标注：AI 生成 —— 全量数据备份/恢复服务（通用数据访问脚手架）
 *
 * 数据接入层 · 备份服务
 * 把全部 preferences 存储（画像/历史/日志/饮食/目标/设置/伤病/饮水等）
 * 导出为单个 JSON 文件到沙箱 filesDir；恢复前校验版本号与结构。
 * 基于 @ohos.file.fs 与 preferences，纯本地沙箱操作，无网络请求。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import fs from '@ohos.file.fs';

/** 单个键值条目（valueJson 为原值的 JSON 序列化，恢复时原样写回） */
interface PrefEntry {
  key: string;
  valueJson: string;
}

/** 单个 preferences 存储的完整转储 */
interface StoreDump {
  name: string;
  entries: PrefEntry[];
}

/** 备份文件顶层结构（带版本号，恢复时校验） */
interface BackupPackage {
  version: number;
  exportedAt: string;
  stores: StoreDump[];
}

export class BackupService {
  /** 备份文件版本号（结构变更时递增，恢复时校验） */
  private static readonly VERSION: number = 1;
  /** 参与备份的全部 preferences 存储名（与各 Store 类 STORE_NAME 一致） */
  private static readonly STORE_NAMES: string[] = [
    'sport_history', 'workout_log', 'diet_log', 'wellness_log', 'body_metrics',
    'training_goal', 'user_profile', 'injury_records', 'sport_settings', 'water_log'
  ];

  private static filePath(context: common.UIAbilityContext): string {
    return `${context.filesDir}/henglian_backup.json`;
  }

  /** 导出全量数据为单个 JSON 文件，返回沙箱路径；失败抛出 Error */
  static exportAll(context: common.UIAbilityContext): string {
    const stores: StoreDump[] = [];
    BackupService.STORE_NAMES.forEach((name: string) => {
      const prefs: preferences.Preferences = preferences.getPreferencesSync(context, { name: name });
      const all: Record<string, preferences.ValueType> =
        prefs.getAllSync() as Record<string, preferences.ValueType>;
      const entries: PrefEntry[] = [];
      Object.keys(all).forEach((key: string) => {
        // Record 哈希表按键读取（非固定字段对象，见开发规范 #5 的适用范围说明）
        entries.push({ key: key, valueJson: JSON.stringify(all[key]) });
      });
      stores.push({ name: name, entries: entries });
    });
    const pack: BackupPackage = {
      version: BackupService.VERSION,
      exportedAt: new Date().toLocaleString(),
      stores: stores
    };
    const path: string = BackupService.filePath(context);
    const file: fs.File = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(file.fd, JSON.stringify(pack));
    } finally {
      fs.closeSync(file);
    }
    return path;
  }

  /** 备份文件是否已存在 */
  static backupExists(context: common.UIAbilityContext): boolean {
    try {
      return fs.accessSync(BackupService.filePath(context));
    } catch {
      return false;
    }
  }

  /**
   * 从备份文件恢复全量数据（调用方负责覆盖确认弹窗）。
   * 结构或版本不合法时抛出 Error；返回恢复的键值条目总数。
   */
  static restoreAll(context: common.UIAbilityContext): number {
    const path: string = BackupService.filePath(context);
    let content: string = '';
    const file: fs.File = fs.openSync(path, fs.OpenMode.READ_ONLY);
    try {
      const stat = fs.statSync(path);
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      content = decoder.decodeToString(new Uint8Array(buffer));
    } finally {
      fs.closeSync(file);
    }
    let pack: BackupPackage;
    try {
      pack = JSON.parse(content) as BackupPackage;
    } catch (err) {
      throw new Error('备份文件不是合法的 JSON');
    }
    if (pack.version !== BackupService.VERSION || !Array.isArray(pack.stores)) {
      throw new Error(`备份文件版本或结构不兼容（version=${pack.version}）`);
    }
    let restored: number = 0;
    pack.stores.forEach((store: StoreDump) => {
      if (BackupService.STORE_NAMES.indexOf(store.name) < 0 || !Array.isArray(store.entries)) {
        return;
      }
      const prefs: preferences.Preferences =
        preferences.getPreferencesSync(context, { name: store.name });
      store.entries.forEach((entry: PrefEntry) => {
        prefs.putSync(entry.key, JSON.parse(entry.valueJson) as preferences.ValueType);
        restored++;
      });
      prefs.flush();
    });
    return restored;
  }
}
