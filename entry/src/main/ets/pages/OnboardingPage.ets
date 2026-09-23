/*
 * 文件标注：AI 生成 —— 新手引导页面（通用 UI 脚手架）
 *
 * 可视化 UI 层 · 新手引导
 * 首次启动（画像未填写）时进入：五步问答（性别 → 年龄 → 身高体重 → 目标 → 经验），
 * 完成后写入 UserProfileStore（filled=true）并 replaceUrl 回首页；
 * 支持「跳过」按默认画像直接开始。全部本地完成，无网络请求。
 */
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ThemeManager } from '../theme/ThemeManager';
import { SectionCard } from '../components/SectionCard';
import { UserProfileStore } from '../data/UserProfileStore';
import { UserProfile, USER_GOAL_LIST, EXPERIENCE_LEVEL_LIST, GENDER_LIST } from '../model/UserProfile';

@Entry
@Component
struct OnboardingPage {
  @State theme: ThemeManager = ThemeManager.instance;

  // 引导进度：0 性别 / 1 年龄 / 2 身高体重 / 3 目标 / 4 经验
  @State step: number = 0;
  // 问答状态（默认值与 UserProfile 一致）
  @State gender: string = GENDER_LIST[0];
  @State age: number = 30;
  @State heightCm: number = 170;
  @State weightKg: number = 65;
  @State goal: string = USER_GOAL_LIST[1];
  @State experienceLevel: string = EXPERIENCE_LEVEL_LIST[0];
  @State errors: string[] = [];

  private profileStore: UserProfileStore | null = null;

  aboutToAppear(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.profileStore = new UserProfileStore(context);
  }

  /** 保存画像并回首页（跳过走默认画像；完成走问卷值，先校验） */
  private finish(useAnswers: boolean): void {
    if (this.profileStore === null) {
      return;
    }
    const profile: UserProfile = new UserProfile();
    if (useAnswers) {
      profile.gender = this.gender;
      profile.age = this.age;
      profile.heightCm = this.heightCm;
      profile.weightKg = this.weightKg;
      profile.goal = this.goal;
      profile.experienceLevel = this.experienceLevel;
      this.errors = profile.validate();
      if (this.errors.length > 0) {
        return;
      }
    }
    profile.filled = true;
    this.profileStore.save(profile);
    router.replaceUrl({ url: 'pages/Index' });
  }

