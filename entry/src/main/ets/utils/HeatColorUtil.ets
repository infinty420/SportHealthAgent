/*
 * 文件标注：AI 生成 —— 热力图颜色工具（纯计算，无 UI、无网络）
 *
 * 工具层 · HeatColorUtil
 * shadeColor()：由调色板基色推导明暗色；
 * alphaColor()：由调色板基色推导带透明度的 rgba() 颜色（发光色斑渐变用）。
 * 输入一律为 '#RRGGBB' 调色板色值，不产生任何硬编码色值。
 */

export class HeatColorUtil {
  /** 明暗推导：amount > 0 向白色靠拢，< 0 向黑色靠拢（|amount| ∈ 0~1） */
  static shadeColor(hex: string, amount: number): string {
    const rgb: number[] = HeatColorUtil.parseHex(hex);
    const target: number = amount >= 0 ? 255 : 0;
    const factor: number = Math.abs(amount);
    const nr: number = Math.round(rgb[0] + (target - rgb[0]) * factor);
    const ng: number = Math.round(rgb[1] + (target - rgb[1]) * factor);
    const nb: number = Math.round(rgb[2] + (target - rgb[2]) * factor);
    return `#${HeatColorUtil.toHex(nr)}${HeatColorUtil.toHex(ng)}${HeatColorUtil.toHex(nb)}`;
  }

  /** 透明度推导：'#RRGGBB' + alpha(0~1) → 'rgba(r,g,b,a)'（Canvas 渐变色斑用） */
  static alphaColor(hex: string, alpha: number): string {
    const rgb: number[] = HeatColorUtil.parseHex(hex);
    return `rgba(${rgb[0]},${rgb[1]},${rgb[2]},${alpha})`;
  }

  /** '#RRGGBB' → [r, g, b] */
  private static parseHex(hex: string): number[] {
    const rgb: number[] = [];
    rgb.push(parseInt(hex.substring(1, 3), 16));
    rgb.push(parseInt(hex.substring(3, 5), 16));
    rgb.push(parseInt(hex.substring(5, 7), 16));
    return rgb;
  }

  /** 0-255 → 两位十六进制（静态方法内一律用类名访问，不用 this） */
  private static toHex(value: number): string {
    const clamped: number = Math.max(0, Math.min(255, value));
    const text: string = clamped.toString(16);
    return text.length < 2 ? `0${text}` : text;
  }
}
