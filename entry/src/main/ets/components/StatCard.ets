/*
 * 文件标注：AI 生成 —— 统计卡（通用 UI 组件）
 * 约束：组件内禁止硬编码色值，一律读取 theme.palette.*。
 * 结构：顶部 4px 同色系渐变条 + 大数字（36 Medium）+ 小标签（12 secondaryText）+ 右上 IconBadge。
 */
import { ThemeManager } from '../theme/ThemeManager';
import { Typography } from '../utils/Typography';
import { DesignTokens } from '../utils/DesignTokens';
import { IconBadge } from './IconBadge';

/** 统计卡：时长/卡路里/频次等汇总数据的统一展示位 */
@Component
export struct StatCard {
  @ObjectLink theme: ThemeManager;
  /** 小标签，如「总时长」（支持 string 与 $r 资源） */
  @Prop label: ResourceStr = '';
  /** 大数字文案（已格式化，如 '120'） */
  @Prop value: string = '';
  /** 单位，如 '分钟'；空串不显示 */
  @Prop unit: string = '';
  /** 图标资源名，如 'app.media.ic_duration' */
  @Prop iconRes: string = '';
  /** 色调：blue / green / orange / red */
  @Prop tone: string = 'blue';
  /** 入场错峰延迟（ms），默认 0；仅首屏前几张卡片传入 */
  @Prop enterDelay: number = 0;
  /** 入场动效标记 */
  @State private entered: boolean = false;

  /** tone → 语义色（渐变条端色推导基准） */
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

  /** tone → 渐变条端色（blue 用 accentStart→End 同系对，其余用同纯色退化为实色条） */
  private barStart(): string {
    if (this.tone === 'blue') {
      return this.theme.palette.accentStart ?? this.theme.palette.accent;
    }
    return this.toneColor();
  }

  private barEnd(): string {
    if (this.tone === 'blue') {
      return this.theme.palette.accentEnd ?? this.theme.palette.accent;
    }
    return this.toneColor();
  }

  build() {
    Column() {
      // 顶部 4px 同色系渐变条
      Row()
        .width('100%')
        .height(4)
        .linearGradient({ angle: 0, colors: [[this.barStart(), 0.0], [this.barEnd(), 1.0]] })
        .accessibilityLevel('no')
      Row() {
        Column({ space: 4 }) {
          Row({ space: 4 }) {
            Text(this.value)
              .fontSize(Typography.fontSize('numberXL'))
              .fontWeight(Typography.fontWeight('numberXL'))
              .fontColor(this.theme.palette.ink ?? this.theme.palette.primaryText)
            if (this.unit.length > 0) {
              Text(this.unit)
                .fontSize(12)
                .fontColor(this.theme.palette.secondaryText)
                .margin({ top: 14 })
            }
          }
          .alignItems(VerticalAlign.Bottom)
          Text(this.label)
            .fontSize(12)
            .fontColor(this.theme.palette.secondaryText)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        if (this.iconRes.length > 0) {
          IconBadge({ theme: this.theme, iconRes: this.iconRes, tone: this.tone, badgeSize: 40 })
        }
      }
      .width('100%')
      .padding(DesignTokens.space16)
      .alignItems(VerticalAlign.Top)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .borderRadius(DesignTokens.radiusXl)
    .clip(true)
    .backgroundColor(this.theme.palette.cardBackground)
    .shadow({ radius: DesignTokens.shadowMdRadius, color: this.theme.palette.cardShadow, offsetX: 0, offsetY: DesignTokens.shadowMdOffsetY })
    .accessibilityText((typeof this.label === 'string' ? `${this.label} ` : '') + `${this.value}${this.unit}`)
    .opacity(this.entered ? 1 : 0)
    .translate({ x: 0, y: this.entered ? 0 : 12 })
    .onAppear(() => {
      // 入场：250ms ease 淡入上滑（可选错峰延迟，仅首屏前几张传入）
      const timerId: number = setTimeout(() => {
        animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
          this.entered = true;
        });
        clearTimeout(timerId);
      }, this.enterDelay);
    })
  }
}