  /** 选项 chips 行（单选；选中项用强调色填充） */
  @Builder
  private optionChips(options: string[], current: string, onPick: (v: string) => void): void {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(options, (option: string) => {
        Text(option)
          .fontSize(14)
          .fontColor(option === current ? this.theme.palette.onAccent : this.theme.palette.primaryText)
          .textAlign(TextAlign.Center)
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .borderRadius(18)
          .backgroundColor(option === current ? this.theme.palette.accent : this.theme.palette.inputBackground)
          .margin({ right: 10, bottom: 10 })
          .accessibilityText(`选择${option}`)
          .onClick(() => {
            onPick(option);
          })
      }, (option: string): string => option)
    }
    .width('100%')
  }

  /** 数值滑块（标签实时显示当前值） */
  @Builder
  private valueSlider(label: string, value: number, min: number, max: number, onSlide: (v: number) => void): void {
    Column({ space: 2 }) {
      Text(`${label}：${value}`)
        .fontSize(14)
        .fontColor(this.theme.palette.primaryText)
      Slider({ value: value, min: min, max: max, step: 1 })
        .selectedColor(this.theme.palette.accent)
        .trackColor(this.theme.palette.track)
        .blockColor(this.theme.palette.accent)
        .accessibilityText(`调整${label}`)
        .onChange((v: number) => {
          onSlide(Math.round(v));
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ bottom: 10 })
  }

  build(): void {
    Column() {
      // 顶部：标题 + 进度指示
      Row() {
        Text('欢迎使用衡练')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.primaryText)
        Blank()
        Text(`${this.step + 1} / 5`)
          .fontSize(13)
          .fontColor(this.theme.palette.secondaryText)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 8 })

      // 进度条（五个圆点，已完成用强调色）
      Row({ space: 6 }) {
        ForEach([0, 1, 2, 3, 4], (index: number) => {
          Circle()
            .width(8)
            .height(8)
            .fill(index <= this.step ? this.theme.palette.accent : this.theme.palette.track)
        }, (index: number): string => `${index}`)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 16 })

      Scroll() {
        Column() {
          if (this.step === 0) {
            SectionCard({ theme: this.theme, title: '第 1 步 · 性别' }) {
              this.optionChips(GENDER_LIST, this.gender, (v: string) => {
                this.gender = v;
              })
            }
          }
          if (this.step === 1) {
            SectionCard({ theme: this.theme, title: '第 2 步 · 年龄' }) {
              this.valueSlider('年龄（岁）', this.age, 10, 100, (v: number) => {
                this.age = v;
              })
            }
          }
          if (this.step === 2) {
            SectionCard({ theme: this.theme, title: '第 3 步 · 身高体重' }) {
              this.valueSlider('身高（厘米）', this.heightCm, 100, 230, (v: number) => {
                this.heightCm = v;
              })
              this.valueSlider('体重（公斤）', this.weightKg, 30, 150, (v: number) => {
                this.weightKg = v;
              })
            }
          }
          if (this.step === 3) {
            SectionCard({ theme: this.theme, title: '第 4 步 · 训练目标' }) {
              this.optionChips(USER_GOAL_LIST, this.goal, (v: string) => {
                this.goal = v;
              })
            }
          }
          if (this.step === 4) {
            SectionCard({ theme: this.theme, title: '第 5 步 · 训练经验' }) {
              this.optionChips(EXPERIENCE_LEVEL_LIST, this.experienceLevel, (v: string) => {
                this.experienceLevel = v;
              })
              Text('经验等级影响引擎的强度与容量建议：新手更保守，高阶更激进')
                .fontSize(11)
                .fontColor(this.theme.palette.secondaryText)
                .lineHeight(16)
                .margin({ top: 4 })
            }
          }

          // 校验错误提示
          if (this.errors.length > 0) {
            ForEach(this.errors, (err: string) => {
              Text(err)
                .fontSize(12)
                .fontColor(this.theme.palette.danger)
                .margin({ bottom: 4 })
            }, (err: string): string => err)
          }

          // 底部按钮：上一步 / 下一步 / 完成 / 跳过
          Row({ space: 12 }) {
            if (this.step > 0) {
              Button('上一步')
                .fontSize(14)
                .fontColor(this.theme.palette.primaryText)
                .backgroundColor(this.theme.palette.inputBackground)
                .borderRadius(20)
                .height(40)
                .layoutWeight(1)
                .accessibilityText('返回上一个问题')
                .onClick(() => {
                  this.step = this.step - 1;
                })
            }
            Button(this.step < 4 ? '下一步' : '完成并开始')
              .fontSize(14)
              .fontColor(this.theme.palette.onAccent)
              .backgroundColor(this.theme.palette.accent)
              .borderRadius(20)
              .height(40)
              .layoutWeight(1)
              .accessibilityText(this.step < 4 ? '进入下一个问题' : '保存画像并进入首页')
              .onClick(() => {
                if (this.step < 4) {
                  this.step = this.step + 1;
                } else {
                  this.finish(true);
                }
              })
          }
          .width('100%')
          .margin({ top: 8 })

          Button('跳过，使用默认画像开始')
            .fontSize(12)
            .fontColor(this.theme.palette.secondaryText)
            .backgroundColor(Color.Transparent)
            .height(36)
            .margin({ top: 10 })
            .accessibilityText('跳过引导，使用默认画像')
            .onClick(() => {
              this.finish(false);
            })
        }
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }
}
