/*
 * 文件标注：AI 生成 —— 分区卡片容器（通用 UI 组件）
 * 约束：组件内禁止硬编码色值，一律读取 theme.palette.*。
 * 视觉升级：可选「01/02/03」细体编号、圆角 20、柔和投影、可选 accentGlow 柔光底纹。
 */
import { ThemeManager } from '../theme/ThemeManager';
import { SoftGlowUtil } from '../utils/SoftGlowUtil';
import { IconBadge } from './IconBadge';

/** 带标题的卡片容器，三大分析模块共用 */
@Component
export struct SectionCard {
  @ObjectLink theme: ThemeManager;
  /** 卡片标题，如「模块① 本次训练评估」 */
  @Prop title: string = '';
  /** 可选细体编号（如 '01'），空串不显示 */
  @Prop index: string = '';
  /** 可选柔光底纹（accentGlow 径向渐变，预生成缓存，非每帧绘制） */
  @Prop glow: boolean = false;
  /** 可选标题图标资源名（如 'app.media.ic_training'），空串不显示 */
  @Prop iconRes: string = '';
  /** 图标徽章色调：blue / green / orange / red */
  @Prop accentTone: string = 'blue';
  /** 入场错峰延迟（ms），默认 0；仅首屏前几张卡片传入 */
  @Prop enterDelay: number = 0;
  /** 卡片内容插槽 */
  @BuilderParam content: () => void;
  /** 入场动效标记：onAppear 后 250ms 淡入上滑 */
  @State private entered: boolean = false;

  build() {
    Column() {
      Row({ space: 8 }) {
        if (this.iconRes.length > 0) {
          // 36×36 软底图标徽章（tone 取 *Soft/语义色）
          IconBadge({ theme: this.theme, iconRes: this.iconRes, tone: this.accentTone, badgeSize: 36 })
        }
        if (this.index.length > 0) {
          Text(this.index)
            .fontSize(12)
            .fontWeight(FontWeight.Regular)
            .fontColor(this.theme.palette.secondaryText)
            .accessibilityLevel('no')
        }
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.palette.ink ?? this.theme.palette.primaryText)
      }
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })
      this.content()
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.theme.palette.cardBackground)
    .radialGradient({
      center: ['80%', '0%'],
      radius: 220,
      colors: this.glow && this.theme.palette.accentGlow !== undefined ?
        SoftGlowUtil.getGlowColors(this.theme.palette.accentGlow ?? '') :
        SoftGlowUtil.transparentColors(this.theme.palette.accentGlow ?? this.theme.palette.cardBackground)
    })
    .shadow({ radius: 10, color: this.theme.palette.cardShadow, offsetX: 0, offsetY: 2 })
    .margin({ bottom: 14 })
    .opacity(this.entered ? 1 : 0)
    .translate({ x: 0, y: this.entered ? 0 : 16 })
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
