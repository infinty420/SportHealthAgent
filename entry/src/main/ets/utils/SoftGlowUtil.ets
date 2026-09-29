/*
 * 文件标注：AI 生成 —— 柔光渐变工具（通用 UI 基础设施）
 *
 * 视觉系统 · SoftGlowUtil
 * 由调色板 accentGlow（'#AARRGGBB'）推导径向渐变色组：[中心柔光 → 边缘全透明]，
 * 供组件 .radialGradient() 一次性叠加；结果按颜色内存缓存，禁止每帧重算。
 */
import { HeatColorUtil } from './HeatColorUtil';

export class SoftGlowUtil {
  /** 内存缓存：accentGlow 色值 → 径向渐变色组 */
  private static readonly cache: Map<string, Array<[string, number]>> =
    new Map<string, Array<[string, number]>>();

  /**
   * 取柔光径向渐变色组（中心 accentGlow → 边缘同色全透明）。
   * accentGlow 为 '#AARRGGBB'（自带约 8% alpha），同一色值只计算一次。
   */
  static getGlowColors(glowColor: string): Array<[string, number]> {
    const hit: Array<[string, number]> | undefined = SoftGlowUtil.cache.get(glowColor);
    if (hit !== undefined) {
      return hit;
    }
    // '#AARRGGBB' → RGB 部分推导全透明端点（不产生硬编码色值）
    const rgbHex: string = `#${glowColor.substring(3)}`;
    const transparent: string = HeatColorUtil.alphaColor(rgbHex, 0);
    const colors: Array<[string, number]> = [[glowColor, 0.0], [transparent, 1.0]];
    SoftGlowUtil.cache.set(glowColor, colors);
    return colors;
  }

  /** 透明色组（glow 关闭时占位用，视觉上等于无柔光） */
  static transparentColors(glowColor: string): Array<[string, number]> {
    const rgbHex: string = `#${glowColor.substring(3)}`;
    const transparent: string = HeatColorUtil.alphaColor(rgbHex, 0);
    return [[transparent, 0.0], [transparent, 1.0]];
  }
}
