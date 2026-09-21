/*
 * 文件标注：AI 生成 —— 训练日志录入页（通用 UI 脚手架）
 *
 * 可视化 UI 层 · 训练日志录入
 * 动作选择器复用 ExerciseLibrary 数据（器械/部位双维筛选 + 双列网格），
 * 选中后进入组数表格录入（次数 / 重量 / RPE），并展示该动作的渐进超负荷建议。
 * 校验通过后经 WorkoutLogStore 持久化（preferences，纯本地）。
 * 主题约束：本文件不出现任何硬编码色值，一律读取 theme.palette.*。
 */
import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeToggle } from '../components/ThemeToggle';
import { SectionCard } from '../components/SectionCard';
import {
  ExerciseItem, ExerciseLibrary, EXERCISE_EQUIPMENTS, EXERCISE_MUSCLES
} from '../data/ExerciseLibrary';
import { WorkoutLog, WorkoutSet, RPE_MIN, RPE_MAX } from '../model/WorkoutLog';
import { WorkoutLogStore } from '../data/WorkoutLogStore';
import { ProgressiveOverloadPlanner, OverloadSuggestion } from '../agent/rules/ProgressiveOverloadPlanner';
import { PRTracker, PRCheck } from '../agent/rules/PRTracker';

/** 可编辑的组行（@Observed 供增删组时刷新） */
@Observed
class SetRow {
  repsText: string = '10';
  weightText: string = '20';
  rpe: string = '8';
  /** RIR 选项：'-' 表示未填（此时以 RPE 为准） */
  rir: string = '-';
}

@Entry
@Component
struct WorkoutLogPage {
  @State theme: ThemeManager = ThemeManager.instance;
  private store: WorkoutLogStore | null = null;

  @State private selectedEquipment: string = '全部';
  @State private selectedMuscle: string = '全部';
  @State private shownList: ExerciseItem[] = ExerciseLibrary.all();
  @State private selected: ExerciseItem | null = null;
  @State private setRows: SetRow[] = [new SetRow(), new SetRow(), new SetRow()];
  @State private suggestion: OverloadSuggestion | null = null;
  private readonly equipments: string[] = ['全部'].concat(EXERCISE_EQUIPMENTS);
  private readonly muscles: string[] = ['全部'].concat(EXERCISE_MUSCLES);
  private readonly rpeOptions: string[] = WorkoutLogPage.buildRpeOptions();
  private readonly rirOptions: string[] = ['-', '0', '1', '2', '3', '4', '5'];

  private static buildRpeOptions(): string[] {
    const options: string[] = [];
    for (let rpe: number = RPE_MIN; rpe <= RPE_MAX; rpe++) {
      options.push(`${rpe}`);
    }
    return options;
  }

  aboutToAppear(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.store = new WorkoutLogStore(context);
  }

  private applyFilter(): void {
    this.shownList = ExerciseLibrary.filter(this.selectedEquipment, this.selectedMuscle);
  }

  private selectExercise(item: ExerciseItem): void {
    this.selected = item;
    if (this.store !== null) {
      const history: WorkoutLog[] = this.store.listByExercise(item.id);
      this.suggestion = ProgressiveOverloadPlanner.suggest(history);
    }
  }

  private addSet(): void {
    const next: SetRow[] = this.setRows.concat([new SetRow()]);
    this.setRows = next;
  }

  private removeSet(index: number): void {
    if (this.setRows.length <= 1) {
      return;
    }
    const next: SetRow[] = this.setRows.filter((row: SetRow, idx: number) => idx !== index);
    this.setRows = next;
  }

