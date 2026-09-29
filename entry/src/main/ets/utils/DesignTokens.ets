/*
 * 文件标注：AI 生成 —— 设计令牌（通用 UI 基础设施）
 *
 * 视觉系统 · DesignTokens
 * 圆角 / 间距 / 阴影 / 动效的统一取值阶梯。数值全量对齐现有组件散落值
 * （卡片 20、输入框与胶囊 12、图片 16、详情大图 24、日历格 8、页面边距 16、
 * 网格间隙 10、卡片阴影 radius 10 offsetY 2），只收敛常量、不改变任何现有视觉数值。
 * 色值不入令牌：阴影色等由调用方读取 theme.palette.cardShadow。
 */

/** 设计令牌（静态常量集合） */
export class DesignTokens {
  // ===== 圆角阶梯 =====
  /** 小元素（日历格、小标签） */
  static readonly radiusSm: number = 8;
  /** 输入框、筛选胶囊、芯片 */
  static readonly radiusMd: number = 12;
  /** 卡片内图片、横幅条 */
  static readonly radiusLg: number = 16;
  /** 卡片、主按钮 */
  static readonly radiusXl: number = 20;
  /** 详情页大图 */
  static readonly radius24: number = 24;

  // ===== 间距阶梯 =====
  static readonly space4: number = 4;
  static readonly space8: number = 8;
  static readonly space10: number = 10;
  static readonly space12: number = 12;
  static readonly space16: number = 16;
  static readonly space20: number = 20;
  static readonly space24: number = 24;

  // ===== 阴影阶梯（颜色由调用方取 palette.cardShadow） =====
  /** 轻量悬浮（小徽章、胶囊） */
  static readonly shadowSmRadius: number = 6;
  static readonly shadowSmOffsetY: number = 1;
  /** 标准卡片（与现有 SectionCard 一致） */
  static readonly shadowMdRadius: number = 10;
  static readonly shadowMdOffsetY: number = 2;
  /** 强调浮层 */
  static readonly shadowLgRadius: number = 14;
  static readonly shadowLgOffsetY: number = 4;

  // ===== 动效（全站一种语言：200/250ms + EaseOut） =====
  static readonly durationFast: number = 200;
  static readonly durationNormal: number = 250;
  /** 首屏卡片入场错峰间隔 */
  static readonly staggerMs: number = 40;
  /** 按压缩放值 */
  static readonly pressScale: number = 0.97;
  /** 统一缓动曲线名（供 animateTo/animation 的 curve 参数注释对齐用） */
  static readonly easing: Curve = Curve.EaseOut;
}
