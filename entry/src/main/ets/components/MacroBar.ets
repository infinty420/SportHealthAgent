/*
 * 文件标注：AI 生成 —— 宏量营养素占比条（通用 UI 组件）
 * 约束：组件内禁止硬编码色值；条颜色由父组件从 theme.palette.protein/carb/fat 传入。
 * 视觉升级：填充条为同色系线性渐变（两端深浅差 10%，由 HeatColorUtil 推导），条尾小圆点。
 */
import { ThemeManager } from '../theme/ThemeManager';
import { HeatColorUtil } from '../utils/HeatColorUtil';

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

      // 占比条：轨道 + 渐变填充 + 条尾小圆点
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(8)
          .borderRadius(4)
          .backgroundColor(this.theme.palette.track)
        if (this.pct > 0) {
          // 填充条 + 条尾小圆点（圆点吸附在填充末端，半跨条外）
          Row() {
            Row()
              .layoutWeight(1)
              .height(8)
              .borderRadius(4)
              .linearGradient({
                angle: 0,
                colors: [[this.barColor, 0.0], [HeatColorUtil.shadeColor(this.barColor, -0.1), 1.0]]
              })
            Circle({ width: 10, height: 10 })
              .fill(HeatColorUtil.shadeColor(this.barColor, -0.1))
              .margin({ left: -5 })
              .accessibilityLevel('no')
          }
          .width(`${this.pct}%`)
          .alignItems(VerticalAlign.Center)
          .height(10)
        }
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 10 })
  }
}
