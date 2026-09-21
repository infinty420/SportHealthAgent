/*
 * 文件标注：AI 生成 —— 动作库列表页脚手架与通用 UI（数据来自 data/ExerciseLibrary.ets）
 *
 * 可视化 UI 层 · 动作库列表页（参考「快练」：顶部器械分类 + 左侧部位栏 + 双列卡片网格）
 * 主题约束：本文件不出现任何硬编码色值，一律读取 theme.palette.*。
 * 数据约束：动作数据全部本地内置，无网络请求。
 */
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../theme/ThemeManager';
import { ExerciseItem, ExerciseLibrary, EXERCISE_EQUIPMENTS, EXERCISE_MUSCLES } from '../data/ExerciseLibrary';
import { ThemeToggle } from '../components/ThemeToggle';

/** 详情页路由参数（显式类声明，避免裸对象字面量） */
export class ExerciseDetailParams {
  id: string = '';
}

@Entry
@Component
struct ExerciseLibraryPage {
  @State theme: ThemeManager = ThemeManager.instance;
  @State selectedEquipment: string = '全部';
  @State selectedMuscle: string = '全部';
  @State shownList: ExerciseItem[] = ExerciseLibrary.all();

  /** 器械筛选项（「全部」+ 6 类器械；成员变量供 ForEach 直接使用） */
  private readonly equipments: string[] = ['全部'].concat(EXERCISE_EQUIPMENTS);
  /** 部位筛选项（「全部」+ 8 个部位；成员变量供 ForEach 直接使用） */
  private readonly muscles: string[] = ['全部'].concat(EXERCISE_MUSCLES);

  private applyFilter(): void {
    this.shownList = ExerciseLibrary.filter(this.selectedEquipment, this.selectedMuscle);
  }

  private selectEquipment(equipment: string): void {
    this.selectedEquipment = equipment;
    this.applyFilter();
  }

  private selectMuscle(muscle: string): void {
    this.selectedMuscle = muscle;
    this.applyFilter();
  }

  private openDetail(item: ExerciseItem): void {
    const params: ExerciseDetailParams = new ExerciseDetailParams();
    params.id = item.id;
    router.pushUrl({ url: 'pages/ExerciseDetail', params: params })
      .catch((err: Error) => {
        console.error(`openDetail failed: ${err.message}`);
      });
  }

  build() {
    Column() {
      // ===== 顶部栏：返回 + 标题 + 主题切换 =====
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
        Text('动作库')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.primaryText)
          .margin({ left: 12 })
        Blank()
        ThemeToggle({ theme: this.theme })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // ===== 顶部器械筛选条（杠铃 / 哑铃 / 史密斯 / 绳索 / 自重 / 弹力带） =====
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.equipments, (equipment: string) => {
            Text(equipment)
              .fontSize(13)
              .fontColor(this.selectedEquipment === equipment ?
                this.theme.palette.onAccent : this.theme.palette.primaryText)
              .padding({ left: 14, right: 14, top: 7, bottom: 7 })
              .borderRadius(16)
              .backgroundColor(this.selectedEquipment === equipment ?
                this.theme.palette.accent : this.theme.palette.inputBackground)
              .onClick(() => {
                this.selectEquipment(equipment);
              })
          }, (equipment: string) => equipment)
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .margin({ bottom: 10 })

      // ===== 主体：左侧部位栏 + 右侧双列动作网格 =====
      Row() {
        // 左侧部位边栏
        Scroll() {
          Column({ space: 6 }) {
            ForEach(this.muscles, (muscle: string) => {
              Text(muscle)
                .fontSize(13)
                .fontColor(this.selectedMuscle === muscle ?
                  this.theme.palette.onAccent : this.theme.palette.primaryText)
                .textAlign(TextAlign.Center)
                .width(72)
                .padding({ top: 9, bottom: 9 })
                .borderRadius(12)
                .backgroundColor(this.selectedMuscle === muscle ?
                  this.theme.palette.accent : this.theme.palette.inputBackground)
                .onClick(() => {
                  this.selectMuscle(muscle);
                })
            }, (muscle: string) => muscle)
          }
          .padding({ left: 16, right: 8, bottom: 24 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .height('100%')

        // 右侧双列卡片网格（Grid 自带滚动，不外套 Scroll）
        Grid() {
          ForEach(this.shownList, (item: ExerciseItem) => {
            GridItem() {
              Column({ space: 6 }) {
                Image($r(item.imageRes))
                  .width('100%')
                  .aspectRatio(1)
                  .borderRadius(12)
                Text(item.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.theme.palette.primaryText)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${item.muscle}·${item.subMuscle} · ${item.difficulty}`)
                  .fontSize(11)
                  .fontColor(this.theme.palette.secondaryText)
              }
              .alignItems(HorizontalAlign.Start)
              .padding(8)
              .borderRadius(14)
              .backgroundColor(this.theme.palette.cardBackground)
              .onClick(() => {
                this.openDetail(item);
              })
            }
          }, (item: ExerciseItem) => item.id)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .padding({ right: 16, bottom: 24 })
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .height('100%')
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }
}
