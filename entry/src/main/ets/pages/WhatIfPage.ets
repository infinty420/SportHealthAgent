/*
 * 文件标注：AI 生成 —— What-if 情景模拟页面（通用 UI 脚手架）
 *
 * 可视化 UI 层 · What-if 模拟器
 * 三个滑块（每周训练次数 / 每日热量偏移 / 目标体重）实时驱动 WhatIfSimulator
 * 推算 4 周与 8 周后的体重与累计负荷；Canvas 折线对比「当前基线 vs 模拟值」。
 * 全部计算本地完成，无网络请求、无模型推理。
 */
import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ThemeManager } from '../theme/ThemeManager';
import { SectionCard } from '../components/SectionCard';
import { UserProfileStore } from '../data/UserProfileStore';
import { HistoryStore, HistoryEntry } from '../data/HistoryStore';
import { WhatIfSimulator, WhatIfResult } from '../agent/rules/WhatIfSimulator';
import { HeatColorUtil } from '../utils/HeatColorUtil';

@Entry
@Component
struct WhatIfPage {
  @State theme: ThemeManager = ThemeManager.instance;

  // 滑块状态：每周训练次数 / 每日热量偏移 / 目标体重
  @State sessions: number = 3;
  @State calorieOffset: number = 0;
  @State targetWeight: number = 65;

  // 基线数据（画像体重 + 历史单次平均负荷）
  @State currentWeight: number = 65;
  @State avgSessionLoad: number = 50;

