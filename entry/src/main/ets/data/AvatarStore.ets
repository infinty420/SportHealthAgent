/*
 * 文件标注：AI 生成 —— 用户头像本地持久化（通用数据访问脚手架）
 *
 * 数据接入层 · 头像存储
 * 系统相册选择器（photoViewPicker，系统组件授权读取，无需在 module.json5 申请权限）
 * 选图后复制进应用沙箱，沙箱路径写入 preferences；全程本地完成，无网络请求，
 * 符合赛事「端侧、不联网」约束。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';

export class AvatarStore {
  private static readonly STORE_NAME: string = 'user_avatar';
  private static readonly KEY_PATH: string = 'avatar_path';

  private readonly prefs: preferences.Preferences;
  private readonly filesDir: string;

  constructor(context: common.UIAbilityContext) {
    this.prefs = preferences.getPreferencesSync(context, { name: AvatarStore.STORE_NAME });
    this.filesDir = context.filesDir;
  }

  /** 当前头像沙箱路径；未设置时返回空串 */
  load(): string {
    return this.prefs.getSync(AvatarStore.KEY_PATH, '') as string;
  }

  /** 把相册选中的图片复制进沙箱并持久化路径；返回新沙箱路径（异常由调用方捕获提示） */
  saveFromUri(uri: string): string {
    const destPath: string = `${this.filesDir}/avatar_${Date.now()}.jpg`;
    const src: fs.File = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    try {
      fs.copyFileSync(src.fd, destPath);
    } finally {
      fs.closeSync(src);
    }
    // 清理上一张头像，避免沙箱越积越多
    const oldPath: string = this.load();
    if (oldPath.length > 0 && oldPath !== destPath) {
      try {
        fs.unlinkSync(oldPath);
      } catch (err) {
        console.warn(`AvatarStore remove old failed: ${JSON.stringify(err)}`);
      }
    }
    this.prefs.putSync(AvatarStore.KEY_PATH, destPath);
    this.prefs.flush();
    return destPath;
  }
}
