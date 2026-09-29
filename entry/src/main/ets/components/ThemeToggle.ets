/*
 * 文件标注：AI 生成 —— 主题切换按钮（通用 UI 组件）
 * 约束：组件内禁止硬编码色值，一律读取 theme.palette.*。
 * 视觉升级：日/月线性 SVG 图标（stroke-only），切换时图标 360° 旋转（animateTo 300ms）。
 */
import { ThemeManager } from '../theme/ThemeManager';

/** 顶部「深色/浅色」切换按钮 */
@Component
export struct ThemeToggle {
  @ObjectLink theme: ThemeManager;
  /** 图标旋转角：每次切换累加 360°，触发旋转动效 */
  @State private spinAngle: number = 0;

  build() {
    Button() {
      Row({ space: 6 }) {
        Image(this.theme.isDark() ? $r('app.media.icon_sun') : $r('app.media.icon_moon'))
          .width(16)
          .height(16)
          .fillColor(this.theme.palette.onAccent)
          .rotate({ angle: this.spinAngle })
          .accessibilityLevel('no')
        Text(this.theme.isDark() ? '浅色' : '深色')
          .fontSize(14)
          .fontColor(this.theme.palette.onAccent)
      }
      .alignItems(VerticalAlign.Center)
    }
    .backgroundColor(this.theme.palette.accent)
    .borderRadius(18)
    .height(36)
    .accessibilityText(this.theme.isDark() ? '切换到浅色模式' : '切换到深色模式')
    .onClick(() => {
      // 图标旋转 360°，同时只改 mode 由 @Observed 触发全量重绘
      animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
        this.spinAngle = this.spinAngle + 360;
        this.theme.toggle();
      });
    })
  }
}
