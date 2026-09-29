/*
 * 文件标注：AI 生成 —— 渐变主按钮（通用 UI 组件）
 * 约束：组件内禁止硬编码色值；渐变为 accentStart→accentEnd 同色系（缺省回退 accent 纯色）。
 * 原生 Row 容器包装：按下 scale 0.97 / 200ms EaseOut 回弹。
 */
import { ThemeManager } from '../theme/ThemeManager';
import { DesignTokens } from '../utils/DesignTokens';

/** 渐变主按钮：accentStart→accentEnd 线性渐变 + radius16 + 按压回弹 */
@Component
export struct GradientButton {
  @ObjectLink theme: ThemeManager;
  /** 按钮文案 */
  @Prop buttonText: string = '';
  /** 点击回调 */
  onAction?: () => void;

  build() {
    Row() {
      Text(this.buttonText)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.theme.palette.onAccent)
    }
    .width('100%')
    .height(44)
    .justifyContent(FlexAlign.Center)
    .borderRadius(DesignTokens.radiusLg)
    .linearGradient({
      angle: 90,
      colors: [
        [this.theme.palette.accentStart ?? this.theme.palette.accent, 0.0],
        [this.theme.palette.accentEnd ?? this.theme.palette.accent, 1.0]
      ]
    })
    .stateStyles({
      pressed: { .scale({ x: DesignTokens.pressScale, y: DesignTokens.pressScale }) },
      normal: { .scale({ x: 1.0, y: 1.0 }) }
    })
    .accessibilityText(this.buttonText)
    .onClick(() => {
      if (this.onAction !== undefined) {
        this.onAction();
      }
    })
  }
}
