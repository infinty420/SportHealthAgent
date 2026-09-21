/*
 * 文件标注：AI 生成 —— 动作详情页脚手架与通用 UI（数据来自 data/ExerciseLibrary.ets）
 *
 * 可视化 UI 层 · 动作详情页（参考「快练」：3D 动作示例大图 + 标签 + 编号步骤 + 呼吸节奏）
 * 展示 3D 解剖风示例图、器械/部位/难度标签、训练建议、呼吸节奏、目标肌群、动作要领。
 * 主题约束：本文件不出现任何硬编码色值，一律读取 theme.palette.*。
 */
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../theme/ThemeManager';
import { ExerciseItem, ExerciseLibrary } from '../data/ExerciseLibrary';
import { ExerciseDetailParams } from './ExerciseLibrary';
import { ThemeToggle } from '../components/ThemeToggle';

@Entry
@Component
struct ExerciseDetailPage {
  @State theme: ThemeManager = ThemeManager.instance;
  @State exercise: ExerciseItem | null = null;
  /** 组间休息剩余秒数（0 = 未计时） */
  @State secondsLeft: number = 0;
  private restTimerId: number = -1;

  aboutToAppear(): void {
    const params: ExerciseDetailParams = router.getParams() as ExerciseDetailParams;
    if (params !== null && params !== undefined && params.id.length > 0) {
      this.exercise = ExerciseLibrary.findById(params.id);
    }
  }

  onPageHide(): void {
    this.stopRest();
  }

  aboutToDisappear(): void {
    this.stopRest();
  }

  /** 是否复合动作（多肌群或杠铃/史密斯器械）→ 休息 150/180 秒；孤立动作 60/90 秒 */
  private isCompound(): boolean {
    const exercise: ExerciseItem | null = this.exercise;
    if (exercise === null) {
      return false;
    }
    return exercise.targetMuscles.indexOf('、') >= 0 ||
      exercise.equipment === '杠铃' || exercise.equipment === '史密斯';
  }

  /** 启动组间休息倒计时 */
  private startRest(seconds: number): void {
    this.stopRest();
    this.secondsLeft = seconds;
    this.restTimerId = setInterval(() => {
      if (this.secondsLeft > 1) {
        this.secondsLeft--;
      } else {
        this.stopRest();
      }
    }, 1000);
  }

  /** 停止并清零倒计时 */
  private stopRest(): void {
    if (this.restTimerId >= 0) {
      clearInterval(this.restTimerId);
      this.restTimerId = -1;
    }
    if (this.secondsLeft !== 0) {
      this.secondsLeft = 0;
    }
  }