  private chartCtx: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true));

  aboutToAppear(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const profileStore: UserProfileStore = new UserProfileStore(context);
    const profile = profileStore.load();
    if (profile.weightKg >= 40 && profile.weightKg <= 120) {
      this.currentWeight = profile.weightKg;
      this.targetWeight = profile.weightKg;
    }
    const historyStore: HistoryStore = new HistoryStore(context);
    const entries: HistoryEntry[] = historyStore.list().slice(0, 30);
    if (entries.length > 0) {
      let total: number = 0;
      entries.forEach((entry: HistoryEntry) => {
        total += entry.load;
      });
      this.avgSessionLoad = Math.round(total / entries.length);
    }
  }

  /** 当前滑块组合下的模拟结果（UI 文本与 Canvas 共用同一计算入口） */
  private simResult(): WhatIfResult {
    return WhatIfSimulator.simulate(this.currentWeight, this.sessions,
      this.avgSessionLoad, this.calorieOffset);
  }

  /** 距目标体重的预计周数（按当前热量偏移线性推算；无法达成返回 -1） */
  private weeksToGoal(): number {
    const gap: number = this.targetWeight - this.currentWeight;
    if (Math.abs(gap) < 0.05) {
      return 0;
    }
    const dailyKg: number = this.calorieOffset / 7700;
    if (dailyKg === 0 || (gap > 0) !== (dailyKg > 0)) {
      return -1;
    }
    return Math.ceil(Math.abs(gap / dailyKg) / 7);
  }

  /** 体重趋势折线：基线（轨道色水平线）vs 模拟值（强调色斜线），横轴 0–8 周 */
  private drawChart(): void {
    const ctx: CanvasRenderingContext2D = this.chartCtx;
    ctx.clearRect(0, 0, 320, 180);
    const result: WhatIfResult = this.simResult();
    const w: number = 280;
    const h: number = 120;
    const left: number = 20;
    const top: number = 16;
    // 纵轴范围：覆盖当前体重 / 8 周模拟值 / 目标体重，上下各留 2kg
    let minW: number = Math.min(this.currentWeight, result.weight8WeekKg, this.targetWeight) - 2;
    let maxW: number = Math.max(this.currentWeight, result.weight8WeekKg, this.targetWeight) + 2;
    if (maxW - minW < 4) {
      maxW = minW + 4;
    }
    const yOf = (kg: number): number => top + h - (kg - minW) / (maxW - minW) * h;
    const xOf = (week: number): number => left + week / 8 * w;
    // 网格与周刻度（4 周 / 8 周）
    ctx.strokeStyle = this.theme.palette.track;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(left, top);
    ctx.lineTo(left, top + h);
    ctx.lineTo(left + w, top + h);
    ctx.stroke();
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillStyle = this.theme.palette.secondaryText;
    for (let week: number = 0; week <= 8; week += 4) {
      ctx.fillText(`${week} 周`, xOf(week), top + h + 14);
    }
    // 基线：体重维持当前值（轨道色）
    ctx.strokeStyle = this.theme.palette.track;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(xOf(0), yOf(this.currentWeight));
    ctx.lineTo(xOf(8), yOf(this.currentWeight));
    ctx.stroke();
    // 目标体重参考线（成功色细线 + 标签）
    ctx.strokeStyle = HeatColorUtil.alphaColor(this.theme.palette.success, 0.6);
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(xOf(0), yOf(this.targetWeight));
    ctx.lineTo(xOf(8), yOf(this.targetWeight));
    ctx.stroke();
    ctx.textAlign = 'right';
    ctx.fillStyle = this.theme.palette.success;
    ctx.fillText(`目标 ${this.targetWeight}kg`, left + w - 4, yOf(this.targetWeight) - 4);
    // 模拟曲线：当前 → 8 周预测（强调色）
    ctx.strokeStyle = this.theme.palette.accent;
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.moveTo(xOf(0), yOf(this.currentWeight));
    ctx.lineTo(xOf(4), yOf(result.weight4WeekKg));
    ctx.lineTo(xOf(8), yOf(result.weight8WeekKg));
    ctx.stroke();
    // 端点数值标签
    ctx.fillStyle = this.theme.palette.accent;
    ctx.fillText(`${result.weight8WeekKg}kg`, left + w - 4, yOf(result.weight8WeekKg) - 6);
    ctx.textAlign = 'left';
    ctx.fillStyle = this.theme.palette.secondaryText;
    ctx.fillText(`— 模拟  — 基线`, left + 4, top + 2);
  }

  build() {
    Column() {
      // 顶部栏：返回 + 标题
      Row() {
        Button('← 返回')
          .fontSize(14)
          .fontColor(this.theme.palette.accent)
          .backgroundColor(this.theme.palette.inputBackground)
          .borderRadius(18)
          .height(36)
          .accessibilityText('返回上一页')
          .onClick(() => {
            router.back();
          })
        Blank()
        Text('What-if 情景模拟')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.primaryText)
        Blank()
        Row()
          .width(64)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          // 假设条件滑块
          SectionCard({ theme: this.theme, title: '假设条件' }) {
            Text(`每周训练次数：${this.sessions} 次`)
              .fontSize(13)
              .fontColor(this.theme.palette.primaryText)
            Slider({ value: this.sessions, min: 1, max: 7, step: 1 })
              .selectedColor(this.theme.palette.accent)
              .accessibilityText('调整每周训练次数')
              .onChange((v: number) => {
                this.sessions = Math.round(v);
                this.drawChart();
              })
            Text(`每日热量偏移：${this.calorieOffset > 0 ? '+' : ''}${this.calorieOffset} kcal`)
              .fontSize(13)
              .fontColor(this.theme.palette.primaryText)
              .margin({ top: 8 })
            Slider({ value: this.calorieOffset, min: -500, max: 500, step: 50 })
              .selectedColor(this.theme.palette.accent)
              .accessibilityText('调整每日热量偏移')
              .onChange((v: number) => {
                this.calorieOffset = Math.round(v);
                this.drawChart();
              })
            Text(`目标体重：${this.targetWeight} kg（当前 ${this.currentWeight} kg）`)
              .fontSize(13)
              .fontColor(this.theme.palette.primaryText)
              .margin({ top: 8 })
            Slider({ value: this.targetWeight, min: 40, max: 120, step: 1 })
              .selectedColor(this.theme.palette.accent)
              .accessibilityText('调整目标体重')
              .onChange((v: number) => {
                this.targetWeight = Math.round(v);
                this.drawChart();
              })
          }

          // 体重趋势对比图
          SectionCard({ theme: this.theme, title: '体重趋势：基线 vs 模拟' }) {
            Canvas(this.chartCtx)
              .width('100%')
              .height(180)
              .accessibilityText('体重趋势模拟折线图')
              .onReady(() => {
                this.drawChart();
              })
          }

          // 结论
          SectionCard({ theme: this.theme, title: '模拟结论' }) {
            Text(this.simResult().note)
              .fontSize(13)
              .fontColor(this.theme.palette.primaryText)
              .lineHeight(19)
            Text(`4 周累计负荷约 ${this.simResult().load4Week} 点 · 8 周约 ${this.simResult().load8Week} 点` +
              `（单次平均负荷 ${this.avgSessionLoad}）`)
              .fontSize(13)
              .fontColor(this.theme.palette.secondaryText)
              .lineHeight(19)
              .margin({ top: 6 })
            Text(this.weeksToGoal() < 0 ?
              '当前热量偏移方向与目标体重相反，调整后这里给出预计达成时间' :
              (this.weeksToGoal() === 0 ? '已处于目标体重' :
                `按当前热量偏移，预计约 ${this.weeksToGoal()} 周后达到目标体重`))
              .fontSize(13)
              .fontColor(this.theme.palette.accent)
              .lineHeight(19)
              .margin({ top: 6 })
            Text('以上为确定性公式估算（7700 kcal ≈ 1kg），仅供参考，非医疗建议')
              .fontSize(11)
              .fontColor(this.theme.palette.secondaryText)
              .margin({ top: 10 })
          }

          Button('把模拟次数写入本周目标')
            .fontSize(14)
            .fontColor(this.theme.palette.onAccent)
            .backgroundColor(this.theme.palette.accent)
            .borderRadius(20)
            .width('100%')
            .height(40)
            .accessibilityText('将模拟的每周训练次数写入本周目标')
            .onClick(() => {
              promptAction.showToast({ message: '请在首页「本周目标」卡中调整周次数目标' });
            })
        }
        .padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }
}
