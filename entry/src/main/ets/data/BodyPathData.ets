/*
 * 文件标注：AI 生成 —— 人体部位多边形路径数据（纯本地数据，无网络）
 *
 * 数据层 · BodyPathData
 * 每个部位用简化多边形表示，点坐标按归一化 0–100 存储，绘制时按画布尺寸缩放。
 * 正面：肩(长弧形条) / 胸(梯形上宽下窄) / 腹(矩形) / 臀(半圆) / 手臂(两根细条) / 腿(两根条)；
 * 背面：肩 / 背(梯形) / 臀 / 腿 / 手臂。
 * 成对部位（手臂/腿）用「左/右」后缀键区分，groupOf() 归并到 7 个部位组。
 */

export class BodyPathData {
  /** 正面部位路径：键为部位名（成对部位带左/右后缀），值为归一化坐标点串 */
  static getFrontPaths(): Map<string, number[][]> {
    const paths: Map<string, number[][]> = new Map<string, number[][]>();
    paths.set('肩', [[18, 8], [82, 8], [86, 16], [80, 20], [20, 20], [14, 16]]);
    paths.set('胸', [[30, 22], [70, 22], [74, 30], [66, 40], [34, 40], [26, 30]]);
    paths.set('腹', [[38, 42], [62, 42], [60, 56], [40, 56]]);
    paths.set('臀', [[36, 58], [64, 58], [68, 68], [60, 74], [40, 74], [32, 68]]);
    paths.set('手臂左', [[10, 20], [18, 20], [16, 44], [12, 52], [6, 50], [6, 28]]);
    paths.set('手臂右', [[82, 20], [90, 20], [94, 28], [94, 50], [88, 52], [84, 44]]);
    paths.set('腿左', [[37, 76], [49, 76], [47, 97], [39, 97]]);
    paths.set('腿右', [[51, 76], [63, 76], [61, 97], [53, 97]]);
    return paths;
  }

  /** 背面部位路径 */
  static getBackPaths(): Map<string, number[][]> {
    const paths: Map<string, number[][]> = new Map<string, number[][]>();
    paths.set('肩', [[18, 8], [82, 8], [86, 16], [80, 20], [20, 20], [14, 16]]);
    paths.set('背', [[28, 22], [72, 22], [66, 44], [60, 54], [40, 54], [34, 44]]);
    paths.set('臀', [[36, 58], [64, 58], [68, 68], [60, 74], [40, 74], [32, 68]]);
    paths.set('手臂左', [[10, 20], [18, 20], [16, 44], [12, 52], [6, 50], [6, 28]]);
    paths.set('手臂右', [[82, 20], [90, 20], [94, 28], [94, 50], [88, 52], [84, 44]]);
    paths.set('腿左', [[37, 76], [49, 76], [47, 97], [39, 97]]);
    paths.set('腿右', [[51, 76], [63, 76], [61, 97], [53, 97]]);
    return paths;
  }

  /** 路径键 → 部位组名（手臂左/右 → 手臂，腿左/右 → 腿，其余原样） */
  static groupOf(key: string): string {
    if (key === '手臂左' || key === '手臂右') {
      return '手臂';
    }
    if (key === '腿左' || key === '腿右') {
      return '腿';
    }
    return key;
  }

  /** 路径键 → 透视深度因子 z（0 远 1 近；胸/背最前，腿最后） */
  static depthOf(key: string): number {
    const group: string = BodyPathData.groupOf(key);
    if (group === '胸') {
      return 1.0;
    }
    if (group === '背') {
      return 0.95;
    }
    if (group === '肩') {
      return 0.9;
    }
    if (group === '腹') {
      return 0.8;
    }
    if (group === '臀') {
      return 0.75;
    }
    if (group === '手臂') {
      return 0.7;
    }
    if (group === '腿') {
      return 0.6;
    }
    return 0.5;
  }
}
