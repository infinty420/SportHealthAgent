/*
 * 文件标注：AI 生成 —— 当日明细独立页（通用 UI 脚手架）
 *
 * 可视化 UI 层 · 当日明细
 * 发现页日历点击某天跳转而来（router 参数 dateKey=YYYY-MM-DD）：
 * 当日概览（星期/动作数/总组数/总容量）+ 动作明细列表 + 当日破纪录事件（PR）。
 * 数据全部来自本地 WorkoutLogStore / PRTracker，确定性规则聚合，无网络请求。
 * 主题约束：本文件不出现任何硬编码色值，一律读取 theme.palette.*。
 */
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeToggle } from '../components/ThemeToggle';
import { BackgroundLayer } from '../components/BackgroundLayer';
import { SectionCard } from '../components/SectionCard';
import { ExerciseItem, ExerciseLibrary } from '../data/ExerciseLibrary';
import { WorkoutLog } from '../model/WorkoutLog';
import { WorkoutLogStore } from '../data/WorkoutLogStore';
import { PRTracker, DailyPREvent } from '../agent/rules/PRTracker';

/** 路由参数（发现页日历点击传入） */
interface DayDetailParams {
  dateKey?: string;
}

@Entry
@Component
struct DayDetailPage {
  @State theme: ThemeManager = ThemeManager.instance;
  @State private dateKey: string = '';
  @State private weekdayText: string = '';
  @State private dayLogs: WorkoutLog[] = [];
  @State private dayVolume: number = 0;
  @State private daySets: number = 0;
  @State private dayPRs: DailyPREvent[] = [];
  private logStore: WorkoutLogStore | null = null;

  aboutToAppear(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.logStore = new WorkoutLogStore(context);
    const params: DayDetailParams = router.getParams() as DayDetailParams;
    if (params !== null && params !== undefined && params.dateKey !== undefined && params.dateKey.length > 0) {
      this.dateKey = params.dateKey;
    } else {
      // 缺省退回今天
      const now: Date = new Date();
      const month: string = `${now.getMonth() + 1}`.padStart(2, '0');
      const day: string = `${now.getDate()}`.padStart(2, '0');
      this.dateKey = `${now.getFullYear()}-${month}-${day}`;
    }
    this.weekdayText = DayDetailPage.weekdayOf(this.dateKey);
    this.reload();
  }

  /** 日期键 → 星期几 */
  private static weekdayOf(dateKey: string): string {
    const parts: string[] = dateKey.split('-');
    if (parts.length !== 3) {
      return '';
    }
    const date: Date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
    const names: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return names[date.getDay()];
  }

  private reload(): void {
    if (this.logStore === null) {
      return;
    }
    const logs: WorkoutLog[] = this.logStore.listByDate(this.dateKey);
    this.dayLogs = logs;
    let volume: number = 0;
    let sets: number = 0;
    logs.forEach((log: WorkoutLog) => {
      volume += log.totalVolume();
      sets += log.sets.length;
    });
    this.dayVolume = volume;
    this.daySets = sets;
    // 当日破纪录事件（PR 依赖全量历史，先算全量再按天过滤）
    const events: DailyPREvent[] = PRTracker.dailyPREvents(this.logStore.list());
    this.dayPRs = events.filter((event: DailyPREvent) => event.dateKey === this.dateKey);
  }

  /** 日志行摘要：动作名 + 组数/次数/容量 */
  private logSummary(log: WorkoutLog): string {
    const item: ExerciseItem | null = ExerciseLibrary.findById(log.exerciseId);
    const name: string = item === null ? log.exerciseId : item.name;
    const volume: number = log.totalVolume();
    if (volume > 0) {
      return `${name} · ${log.sets.length} 组 · 总次数 ${log.totalReps()} · 容量 ${volume} kg`;
    }
    return `${name} · ${log.sets.length} 组 · 总次数 ${log.totalReps()}`;
  }

  private logMuscleTag(log: WorkoutLog): string {
    const item: ExerciseItem | null = ExerciseLibrary.findById(log.exerciseId);
    if (item === null) {
      return '';
    }
    return `${item.muscle}·${item.subMuscle}`;
  }

  build() {
    // 根布局：背景层（最底，固定不滚动）+ 内容列
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
            .accessibilityText('返回发现页')
            .onClick(() => {
              router.back();
            })
          Text('当日明细')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.palette.primaryText)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .margin({ left: 12 })
          ThemeToggle({ theme: this.theme })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        Scroll() {
          Column() {
            // ===== 当日概览 =====
            SectionCard({ theme: this.theme, title: `${this.dateKey} · ${this.weekdayText}` }) {
              Row() {
                Column({ space: 4 }) {
                  Text(`${this.dayLogs.length}`)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.theme.palette.primaryText)
                  Text('动作数')
                    .fontSize(12)
                    .fontColor(this.theme.palette.secondaryText)
                }
                .layoutWeight(1)
                Column({ space: 4 }) {
                  Text(`${this.daySets}`)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.theme.palette.primaryText)
                  Text('总组数')
                    .fontSize(12)
                    .fontColor(this.theme.palette.secondaryText)
                }
                .layoutWeight(1)
                Column({ space: 4 }) {
                  Text(`${this.dayVolume}`)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.theme.palette.accent)
                  Text('总容量(kg)')
                    .fontSize(12)
                    .fontColor(this.theme.palette.secondaryText)
                }
                .layoutWeight(1)
              }
              .width('100%')
            }

            // ===== 动作明细 =====
            SectionCard({ theme: this.theme, title: '动作明细' }) {
              if (this.dayLogs.length === 0) {
                Column({ space: 8 }) {
                  Text('🌙')
                    .fontSize(28)
                    .accessibilityLevel('no')
                  Text('当日暂无训练记录')
                    .fontSize(13)
                    .fontColor(this.theme.palette.secondaryText)
                }
                .width('100%')
                .padding({ top: 12, bottom: 12 })
              } else {
                ForEach(this.dayLogs, (log: WorkoutLog) => {
                  Row() {
                    Column({ space: 2 }) {
                      Text(this.logSummary(log))
                        .fontSize(13)
                        .fontColor(this.theme.palette.primaryText)
                      Text(this.logMuscleTag(log))
                        .fontSize(11)
                        .fontColor(this.theme.palette.secondaryText)
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                  }
                  .width('100%')
                  .padding({ top: 6, bottom: 6 })
                }, (log: WorkoutLog) => `${log.timestamp}-${log.exerciseId}`)
              }
            }

            // ===== 当日破纪录 =====
            if (this.dayPRs.length > 0) {
              SectionCard({ theme: this.theme, title: '当日破纪录' }) {
                ForEach(this.dayPRs, (event: DailyPREvent) => {
                  Text(`🏅 ${event.exerciseName}：${event.message}`)
                    .fontSize(12)
                    .fontColor(this.theme.palette.warning)
                    .lineHeight(17)
                    .margin({ top: 6 })
                }, (event: DailyPREvent) => `${event.dateKey}-${event.exerciseName}-${event.message}`)
              }
            }
          }
          .padding({ left: 16, right: 16, top: 8, bottom: 24 })
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
}
