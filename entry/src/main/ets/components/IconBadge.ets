/*
 * 文件标注：AI 生成 —— 图标徽章（通用 UI 组件）
 * 约束：组件内禁止硬编码色值，一律读取 theme.palette.*（*Soft 软底 + 语义色图标）。
 * 图标为 24×24 currentColor 线性 SVG，经 Image.fillColor 着色。
 */
import { ThemeManager } from '../theme/ThemeManager';

/** 图标徽章：软底圆角方块 + 线性图标，tone 映射语义色 */
@Component
export struct IconBadge {
  @ObjectLink theme: ThemeManager;
  /** 图标资源名，如 'app.media.ic_training' */
  @Prop iconRes: string = '';
  /** 色调：blue / green / orange / red */
  @Prop tone: string = 'blue';
  /** 徽章边长（vp），默认 40 */
  @Prop badgeSize: number = 40;

  /** tone → 图标色（语义色） */
  private toneColor(): string {
    if (this.tone === 'green') {
      return this.theme.palette.success;
    }
    if (this.tone === 'orange') {
      return this.theme.palette.warning;
    }
    if (this.tone === 'red') {
      return this.theme.palette.danger;
    }
    return this.theme.palette.accent;
  }

  /** tone → 软底色（*Soft，缺省回退 accentSoft / inputBackground） */
  private toneSoft(): string {
    if (this.tone === 'green') {
      return this.theme.palette.successSoft ?? this.theme.palette.inputBackground;
    }
    if (this.tone === 'orange') {
      return this.theme.palette.warningSoft ?? this.theme.palette.inputBackground;
    }
    if (this.tone === 'red') {
      return this.theme.palette.dangerSoft ?? this.theme.palette.inputBackground;
    }
    return this.theme.palette.accentSoft;
  }

  build() {
    Column() {
      Image($r(this.iconRes))
        .width(this.badgeSize * 0.6)
        .height(this.badgeSize * 0.6)
        .fillColor(this.toneColor())
    }
    .width(this.badgeSize)
    .height(this.badgeSize)
    .borderRadius(12)
    .backgroundColor(this.toneSoft())
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .accessibilityLevel('no')
  }
}
