/*
 * 文件标注：AI 生成 —— 训练报表页脚手架与通用 UI（统计来自 data/HistoryStore.ets）
 *
 * 可视化 UI 层 · 周/月报表页
 * 展示近 7/30 天的总时长、总热量、平均负荷、训练频次与周目标达成率。
 * 主题约束：本文件不出现任何硬编码色值，一律读取 theme.palette.*。
 * 文案约束：页面级文案走 string.json 资源（中英双语）。
 */
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ThemeManager } from '../theme/ThemeManager';
import { HistoryStore, HistoryEntry, PeriodStats } from '../data/HistoryStore';
import { GoalStore, TrainingGoal } from '../data/GoalStore';
import { BodyMetricsStore } from '../data/BodyMetricsStore';
import { WellnessLogStore, WellnessEntry } from '../data/WellnessLogStore';
import { WorkoutLogStore } from '../data/WorkoutLogStore';
import { WorkoutLog } from '../model/WorkoutLog';
import { FatigueModel, FatigueResult } from '../agent/rules/FatigueModel';
import { ReadinessScorer, ReadinessInput, ReadinessReport } from '../agent/rules/ReadinessScorer';
import { WeightTrendAnalyzer, WeightTrendReport } from '../agent/rules/WeightTrendAnalyzer';
import { MesocyclePlanner, MesocyclePlan, MesocycleWeek } from '../agent/rules/MesocyclePlanner';
import { ProgressiveOverloadPlanner } from '../agent/rules/ProgressiveOverloadPlanner';
import { PRTracker, ExercisePR, DailyPREvent } from '../agent/rules/PRTracker';
import { ExerciseItem, ExerciseLibrary } from '../data/ExerciseLibrary';
import { BadgeEngine, Badge, BadgeStats } from '../agent/rules/BadgeEngine';
import { InsightGenerator, Insight, InsightInput } from '../agent/rules/InsightGenerator';
import { WhatIfSimulator, WhatIfResult } from '../agent/rules/WhatIfSimulator';
import { MuscleBalanceAnalyzer, MuscleBalanceReport } from '../agent/rules/MuscleBalanceAnalyzer';
import { UserProfileStore } from '../data/UserProfileStore';
import { UserProfile } from '../model/UserProfile';
import { ThemeToggle } from '../components/ThemeToggle';
import { SectionCard } from '../components/SectionCard';

/** 月日历格子（训练日历与个人纪录合并卡用） */
interface ReportCalCell {
  /** 唯一键 */
  key: string;
  /** 日号（0 表示空白占位） */
  day: number;
  /** 日期键 YYYY-MM-DD（空白格为空串） */
  dateKey: string;
  /** 是否属于当前月 */
  inMonth: boolean;
  /** 当日训练次数（热力着色依据） */
  count: number;
  /** 是否选中 */
  selected: boolean;
  /** 是否今天 */
  isToday: boolean;
}

@Entry
@Component
struct ReportPage {
  @State theme: ThemeManager = ThemeManager.instance;
  @State isWeekly: boolean = true;
  @State stats: PeriodStats = { sessions: 0, totalDurationMin: 0, totalCalories: 0, avgLoad: 0 };
  @State goal: TrainingGoal = new TrainingGoal();
  // 二期：准备度 / 体重趋势 / 中周期
  @State readiness: ReadinessReport | null = null;
  @State weightTrend: WeightTrendReport | null = null;
  @State mesocycle: MesocyclePlan | null = null;
  // 四期：PR / 徽章 / 洞察 / What-if / 年度热力
  @State prList: ExercisePR[] = [];
  @State badges: Badge[] = [];
  @State insights: Insight[] = [];
  @State streak: number = 0;
  @State whatIfSessionsText: string = '4';
  @State whatIfCalorieText: string = '-300';
  @State whatIfResult: WhatIfResult | null = null;
  private calendarData: Map<string, number> = new Map<string, number>();
  // 训练日历 × 个人纪录合并卡：月日历状态
  @State private calYear: number = 2026;
  @State private calMonth: number = 0;
  @State private calMonthTitle: string = '';
  @State private calCells: ReportCalCell[] = [];
  @State private selectedDateKey: string = '';
  @State private dayLogs: WorkoutLog[] = [];
  @State private dayVolume: number = 0;
  @State private dayPRs: DailyPREvent[] = [];
  /** 日期 → 当日破纪录事件 */
  private prByDate: Map<string, DailyPREvent[]> = new Map<string, DailyPREvent[]>();
  private readonly weekHeaders: string[] = ['一', '二', '三', '四', '五', '六', '日'];
  private currentWeightKg: number = 0;
  private avgSessionLoad: number = 0;

  private historyStore: HistoryStore | null = null;
  private bodyStore: BodyMetricsStore | null = null;
  private wellnessStore: WellnessLogStore | null = null;
  private workoutStore: WorkoutLogStore | null = null;
  private profileStore: UserProfileStore | null = null;

