/*
 * 文件标注：AI 生成 —— 全量数据备份/恢复服务（通用数据访问脚手架）
 *
 * 数据接入层 · 备份服务
 * 把全部 preferences 存储（画像/历史/日志/饮食/目标/设置/伤病/饮水/头像路径等）
 * 连同头像图片本体（base64）打包为单个 JSON：
 *   1. 沙箱快速备份（filesDir/henglian_backup.json）；
 *   2. 系统文件选择器导出到公共目录 / 从外部文件恢复（用户主动选择，系统授权，无需权限）。
 * 恢复前校验版本号与结构；头像写回沙箱并修正 avatar_path。
 * 基于 @ohos.file.fs 与 preferences，纯本地操作，无网络请求，符合赛事「端侧、不联网」约束。
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

/** 备份文件顶层结构（带版本号，恢复时校验；avatarBase64 为可选增量，旧备份无此字段仍可恢复） */
interface BackupPackage {
  version: number;
  exportedAt: string;
  stores: StoreDump[];
  /** 头像图片本体的 base64（可选；恢复时写回沙箱并更新 user_avatar.avatar_path） */
  avatarBase64?: string;
}

/** 沙箱备份文件摘要信息（备份页展示用） */
export interface SandboxBackupInfo {
  exists: boolean;
  exportedAt: string;
  sizeKb: number;
}

export class BackupService {
  /** 备份文件版本号（结构变更时递增；avatarBase64 为可选字段，未递增版本号，v1 备份仍可恢复） */
  private static readonly VERSION: number = 1;
  /** 参与备份的全部 preferences 存储名（与各 Store 类 STORE_NAME 一致） */
  private static readonly STORE_NAMES: string[] = [
    'sport_history', 'workout_log', 'diet_log', 'wellness_log', 'body_metrics',
    'training_goal', 'user_profile', 'injury_records', 'sport_settings', 'water_log',
    'user_avatar'
  ];
  /** 头像存储与键名（与 AvatarStore 一致） */
  private static readonly AVATAR_STORE: string = 'user_avatar';
  private static readonly AVATAR_KEY: string = 'avatar_path';

  private static filePath(context: common.UIAbilityContext): string {
    return `${context.filesDir}/henglian_backup.json`;
  }

  /** 读取头像文件并 base64 编码；无头像或读取失败返回空串 */
  private static readAvatarBase64(context: common.UIAbilityContext): string {
    try {
      const prefs: preferences.Preferences =
        preferences.getPreferencesSync(context, { name: BackupService.AVATAR_STORE });
      const path: string = prefs.getSync(BackupService.AVATAR_KEY, '') as string;
      if (path.length === 0 || !fs.accessSync(path)) {
        return '';
      }
      const stat = fs.statSync(path);
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      const file: fs.File = fs.openSync(path, fs.OpenMode.READ_ONLY);
      try {
        fs.readSync(file.fd, buffer);
      } finally {
        fs.closeSync(file);
      }
      const helper: util.Base64Helper = new util.Base64Helper();
      return helper.encodeToStringSync(new Uint8Array(buffer));
    } catch (err) {
      console.warn(`BackupService read avatar failed: ${JSON.stringify(err)}`);
      return '';
    }
  }

  /** 组装备份包（全量 preferences + 头像本体） */
  private static buildPackage(context: common.UIAbilityContext): BackupPackage {
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
    const avatar: string = BackupService.readAvatarBase64(context);
    if (avatar.length > 0) {
      pack.avatarBase64 = avatar;
    }
    return pack;
  }

  /** 把文本写入指定路径/URI（截断写；调用方保证目标可写） */
  private static writeTextTo(target: string, content: string): void {
    const file: fs.File = fs.openSync(target, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(file.fd, content);
    } finally {
      fs.closeSync(file);
    }
  }

  /** 读取路径/URI 的完整文本内容 */
  private static readTextFrom(source: string): string {
    const stat = fs.statSync(source);
    const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
    const file: fs.File = fs.openSync(source, fs.OpenMode.READ_ONLY);
    try {
      fs.readSync(file.fd, buffer);
    } finally {
      fs.closeSync(file);
    }
    const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
    return decoder.decodeToString(new Uint8Array(buffer));
  }

