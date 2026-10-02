/*
 * 文件标注：AI 生成 —— 全局背景层（通用 UI 组件）
 * 约束：必须在页面 Stack 最底层，卡片保持不透明；背景只在卡片间隙露出。
 * 深浅两套本地图片（resources/base/media/bg_page_*.png），主题切换 200ms 交叉淡入淡出。
 * 装饰层：不参与无障碍朗读，不响应触摸。
 */
import { ThemeManager } from '../theme/ThemeManager';

/** 全局页面背景层：极淡光晕底图，主题切换交叉淡化 */
@Component
export struct BackgroundLayer {
  @ObjectLink theme: ThemeManager;

  build() {
    Stack() {
      Image($r('app.media.bg_page_dark'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(this.theme.mode === 'dark' ? 1 : 0)
        .animation({ duration: 200, curve: Curve.EaseOut })
      Image($r('app.media.bg_page_light'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(this.theme.mode === 'light' ? 1 : 0)
        .animation({ duration: 200, curve: Curve.EaseOut })
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
