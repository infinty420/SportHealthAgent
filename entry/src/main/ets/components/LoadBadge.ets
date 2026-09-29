/*
 * 文件标注：AI 生成 —— 负荷状态色标（通用 UI 组件）
 * 约束：组件内禁止硬编码色值，一律读取 theme.palette.*。
 * 视觉升级：克制化——状态点 + 大数值（accent 纯色）+ 状态文案，无任何放射装饰。
 */
import { ThemeManager } from '../theme/ThemeManager';
import { Typography } from '../utils/Typography';

/** 负荷状态徽标：按 超标/正常/偏低 映射到 危险/成功/警告 语义色 */
@Component
export struct LoadBadge {
  @ObjectLink theme: ThemeManager;
  /** 负荷状态文案：超标 / 正常 / 偏低 */
  @Prop status: string = '';
  /** 负荷数值（0–100） */
  @Prop load: number = 0;
  /** 滚动显示的负荷值（-1 = 未滚动） */
  @State private shownLoad: number = -1;

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
      // 大数值（accent 纯色，400ms 数字滚动）+ 状态文案（状态色）
      Text(`${this.shownLoad < 0 ? this.load : this.shownLoad}`)
        .fontSize(Typography.fontSize('numberL'))
        .fontWeight(Typography.fontWeight('numberL'))
        .fontColor(this.theme.palette.accent)
      Text(this.status)
        .fontSize(Typography.fontSize('bodyM'))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.statusColor())
    }
    .alignItems(VerticalAlign.Center)
    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
    .borderRadius(14)
    .backgroundColor(this.theme.palette.inputBackground)
    .accessibilityText(`负荷 ${this.load}，状态${this.status}`)
    .onAppear(() => {
      // 数字滚动：400ms 内 8 帧从 0 滚到目标值
      const target: number = this.load;
      let tick: number = 0;
      const timerId: number = setInterval(() => {
        tick++;
        this.shownLoad = Math.round(target * tick / 8);
        if (tick >= 8) {
          this.shownLoad = target;
          clearInterval(timerId);
        }
      }, 50);
    })
  }
}
