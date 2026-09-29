/*
 * 文件标注：AI 生成 —— 骨架屏卡片（通用 UI 组件）
 * 约束：组件内禁止硬编码色值，一律读取 theme.palette.*。
 * 灰色块 + 1.5s 呼吸渐变（opacity 0.3↔0.6 往返循环），用于加载/计算中的占位。
 */
import { ThemeManager } from '../theme/ThemeManager';

/** 骨架屏卡片：标题条 + 两行内容条的呼吸占位 */
@Component
export struct SkeletonCard {
  @ObjectLink theme: ThemeManager;
  /** 呼吸透明度（0.3↔0.6 往返） */
  @State private breath: number = 0.3;

  build() {
    Column({ space: 10 }) {
      Row()
        .width('40%')
        .height(14)
        .borderRadius(7)
        .backgroundColor(this.theme.palette.track)
      Row()
        .width('100%')
        .height(12)
        .borderRadius(6)
        .backgroundColor(this.theme.palette.track)
      Row()
        .width('72%')
        .height(12)
        .borderRadius(6)
        .backgroundColor(this.theme.palette.track)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.theme.palette.cardBackground)
    .opacity(this.breath)
    .accessibilityLevel('no')
    .onAppear(() => {
      // 呼吸循环：1.5s 内 0.3→0.6，Alternate 往返无限次
      animateTo({ duration: 1500, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate }, () => {
        this.breath = 0.6;
      });
    })
  }
}
