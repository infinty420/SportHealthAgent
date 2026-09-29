/*
 * 文件标注：AI 生成 —— 分析报告页脚手架与通用 UI（分析逻辑见 agent/ 目录）
 *
 * 可视化 UI 层 · 分析报告页
 * 「训练」页点击「开始分析 / 模拟数据 / 读取手表」后的跳转目标页：
 * 完整展示模块① 本次训练评估、模块② 饮食方案（带图食物卡片）、模块③ 下一次互补训练规划。
 * 数据经 router 参数（JSON 字符串）传入并本地解析，全程不联网。
 * 主题约束：本文件不出现任何硬编码色值，一律读取 theme.palette.*。
 */
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeToggle } from '../components/ThemeToggle';
import { SectionCard } from '../components/SectionCard';
import { BackgroundLayer } from '../components/BackgroundLayer';
import { LoadBadge } from '../components/LoadBadge';
import { MacroBar } from '../components/MacroBar';
import { AnalysisReport } from '../agent/AnalysisResult';
import { FoodItem, FoodLibrary } from '../data/FoodLibrary';

/** 路由参数（报告 JSON 字符串） */
interface AnalysisResultParams {
  reportJson: string;
}

/** 分析结果 @Builder 按引用传参类型（保持 @State 响应式绑定） */
interface ReportRef {
  report: AnalysisReport;
}

/** 食物卡片行 @Builder 按引用传参类型 */
interface FoodRowSpec {
  title: string;
  foods: string[];
}

@Entry
@Component
struct AnalysisResultPage {
  // 主题中枢（@Observed 单例）：mode 变化触发全量重绘
  @State theme: ThemeManager = ThemeManager.instance;
  @State report: AnalysisReport | null = null;

  aboutToAppear(): void {
    const params: AnalysisResultParams = router.getParams() as AnalysisResultParams;
    if (params !== null && params !== undefined && params.reportJson.length > 0) {
      this.report = JSON.parse(params.reportJson) as AnalysisReport;
    }
  }