  private saveLog(): void {
    const exercise: ExerciseItem | null = this.selected;
    if (exercise === null || this.store === null) {
      return;
    }
    const log: WorkoutLog = new WorkoutLog();
    log.timestamp = Date.now();
    log.exerciseId = exercise.id;
    this.setRows.forEach((row: SetRow, idx: number) => {
      const set: WorkoutSet = {
        setIndex: idx + 1,
        reps: Number(row.repsText),
        weightKg: Number(row.weightText),
        rpe: Number(row.rpe),
        rir: row.rir === '-' ? -1 : Number(row.rir)
      };
      log.sets.push(set);
    });
    const errors: string[] = log.validate();
    if (errors.length > 0) {
      promptAction.showToast({ message: errors[0] });
      return;
    }
    const historyLogs: WorkoutLog[] = this.store.listByExercise(exercise.id);
    historyLogs.push(log);
    const prCheck: PRCheck = PRTracker.checkLatest(historyLogs);
    this.store.save(log);
    promptAction.showToast({ message: prCheck.isPR ? `🏅 ${prCheck.message}` : '已记录，继续加油！' });
    router.back();
  }

  build() {
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
        Text(this.selected === null ? '选择动作' : '录入组数')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.primaryText)
          .margin({ left: 12 })
        Blank()
        ThemeToggle({ theme: this.theme })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.selected === null) {
        // ===== 动作选择器：器械 + 部位双维筛选 =====
        this.filterBar(this.equipments, true)
        this.filterBar(this.muscles, false)
        Grid() {
          ForEach(this.shownList, (item: ExerciseItem) => {
            GridItem() {
              Column({ space: 4 }) {
                Text(item.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.theme.palette.primaryText)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${item.muscle}·${item.subMuscle}`)
                  .fontSize(11)
                  .fontColor(this.theme.palette.secondaryText)
              }
              .alignItems(HorizontalAlign.Start)
              .padding(10)
              .borderRadius(12)
              .backgroundColor(this.theme.palette.cardBackground)
              .accessibilityText(`选择动作 ${item.name}`)
              .onClick(() => {
                this.selectExercise(item);
              })
            }
          }, (item: ExerciseItem) => item.id)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .padding({ left: 16, right: 16, bottom: 16 })
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else {
        this.setsPanel(this.selected)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }

  /** 筛选条（器械行 / 部位行共用） */
  @Builder
  private filterBar(options: string[], isEquipment: boolean): void {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(options, (option: string) => {
          Text(option)
            .fontSize(13)
            .fontColor(this.filterActive(isEquipment, option) ?
              this.theme.palette.onAccent : this.theme.palette.primaryText)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .borderRadius(14)
            .backgroundColor(this.filterActive(isEquipment, option) ?
              this.theme.palette.accent : this.theme.palette.inputBackground)
            .onClick(() => {
              if (isEquipment) {
                this.selectedEquipment = option;
              } else {
                this.selectedMuscle = option;
              }
              this.applyFilter();
            })
        }, (option: string) => option)
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 8 })
  }

  private filterActive(isEquipment: boolean, option: string): boolean {
    return isEquipment ? this.selectedEquipment === option : this.selectedMuscle === option;
  }

  /** 组数录入面板（参数局部收窄，规避 ArkTS 对 this 成员不做智能收窄的限制） */
  @Builder
  private setsPanel(exercise: ExerciseItem | null): void {
    if (exercise !== null) {
      Scroll() {
        Column() {
          SectionCard({ theme: this.theme, title: exercise.name }) {
            Text(`${exercise.equipment} · ${exercise.muscle}·${exercise.subMuscle} · ${exercise.difficulty}`)
              .fontSize(12)
              .fontColor(this.theme.palette.secondaryText)
            if (this.suggestion !== null) {
              Text(this.suggestionText())
                .fontSize(12)
                .fontColor(this.theme.palette.accent)
                .lineHeight(18)
                .margin({ top: 6 })
            }
            // 表头
            Row() {
              this.headCell('组', 40)
              this.headCell('次数', 0)
              this.headCell('重量kg', 0)
              this.headCell('RPE', 0)
              this.headCell('RIR', 0)
              this.headCell('', 40)
            }
            .width('100%')
            .margin({ top: 10 })
            ForEach(this.setRows, (row: SetRow, idx: number) => {
              Row({ space: 6 }) {
                Text(`${idx + 1}`)
                  .fontSize(13)
                  .fontColor(this.theme.palette.secondaryText)
                  .width(40)
                TextInput({ text: row.repsText })
                  .type(InputType.Number)
                  .fontColor(this.theme.palette.primaryText)
                  .backgroundColor(this.theme.palette.inputBackground)
                  .borderRadius(8)
                  .layoutWeight(1)
                  .accessibilityText(`第 ${idx + 1} 组次数`)
                  .onChange((v: string) => {
                    row.repsText = v;
                  })
                TextInput({ text: row.weightText })
                  .type(InputType.Number)
                  .fontColor(this.theme.palette.primaryText)
                  .backgroundColor(this.theme.palette.inputBackground)
                  .borderRadius(8)
                  .layoutWeight(1)
                  .accessibilityText(`第 ${idx + 1} 组重量`)
                  .onChange((v: string) => {
                    row.weightText = v;
                  })
                Select(this.buildRpeSelectOptions())
                  .value(row.rpe)
                  .fontColor(this.theme.palette.primaryText)
                  .backgroundColor(this.theme.palette.inputBackground)
                  .layoutWeight(1)
                  .onSelect((index: number) => {
                    row.rpe = this.rpeOptions[index];
                  })
                Select(this.buildRirSelectOptions())
                  .value(row.rir)
                  .fontColor(this.theme.palette.primaryText)
                  .backgroundColor(this.theme.palette.inputBackground)
                  .layoutWeight(1)
                  .onSelect((index: number) => {
                    row.rir = this.rirOptions[index];
                  })
                Button('删')
                  .fontSize(12)
                  .fontColor(this.theme.palette.secondaryText)
                  .backgroundColor(this.theme.palette.inputBackground)
                  .borderRadius(8)
                  .width(40)
                  .height(32)
                  .accessibilityText(`删除第 ${idx + 1} 组`)
                  .onClick(() => {
                    this.removeSet(idx);
                  })
              }
              .width('100%')
              .margin({ top: 6 })
            }, (row: SetRow, idx: number) => `set_${idx}`)
            Row({ space: 10 }) {
              Button('＋ 加一组')
                .fontSize(14)
                .fontColor(this.theme.palette.accent)
                .backgroundColor(this.theme.palette.inputBackground)
                .borderRadius(18)
                .height(36)
                .layoutWeight(1)
                .accessibilityText('增加一组')
                .onClick(() => {
                  this.addSet();
                })
              Button('保存本次训练')
                .fontSize(14)
                .fontColor(this.theme.palette.onAccent)
                .backgroundColor(this.theme.palette.accent)
                .borderRadius(18)
                .height(36)
                .layoutWeight(1)
                .accessibilityText('校验并保存训练日志')
                .onClick(() => {
                  this.saveLog();
                })
            }
            .width('100%')
            .margin({ top: 14 })
          }
        }
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
  }

  @Builder
  private headCell(text: string, w: number): void {
    if (w > 0) {
      Text(text)
        .fontSize(12)
        .fontColor(this.theme.palette.secondaryText)
        .width(w)
    } else {
      Text(text)
        .fontSize(12)
        .fontColor(this.theme.palette.secondaryText)
        .layoutWeight(1)
    }
  }

  private suggestionText(): string {
    const s: OverloadSuggestion | null = this.suggestion;
    if (s === null) {
      return '';
    }
    return `渐进超负荷建议：${s.message}`;
  }

  private buildRpeSelectOptions(): SelectOption[] {
    return this.rpeOptions.map((rpe: string): SelectOption => {
      return { value: rpe };
    });
  }

  private buildRirSelectOptions(): SelectOption[] {
    return this.rirOptions.map((rir: string): SelectOption => {
      return { value: rir };
    });
  }
}
