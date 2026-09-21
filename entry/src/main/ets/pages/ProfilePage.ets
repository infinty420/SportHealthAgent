/*
 * 文件标注：AI 生成 —— 用户画像页脚手架与通用 UI
 *
 * 可视化 UI 层 · 用户画像录入页
 * 录入性别/年龄/身高/体重/静息心率/目标/经验等级，保存后引擎按画像个性化调参。
 * 主题约束：本文件不出现任何硬编码色值，一律读取 theme.palette.*。
 */
import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ThemeManager } from '../theme/ThemeManager';
import { UserProfile, GENDER_LIST, USER_GOAL_LIST, EXPERIENCE_LEVEL_LIST } from '../model/UserProfile';
import { UserProfileStore } from '../data/UserProfileStore';
import { InjuryRecord, INJURY_PARTS } from '../model/InjuryRecord';
import { InjuryStore } from '../data/InjuryStore';
import { BodyMetricsStore, BodyMetricEntry } from '../data/BodyMetricsStore';
import { ThemeToggle } from '../components/ThemeToggle';

@Entry
@Component
struct ProfilePage {
  @State theme: ThemeManager = ThemeManager.instance;
  @State gender: string = GENDER_LIST[0];
  @State ageText: string = '30';
  @State heightText: string = '170';
  @State weightText: string = '65';
  @State restingHrText: string = '65';
  @State goal: string = USER_GOAL_LIST[1];
  @State level: string = EXPERIENCE_LEVEL_LIST[0];
  @State errors: string[] = [];
  // 伤病记录（训练计划与补强推荐会自动避开禁忌动作）
  @State injuryParts: string[] = [];
  @State injuryPart: string = INJURY_PARTS[0];
  @State injuryDateText: string = '';
  @State injuryError: string = '';

  private store: UserProfileStore | null = null;
  private injuryStore: InjuryStore | null = null;

  aboutToAppear(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.store = new UserProfileStore(context);
    this.injuryStore = new InjuryStore(context);
    const profile: UserProfile = this.store.load();
    if (profile.filled) {
      this.gender = profile.gender;
      this.ageText = `${profile.age}`;
      this.heightText = `${profile.heightCm}`;
      this.weightText = `${profile.weightKg}`;
      this.restingHrText = `${profile.restingHr}`;
      this.goal = profile.goal;
      this.level = profile.experienceLevel;
    }
    const now: Date = new Date();
    const month: string = `${now.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${now.getDate()}`.padStart(2, '0');
    this.injuryDateText = `${now.getFullYear()}-${month}-${day}`;
    this.refreshInjuries();
  }

  private refreshInjuries(): void {
    if (this.injuryStore !== null) {
      this.injuryParts = this.injuryStore.activeParts();
    }
  }

  private saveInjury(): void {
    if (this.injuryStore === null) {
      return;
    }
    const record: InjuryRecord = new InjuryRecord();
    record.part = this.injuryPart;
    record.startDate = this.injuryDateText.trim();
    record.endDate = '';
    const errors: string[] = record.validate();
    if (errors.length > 0) {
      this.injuryError = errors[0];
      return;
    }
    this.injuryError = '';
    this.injuryStore.save(record);
    this.refreshInjuries();
    promptAction.showToast({ message: `${this.injuryPart}部伤病已记录，训练计划将自动避开禁忌动作` });
  }

  private clearInjury(part: string): void {
    if (this.injuryStore === null) {
      return;
    }
    this.injuryStore.clearPart(part);
    this.refreshInjuries();
    promptAction.showToast({ message: `${part}部伤病已清除，祝康复顺利` });
  }

  private save(): void {
    const profile: UserProfile = new UserProfile();
    profile.gender = this.gender;
    profile.age = Number(this.ageText);
    profile.heightCm = Number(this.heightText);
    profile.weightKg = Number(this.weightText);
    profile.restingHr = Number(this.restingHrText);
    profile.goal = this.goal;
    profile.experienceLevel = this.level;
    profile.filled = true;
    this.errors = profile.validate();
    if (this.errors.length > 0) {
      return;
    }
    if (this.store !== null) {
      this.store.save(profile);
      // 同步记录体成分时间序列（体重趋势分析的数据源）
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const bodyStore: BodyMetricsStore = new BodyMetricsStore(context);
      const entry: BodyMetricEntry = {
        timestamp: Date.now(),
        weightKg: profile.weightKg,
        bodyFatPct: 0,
        restingHr: profile.restingHr
      };
      bodyStore.save(entry);
    }
    promptAction.showToast({ message: $r('app.string.profile_saved') });
    router.back();
  }