  build() {
    // 根布局：背景层（最底）+ 原内容列
    Stack() {
      BackgroundLayer({ theme: this.theme })
      Column() {
      // ===== 顶部栏 =====
      Row() {
        Button('‹ 返回')
          .fontSize(14)
          .fontColor(this.theme.palette.accent)
          .backgroundColor(this.theme.palette.inputBackground)
          .borderRadius(18)
          .height(36)
          .accessibilityText('返回训练页')
          .onClick(() => {
            router.back();
          })
        Text('分析报告')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.primaryText)
          .margin({ left: 12 })
        Blank()
        ThemeToggle({ theme: this.theme })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column() {
          if (this.report !== null) {
            this.resultCards({ report: this.report })
          } else {
            // 异常兜底：未收到报告数据
            Column({ space: 10 }) {
              Text('未收到分析数据')
                .fontSize(15)
                .fontColor(this.theme.palette.primaryText)
              Text('请返回训练页重新点击「开始分析」')
                .fontSize(13)
                .fontColor(this.theme.palette.secondaryText)
            }
            .width('100%')
            .padding(24)
            .margin({ top: 40 })
          }
        }
        .padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  /** 分析结果卡片组：模块①评估 + 模块②饮食 + 模块③互补规划 */
  @Builder
  private resultCards($$: ReportRef): void {
    // 模块① 本次训练评估
    SectionCard({ theme: this.theme, title: '模块① 本次训练评估', iconRes: 'app.media.ic_training', accentTone: 'blue' }) {
      LoadBadge({
        theme: this.theme,
        status: $$.report.assessment.loadStatus,
        load: $$.report.assessment.load
      })
      Row({ space: 8 }) {
        Text('恢复状态')
          .fontSize(14)
          .fontColor(this.theme.palette.secondaryText)
        Text($$.report.assessment.recoveryStatus)
          .fontSize(14)
          .fontColor(this.theme.palette.primaryText)
      }
      .margin({ top: 12 })
      Row({ space: 8 }) {
        Text('建议恢复时长')
          .fontSize(14)
          .fontColor(this.theme.palette.secondaryText)
        Text(`${$$.report.assessment.suggestedRecoveryHours} 小时`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.palette.accent)
      }
      .margin({ top: 6 })
      Row({ space: 8 }) {
        Text('疲劳指数')
          .fontSize(14)
          .fontColor(this.theme.palette.secondaryText)
        Text(`${$$.report.fatigueIndex} / 100`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.palette.warning)
      }
      .margin({ top: 6 })
      Text($$.report.assessment.advice)
        .fontSize(14)
        .fontColor(this.theme.palette.primaryText)
        .lineHeight(21)
        .margin({ top: 10 })
    }

    // 模块② 饮食方案（Keep 风格：宏量占比条 + 带图食物卡片）
    SectionCard({ theme: this.theme, title: '模块② 饮食方案', iconRes: 'app.media.ic_diet', accentTone: 'orange' }) {
      Text(`建议补充热量 ${$$.report.diet.totalCalories} 千卡`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.theme.palette.primaryText)
        .margin({ bottom: 12 })
      MacroBar({
        theme: this.theme, label: '蛋白质',
        pct: $$.report.diet.proteinPct, grams: $$.report.diet.proteinGrams,
        barColor: this.theme.palette.protein
      })
      MacroBar({
        theme: this.theme, label: '碳水化合物',
        pct: $$.report.diet.carbPct, grams: $$.report.diet.carbGrams,
        barColor: this.theme.palette.carb
      })
      MacroBar({
        theme: this.theme, label: '脂肪',
        pct: $$.report.diet.fatPct, grams: $$.report.diet.fatGrams,
        barColor: this.theme.palette.fat
      })
      this.foodRow({ title: '蛋白食材', foods: $$.report.diet.proteinFoods })
      this.foodRow({ title: '碳水食材', foods: $$.report.diet.carbFoods })
      this.foodRow({ title: '脂肪食材', foods: $$.report.diet.fatFoods })
      if ($$.report.diet.note.length > 0) {
        Text($$.report.diet.note)
          .fontSize(13)
          .fontColor(this.theme.palette.warning)
          .margin({ top: 8 })
      }
      // 免责声明（合规要求，必须展示）
      Text($$.report.diet.disclaimer)
        .fontSize(12)
        .fontColor(this.theme.palette.secondaryText)
        .margin({ top: 10 })
    }

    // 模块③ 下一次互补训练规划
    SectionCard({ theme: this.theme, title: '模块③ 下一次互补训练规划', iconRes: 'app.media.ic_plan', accentTone: 'green' }) {
      Text($$.report.nextWorkout.workoutType)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme.palette.accent)
      Row({ space: 16 }) {
        Text(`强度：${$$.report.nextWorkout.intensity}`)
          .fontSize(14)
          .fontColor(this.theme.palette.primaryText)
        Text(`时长：${$$.report.nextWorkout.durationMin} 分钟`)
          .fontSize(14)
          .fontColor(this.theme.palette.primaryText)
      }
      .margin({ top: 8 })
      Text(`互补理由：${$$.report.nextWorkout.reason}`)
        .fontSize(14)
        .fontColor(this.theme.palette.secondaryText)
        .lineHeight(21)
        .margin({ top: 8 })
    }

    Text(`报告生成于 ${$$.report.generatedAt} · 全部计算在本地完成`)
      .fontSize(12)
      .fontColor(this.theme.palette.secondaryText)
      .margin({ bottom: 24 })
  }

  /** 一组食物卡片（Keep 风格：横向滑动，图片 + 名称 + 每 100g 热量） */
  @Builder
  private foodRow($$: FoodRowSpec): void {
    Text($$.title)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.theme.palette.secondaryText)
      .margin({ top: 8, bottom: 6 })
    Scroll() {
      Row({ space: 8 }) {
        ForEach($$.foods, (name: string) => {
          this.foodCard(name)
        }, (name: string) => name)
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  /** 单个食物卡片（名称来自食物库，查找逻辑在辅助方法中，builder 内保持声明式） */
  @Builder
  private foodCard(name: string): void {
    Column({ space: 4 }) {
      Image($r(this.foodImage(name)))
        .width(56)
        .height(56)
        .borderRadius(10)
      Text(name)
        .fontSize(12)
        .fontColor(this.theme.palette.primaryText)
        .maxLines(1)
      Text(this.foodKcalText(name))
        .fontSize(10)
        .fontColor(this.theme.palette.secondaryText)
        .maxLines(1)
    }
    .padding(8)
    .borderRadius(12)
    .backgroundColor(this.theme.palette.inputBackground)
  }

  /** 食物图片资源名（未收录或暂无图片时回退到应用图标） */
  private foodImage(name: string): string {
    const food: FoodItem | null = FoodLibrary.findByName(name);
    if (food === null || food.imageRes.length === 0) {
      return 'app.media.app_icon';
    }
    return food.imageRes;
  }

  /** 食物热量文案（未收录时仅显示名称） */
  private foodKcalText(name: string): string {
    const food: FoodItem | null = FoodLibrary.findByName(name);
    if (food === null) {
      return '';
    }
    return `${food.kcalPer100g} kcal/100g`;
  }
}
