/*
 * 文件标注：AI 生成 —— 空状态组件（通用 UI 组件）
 * 约束：组件内禁止硬编码色值，一律读取 theme.palette.*。
 * 线框小人 + 中性文案 + 可选行动按钮，替换纯文字空提示。
 */
import { ThemeManager } from '../theme/ThemeManager';

/** 空状态：线框小人插图 + 引导文案 + 可选主按钮 */
@Component
export struct EmptyState {
  @ObjectLink theme: ThemeManager;
  /** 中性说明文案，如「暂无训练记录」 */
  @Prop message: string = '';
  /** 可选行动按钮文案；空串则不显示按钮 */
  @Prop actionLabel: string = '';
  /** 可选大插图（bg_empty 哑铃线稿，180vp）；false 时用 48vp 线框小人 */
  @Prop illustration: boolean = false;
  /** 按钮点击回调（可选，不传则按钮不响应） */
  onAction?: () => void;

  build() {
    Column({ space: 12 }) {
      if (this.illustration) {
        // 哑铃线稿大插图（透明底 PNG，深浅两套按主题切换）
        Image(this.theme.mode === 'dark' ? $r('app.media.bg_empty_dark') : $r('app.media.bg_empty_light'))
          .width(180)
          .height(180)
          .accessibilityLevel('no')
      } else {
        Image($r('app.media.companion'))
          .width(48)
          .height(48)
          .fillColor(this.theme.palette.secondaryText)
          .accessibilityLevel('no')
      }
      Text(this.message)
        .fontSize(13)
        .fontColor(this.theme.palette.secondaryText)
        .textAlign(TextAlign.Center)
        .lineHeight(18)
      if (this.actionLabel.length > 0) {
        Button(this.actionLabel)
          .fontSize(13)
          .fontColor(this.theme.palette.onAccent)
          .backgroundColor(this.theme.palette.accent)
          .borderRadius(16)
          .height(32)
          .accessibilityText(this.actionLabel)
          .onClick(() => {
            if (this.onAction !== undefined) {
              this.onAction();
            }
          })
      }
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }
}
