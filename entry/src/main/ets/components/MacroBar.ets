/*
 * 文件标注：AI 生成 —— 宏量营养素占比条（通用 UI 组件）
 * 约束：组件内禁止硬编码色值；条颜色由父组件从 theme.palette.protein/carb/fat 传入。
 */
import { ThemeManager } from '../theme/ThemeManager';

/** 单条宏量营养素占比条：名称 + 占比进度条 + 克数 */
@Component
export struct MacroBar {
  @ObjectLink theme: ThemeManager;
  /** 营养素名称，如「蛋白质」 */
  @Prop label: string = '';
  /** 占比（0–100） */
  @Prop pct: number = 0;
  /** 克数 */
  @Prop grams: number = 0;
  /** 条颜色（由父组件取自 theme.palette.*） */
  @Prop barColor: string = '';

  build() {
    Column({ space: 6 }) {
      Row() {
        Text(this.label)
          .fontSize(14)
          .fontColor(this.theme.palette.primaryText)
        Blank()
        Text(`${this.grams} g · ${this.pct}%`)
          .fontSize(13)
          .fontColor(this.theme.palette.secondaryText)
      }
      .width('100%')

      // 占比条：轨道 + 填充
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(8)
          .borderRadius(4)
          .backgroundColor(this.theme.palette.track)
        Row()
          .width(`${this.pct}%`)
          .height(8)
          .borderRadius(4)
          .backgroundColor(this.barColor)
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 10 })
  }
}
