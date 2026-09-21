/*
 * 文件标注：AI 生成 —— 卡片离屏截图导出工具（通用工具函数）
 *
 * 工具层 · 离屏截图导出
 * 使用 componentSnapshot 对已渲染组件离屏截图，经 ImageKit 编码为 PNG
 * 写入应用沙箱 filesDir/exports/。纯本地文件操作，不调系统分享、不联网。
 */
import { componentSnapshot } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

export class SnapshotExporter {
  /**
   * 把指定组件（.id(componentId)）导出为 PNG，保存到沙箱 exports 目录。
   * 结果（沙箱绝对路径或空串表失败）通过回调返回。
   */
  static exportPng(context: common.UIAbilityContext, componentId: string, fileName: string,
    callback: (path: string) => void): void {
    componentSnapshot.get(componentId).then((pixelMap: image.PixelMap) => {
      const dir: string = `${context.filesDir}/exports`;
      if (!fs.accessSync(dir)) {
        fs.mkdirSync(dir, true);
      }
      const path: string = `${dir}/${fileName}.png`;
      const file: fs.File = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      const packer: image.ImagePacker = image.createImagePacker();
      const options: image.PackingOption = { format: 'image/png', quality: 98 };
      packer.packToFile(pixelMap, file.fd, options).then(() => {
        fs.closeSync(file);
        callback(path);
      }).catch((err: Error) => {
        fs.closeSync(file);
        console.error(`SnapshotExporter pack failed: ${err.message}`);
        callback('');
      });
    }).catch((err: Error) => {
      console.error(`SnapshotExporter snapshot failed: ${err.message}`);
      callback('');
    });
  }
}
