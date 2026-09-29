/*
 * 文件标注：AI 生成 —— 柔光背景预生成工具（通用 UI 基础设施）
 *
 * 视觉系统 · SoftGlowUtil
 * 离屏 Canvas 预生成径向渐变柔光图（dataURL），按颜色+尺寸内存缓存，
 * 页面以 backgroundImage 叠加一次即可；禁止每帧重绘，透明度由 accentGlow 自带 alpha 控制。
 */

export class SoftGlowUtil {
  /** 内存缓存：颜色+尺寸 → dataURL */
  private static readonly cache: Map<string, string> = new Map<string, string>();

  /**
   * 取一张径向柔光背景图（中心为 color，向外渐隐至全透明）。
   * 同一参数组合只生成一次，后续直接命中缓存。
   */
  static getGlowBg(color: string, size: number = 240): string {
    const key: string = `${color}-${size}`;
    const hit: string | undefined = SoftGlowUtil.cache.get(key);
    if (hit !== undefined) {
      return hit;
    }
    const canvas: OffscreenCanvas = new OffscreenCanvas(size, size);
    const ctx: OffscreenCanvasRenderingContext2D =
      canvas.getContext('2d') as OffscreenCanvasRenderingContext2D;
    const half: number = size / 2;
    const gradient = ctx.createRadialGradient(half, half, 0, half, half, half);
    gradient.addColorStop(0, color);
    gradient.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, size, size);
    const url: string = canvas.toDataURL('image/png');
    SoftGlowUtil.cache.set(key, url);
    return url;
  }
}
