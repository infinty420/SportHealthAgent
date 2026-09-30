/*
 * 文件标注：AI 生成 —— 食物选择页脚手架与通用 UI（数据来自 data/FoodLibrary.ets）
 *
 * 可视化 UI 层 · 食物选择页
 * 支持按分类/名称筛选，选中后填写份量与餐次，写入今日饮食日志（DietLog）。
 * 主题约束：本文件不出现任何硬编码色值，一律读取 theme.palette.*。
 * 文案约束：页面级文案走 string.json 资源（中英双语）。
 */
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { ThemeManager } from '../theme/ThemeManager';
import { FoodItem, FoodLibrary, FOOD_CATEGORIES } from '../data/FoodLibrary';
import { DietLog, DietLogEntry, MEAL_TYPES } from '../data/DietLog';
import { ThemeToggle } from '../components/ThemeToggle';
import { BackgroundLayer } from '../components/BackgroundLayer';

/** 底部操作面板参数（@Builder 按引用传参：按值传参不触发 UI 刷新，选中食物后面板不弹出） */
interface FoodPanelRef {
  /** 是否已选中食物（true 时面板显示） */
  hasFood: boolean;
  /** 选中食物名（无障碍朗读用；未选中为空串） */
  foodName: string;
}

@Entry
@Component
struct FoodPickerPage {
  @State theme: ThemeManager = ThemeManager.instance;
  @State selectedCategory: string = '全部';
  @State keyword: string = '';
  @State shownList: FoodItem[] = FoodLibrary.all();
  @State selectedFood: FoodItem | null = null;
  @State gramsText: string = '100';
  @State meal: string = MEAL_TYPES[0];

  private readonly categories: string[] = ['全部'].concat(FOOD_CATEGORIES);
  private dietLog: DietLog | null = null;

  aboutToAppear(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.dietLog = new DietLog(context);
  }

  private applyFilter(): void {
    const byCategory: FoodItem[] = FoodLibrary.byCategory(this.selectedCategory);
    const key: string = this.keyword.trim();
    if (key.length === 0) {
      this.shownList = byCategory;
    } else {
      this.shownList = byCategory.filter((item: FoodItem) => item.name.indexOf(key) >= 0);
    }
  }

  private foodImage(food: FoodItem): string {
    if (food.imageRes.length > 0) {
      return food.imageRes;
    }
    return 'app.media.app_icon';
  }

  private isSelected(item: FoodItem): boolean {
    const sel: FoodItem | null = this.selectedFood;
    return sel !== null && sel.name === item.name;
  }

  private addToLog(): void {
    const food: FoodItem | null = this.selectedFood;
    const log: DietLog | null = this.dietLog;
    if (food === null || log === null) {
      return;
    }
    const grams: number = Number(this.gramsText);
    if (Number.isNaN(grams) || grams <= 0 || grams > 2000) {
      promptAction.showToast({ message: '份量需在 1–2000 克之间' });
      return;
    }
    const entry: DietLogEntry = {
      timestamp: Date.now(),
      meal: this.meal,
      foodName: food.name,
      grams: grams
    };
    log.logMeal(entry);
    promptAction.showToast({ message: $r('app.string.food_picker_added') });
    router.back();
  }

