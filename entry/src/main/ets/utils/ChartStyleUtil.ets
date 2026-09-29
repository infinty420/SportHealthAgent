/*
 * 文件标注：AI 生成 —— 图表样式令牌（通用 UI 基础设施）
 *
 * 视觉系统 · ChartStyleUtil
 * 柱状图/环形图/网格线的统一取值：颜色全部来自 theme.palette.*，
 * 渐变只做同色系深浅（accentStart→accentEnd），供 Canvas 绘制处取用。
 */
import { ThemeManager } from '../theme/ThemeManager';
import { DesignTokens } from './DesignTokens';

/** 图表样式令牌（静态常量 + palette 派生） */
export class ChartStyleUtil {
  /** 柱条圆角（vp，绘制时按需换算 px 语境） */
  static barCornerRadius(): number {
    return DesignTokens.radiusSm / 2;
  }

  /** 网格线/坐标轴线色 */
  static gridLineColor(theme: ThemeManager): string {
    return theme.palette.track;
  }

  /** 对比柱（上一周期）填充色 */
  static prevBarColor(theme: ThemeManager): string {
    return theme.palette.track;
  }

  /**
   * 主柱渐变两端色（顶部亮 → 底部深，同色系）：
   * 返回 [顶色, 底色]，供 createLinearGradient addColorStop(0/1) 使用
   */
  static barGradientColors(theme: ThemeManager): string[] {
    const top: string = theme.palette.accentEnd ?? theme.palette.accent;
    const bottom: string = theme.palette.accentStart ?? theme.palette.accent;
    return [top, bottom];
  }

  /** 环形描边渐变两端色（同色系，供环形进度 createLinearGradient 使用） */
  static ringGradientColors(theme: ThemeManager): string[] {
    const start: string = theme.palette.accentStart ?? theme.palette.accent;
    const end: string = theme.palette.accentEnd ?? theme.palette.accent;
    return [start, end];
  }
}
