/*
 * 文件标注：AI 生成 —— 分区卡片容器（通用 UI 组件）
 * 约束：组件内禁止硬编码色值，一律读取 theme.palette.*。
 */
import { ThemeManager } from '../theme/ThemeManager';

/** 带标题的卡片容器，三大分析模块共用 */
@Component
export struct SectionCard {
  @ObjectLink theme: ThemeManager;
  /** 卡片标题，如「模块① 本次训练评估」 */
  @Prop title: string = '';
  /** 卡片内容插槽 */
  @BuilderParam content: () => void;

  build() {
    Column() {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme.palette.primaryText)
        .margin({ bottom: 12 })
      this.content()
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor(this.theme.palette.cardBackground)
    .margin({ bottom: 14 })
  }
}