  build() {
    Column() {
      Row() {
        Button('‹ 返回')
          .fontSize(14)
          .fontColor(this.theme.palette.accent)
          .backgroundColor(this.theme.palette.inputBackground)
          .borderRadius(18)
          .height(36)
          .accessibilityText('返回首页')
          .onClick(() => {
            router.back();
          })
        Text($r('app.string.profile_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.primaryText)
          .margin({ left: 12 })
        Blank()
        ThemeToggle({ theme: this.theme })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          this.selectRow('性别', GENDER_LIST, this.gender, (v: string) => {
            this.gender = v;
          })
          this.numberField('年龄（岁）', this.ageText, (v: string) => {
            this.ageText = v;
          })
          this.numberField('身高（厘米）', this.heightText, (v: string) => {
            this.heightText = v;
          })
          this.numberField('体重（公斤）', this.weightText, (v: string) => {
            this.weightText = v;
          })
          this.numberField('静息心率（次/分）', this.restingHrText, (v: string) => {
            this.restingHrText = v;
          })
          this.selectRow('训练目标', USER_GOAL_LIST, this.goal, (v: string) => {
            this.goal = v;
          })
          this.selectRow('经验等级', EXPERIENCE_LEVEL_LIST, this.level, (v: string) => {
            this.level = v;
          })

          // ===== 伤病记录区 =====
          Text('伤病记录')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.palette.primaryText)
            .margin({ top: 14, bottom: 6 })
          if (this.injuryParts.length > 0) {
            Row({ space: 8 }) {
              ForEach(this.injuryParts, (part: string) => {
                Row({ space: 4 }) {
                  Text(`${part} 恢复中`)
                    .fontSize(12)
                    .fontColor(this.theme.palette.warning)
                  Text('✕')
                    .fontSize(12)
                    .fontColor(this.theme.palette.secondaryText)
                }
                .padding({ left: 12, right: 10, top: 5, bottom: 5 })
                .borderRadius(13)
                .backgroundColor(this.theme.palette.inputBackground)
                .accessibilityText(`清除${part}部伤病记录`)
                .onClick(() => {
                  this.clearInjury(part);
                })
              }, (part: string) => part)
            }
            .margin({ bottom: 8 })
          } else {
            Text('当前无伤病记录')
              .fontSize(12)
              .fontColor(this.theme.palette.secondaryText)
              .margin({ bottom: 8 })
          }
          this.selectRow('伤病部位', INJURY_PARTS, this.injuryPart, (v: string) => {
            this.injuryPart = v;
          })
          Column({ space: 4 }) {
            Text('开始日期（YYYY-MM-DD）')
              .fontSize(13)
              .fontColor(this.theme.palette.secondaryText)
            TextInput({ text: this.injuryDateText })
              .fontColor(this.theme.palette.primaryText)
              .placeholderColor(this.theme.palette.secondaryText)
              .backgroundColor(this.theme.palette.inputBackground)
              .caretColor(this.theme.palette.accent)
              .borderRadius(10)
              .onChange((v: string) => {
                this.injuryDateText = v;
              })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: 10 })
          if (this.injuryError.length > 0) {
            Text(`· ${this.injuryError}`)
              .fontSize(13)
              .fontColor(this.theme.palette.danger)
          }
          Button('保存伤病记录')
            .fontSize(14)
            .fontColor(this.theme.palette.accent)
            .backgroundColor(this.theme.palette.inputBackground)
            .borderRadius(18)
            .height(36)
            .width('100%')
            .accessibilityText('保存伤病记录，计划自动避开禁忌动作')
            .onClick(() => {
              this.saveInjury();
            })

          if (this.errors.length > 0) {
            ForEach(this.errors, (err: string) => {
              Text(`· ${err}`)
                .fontSize(13)
                .fontColor(this.theme.palette.danger)
            }, (err: string) => err)
          }

          Button('保存画像')
            .fontColor(this.theme.palette.onAccent)
            .backgroundColor(this.theme.palette.accent)
            .borderRadius(20)
            .width('100%')
            .margin({ top: 12 })
            .accessibilityDescription('保存用户画像并返回首页')
            .onClick(() => {
              this.save();
            })
          Text('画像仅保存在本机，用于心率区间修正、热量估算与饮食配比个性化')
            .fontSize(12)
            .fontColor(this.theme.palette.secondaryText)
            .margin({ top: 10 })
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }

  @Builder
  private selectRow(label: string, options: string[], current: string, onPick: (v: string) => void): void {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(13)
        .fontColor(this.theme.palette.secondaryText)
      Select(this.toOptions(options))
        .value(current)
        .fontColor(this.theme.palette.primaryText)
        .backgroundColor(this.theme.palette.inputBackground)
        .onSelect((index: number) => {
          onPick(options[index]);
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ bottom: 10 })
  }

  private toOptions(list: string[]): SelectOption[] {
    return list.map((t: string): SelectOption => {
      return { value: t };
    });
  }

  @Builder
  private numberField(label: string, value: string, onChange: (v: string) => void): void {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(13)
        .fontColor(this.theme.palette.secondaryText)
      TextInput({ text: value })
        .type(InputType.Number)
        .fontColor(this.theme.palette.primaryText)
        .placeholderColor(this.theme.palette.secondaryText)
        .backgroundColor(this.theme.palette.inputBackground)
        .caretColor(this.theme.palette.accent)
        .borderRadius(10)
        .onChange(onChange)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ bottom: 10 })
  }
}