  aboutToAppear(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.historyStore = new HistoryStore(context);
    this.bodyStore = new BodyMetricsStore(context);
    this.wellnessStore = new WellnessLogStore(context);
    this.workoutStore = new WorkoutLogStore(context);
    this.profileStore = new UserProfileStore(context);
    const goalStore: GoalStore = new GoalStore(context);
    this.goal = goalStore.load();
    const now: Date = new Date();
    this.calYear = now.getFullYear();
    this.calMonth = now.getMonth();
    this.refresh();
  }

  private refresh(): void {
    if (this.historyStore === null) {
      return;
    }
    this.stats = this.isWeekly ? this.historyStore.getWeeklyStats() : this.historyStore.getMonthlyStats();
    const history: HistoryEntry[] = this.historyStore.list();

    // 疲劳指数与准备度
    const fatigue: FatigueResult = FatigueModel.compute(history);
    let hoursSince: number = -1;
    if (history.length > 0) {
      hoursSince = (Date.now() - history[0].timestamp) / 3600000;
    }
    let sleepHours: number = 0;
    let sleepQuality: number = 0;
    let soreness: number = 0;
    const today: WellnessEntry | null = this.wellnessStore === null ? null : this.wellnessStore.getToday();
    if (today !== null) {
      sleepHours = today.sleepHours;
      sleepQuality = today.sleepQuality;
      soreness = today.soreness;
    }
    const readinessInput: ReadinessInput = {
      fatigueIndex: fatigue.index,
      sleepHours: sleepHours,
      sleepQuality: sleepQuality,
      soreness: soreness,
      hoursSinceLastTraining: hoursSince,
      consecutiveTrainingDays: this.countStreak(history)
    };
    this.readiness = ReadinessScorer.score(readinessInput);

    // 体重趋势
    if (this.bodyStore !== null) {
      this.weightTrend = WeightTrendAnalyzer.analyze(this.bodyStore.list());
    }

    // 中周期：平台期信号取「任一已记录动作连续无进步」
    let plateau: boolean = false;
    if (this.workoutStore !== null) {
      const logs: WorkoutLog[] = this.workoutStore.list();
      const ids: string[] = [];
      logs.forEach((log: WorkoutLog) => {
        if (ids.indexOf(log.exerciseId) < 0) {
          ids.push(log.exerciseId);
        }
      });
      for (let i: number = 0; i < ids.length; i++) {
        const perExercise: WorkoutLog[] =
          logs.filter((log: WorkoutLog) => log.exerciseId === ids[i]).reverse();
        if (ProgressiveOverloadPlanner.suggest(perExercise).plateau) {
          plateau = true;
          break;
        }
      }
    }
    this.mesocycle = MesocyclePlanner.plan(6, fatigue.index, plateau);
    this.refreshAchievements(history);
  }