  /** 秒数格式化为 m:ss */
  private restText(): string {
    const minutes: number = Math.floor(this.secondsLeft / 60);
    const seconds: string = `${this.secondsLeft % 60}`.padStart(2, '0');
    return `${minutes}:${seconds}`;
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
          .onClick(() => {
            router.back();
          })
        Text('动作详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.primaryText)
          .margin({ left: 12 })
        Blank()
        ThemeToggle({ theme: this.theme })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (this.exercise === null) {
        Text('未找到该动作')
          .fontSize(14)
          .fontColor(this.theme.palette.secondaryText)
          .margin({ top: 40 })
      } else {
        this.detailBody(this.exercise)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }

  /** 详情主体（参数局部收窄，规避 ArkTS 对 this 成员不做智能收窄的限制） */
  @Builder
  private detailBody(exercise: ExerciseItem | null): void {
    if (exercise !== null) {
      Scroll() {
        Column() {
          // ===== 3D 动作示例大图 =====
          Image($r(exercise.imageRes))
            .width('100%')
            .aspectRatio(1)
            .borderRadius(16)

          // 动作名称
          Text(exercise.name)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.palette.primaryText)
            .margin({ top: 14 })

          // 属性标签行（器械 / 部位·细分 / 难度）
          Row({ space: 8 }) {
            this.metaChip(exercise.equipment)
            this.metaChip(exercise.muscle === exercise.subMuscle ?
              exercise.muscle : `${exercise.muscle}·${exercise.subMuscle}`)
            this.metaChip(exercise.difficulty)
          }
          .margin({ top: 12 })

          // 训练建议
          this.sectionTitle('训练建议')
          Text(exercise.prescription)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.theme.palette.accent)

          // 组间休息计时器（复合动作 150/180 秒，孤立动作 60/90 秒）
          this.sectionTitle('组间休息')
          this.restPanel()

          // 呼吸节奏
          this.sectionTitle('呼吸节奏')
          Text(exercise.breathing)
            .fontSize(14)
            .fontColor(this.theme.palette.primaryText)
            .lineHeight(22)

          // 目标肌群
          this.sectionTitle('目标肌群')
          Text(exercise.targetMuscles)
            .fontSize(14)
            .fontColor(this.theme.palette.primaryText)

          // 动作描述
          this.sectionTitle('动作说明')
          Text(exercise.description)
            .fontSize(14)
            .fontColor(this.theme.palette.secondaryText)
            .lineHeight(22)

          // 常见错误（警示色标记）
          this.sectionTitle('常见错误')
          ForEach(exercise.commonMistakes, (mistake: string) => {
            Row({ space: 8 }) {
              Text('!')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.theme.palette.onAccent)
                .textAlign(TextAlign.Center)
                .width(20)
                .height(20)
                .borderRadius(10)
                .backgroundColor(this.theme.palette.warning)
              Text(mistake)
                .fontSize(14)
                .fontColor(this.theme.palette.primaryText)
                .layoutWeight(1)
                .lineHeight(21)
            }
            .width('100%')
            .margin({ bottom: 8 })
          }, (mistake: string) => mistake)

          // 动作要领（编号步骤）
          this.sectionTitle('动作要领')
          ForEach(exercise.keyPoints, (point: string, index: number) => {
            Row({ space: 8 }) {
              Text(`${index + 1}`)
                .fontSize(12)
                .fontColor(this.theme.palette.onAccent)
                .textAlign(TextAlign.Center)
                .width(20)
                .height(20)
                .borderRadius(10)
                .backgroundColor(this.theme.palette.accent)
              Text(point)
                .fontSize(14)
                .fontColor(this.theme.palette.primaryText)
                .layoutWeight(1)
                .lineHeight(21)
            }
            .width('100%')
            .margin({ bottom: 8 })
          }, (point: string) => point)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
  }

  /** 属性小标签 */
  @Builder
  private metaChip(text: string): void {
    Text(text)
      .fontSize(12)
      .fontColor(this.theme.palette.accent)
      .padding({ left: 12, right: 12, top: 5, bottom: 5 })
      .borderRadius(13)
      .backgroundColor(this.theme.palette.inputBackground)
  }

  /** 组间休息计时面板 */
  @Builder
  private restPanel(): void {
    Column() {
      if (this.secondsLeft > 0) {
        Text(this.restText())
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.accent)
        Button('结束休息')
          .fontSize(14)
          .fontColor(this.theme.palette.secondaryText)
          .backgroundColor(this.theme.palette.inputBackground)
          .borderRadius(18)
          .height(36)
          .margin({ top: 10 })
          .accessibilityText('结束组间休息计时')
          .onClick(() => {
            this.stopRest();
          })
      } else {
        Text(this.isCompound() ? '复合动作建议休息 2.5–3 分钟' : '孤立动作建议休息 1–1.5 分钟')
          .fontSize(12)
          .fontColor(this.theme.palette.secondaryText)
        Row({ space: 10 }) {
          Button(this.isCompound() ? '2:30' : '1:00')
            .fontSize(14)
            .fontColor(this.theme.palette.onAccent)
            .backgroundColor(this.theme.palette.accent)
            .borderRadius(18)
            .height(36)
            .layoutWeight(1)
            .accessibilityText('开始较短休息计时')
            .onClick(() => {
              this.startRest(this.isCompound() ? 150 : 60);
            })
          Button(this.isCompound() ? '3:00' : '1:30')
            .fontSize(14)
            .fontColor(this.theme.palette.accent)
            .backgroundColor(this.theme.palette.inputBackground)
            .borderRadius(18)
            .height(36)
            .layoutWeight(1)
            .accessibilityText('开始较长休息计时')
            .onClick(() => {
              this.startRest(this.isCompound() ? 180 : 90);
            })
        }
        .width('100%')
        .margin({ top: 8 })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  /** 小节标题 */
  @Builder
  private sectionTitle(title: string): void {
    Text(title)
      .fontSize(15)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.theme.palette.primaryText)
      .margin({ top: 18, bottom: 8 })
  }
}
