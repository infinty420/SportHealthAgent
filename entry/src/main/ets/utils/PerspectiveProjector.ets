/*
 * 文件标注：AI 生成 —— 2.5D 透视投影与绘制辅助（纯计算工具，无 UI、无网络）
 *
 * 工具层 · PerspectiveProjector
 * 1. project()：单点透视投影，近大远小（scale = 1 + z * 0.15），X 轴向灭点偏移模拟 3/4 视角；
 * 2. shadeColor()：由调色板基色推导明暗色（基色一律来自 theme.palette.*，此处只做数值推导）；
 * 3. hitPolygon()：射线法点-多边形命中检测（部位点击 tooltip 用）。
 */

/** 投影后的 2D 坐标（显式 interface，ArkTS 对象字面量契约） */
export interface ProjectedPoint {
  px: number;
  py: number;
}

export class PerspectiveProjector {
  /**
   * 单点透视投影：z=0 最远、z=1 最近；近大远小 + 向灭点收拢。
   * vanishingX 取画布中心，vanishingY 取画布顶部偏上。
   */
  static project(x: number, y: number, z: number, vanishingX: number, vanishingY: number): ProjectedPoint {
    const scale: number = 1 + z * 0.15;
    const point: ProjectedPoint = {
      px: vanishingX + (x - vanishingX) * scale,
      py: vanishingY + (y - vanishingY) * scale
    };
    return point;
  }

  /**
   * 颜色明暗推导：amount > 0 向白色靠拢，< 0 向黑色靠拢（|amount| ∈ 0~1）。
   * 输入为 '#RRGGBB' 调色板色值，输出同格式，不产生任何硬编码色值。
   */
  static shadeColor(hex: string, amount: number): string {
    const r: number = parseInt(hex.substring(1, 3), 16);
    const g: number = parseInt(hex.substring(3, 5), 16);
    const b: number = parseInt(hex.substring(5, 7), 16);
    const target: number = amount >= 0 ? 255 : 0;
    const factor: number = Math.abs(amount);
    const nr: number = Math.round(r + (target - r) * factor);
    const ng: number = Math.round(g + (target - g) * factor);
    const nb: number = Math.round(b + (target - b) * factor);
    return `#${PerspectiveProjector.toHex(nr)}${PerspectiveProjector.toHex(ng)}${PerspectiveProjector.toHex(nb)}`;
  }

  /** 0-255 → 两位十六进制（静态方法内一律用类名访问，不用 this） */
  private static toHex(value: number): string {
    const clamped: number = Math.max(0, Math.min(255, value));
    const text: string = clamped.toString(16);
    return text.length < 2 ? `0${text}` : text;
  }

  /** 射线法：点 (px,py) 是否在多边形 points 内（部位点击命中检测用） */
  static hitPolygon(px: number, py: number, points: number[][]): boolean {
    let inside: boolean = false;
    let j: number = points.length - 1;
    for (let i: number = 0; i < points.length; i++) {
      const xi: number = points[i][0];
      const yi: number = points[i][1];
      const xj: number = points[j][0];
      const yj: number = points[j][1];
      const crosses: boolean = (yi > py) !== (yj > py) &&
        px < (xj - xi) * (py - yi) / (yj - yi) + xi;
      if (crosses) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }
}