  build() {
    // 根布局：背景层（最底，固定不滚动）+ 原内容列
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
          .accessibilityText('返回上一页')
          .onClick(() => {
            router.back();
          })
        Text($r('app.string.food_picker_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.primaryText)
          .margin({ left: 12 })
        Blank()
        ThemeToggle({ theme: this.theme })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // ===== 搜索框（左侧 ic_search 线性图标） =====
      Row({ space: 8 }) {
        Image($r('app.media.ic_search'))
          .width(18)
          .height(18)
          .fillColor(this.theme.palette.secondaryText)
          .margin({ left: 12 })
          .accessibilityLevel('no')
        TextInput({ placeholder: $r('app.string.food_picker_search'), text: this.keyword })
          .fontColor(this.theme.palette.primaryText)
          .placeholderColor(this.theme.palette.secondaryText)
          .backgroundColor(this.theme.palette.inputBackground)
          .caretColor(this.theme.palette.accent)
          .layoutWeight(1)
          .onChange((v: string) => {
            this.keyword = v;
            this.applyFilter();
          })
      }
      .width('100%')
      .borderRadius(10)
      .backgroundColor(this.theme.palette.inputBackground)
      .padding({ left: 4, right: 12 })
      .margin({ left: 16, right: 16, bottom: 10 })

      // ===== 分类筛选条 =====
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.categories, (category: string) => {
            Text(category)
              .fontSize(13)
              .fontColor(this.selectedCategory === category ?
                this.theme.palette.onAccent : this.theme.palette.primaryText)
              .padding({ left: 14, right: 14, top: 7, bottom: 7 })
              .borderRadius(16)
              .backgroundColor(this.selectedCategory === category ?
                this.theme.palette.accent : this.theme.palette.inputBackground)
              .onClick(() => {
                this.selectedCategory = category;
                this.applyFilter();
              })
          }, (category: string) => category)
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .margin({ bottom: 8 })

      // ===== 食物网格（双列） =====
      Grid() {
        ForEach(this.shownList, (item: FoodItem) => {
          GridItem() {
            Column({ space: 6 }) {
              Image($r(this.foodImage(item)))
                .width('100%')
                .aspectRatio(1)
                .borderRadius(16)
              Text(item.name)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.theme.palette.primaryText)
              Text(`${item.kcalPer100g} kcal/100g`)
                .fontSize(11)
                .fontColor(this.theme.palette.secondaryText)
                .maxLines(1)
              Row({ space: 4 }) {
                Text(`蛋${item.proteinPer100g}`)
                  .fontSize(9)
                  .fontColor(this.theme.palette.protein)
                  .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                  .borderRadius(8)
                  .backgroundColor(this.theme.palette.proteinSoft ?? this.theme.palette.inputBackground)
                Text(`碳${item.carbPer100g}`)
                  .fontSize(9)
                  .fontColor(this.theme.palette.carb)
                  .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                  .borderRadius(8)
                  .backgroundColor(this.theme.palette.carbSoft ?? this.theme.palette.inputBackground)
                Text(`脂${item.fatPer100g}`)
                  .fontSize(9)
                  .fontColor(this.theme.palette.fat)
                  .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                  .borderRadius(8)
                  .backgroundColor(this.theme.palette.fatSoft ?? this.theme.palette.inputBackground)
              }
              .accessibilityLevel('no')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(8)
            .borderRadius(20)
            .backgroundColor(this.isSelected(item) ?
              this.theme.palette.inputBackground : this.theme.palette.cardBackground)
            .shadow({ radius: 10, color: this.theme.palette.cardShadow, offsetX: 0, offsetY: 2 })
            .borderWidth(this.isSelected(item) ? 2 : 0)
            .borderColor(this.theme.palette.accent)
            .accessibilityText(`${item.name}，每 100 克 ${item.kcalPer100g} 千卡`)
            .onClick(() => {
              this.selectedFood = item;
            })
          }
        }, (item: FoodItem) => item.name)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .padding({ left: 16, right: 16, bottom: 12 })
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // ===== 底部：份量 + 餐次 + 添加 =====
      this.bottomPanel({
        hasFood: this.selectedFood !== null,
        foodName: this.selectedFood === null ? '' : this.selectedFood.name
      })
    }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  /** 底部操作面板（$$ 按引用传参，保证选中食物后面板即时弹出） */
  @Builder
  private bottomPanel($$: FoodPanelRef): void {
    if ($$.hasFood) {
      Column({ space: 10 }) {
        Row({ space: 10 }) {
          Text($r('app.string.food_picker_meal'))
            .fontSize(13)
            .fontColor(this.theme.palette.secondaryText)
          Select(this.buildMealOptions())
            .value(this.meal)
            .fontColor(this.theme.palette.primaryText)
            .backgroundColor(this.theme.palette.inputBackground)
            .layoutWeight(1)
            .onSelect((index: number) => {
              this.meal = MEAL_TYPES[index];
            })
        }
        .width('100%')
        Row({ space: 10 }) {
          Text($r('app.string.food_picker_grams'))
            .fontSize(13)
            .fontColor(this.theme.palette.secondaryText)
          TextInput({ text: this.gramsText })
            .type(InputType.Number)
            .fontColor(this.theme.palette.primaryText)
            .backgroundColor(this.theme.palette.inputBackground)
            .caretColor(this.theme.palette.accent)
            .borderRadius(10)
            .layoutWeight(1)
            .onChange((v: string) => {
              this.gramsText = v;
            })
        }
        .width('100%')
        Button($r('app.string.food_picker_add'))
          .fontColor(this.theme.palette.onAccent)
          .backgroundColor(this.theme.palette.accent)
          .borderRadius(20)
          .width('100%')
          .accessibilityDescription(`将 ${$$.foodName} 加入今日饮食记录`)
          .onClick(() => {
            this.addToLog();
          })
      }
      .padding({ left: 16, right: 16, bottom: 16 })
      .backgroundColor(this.theme.palette.cardBackground)
    }
  }

  private buildMealOptions(): SelectOption[] {
    return MEAL_TYPES.map((t: string): SelectOption => {
      return { value: t };
    });
  }
}
