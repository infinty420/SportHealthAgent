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

@Component
export struct ExerciseLibraryPage {
  @State theme: ThemeManager = ThemeManager.instance;
  @State selectedEquipment: string = '全部';
  @State selectedMuscle: string = '全部';
  @State keyword: string = '';
  @State selectedDifficulty: string = '全部';
  @State shownList: ExerciseItem[] = ExerciseLibrary.all();

  /** 器械筛选项（「全部」+ 6 类器械；成员变量供 ForEach 直接使用） */
  private readonly equipments: string[] = ['全部'].concat(EXERCISE_EQUIPMENTS);
  /** 部位筛选项（「全部」+ 8 个部位；成员变量供 ForEach 直接使用） */
  private readonly muscles: string[] = ['全部'].concat(EXERCISE_MUSCLES);
  /** 难度筛选项（2.6 多条件检索：纯数组 filter，无搜索引擎） */
  private readonly difficulties: string[] = ['全部', '初级', '中级', '高级'];

  /** 多条件过滤：器械 × 部位 × 名称关键词 × 难度（先算好赋值给 shownList，ForEach 不直接调方法） */
  private applyFilter(): void {
    const base: ExerciseItem[] = ExerciseLibrary.filter(this.selectedEquipment, this.selectedMuscle);
    const kw: string = this.keyword.trim();
    this.shownList = base.filter((item: ExerciseItem) => {
      if (this.selectedDifficulty !== '全部' && item.difficulty !== this.selectedDifficulty) {
        return false;
      }
      if (kw.length > 0 && item.name.indexOf(kw) < 0 && item.subMuscle.indexOf(kw) < 0 &&
        item.targetMuscles.indexOf(kw) < 0) {
        return false;
      }
      return true;
    });
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
      // ===== 顶部栏：标题 + 主题切换（已嵌入底部 Tabs，无返回键） =====
      Row() {
        Text('动作库')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.primaryText)
        Blank()
        ThemeToggle({ theme: this.theme })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // ===== 搜索栏 + 难度筛选（2.6：名称/肌群/器械/难度多条件检索） =====
      Row({ space: 8 }) {
        TextInput({ placeholder: '搜索动作名 / 细分部位 / 目标肌群', text: this.keyword })
          .fontColor(this.theme.palette.primaryText)
          .placeholderColor(this.theme.palette.secondaryText)
          .backgroundColor(this.theme.palette.inputBackground)
          .borderRadius(16)
          .height(36)
          .layoutWeight(1)
          .accessibilityText('搜索动作库')
          .onChange((v: string) => {
            this.keyword = v;
            this.applyFilter();
          })
        ForEach(this.difficulties, (diff: string) => {
          Text(diff)
            .fontSize(12)
            .fontColor(this.selectedDifficulty === diff ?
              this.theme.palette.onAccent : this.theme.palette.primaryText)
            .textAlign(TextAlign.Center)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .borderRadius(13)
            .backgroundColor(this.selectedDifficulty === diff ?
              this.theme.palette.accent : this.theme.palette.inputBackground)
            .accessibilityText(`按难度 ${diff} 筛选`)
            .onClick(() => {
              this.selectedDifficulty = diff;
              this.applyFilter();
            })
        }, (diff: string) => diff)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

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
