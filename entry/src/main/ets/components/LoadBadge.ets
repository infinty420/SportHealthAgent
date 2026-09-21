/*
 * 文件标注：AI 生成 —— 负荷状态色标（通用 UI 组件）
 * 约束：组件内禁止硬编码色值，一律读取 theme.palette.*。
 */
import { ThemeManager } from '../theme/ThemeManager';

/** 负荷状态徽标：按 超标/正常/偏低 映射到 危险/成功/警告 语义色 */
@Component
export struct LoadBadge {
  @ObjectLink theme: ThemeManager;
  /** 负荷状态文案：超标 / 正常 / 偏低 */
  @Prop status: string = '';
  /** 负荷数值（0–100） */
  @Prop load: number = 0;

  /** 状态 → 语义色映射（色值来自调色板，非硬编码） */
  private statusColor(): string {
    if (this.status === '超标') {
      return this.theme.palette.danger;
    }
    if (this.status === '正常') {
      return this.theme.palette.success;
    }
    return this.theme.palette.warning;
  }

  build() {
    Row({ space: 8 }) {
      // 状态色点
      Circle({ width: 10, height: 10 })
        .fill(this.statusColor())
      Text(`负荷 ${this.load} · ${this.status}`)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.statusColor())
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(14)
    .backgroundColor(this.theme.palette.inputBackground)
  }
}