  /** 四期聚合：PR / 徽章 / 洞察 / 年度热力数据 */
  private refreshAchievements(history: HistoryEntry[]): void {
    // 连续天数与最长连练
    this.streak = this.countStreak(history);
    const dayKeys: string[] = this.sortedDayKeys(history);
    let best: number = 0;
    let run: number = 0;
    for (let i: number = 0; i < dayKeys.length; i++) {
      if (run === 0) {
        run = 1;
      } else {
        const prev: number = Date.parse(`${dayKeys[i - 1]}T00:00:00`);
        const curr: number = Date.parse(`${dayKeys[i]}T00:00:00`);
        run = curr - prev === 86400000 ? run + 1 : 1;
      }
      best = Math.max(best, run);
    }
    best = Math.max(best, this.streak);

    // 训练容量聚合
    const now: number = Date.now();
    const dayMs: number = 86400000;
    let totalVolume: number = 0;
    let weeklyVolume: number = 0;
    let prevWeeklyVolume: number = 0;
    let plateauExercises: number = 0;
    let prCount: number = 0;
    let exercisesTried: number = 0;
    let allLogs: WorkoutLog[] = [];
    if (this.workoutStore !== null) {
      allLogs = this.workoutStore.list();
      const ids: string[] = [];
      allLogs.forEach((log: WorkoutLog) => {
        totalVolume += log.totalVolume();
        const age: number = now - log.timestamp;
        if (age < 7 * dayMs) {
          weeklyVolume += log.totalVolume();
        } else if (age < 14 * dayMs) {
          prevWeeklyVolume += log.totalVolume();
        }
        if (ids.indexOf(log.exerciseId) < 0) {
          ids.push(log.exerciseId);
        }
      });
      exercisesTried = ids.length;
      this.prList = PRTracker.summarize(allLogs);
      ids.forEach((id: string) => {
        const perExercise: WorkoutLog[] =
          allLogs.filter((log: WorkoutLog) => log.exerciseId === id).reverse();
        if (ProgressiveOverloadPlanner.suggest(perExercise).plateau) {
          plateauExercises++;
        }
        if (PRTracker.checkLatest(perExercise).isPR) {
          prCount++;
        }
      });
    }

    // 画像与体重
    let profileFilled: boolean = false;
    if (this.profileStore !== null) {
      const profile: UserProfile = this.profileStore.load();
      profileFilled = profile.filled;
      const trend: WeightTrendReport | null = this.weightTrend;
      if (trend !== null && trend.currentKg > 0) {
        this.currentWeightKg = trend.currentKg;
      } else if (profile.weightKg > 0) {
        this.currentWeightKg = profile.weightKg;
      }
    }

    // 单次平均负荷（What-if 基准）
    let totalLoad: number = 0;
    history.forEach((entry: HistoryEntry) => {
      totalLoad += entry.load;
    });
    this.avgSessionLoad = history.length > 0 ? Math.round(totalLoad / history.length) : 0;

    // 徽章
    const weeklyStats: PeriodStats = this.historyStore === null ?
      { sessions: 0, totalDurationMin: 0, totalCalories: 0, avgLoad: 0 } : this.historyStore.getWeeklyStats();
    let totalDuration: number = 0;
    history.forEach((entry: HistoryEntry) => {
      totalDuration += entry.durationMin;
    });
    const badgeStats: BadgeStats = {
      totalSessions: history.length,
      totalDurationMin: totalDuration,
      currentStreak: this.streak,
      bestStreak: best,
      weeklySessions: weeklyStats.sessions,
      weeklyTarget: this.goal.weeklySessions,
      weeklyVolumeKg: weeklyVolume,
      prevWeeklyVolumeKg: prevWeeklyVolume,
      totalVolumeKg: totalVolume,
      prCount: prCount,
      exercisesTried: exercisesTried,
      profileFilled: profileFilled
    };
    this.badges = BadgeEngine.evaluate(badgeStats);

    // 洞察
    const balance: MuscleBalanceReport = MuscleBalanceAnalyzer.analyze(
      this.workoutStore === null ? [] : this.workoutStore.weeklyLogs());
    const readinessSnap: ReadinessReport | null = this.readiness;
    const trendSnap: WeightTrendReport | null = this.weightTrend;
    const insightInput: InsightInput = {
      weeklySessions: weeklyStats.sessions,
      prevWeeklySessions: this.prevWeekSessions(history),
      weeklyVolumeKg: weeklyVolume,
      prevWeeklyVolumeKg: prevWeeklyVolume,
      streak: this.streak,
      readinessScore: readinessSnap === null ? -1 : readinessSnap.score,
      overtrainingLevel: readinessSnap === null ? '无' : readinessSnap.overtrainingLevel,
      imbalances: balance.imbalances,
      plateauExercises: plateauExercises,
      weightSlopeKgPerWeek: trendSnap === null ? 0 : trendSnap.slopeKgPerWeek,
      goal: profileFilled && this.profileStore !== null ? this.profileStore.load().goal : ''
    };
    this.insights = InsightGenerator.generate(insightInput);

    // 年度热力数据（日期 → 当日训练次数；历史记录与力量日志合并计数）
    const calendar: Map<string, number> = new Map<string, number>();
    history.forEach((entry: HistoryEntry) => {
      const key: string = WellnessLogStore.todayKey(entry.timestamp);
      calendar.set(key, (calendar.get(key) ?? 0) + 1);
    });
    allLogs.forEach((log: WorkoutLog) => {
      const key: string = log.dateKey();
      calendar.set(key, (calendar.get(key) ?? 0) + 1);
    });
    this.calendarData = calendar;
    // PR 事件按天聚合（点日历某天时展示当日纪录）
    const events: DailyPREvent[] = PRTracker.dailyPREvents(allLogs);
    const prGrouped: Map<string, DailyPREvent[]> = new Map<string, DailyPREvent[]>();
    events.forEach((event: DailyPREvent) => {
      const bucket: DailyPREvent[] = prGrouped.get(event.dateKey) ?? [];
      bucket.push(event);
      prGrouped.set(event.dateKey, bucket);
    });
    this.prByDate = prGrouped;
    this.rebuildCalendarCells();
    this.refreshDayDetail();

    // What-if 默认跑一次（用当前画像体重与平均负荷）
    this.runWhatIf();
  }

  /** 历史中出现过的训练日（升序 YYYY-MM-DD） */
  private sortedDayKeys(history: HistoryEntry[]): string[] {
    const keys: string[] = [];
    history.forEach((entry: HistoryEntry) => {
      const key: string = WellnessLogStore.todayKey(entry.timestamp);
      if (keys.indexOf(key) < 0) {
        keys.push(key);
      }
    });
    keys.sort();
    return keys;
  }

