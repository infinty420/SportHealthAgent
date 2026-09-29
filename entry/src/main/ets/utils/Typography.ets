/*
 * 文件标注：AI 生成 —— 字级设计 token（通用 UI 基础设施）
 *
 * 视觉系统 · Typography
 * 集中定义字号与字重档位，页面/组件统一取用，避免魔法数字散落各处。
 * 只含字体规格，不含颜色（颜色一律 theme.palette.*）。
 */

/** 字级档位 */
export type TypeLevel = 'titleL' | 'titleM' | 'bodyL' | 'bodyM' | 'numberXL' | 'numberL';

export class Typography {
  /** 各档位字号（vp） */
  private static readonly SIZES: Record<string, number> = {
    'titleL': 22,
    'titleM': 16,
    'bodyL': 14,
    'bodyM': 13,
    'numberXL': 36,
    'numberL': 24
  };

  /** 字号 */
  static fontSize(level: TypeLevel): number {
    return Typography.SIZES[level];
  }

  /** 字重：标题与数字用 Medium，正文用 Regular */
  static fontWeight(level: TypeLevel): FontWeight {
    if (level === 'titleL' || level === 'titleM' || level === 'numberXL' || level === 'numberL') {
      return FontWeight.Medium;
    }
    return FontWeight.Regular;
  }
}
