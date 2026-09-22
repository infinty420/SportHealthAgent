/*
 * 文件标注：AI 生成 —— 主题中枢（通用 UI 基础设施）
 *
 * 主题中枢 · ThemeManager
 * 防深色模式失效的硬性契约（后续修改代码时不得改动本契约）：
 *   1. 全应用颜色唯一定义在 lightPalette 与 darkPalette 两处；
 *   2. 组件禁止任何硬编码色值（不得出现 '#xxxxxx'），只能读取 theme.palette.*；
 *   3. 切换主题只改 mode，由 @Observed 触发全量重绘。
 */

/** 调色板：所有组件可使用的颜色集合（语义化命名） */
export interface Palette {
  /** 页面背景 */
  pageBackground: string;
  /** 卡片背景 */
  cardBackground: string;
  /** 输入框背景 */
  inputBackground: string;
  /** 主文本 */
  primaryText: string;
  /** 次要文本 */
  secondaryText: string;
  /** 主题强调色（按钮、高亮） */
  accent: string;
  /** 强调色上的文本 */
  onAccent: string;
  /** 成功/正常（负荷正常色标） */
  success: string;
  /** 警告/偏低（负荷偏低色标） */
  warning: string;
  /** 危险/超标（负荷超标色标） */
  danger: string;
  /** 分割线、进度条轨道 */
  track: string;
  /** 宏量营养素：蛋白质 */
  protein: string;
  /** 宏量营养素：碳水 */
  carb: string;
  /** 宏量营养素：脂肪 */
  fat: string;
  /** 强调色浅底（选中胶囊、标签底色） */
  accentSoft: string;
  /** 首页横幅渐变起始色 */
  heroStart: string;
  /** 首页横幅渐变结束色 */
  heroEnd: string;
  /** 横幅上的文字颜色（两种主题下均为浅色） */
  onHero: string;
  /** 卡片柔和投影色 */
  cardShadow: string;
}

export type ThemeMode = 'light' | 'dark';

@Observed
export class ThemeManager {
  /** 当前主题模式：切换主题只需修改本字段 */
  mode: ThemeMode = 'light';

  /** 全局单例 */
  private static _instance: ThemeManager | null = null;

  static get instance(): ThemeManager {
    if (ThemeManager._instance === null) {
      ThemeManager._instance = new ThemeManager();
    }
    return ThemeManager._instance;
  }

  /** 浅色调色板（全应用浅色颜色唯一定义处） */
  private readonly lightPalette: Palette = {
    pageBackground: '#F5F7FA',
    cardBackground: '#FFFFFF',
    inputBackground: '#EEF1F5',
    primaryText: '#1A1C1E',
    secondaryText: '#6B7280',
    accent: '#2F6BFF',
    onAccent: '#FFFFFF',
    success: '#22A06B',
    warning: '#E8A13A',
    danger: '#E5484D',
    track: '#E3E7EC',
    protein: '#E5484D',
    carb: '#2F6BFF',
    fat: '#E8A13A',
    accentSoft: '#E4ECFF',
    heroStart: '#3D74FF',
    heroEnd: '#7BA6FF',
    onHero: '#FFFFFF',
    cardShadow: '#14000000'
  };

  /** 深色调色板（全应用深色颜色唯一定义处） */
  private readonly darkPalette: Palette = {
    pageBackground: '#101214',
    cardBackground: '#1B1E22',
    inputBackground: '#262A2F',
    primaryText: '#F2F4F6',
    secondaryText: '#9AA1A9',
    accent: '#6E9BFF',
    onAccent: '#0E1116',
    success: '#3ECF92',
    warning: '#F2B75C',
    danger: '#FF6B70',
    track: '#33383E',
    protein: '#FF6B70',
    carb: '#6E9BFF',
    fat: '#F2B75C',
    accentSoft: '#24344F',
    heroStart: '#1F3A6E',
    heroEnd: '#2E4E8F',
    onHero: '#FFFFFF',
    cardShadow: '#66000000'
  };

  /** 当前生效的调色板：组件一律通过 theme.palette.* 取色 */
  get palette(): Palette {
    return this.mode === 'light' ? this.lightPalette : this.darkPalette;
  }

  /** 切换深色/浅色 */
  toggle(): void {
    this.mode = this.mode === 'light' ? 'dark' : 'light';
  }

  isDark(): boolean {
    return this.mode === 'dark';
  }
}