  /** 上周训练次数 */
  private prevWeekSessions(history: HistoryEntry[]): number {
    const now: number = Date.now();
    let count: number = 0;
    history.forEach((entry: HistoryEntry) => {
      const age: number = now - entry.timestamp;
      if (age >= 7 * 86400000 && age < 14 * 86400000) {
        count++;
      }
    });
    return count;
  }

  /** 运行 What-if 模拟 */
  private runWhatIf(): void {
    if (this.currentWeightKg <= 0) {
      this.whatIfResult = null;
      return;
    }
    const sessions: number = Number(this.whatIfSessionsText) >= 0 ? Number(this.whatIfSessionsText) : 0;
    const calorieDelta: number = Number(this.whatIfCalorieText);
    this.whatIfResult = WhatIfSimulator.simulate(this.currentWeightKg, sessions,
      this.avgSessionLoad, Number.isNaN(calorieDelta) ? 0 : calorieDelta);
  }

  /** 日期键（YYYY-MM-DD，本地时区） */
  private static dateKeyOf(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const month: string = `${date.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${date.getDate()}`.padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  /** 重建当前月日历格子（周一开头，标具体年月日，按当日训练次数着色） */
  private rebuildCalendarCells(): void {
    const year: number = this.calYear;
    const month: number = this.calMonth;
    this.calMonthTitle = `${year} 年 ${month + 1} 月`;
    const firstWeekday: number = (new Date(year, month, 1).getDay() + 6) % 7;
    const daysInMonth: number = new Date(year, month + 1, 0).getDate();
    const totalCells: number = Math.ceil((firstWeekday + daysInMonth) / 7) * 7;
    const todayKey: string = ReportPage.dateKeyOf(Date.now());
    const cells: ReportCalCell[] = [];
    for (let i: number = 0; i < totalCells; i++) {
      const offset: number = i - firstWeekday + 1;
      if (offset < 1 || offset > daysInMonth) {
        const pad: ReportCalCell = {
          key: `pad-${i}`, day: 0, dateKey: '', inMonth: false, count: 0, selected: false, isToday: false
        };
        cells.push(pad);
      } else {
        const key: string = ReportPage.dateKeyOf(new Date(year, month, offset).getTime());
        const cell: ReportCalCell = {
          key: `cur-${key}`, day: offset, dateKey: key, inMonth: true,
          count: this.calendarData.get(key) ?? 0,
          selected: key === this.selectedDateKey,
          isToday: key === todayKey
        };
        cells.push(cell);
      }
    }
    this.calCells = cells;
  }

  private shiftMonth(direction: number): void {
    const next: Date = new Date(this.calYear, this.calMonth + direction, 1);
    this.calYear = next.getFullYear();
    this.calMonth = next.getMonth();
    this.rebuildCalendarCells();
  }

  /** 点选某天：跳到「个人纪录」区查看当日记录；再点一次取消选中回到总榜 */
  private selectDay(cell: ReportCalCell): void {
    if (!cell.inMonth) {
      return;
    }
    this.selectedDateKey = cell.selected ? '' : cell.dateKey;
    this.rebuildCalendarCells();
    this.refreshDayDetail();
  }

  /** 刷新选中日明细：当日训练日志、容量与破纪录事件 */
  private refreshDayDetail(): void {
    if (this.selectedDateKey === '' || this.workoutStore === null) {
      this.dayLogs = [];
      this.dayVolume = 0;
      this.dayPRs = [];
      return;
    }
    const logs: WorkoutLog[] = this.workoutStore.listByDate(this.selectedDateKey);
    this.dayLogs = logs;
    let volume: number = 0;
    logs.forEach((log: WorkoutLog) => {
      volume += log.totalVolume();
    });
    this.dayVolume = volume;
    this.dayPRs = this.prByDate.get(this.selectedDateKey) ?? [];
  }

  /** 当日次数 → 格子底色（全部取自调色板） */
  private cellColor(count: number): string {
    if (count >= 3) {
      return this.theme.palette.warning;
    }
    if (count === 2) {
      return this.theme.palette.accent;
    }
    if (count === 1) {
      return this.theme.palette.success;
    }
    return this.theme.palette.cardBackground;
  }

  /** 日志行摘要：动作名 + 组数/次数/容量 */
  private dayLogSummary(log: WorkoutLog): string {
    const item: ExerciseItem | null = ExerciseLibrary.findById(log.exerciseId);
    const name: string = item === null ? log.exerciseId : item.name;
    const volume: number = log.totalVolume();
    if (volume > 0) {
      return `${name} · ${log.sets.length} 组 · 总次数 ${log.totalReps()} · 容量 ${volume} kg`;
    }
    return `${name} · ${log.sets.length} 组 · 总次数 ${log.totalReps()}`;
  }

  /** 连续训练天数（今天未训练时从昨天往前数） */
  private countStreak(history: HistoryEntry[]): number {
    const dayKeys: string[] = [];
    history.forEach((entry: HistoryEntry) => {
      const d: Date = new Date(entry.timestamp);
      const key: string = `${d.getFullYear()}-${`${d.getMonth() + 1}`.padStart(2, '0')}-` +
        `${`${d.getDate()}`.padStart(2, '0')}`;
      if (dayKeys.indexOf(key) < 0) {
        dayKeys.push(key);
      }
    });
    let cursor: number = Date.now();
    if (dayKeys.indexOf(WellnessLogStore.todayKey(cursor)) < 0) {
      cursor -= 86400000;
    }
    let streak: number = 0;
    for (let i: number = 0; i < 370; i++) {
      if (dayKeys.indexOf(WellnessLogStore.todayKey(cursor)) < 0) {
        break;
      }
      streak++;
      cursor -= 86400000;
    }
    return streak;
  }

  /** 周目标达成率（%，仅周视图有意义；次数与时长取较低者更保守） */
  private goalRate(): number {
    if (this.goal.weeklySessions <= 0) {
      return 0;
    }
    const sessionRate: number = this.stats.sessions * 100 / this.goal.weeklySessions;
    const durationRate: number = this.stats.totalDurationMin * 100 / this.goal.weeklyDurationMin;
    return Math.min(100, Math.round(Math.min(sessionRate, durationRate)));
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
          .accessibilityText('返回首页')
          .onClick(() => {
            router.back();
          })
        Text($r('app.string.report_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.primaryText)
          .margin({ left: 12 })
        Blank()
        ThemeToggle({ theme: this.theme })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // ===== 周/月切换 =====
      Row({ space: 8 }) {
        this.periodTab($r('app.string.report_weekly'), true)
        this.periodTab($r('app.string.report_monthly'), false)
      }
      .padding({ left: 16, right: 16, bottom: 12 })

      Scroll() {
        Column({ space: 12 }) {
          if (this.stats.sessions === 0) {
            Text($r('app.string.report_empty'))
              .fontSize(14)
              .fontColor(this.theme.palette.secondaryText)
              .margin({ top: 40 })
          } else {
            // ===== 统计卡片 =====
            Row({ space: 10 }) {
              this.statCard($r('app.string.report_sessions'), `${this.stats.sessions}`)
              this.statCard($r('app.string.report_avg_load'), `${this.stats.avgLoad}`)
            }
            .width('100%')
            Row({ space: 10 }) {
              this.statCard($r('app.string.report_duration'), `${this.stats.totalDurationMin}`)
              this.statCard($r('app.string.report_calories'), `${this.stats.totalCalories}`)
            }
            .width('100%')

            // ===== 周目标达成环 =====
            if (this.isWeekly) {
              Column({ space: 8 }) {
                Text($r('app.string.report_goal_rate'))
                  .fontSize(14)
                  .fontColor(this.theme.palette.secondaryText)
                Stack() {
                  Progress({ value: this.goalRate(), total: 100, type: ProgressType.Ring })
                    .width(120)
                    .height(120)
                    .color(this.theme.palette.accent)
                    .backgroundColor(this.theme.palette.track)
                  Text(`${this.goalRate()}%`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.theme.palette.primaryText)
                }
                .accessibilityText(`周目标达成率 ${this.goalRate()}%`)
                Text(`目标：每周 ${this.goal.weeklySessions} 次 · ${this.goal.weeklyDurationMin} 分钟`)
                  .fontSize(12)
                  .fontColor(this.theme.palette.secondaryText)
              }
              .width('100%')
              .padding(16)
              .borderRadius(14)
              .backgroundColor(this.theme.palette.cardBackground)
            }
          }

          // ===== 二期卡片：准备度 / 体重趋势 / 中周期（始终渲染，空态有引导文案） =====
          this.readinessCard(this.readiness)
          this.weightTrendCard(this.weightTrend)
          this.mesocycleCard(this.mesocycle)

          // ===== 四期卡片：日历与纪录合并卡 / 徽章 / 洞察 / What-if =====
          this.calendarPrCard()
          this.badgeCard()
          this.insightCard()
          this.whatIfCard(this.whatIfResult)
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

  /** 训练日历 × 个人纪录合并卡：月历标年月日、按次数着色，点日期在下方看当日记录与当日 PR */
  @Builder
  private calendarPrCard(): void {
    SectionCard({ theme: this.theme, title: '训练日历与个人纪录' }) {
      Text(`当前连续训练 ${this.streak} 天`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.theme.palette.primaryText)
        .margin({ bottom: 8 })
      // ===== 月日历（周一开头，‹ › 翻月） =====
      Row() {
        Button('‹')
          .fontSize(16)
          .fontColor(this.theme.palette.accent)
          .backgroundColor(this.theme.palette.inputBackground)
          .borderRadius(16)
          .width(40)
          .height(32)
          .accessibilityText('上个月')
          .onClick(() => {
            this.shiftMonth(-1);
          })
        Text(this.calMonthTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.palette.primaryText)
        Button('›')
          .fontSize(16)
          .fontColor(this.theme.palette.accent)
          .backgroundColor(this.theme.palette.inputBackground)
          .borderRadius(16)
          .width(40)
          .height(32)
          .accessibilityText('下个月')
          .onClick(() => {
            this.shiftMonth(1);
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 8 })
      Row() {
        ForEach(this.weekHeaders, (header: string) => {
          Text(header)
            .fontSize(12)
            .fontColor(this.theme.palette.secondaryText)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        }, (header: string) => header)
      }
      .width('100%')
      .margin({ bottom: 4 })
      Grid() {
        ForEach(this.calCells, (cell: ReportCalCell) => {
          GridItem() {
            Text(cell.day === 0 ? '' : `${cell.day}`)
              .fontSize(13)
              .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(!cell.inMonth ? this.theme.palette.track :
                cell.count > 0 ? this.theme.palette.onAccent : this.theme.palette.primaryText)
              .textAlign(TextAlign.Center)
              .width('100%')
              .height(36)
              .borderRadius(8)
              .backgroundColor(cell.inMonth ? this.cellColor(cell.count) : this.theme.palette.cardBackground)
              .borderWidth(cell.selected ? 2 : 0)
              .borderColor(this.theme.palette.primaryText)
              .onClick(() => {
                this.selectDay(cell);
              })
          }
        }, (cell: ReportCalCell) => cell.key)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .columnsGap(4)
      .rowsGap(4)
      .width('100%')
      Row({ space: 14 }) {
        this.calLegend(this.theme.palette.cardBackground, '无记录')
        this.calLegend(this.theme.palette.success, '1 次')
        this.calLegend(this.theme.palette.accent, '2 次')
        this.calLegend(this.theme.palette.warning, '≥3 次')
      }
      .width('100%')
      .margin({ top: 6, bottom: 10 })

      // ===== 个人纪录：选中日期时显示当日记录与当日 PR，否则显示总榜 =====
      if (this.selectedDateKey === '') {
        Text('个人纪录（PR）')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.palette.primaryText)
        Text('点击日历中某一天，可查看当日记录与破纪录事件')
          .fontSize(11)
          .fontColor(this.theme.palette.secondaryText)
          .margin({ top: 2, bottom: 4 })
        if (this.prList.length === 0) {
          Text('暂无力量训练纪录，在「记训练」中录入组数后自动生成')
            .fontSize(13)
            .fontColor(this.theme.palette.secondaryText)
            .lineHeight(18)
        } else {
          ForEach(this.prList.slice(0, 8), (pr: ExercisePR) => {
            Row() {
              Text(pr.exerciseName)
                .fontSize(13)
                .fontColor(this.theme.palette.primaryText)
                .layoutWeight(1)
              Text(pr.maxWeightKg > 0 ?
                `${pr.maxWeightKg}kg · 1RM≈${pr.bestOneRepMax}kg` : `${pr.bestTotalReps} 次`)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.theme.palette.accent)
              Text(` · ${pr.sessions} 次`)
                .fontSize(12)
                .fontColor(this.theme.palette.secondaryText)
            }
            .width('100%')
            .margin({ top: 6 })
          }, (pr: ExercisePR) => pr.exerciseId)
          if (this.prList.length > 8) {
            Text(`…共 ${this.prList.length} 个动作有纪录`)
              .fontSize(12)
              .fontColor(this.theme.palette.secondaryText)
              .margin({ top: 6 })
          }
        }
      } else {
        Row() {
          Text(`当日记录 · ${this.selectedDateKey}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.theme.palette.primaryText)
            .layoutWeight(1)
          Button('‹ 全部纪录')
            .fontSize(12)
            .fontColor(this.theme.palette.accent)
            .backgroundColor(this.theme.palette.inputBackground)
            .borderRadius(14)
            .height(28)
            .accessibilityText('返回个人纪录总榜')
            .onClick(() => {
              this.selectedDateKey = '';
              this.rebuildCalendarCells();
              this.refreshDayDetail();
            })
        }
        .width('100%')
        if (this.dayLogs.length === 0) {
          Text('当日无训练记录')
            .fontSize(13)
            .fontColor(this.theme.palette.secondaryText)
            .margin({ top: 6 })
        } else {
          ForEach(this.dayLogs, (log: WorkoutLog) => {
            Text(this.dayLogSummary(log))
              .fontSize(13)
              .fontColor(this.theme.palette.primaryText)
              .width('100%')
              .margin({ top: 6 })
          }, (log: WorkoutLog) => `${log.timestamp}-${log.exerciseId}`)
          if (this.dayVolume > 0) {
            Text(`当日总容量：${this.dayVolume} kg`)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.theme.palette.accent)
              .margin({ top: 4 })
          }
        }
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

  @Builder
  private calLegend(color: string, label: string): void {
    Row({ space: 4 }) {
      Text()
        .width(10)
        .height(10)
        .borderRadius(2)
        .backgroundColor(color)
      Text(label)
        .fontSize(11)
        .fontColor(this.theme.palette.secondaryText)
    }
  }

  /** 徽章墙（达成彩色 / 未达成置灰 + 进度） */
  @Builder
  private badgeCard(): void {
    SectionCard({ theme: this.theme, title: `成就徽章（${BadgeEngine.earnedCount(this.badges)}/${this.badges.length}）` }) {
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.badges, (badge: Badge) => {
          Column({ space: 4 }) {
            Text(badge.earned ? '🏅' : '🔒')
              .fontSize(20)
            Text(badge.name)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(badge.earned ? this.theme.palette.accent : this.theme.palette.secondaryText)
            Text(badge.earned ? '已达成' : `${badge.progress}%`)
              .fontSize(10)
              .fontColor(this.theme.palette.secondaryText)
          }
          .padding(8)
          .width('24%')
          .margin({ bottom: 8 })
          .borderRadius(10)
          .backgroundColor(this.theme.palette.inputBackground)
          .accessibilityText(`${badge.name}：${badge.description}，${badge.earned ? '已达成' : `进度 ${badge.progress}%`}`)
        }, (badge: Badge) => badge.id)
      }
      .width('100%')
    }
  }

  /** 洞察卡（模板化结论 + 依据） */
  @Builder
  private insightCard(): void {
    SectionCard({ theme: this.theme, title: '训练洞察' }) {
      ForEach(this.insights, (insight: Insight) => {
        Column({ space: 2 }) {
          Text(insight.text)
            .fontSize(13)
            .fontColor(insight.sentiment === '负' ?
              this.theme.palette.warning : this.theme.palette.primaryText)
            .lineHeight(18)
          Text(insight.evidence)
            .fontSize(11)
            .fontColor(this.theme.palette.secondaryText)
            .lineHeight(15)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .margin({ top: 6 })
      }, (insight: Insight) => insight.text)
    }
  }

  /** What-if 情景模拟卡（参数局部收窄） */
  @Builder
  private whatIfCard(result: WhatIfResult | null): void {
    SectionCard({ theme: this.theme, title: 'What-if 情景模拟' }) {
      if (this.currentWeightKg <= 0) {
        Text('先在「用户画像」中填写体重，再模拟未来趋势')
          .fontSize(13)
          .fontColor(this.theme.palette.secondaryText)
          .lineHeight(18)
      } else {
        Row({ space: 10 }) {
          Column({ space: 4 }) {
            Text('每周训练次数')
              .fontSize(12)
              .fontColor(this.theme.palette.secondaryText)
            TextInput({ text: this.whatIfSessionsText })
              .type(InputType.Number)
              .fontColor(this.theme.palette.primaryText)
              .backgroundColor(this.theme.palette.inputBackground)
              .borderRadius(8)
              .accessibilityText('假设的每周训练次数')
              .onChange((v: string) => {
                this.whatIfSessionsText = v;
              })
          }
          .layoutWeight(1)
          Column({ space: 4 }) {
            Text('每日热量增减（kcal）')
              .fontSize(12)
              .fontColor(this.theme.palette.secondaryText)
            TextInput({ text: this.whatIfCalorieText })
              .type(InputType.Number)
              .fontColor(this.theme.palette.primaryText)
              .backgroundColor(this.theme.palette.inputBackground)
              .borderRadius(8)
              .accessibilityText('假设的每日热量增减，负数为缺口')
              .onChange((v: string) => {
                this.whatIfCalorieText = v;
              })
          }
          .layoutWeight(1)
        }
        .width('100%')
        Button('模拟 4 / 8 周趋势')
          .fontSize(14)
          .fontColor(this.theme.palette.onAccent)
          .backgroundColor(this.theme.palette.accent)
          .borderRadius(18)
          .height(36)
          .width('100%')
          .margin({ top: 10 })
          .accessibilityText('运行 What-if 模拟')
          .onClick(() => {
            this.runWhatIf();
          })
        if (result !== null) {
          Text(result.note)
            .fontSize(13)
            .fontColor(this.theme.palette.primaryText)
            .lineHeight(18)
            .margin({ top: 10 })
          Text(`负荷累积：4 周 ${result.load4Week} · 8 周 ${result.load8Week}` +
            `（基于单次平均负荷 ${this.avgSessionLoad}）`)
            .fontSize(12)
            .fontColor(this.theme.palette.secondaryText)
            .lineHeight(16)
            .margin({ top: 4 })
        }
      }
    }
  }

  /** 准备度卡（疲劳 + 睡眠 + 酸痛 + 距上次训练 → 当日强度档与过度训练预警；参数局部收窄） */
  @Builder
  private readinessCard(report: ReadinessReport | null): void {
    SectionCard({ theme: this.theme, title: '今日准备度' }) {
      if (report === null) {
        Text('暂无数据')
          .fontSize(13)
          .fontColor(this.theme.palette.secondaryText)
      } else {
        Row({ space: 16 }) {
          Stack() {
            Progress({ value: report.score, total: 100, type: ProgressType.Ring })
              .width(84)
              .height(84)
              .color(report.score >= 50 ? this.theme.palette.accent : this.theme.palette.warning)
              .backgroundColor(this.theme.palette.track)
            Text(`${report.score}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.theme.palette.primaryText)
          }
          .accessibilityText(`准备度 ${report.score} 分`)
          Column({ space: 4 }) {
            Text(`建议强度：${report.tier}`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.theme.palette.primaryText)
            Text(report.overtrainingLevel === '无' ?
              '无过度训练风险' : `过度训练${report.overtrainingLevel}色预警`)
              .fontSize(13)
              .fontColor(report.overtrainingLevel === '无' ?
                this.theme.palette.success : this.theme.palette.danger)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        ForEach(report.notes, (note: string) => {
          Text(`· ${note}`)
            .fontSize(12)
            .fontColor(this.theme.palette.secondaryText)
            .lineHeight(17)
            .margin({ top: 4 })
        }, (note: string) => note)
      }
    }
  }

  /** 体重趋势卡（14 天最小二乘 + 4 周预测 + 平台期提示；参数局部收窄） */
  @Builder
  private weightTrendCard(trend: WeightTrendReport | null): void {
    SectionCard({ theme: this.theme, title: '体重趋势' }) {
      if (trend === null || trend.samples < 2) {
        Text('体重数据不足，在「用户画像」中更新体重后，这里会显示趋势与 4 周预测')
          .fontSize(13)
          .fontColor(this.theme.palette.secondaryText)
          .lineHeight(18)
      } else {
        Row({ space: 16 }) {
          Column({ space: 4 }) {
            Text(`${trend.currentKg} kg`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.theme.palette.primaryText)
            Text('当前体重')
              .fontSize(11)
              .fontColor(this.theme.palette.secondaryText)
          }
          Column({ space: 4 }) {
            Text(`${trend.slopeKgPerWeek > 0 ? '+' : ''}${trend.slopeKgPerWeek} kg/周`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.theme.palette.accent)
            Text(`4 周预测 ${trend.forecast4WeekKg} kg`)
              .fontSize(12)
              .fontColor(this.theme.palette.secondaryText)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        Text(trend.note)
          .fontSize(12)
          .fontColor(trend.plateau ? this.theme.palette.warning : this.theme.palette.secondaryText)
          .lineHeight(17)
          .margin({ top: 8 })
      }
    }
  }

  /** 中周期卡（波浪渐进 + 减载周安排；参数局部收窄） */
  @Builder
  private mesocycleCard(plan: MesocyclePlan | null): void {
    SectionCard({ theme: this.theme, title: '中周期负荷编排' }) {
      if (plan === null) {
        Text('暂无数据')
          .fontSize(13)
          .fontColor(this.theme.palette.secondaryText)
      } else {
        Text(plan.note)
          .fontSize(13)
          .fontColor(plan.deloadAdvised ? this.theme.palette.danger : this.theme.palette.secondaryText)
          .lineHeight(18)
        ForEach(plan.weeks, (week: MesocycleWeek) => {
          Row() {
            Text(`第 ${week.weekIndex} 周`)
              .fontSize(13)
              .fontColor(this.theme.palette.primaryText)
              .width(56)
            Text(week.isDeload ? '减载' : `容量 ${week.volumePct}%`)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(week.isDeload ? this.theme.palette.warning : this.theme.palette.accent)
              .width(96)
            Text(`强度 ${week.intensityPct}%`)
              .fontSize(12)
              .fontColor(this.theme.palette.secondaryText)
          }
          .width('100%')
          .margin({ top: 6 })
        }, (week: MesocycleWeek) => `${week.weekIndex}`)
      }
    }
  }

  @Builder
  private periodTab(label: string | Resource, weekly: boolean): void {
    Text(label)
      .fontSize(14)
      .fontColor(this.isWeekly === weekly ? this.theme.palette.onAccent : this.theme.palette.primaryText)
      .textAlign(TextAlign.Center)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .borderRadius(18)
      .backgroundColor(this.isWeekly === weekly ?
        this.theme.palette.accent : this.theme.palette.inputBackground)
      .onClick(() => {
        this.isWeekly = weekly;
        this.refresh();
      })
  }

  @Builder
  private statCard(label: string | Resource, value: string): void {
    Column({ space: 6 }) {
      Text(value)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme.palette.accent)
      Text(label)
        .fontSize(12)
        .fontColor(this.theme.palette.secondaryText)
    }
    .alignItems(HorizontalAlign.Center)
    .padding(16)
    .borderRadius(14)
    .backgroundColor(this.theme.palette.cardBackground)
    .layoutWeight(1)
  }
}