  /** 导出全量数据为单个 JSON 文件到沙箱，返回沙箱路径；失败抛出 Error */
  static exportAll(context: common.UIAbilityContext): string {
    const pack: BackupPackage = BackupService.buildPackage(context);
    const path: string = BackupService.filePath(context);
    BackupService.writeTextTo(path, JSON.stringify(pack));
    return path;
  }

  /** 导出全量数据到系统选择器给出的 URI（用户选定的公共目录文件）；失败抛出 Error */
  static exportToUri(context: common.UIAbilityContext, uri: string): void {
    const pack: BackupPackage = BackupService.buildPackage(context);
    BackupService.writeTextTo(uri, JSON.stringify(pack));
  }

  /** 沙箱备份文件是否已存在 */
  static backupExists(context: common.UIAbilityContext): boolean {
    try {
      return fs.accessSync(BackupService.filePath(context));
    } catch {
      return false;
    }
  }

  /** 沙箱备份摘要（是否存在 / 导出时间 / 大小 KB）；解析失败按不存在处理 */
  static sandboxBackupInfo(context: common.UIAbilityContext): SandboxBackupInfo {
    const none: SandboxBackupInfo = { exists: false, exportedAt: '', sizeKb: 0 };
    try {
      const path: string = BackupService.filePath(context);
      if (!fs.accessSync(path)) {
        return none;
      }
      const stat = fs.statSync(path);
      let exportedAt: string = '';
      try {
        const pack: BackupPackage = JSON.parse(BackupService.readTextFrom(path)) as BackupPackage;
        exportedAt = pack.exportedAt ?? '';
      } catch {
        exportedAt = '';
      }
      const info: SandboxBackupInfo = {
        exists: true,
        exportedAt: exportedAt,
        sizeKb: Math.max(1, Math.round(stat.size / 1024))
      };
      return info;
    } catch {
      return none;
    }
  }

  /**
   * 从备份 JSON 文本恢复全量数据（调用方负责覆盖确认弹窗）。
   * 结构或版本不合法时抛出 Error；返回恢复的键值条目总数。
   * 含头像本体时写回沙箱并把 avatar_path 指向新文件。
   */
  static restoreFromContent(context: common.UIAbilityContext, content: string): number {
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
    // 头像本体：写回沙箱新文件并修正路径（旧备份无此字段则跳过）
    if (pack.avatarBase64 !== undefined && pack.avatarBase64.length > 0) {
      try {
        const helper: util.Base64Helper = new util.Base64Helper();
        const bytes: Uint8Array = helper.decodeSync(pack.avatarBase64);
        const destPath: string = `${context.filesDir}/avatar_restored_${Date.now()}.jpg`;
        const file: fs.File = fs.openSync(destPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
        try {
          fs.writeSync(file.fd, bytes.buffer);
        } finally {
          fs.closeSync(file);
        }
        const prefs: preferences.Preferences =
          preferences.getPreferencesSync(context, { name: BackupService.AVATAR_STORE });
        prefs.putSync(BackupService.AVATAR_KEY, destPath);
        prefs.flush();
      } catch (err) {
        console.warn(`BackupService restore avatar failed: ${JSON.stringify(err)}`);
      }
    }
    return restored;
  }

  /**
   * 从沙箱备份文件恢复全量数据（调用方负责覆盖确认弹窗）。
   * 结构或版本不合法时抛出 Error；返回恢复的键值条目总数。
   */
  static restoreAll(context: common.UIAbilityContext): number {
    return BackupService.restoreFromContent(context, BackupService.readTextFrom(BackupService.filePath(context)));
  }

  /** 从系统选择器给出的外部备份文件恢复；失败抛出 Error */
  static restoreFromUri(context: common.UIAbilityContext, uri: string): number {
    return BackupService.restoreFromContent(context, BackupService.readTextFrom(uri));
  }
}
