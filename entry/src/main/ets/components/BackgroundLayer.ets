/*
 * 文件标注：AI 生成 —— 全局背景层（通用 UI 组件）
 * 约束：必须在页面 Stack 最底层，卡片保持不透明；背景只在卡片间隙露出。
 * 底：绿→橙→红三段对角渐变（色值取自调色板 bgGrad*，深浅两套自动切换）。
 * 上：圆点平铺纹理（极淡 accent 着色）。
 * 装饰层：不参与无障碍朗读，不响应触摸。
 */
import { ThemeManager } from '../theme/ThemeManager';

/** 全局页面背景层：绿橙红三段渐变 + 圆点纹理 */
@Component
export struct BackgroundLayer {
  @ObjectLink theme: ThemeManager;

  build() {
    Stack() {
      // 绿→橙→红 三段对角渐变底（palette.bgGrad*，缺省退回纯色 pageBackground）
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 160,
          colors: [
            [this.theme.palette.bgGradStart ?? this.theme.palette.pageBackground, 0.0],
            [this.theme.palette.bgGradMid ?? this.theme.palette.pageBackground, 0.5],
            [this.theme.palette.bgGradEnd ?? this.theme.palette.pageBackground, 1.0]
          ]
        })
      // 圆点平铺纹理：极淡 accent 着色，铺在卡片间隙的空白处，避免界面单调
      Image($r('app.media.pattern_dot'))
        .width('100%')
        .height('100%')
        .objectRepeat(ImageRepeat.XY)
        .fillColor(this.theme.palette.accent)
        .opacity(0.05)
    }
    .width('100%')
    .height('100%')
    .accessibilityLevel('no')
    .hitTestBehavior(HitTestMode.None)
  }
}
