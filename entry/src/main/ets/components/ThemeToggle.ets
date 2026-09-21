/*
 * 文件标注：AI 生成 —— 主题切换按钮（通用 UI 组件）
 * 约束：组件内禁止硬编码色值，一律读取 theme.palette.*。
 */
import { ThemeManager } from '../theme/ThemeManager';

/** 顶部「深色/浅色」切换按钮 */
@Component
export struct ThemeToggle {
  @ObjectLink theme: ThemeManager;

  build() {
    Button(this.theme.isDark() ? '☀️ 浅色' : '🌙 深色')
      .fontSize(14)
      .fontColor(this.theme.palette.onAccent)
      .backgroundColor(this.theme.palette.accent)
      .borderRadius(18)
      .height(36)
      .onClick(() => {
        // 只改 mode，由 @Observed 触发全量重绘
        this.theme.toggle();
      })
  }
}
