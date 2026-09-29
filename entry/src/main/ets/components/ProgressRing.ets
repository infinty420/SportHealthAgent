/*
 * 文件标注：AI 生成 —— 极简圆环进度（通用 UI 组件）
 * 约束：组件内禁止硬编码色值，一律读取 theme.palette.*。
 * stroke 6 细环 + accent 纯色 + 中心大数字（numberL），用于准备度/目标达成。
 */
import { ThemeManager } from '../theme/ThemeManager';
import { Typography } from '../utils/Typography';

/** 极简圆环进度：环形进度 + 中心数值与说明 */
@Component
export struct ProgressRing {
  @ObjectLink theme: ThemeManager;
  /** 当前值 */
  @Prop value: number = 0;
  /** 总量（默认 100 即百分比） */
  @Prop total: number = 100;
  /** 中心大数字文本（缺省显示 value 整数） */
  @Prop centerText: string = '';
  /** 中心数字下方的小字说明（可选） */
  @Prop caption: string = '';
  /** 环直径（vp） */
  @Prop diameter: number = 84;
  /** 可选环色（空串 = accent；用于准备度档位四色映射） */
  @Prop ringColor: string = '';
  /** 滚动显示的数值（-1 = 未滚动，直接显示真实值） */
  @State private shownValue: number = -1;

  /** 数字滚动：400ms ease-out 从 0 滚到目标值（仅纯数字模式） */
  private rollTo(target: number): void {
    const steps: number = 8;
    let tick: number = 0;
    const timerId: number = setInterval(() => {
      tick++;
      this.shownValue = Math.round(target * tick / steps);
      if (tick >= steps) {
        this.shownValue = target;
        clearInterval(timerId);
      }
    }, 50);
  }

  build() {
    Stack() {
      Progress({ value: this.value, total: this.total, type: ProgressType.Ring })
        .width(this.diameter)
        .height(this.diameter)
        .color(this.ringColor.length > 0 ? this.ringColor : this.theme.palette.accent)
        .backgroundColor(this.theme.palette.track)
        .style({ strokeWidth: 6 })
      Column({ space: 0 }) {
        Text(this.centerText.length > 0 ? this.centerText :
          `${this.shownValue < 0 ? Math.round(this.value) : this.shownValue}`)
          .fontSize(Typography.fontSize('numberL'))
          .fontWeight(Typography.fontWeight('numberL'))
          .fontColor(this.theme.palette.ink ?? this.theme.palette.primaryText)
        if (this.caption.length > 0) {
          Text(this.caption)
            .fontSize(10)
            .fontColor(this.theme.palette.secondaryText)
        }
      }
      .alignItems(HorizontalAlign.Center)
    }
    .accessibilityText(`进度 ${Math.round(this.value)}，共 ${Math.round(this.total)}`)
    .onAppear(() => {
      // 纯数字模式（无自定义中心文本）时执行数字滚动
      if (this.centerText.length === 0) {
        this.rollTo(this.value);
      }
    })
  }
}
