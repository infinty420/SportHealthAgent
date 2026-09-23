/*
 * 文件标注：AI 生成 —— 发现页：训练历史日历 + 按天明细 + 数据统计（通用 UI 脚手架）
 *
 * 可视化 UI 层 · 发现
 * 1. 训练历史：月日历（周一开头，含邻月补齐灰格，支持翻月），有训练的日子标圆点；
 * 2. 当日明细：选中日期的动作列表、组数/容量汇总与当日破纪录事件（PR 按天分类）；
 * 3. 数据统计：周/月/年切换 + 范围翻页，
 *    部位频次人体热力、部位组数环形图、训练时长环比、分部位容量卡。
 * 数据全部来自本地 WorkoutLogStore / HistoryStore，确定性规则聚合，无网络请求。
 * 主题约束：本文件不出现任何硬编码色值，一律读取 theme.palette.*。
 */
import { common } from '@kit.AbilityKit';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeToggle } from '../components/ThemeToggle';
import { HeatColorUtil } from '../utils/HeatColorUtil';
import { BodyPathData } from '../data/BodyPathData';
import { SectionCard } from '../components/SectionCard';
import { ExerciseItem, ExerciseLibrary } from '../data/ExerciseLibrary';
import { WorkoutLog } from '../model/WorkoutLog';
import { WorkoutLogStore } from '../data/WorkoutLogStore';
import { HistoryEntry, HistoryStore } from '../data/HistoryStore';
import { PRTracker, DailyPREvent } from '../agent/rules/PRTracker';
import {
  TrainingStatsAggregator, StatsPeriod, StatsRange, MuscleStat, VolumeBestDay, HEAT_MUSCLE_GROUPS
} from '../agent/rules/TrainingStatsAggregator';

/** 日历格子（@Builder/ForEach 传参类型） */
interface CalCell {
  /** 唯一键 */
  key: string;
  /** 日号（0 表示空白占位） */
  day: number;
  /** 日期键 YYYY-MM-DD（空白格为空串） */
  dateKey: string;
  /** 是否属于当前月 */
  inMonth: boolean;
  /** 当日是否有训练日志 */
  hasLog: boolean;
  /** 是否选中 */
  selected: boolean;
  /** 是否今天 */
  isToday: boolean;
}

/** 环形图图例行 */
interface DonutLegendItem {
  name: string;
  sets: number;
  colorIndex: number;
}

@Component
export struct HistoryCalendar {
  @State theme: ThemeManager = ThemeManager.instance;
  /** 父级 Tabs 切换信号：值变化时重载日历与统计数据（替代页面级 onPageShow） */
  @Prop @Watch('reloadAll') refreshTick: number = 0;
  private logStore: WorkoutLogStore | null = null;
  private historyStore: HistoryStore | null = null;

  // ===== 原始数据 =====
  @State private allLogs: WorkoutLog[] = [];
  @State private historyEntries: HistoryEntry[] = [];
  /** 日期 → 日志条数（日历圆点） */
  private dateCounts: Map<string, number> = new Map<string, number>();
  /** 日期 → 当日破纪录事件 */
  private prByDate: Map<string, DailyPREvent[]> = new Map<string, DailyPREvent[]>();

  // ===== 日历状态 =====
  @State private calYear: number = 2026;
  @State private calMonth: number = 0;
  @State private cells: CalCell[] = [];
  @State private monthTitle: string = '';
  @State private selectedDateKey: string = '';
  private readonly weekHeaders: string[] = ['一', '二', '三', '四', '五', '六', '日'];
  private readonly periodModes: string[] = ['week', 'month', 'year'];

  // ===== 当日明细 =====
  @State private dayLogs: WorkoutLog[] = [];
  @State private dayVolume: number = 0;
  @State private dayPRs: DailyPREvent[] = [];

  // ===== 数据统计 =====
  @State private periodMode: StatsPeriod = 'week';
  @State private rangeAnchor: number = Date.now();
  @State private rangeLabel: string = '';
  @State private stats: MuscleStat[] = [];
  @State private totalSets: number = 0;
  @State private rangeLogCount: number = 0;
  @State private durCurrent: number = 0;
  @State private durPrev: number = 0;
  @State private volMuscle: string = '胸';
  @State private volTotal: number = 0;
  @State private volBestDate: string = '';
  @State private volBestKg: number = 0;
  @State private legendItems: DonutLegendItem[] = [];

  // ===== Canvas =====
  private heatCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private donutCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private durCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  @State private heatCanvasKey: string = 'heat-0';
  @State private donutCanvasKey: string = 'donut-0';
  @State private durCanvasKey: string = 'dur-0';

  // ===== 2.5D 热力增强 =====
  /** 热力指标：sessions 频次 / effectiveSets 组数 / volumeKg 容量 */
  @State private heatMetric: string = 'sessions';
  /** 部位图例点击选中（描边高亮；空串表示未选中） */
  @State private heatHighlight: string = '';
  /** 部位点击气泡（2 秒自动消失） */
  @State private heatTip: string = '';
  @State private heatTipVisible: boolean = false;
  /** 部位点击命中区域（色斑键 → [cx, cy, r] 像素坐标） */
  private heatHitMap: Map<string, number[]> = new Map<string, number[]>();

  aboutToAppear(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.logStore = new WorkoutLogStore(context);
    this.historyStore = new HistoryStore(context);
    const now: Date = new Date();
    this.calYear = now.getFullYear();
    this.calMonth = now.getMonth();
    this.selectedDateKey = HistoryCalendar.dateKeyOf(now.getTime());
    this.reloadAll();
  }

  /** 日期键（与 WorkoutLog.dateKey 同规则：YYYY-MM-DD 本地时区） */
  private static dateKeyOf(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const month: string = `${date.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${date.getDate()}`.padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  /** 全量刷新：日志/历史/PR 事件索引 → 日历 + 明细 + 统计 */
  private reloadAll(): void {
    if (this.logStore !== null) {
      this.allLogs = this.logStore.list();
    }
    if (this.historyStore !== null) {
      this.historyEntries = this.historyStore.list();
    }
    const counts: Map<string, number> = new Map<string, number>();
    this.allLogs.forEach((log: WorkoutLog) => {
      const key: string = log.dateKey();
      counts.set(key, (counts.get(key) ?? 0) + 1);
    });
    this.dateCounts = counts;
    const events: DailyPREvent[] = PRTracker.dailyPREvents(this.allLogs);
    const grouped: Map<string, DailyPREvent[]> = new Map<string, DailyPREvent[]>();
    events.forEach((event: DailyPREvent) => {
      const bucket: DailyPREvent[] = grouped.get(event.dateKey) ?? [];
      bucket.push(event);
      grouped.set(event.dateKey, bucket);
    });
    this.prByDate = grouped;
    this.rebuildCalendar();
    this.refreshDayDetail();
    this.refreshStats();
  }

  // ==================== 日历 ====================

  /** 重建当前月日历格子（周一开头，邻月补齐灰格） */
  private rebuildCalendar(): void {
    const year: number = this.calYear;
    const month: number = this.calMonth;
    this.monthTitle = `${year} 年 ${month + 1} 月`;
    const firstWeekday: number = (new Date(year, month, 1).getDay() + 6) % 7;
    const daysInMonth: number = new Date(year, month + 1, 0).getDate();
    const prevMonthDays: number = new Date(year, month, 0).getDate();
    const totalCells: number = Math.ceil((firstWeekday + daysInMonth) / 7) * 7;
    const todayKey: string = HistoryCalendar.dateKeyOf(Date.now());
    const cells: CalCell[] = [];
    for (let i: number = 0; i < totalCells; i++) {
      const offset: number = i - firstWeekday + 1;
      let cell: CalCell;
      if (offset < 1) {
        // 上月灰格
        const day: number = prevMonthDays + offset;
        cell = {
          key: `prev-${i}`, day: day, dateKey: '', inMonth: false,
          hasLog: false, selected: false, isToday: false
        };
      } else if (offset > daysInMonth) {
        // 下月灰格
        cell = {
          key: `next-${i}`, day: offset - daysInMonth, dateKey: '', inMonth: false,
          hasLog: false, selected: false, isToday: false
        };
      } else {
        const key: string = HistoryCalendar.dateKeyOf(new Date(year, month, offset).getTime());
        cell = {
          key: `cur-${key}`, day: offset, dateKey: key, inMonth: true,
          hasLog: (this.dateCounts.get(key) ?? 0) > 0,
          selected: key === this.selectedDateKey,
          isToday: key === todayKey
        };
      }
      cells.push(cell);
    }
    this.cells = cells;
  }

  private shiftMonth(direction: number): void {
    const next: Date = new Date(this.calYear, this.calMonth + direction, 1);
    this.calYear = next.getFullYear();
    this.calMonth = next.getMonth();
    this.rebuildCalendar();
  }

  private selectDay(cell: CalCell): void {
    if (!cell.inMonth) {
      return;
    }
    this.selectedDateKey = cell.dateKey;
    this.rebuildCalendar();
    this.refreshDayDetail();
  }

  // ==================== 当日明细 ====================

  private refreshDayDetail(): void {
    if (this.logStore === null) {
      return;
    }
    const logs: WorkoutLog[] = this.logStore.listByDate(this.selectedDateKey);
    this.dayLogs = logs;
    let volume: number = 0;
    logs.forEach((log: WorkoutLog) => {
      volume += log.totalVolume();
    });
    this.dayVolume = volume;
    this.dayPRs = this.prByDate.get(this.selectedDateKey) ?? [];
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

  // ==================== 数据统计 ====================

  private setPeriod(mode: string): void {
    if (mode === 'month') {
      this.periodMode = 'month';
    } else if (mode === 'year') {
      this.periodMode = 'year';
    } else {
      this.periodMode = 'week';
    }
    this.rangeAnchor = Date.now();
    this.refreshStats();
  }

  private shiftRange(direction: number): void {
    this.rangeAnchor = TrainingStatsAggregator.shiftAnchor(this.periodMode, this.rangeAnchor, direction);
    this.refreshStats();
  }

  /** 统计区全量刷新（范围标签 + 部位聚合 + 时长环比 + 容量卡） */
  private refreshStats(): void {
    const range: StatsRange = TrainingStatsAggregator.rangeFor(this.periodMode, this.rangeAnchor);
    this.rangeLabel = range.label;
    const inRange: WorkoutLog[] = TrainingStatsAggregator.filterLogs(this.allLogs, range);
    this.rangeLogCount = inRange.length;
    const stats: MuscleStat[] = TrainingStatsAggregator.muscleStats(inRange);
    this.stats = stats;
    let sets: number = 0;
    const legends: DonutLegendItem[] = [];
    stats.forEach((stat: MuscleStat, idx: number) => {
      sets += stat.effectiveSets;
      if (stat.effectiveSets > 0) {
        const item: DonutLegendItem = { name: stat.muscle, sets: stat.effectiveSets, colorIndex: idx };
        legends.push(item);
      }
    });
    this.totalSets = sets;
    this.legendItems = legends;
    // 时长环比（历史记录口径）
    const prevAnchor: number = TrainingStatsAggregator.shiftAnchor(this.periodMode, this.rangeAnchor, -1);
    const prevRange: StatsRange = TrainingStatsAggregator.rangeFor(this.periodMode, prevAnchor);
    this.durCurrent = TrainingStatsAggregator.durationMin(this.historyEntries, range);
    this.durPrev = TrainingStatsAggregator.durationMin(this.historyEntries, prevRange);
    this.refreshVolumeCard(inRange);
    // 强制重建三个 Canvas 触发重绘
    const stamp: number = Date.now() % 100000;
    this.heatCanvasKey = `heat-${stamp}`;
    this.donutCanvasKey = `donut-${stamp}`;
    this.durCanvasKey = `dur-${stamp}`;
  }

  private refreshVolumeCard(inRange: WorkoutLog[]): void {
    let total: number = 0;
    this.stats.forEach((stat: MuscleStat) => {
      if (stat.muscle === this.volMuscle) {
        total = stat.volumeKg;
      }
    });
    this.volTotal = total;
    const best: VolumeBestDay | null = TrainingStatsAggregator.bestVolumeDay(inRange, this.volMuscle);
    if (best === null) {
      this.volBestDate = '';
      this.volBestKg = 0;
    } else {
      this.volBestDate = best.dateKey;
      this.volBestKg = best.volumeKg;
    }
  }

  private pickVolMuscle(muscle: string): void {
    this.volMuscle = muscle;
    const range: StatsRange = TrainingStatsAggregator.rangeFor(this.periodMode, this.rangeAnchor);
    const inRange: WorkoutLog[] = TrainingStatsAggregator.filterLogs(this.allLogs, range);
    this.refreshVolumeCard(inRange);
  }

  private periodWord(): string {
    if (this.periodMode === 'week') {
      return '本周';
    }
    if (this.periodMode === 'month') {
      return '本月';
    }
    return '今年';
  }

  /** 时长环比文案 */
  private durationCompareText(): string {
    const diff: number = this.durCurrent - this.durPrev;
    if (diff >= 0) {
      return `${this.periodWord()}训练时长比上一周期 增加了 ${diff} 分钟 ↑`;
    }
    return `${this.periodWord()}训练时长比上一周期 减少了 ${-diff} 分钟 ↓`;
  }

  // ==================== Canvas 绘制 ====================

  /** 部位组 → 聚合结果（条件查找，避免动态索引） */
  private statOf(group: string): MuscleStat | null {
    let found: MuscleStat | null = null;
    this.stats.forEach((item: MuscleStat) => {
      if (item.muscle === group) {
        found = item;
      }
    });
    return found;
  }

  /** 部位组 → 当前热力指标值 */
  private metricValueOf(group: string): number {
    const stat: MuscleStat | null = this.statOf(group);
    if (stat === null) {
      return 0;
    }
    if (this.heatMetric === 'effectiveSets') {
      return stat.effectiveSets;
    }
    if (this.heatMetric === 'volumeKg') {
      return stat.volumeKg;
    }
    return stat.sessions;
  }

  /** 当前指标 → 0-3 档（频次 0/1-2/3-4/≥5；组数 0/1-5/6-15/>15；容量 0/<50/50-150/>150） */
  private metricTierOf(group: string): number {
    const value: number = this.metricValueOf(group);
    if (value <= 0) {
      return 0;
    }
    if (this.heatMetric === 'effectiveSets') {
      if (value <= 5) {
        return 1;
      }
      if (value <= 15) {
        return 2;
      }
      return 3;
    }
    if (this.heatMetric === 'volumeKg') {
      if (value < 50) {
        return 1;
      }
      if (value <= 150) {
        return 2;
      }
      return 3;
    }
    if (value <= 2) {
      return 1;
    }
    if (value <= 4) {
      return 2;
    }
    return 3;
  }

  /** 档位 → 热力色（全部取自调色板） */
  private metricColor(group: string): string {
    const tier: number = this.metricTierOf(group);
    if (tier <= 0) {
      return this.theme.palette.track;
    }
    if (tier === 1) {
      return this.theme.palette.success;
    }
    if (tier === 2) {
      return this.theme.palette.accent;
    }
    return this.theme.palette.warning;
  }

  /** 部位最近一次训练日期（全部日志范围，tooltip 用） */
  private lastDateOf(group: string): string {
    let latest: string = '';
    this.allLogs.forEach((log: WorkoutLog) => {
      const item: ExerciseItem | null = ExerciseLibrary.findById(log.exerciseId);
      if (item === null) {
        return;
      }
      if (TrainingStatsAggregator.groupOf(item.muscle) !== group) {
        return;
      }
      const key: string = log.dateKey();
      if (key > latest) {
        latest = key;
      }
    });
    return latest.length === 0 ? '-' : latest;
  }

  /** 部位点击：按色斑圆心距离命中 → 弹出统计气泡，2 秒后自动消失 */
  private onHeatTap(x: number, y: number): void {
    let hitGroup: string = '';
    this.heatHitMap.forEach((spot: number[], key: string) => {
      const dx: number = x - spot[0];
      const dy: number = y - spot[1];
      if (hitGroup.length === 0 && dx * dx + dy * dy <= (spot[2] + 6) * (spot[2] + 6)) {
        hitGroup = BodyPathData.groupOf(key);
      }
    });
    if (hitGroup.length === 0) {
      return;
    }
    const stat: MuscleStat | null = this.statOf(hitGroup);
    if (stat === null || stat.sessions === 0) {
      this.heatTip = `${hitGroup}：本周期暂无训练`;
    } else {
      this.heatTip = `${hitGroup}：${stat.sessions} 次 · ${stat.effectiveSets} 组 · ` +
        `${stat.volumeKg} kg · 最近 ${this.lastDateOf(hitGroup)}`;
    }
    this.heatTipVisible = true;
    setTimeout(() => {
      this.heatTipVisible = false;
    }, 2000);
  }

  /** 环形图分段色（调色板轮换） */
  private segColor(index: number): string {
    const mod: number = index % 7;
    if (mod === 0) {
      return this.theme.palette.accent;
    }
    if (mod === 1) {
      return this.theme.palette.success;
    }
    if (mod === 2) {
      return this.theme.palette.warning;
    }
    if (mod === 3) {
      return this.theme.palette.danger;
    }
    if (mod === 4) {
      return this.theme.palette.carb;
    }
    if (mod === 5) {
      return this.theme.palette.fat;
    }
    return this.theme.palette.secondaryText;
  }

  /** Canvas 字体（vp 规格 → 物理 px，解决高分屏文字过小问题） */
  private canvasFont(vpSize: number, bold: boolean): string {
    const px: number = Math.round(vp2px(vpSize));
    return bold ? `bold ${px}px sans-serif` : `${px}px sans-serif`;
  }

  /** 绘制热力发光色斑（叠加在真人轮廓底图上），颜色按当前指标档位 */
  private drawHeat(): void {
    const ctx: CanvasRenderingContext2D = this.heatCtx;
    ctx.clearRect(0, 0, 320, 190);
    // 图注（与底图两个人体居中对齐）
    ctx.fillStyle = this.theme.palette.secondaryText;
    ctx.font = this.canvasFont(12, false);
    ctx.textAlign = 'center';
    ctx.fillText('正面', 100, 12);
    ctx.fillText('背面', 220, 12);
    // 命中区域每次重绘重建
    this.heatHitMap.clear();
    this.drawSpots(ctx, BodyPathData.getFrontSpots(), 100);
    this.drawSpots(ctx, BodyPathData.getBackSpots(), 220);
  }

  /** 单个人体的热力色斑：径向渐变发光 + 选中描边 + 训练日红点标记 */
  private drawSpots(ctx: CanvasRenderingContext2D, spots: Map<string, number[]>, centerX: number): void {
    const bodyW: number = 95;
    const bodyH: number = 190;
    spots.forEach((spot: number[], key: string) => {
      const group: string = BodyPathData.groupOf(key);
      const tier: number = this.metricTierOf(group);
      const base: string = this.metricColor(group);
      const cx: number = centerX + (spot[0] - 50) / 100 * bodyW;
      const cy: number = spot[1] / 100 * bodyH;
      const r: number = spot[2] / 100 * bodyW * 1.15;
      // 部位点击命中区域（像素坐标）
      this.heatHitMap.set(key, [cx, cy, r]);
      // 径向渐变发光斑（中心亮、边缘淡出，颜色由调色板基色推导）
      const gradient: CanvasGradient = ctx.createRadialGradient(cx, cy, r * 0.1, cx, cy, r);
      gradient.addColorStop(0, HeatColorUtil.alphaColor(HeatColorUtil.shadeColor(base, 0.15), tier > 0 ? 0.8 : 0.4));
      gradient.addColorStop(1, HeatColorUtil.alphaColor(base, 0.04));
      ctx.fillStyle = gradient;
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, Math.PI * 2);
      ctx.fill();
      // 部位图例点击选中：描边高亮
      if (this.heatHighlight === group) {
        ctx.beginPath();
        ctx.arc(cx, cy, r + 2, 0, Math.PI * 2);
        ctx.strokeStyle = this.theme.palette.accent;
        ctx.lineWidth = 2;
        ctx.stroke();
      }
      // 训练日标记：有训练的部位中心画红点 + 频次数（成对部位只在左侧画一次）
      const stat: MuscleStat | null = this.statOf(group);
      if (stat !== null && stat.sessions > 0 && !key.endsWith('右')) {
        ctx.beginPath();
        ctx.fillStyle = this.theme.palette.danger;
        ctx.arc(cx, cy, 8, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = this.theme.palette.onHero;
        ctx.font = this.canvasFont(10, true);
        ctx.textAlign = 'center';
        ctx.fillText(`${stat.sessions}`, cx, cy + 3);
      }
    });
  }

  /** 绘制部位组数环形图（中心显示总组数） */
  private drawDonut(): void {
    const ctx: CanvasRenderingContext2D = this.donutCtx;
    ctx.clearRect(0, 0, 200, 200);
    const cx: number = 100;
    const cy: number = 100;
    const outer: number = 92;
    const inner: number = 56;
    if (this.totalSets <= 0) {
      ctx.fillStyle = this.theme.palette.track;
      ctx.beginPath();
      ctx.arc(cx, cy, outer, 0, Math.PI * 2);
      ctx.arc(cx, cy, inner, 0, Math.PI * 2, true);
      ctx.closePath();
      ctx.fill();
    } else {
      let angle: number = -Math.PI / 2;
      this.stats.forEach((stat: MuscleStat, idx: number) => {
        if (stat.effectiveSets <= 0) {
          return;
        }
        const sweep: number = stat.effectiveSets / this.totalSets * Math.PI * 2;
        ctx.fillStyle = this.segColor(idx);
        ctx.beginPath();
        ctx.arc(cx, cy, outer, angle, angle + sweep);
        ctx.arc(cx, cy, inner, angle + sweep, angle, true);
        ctx.closePath();
        ctx.fill();
        angle += sweep;
      });
    }
    // 中心总组数
    ctx.fillStyle = this.theme.palette.primaryText;
    ctx.font = this.canvasFont(32, true);
    ctx.textAlign = 'center';
    ctx.fillText(`${this.totalSets}`, cx, cy + 2);
    ctx.fillStyle = this.theme.palette.secondaryText;
    ctx.font = this.canvasFont(13, false);
    ctx.fillText('总组数', cx, cy + 26);
  }

  /** 绘制训练时长对比双柱（左：上一周期，右：本周期） */
  private drawDuration(): void {
    const ctx: CanvasRenderingContext2D = this.durCtx;
    ctx.clearRect(0, 0, 320, 150);
    const maxVal: number = Math.max(this.durCurrent, this.durPrev);
    const baseY: number = 118;
    const maxH: number = 88;
    const prevH: number = maxVal > 0 ? Math.max(4, this.durPrev / maxVal * maxH) : 4;
    const curH: number = maxVal > 0 ? Math.max(4, this.durCurrent / maxVal * maxH) : 4;
    // 上一周期柱
    ctx.fillStyle = this.theme.palette.track;
    ctx.fillRect(60, baseY - prevH, 70, prevH);
    // 本周期柱
    ctx.fillStyle = this.theme.palette.accent;
    ctx.fillRect(190, baseY - curH, 70, curH);
    // 数值
    ctx.fillStyle = this.theme.palette.secondaryText;
    ctx.font = this.canvasFont(13, false);
    ctx.textAlign = 'center';
    ctx.fillText(`${this.durPrev} 分钟`, 95, baseY - prevH - 8);
    ctx.fillStyle = this.theme.palette.accent;
    ctx.fillText(`${this.durCurrent} 分钟`, 225, baseY - curH - 8);
    // 轴与标签
    ctx.fillStyle = this.theme.palette.track;
    ctx.fillRect(20, baseY, 280, 1);
    ctx.fillStyle = this.theme.palette.secondaryText;
    ctx.fillText('上一周期', 95, baseY + 20);
    ctx.fillText(this.periodWord(), 225, baseY + 20);
  }

  // ==================== 页面 ====================

  build() {
    Column() {
      // ===== 顶部栏（已嵌入底部 Tabs，无返回键） =====
      Row() {
        Text('发现')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.primaryText)
        Blank()
        ThemeToggle({ theme: this.theme })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column() {
          // ===== 训练历史日历 =====
          SectionCard({ theme: this.theme, title: '训练历史' }) {
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
              Text(this.monthTitle)
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

            // 星期表头（周一开头）
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
              ForEach(this.cells, (cell: CalCell) => {
                GridItem() {
                  Column({ space: 2 }) {
                    Text(cell.day === 0 ? '' : `${cell.day}`)
                      .fontSize(14)
                      .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Normal)
                      .fontColor(!cell.inMonth ? this.theme.palette.track :
                        cell.selected ? this.theme.palette.onAccent : this.theme.palette.primaryText)
                    Text('●')
                      .fontSize(8)
                      .fontColor(cell.hasLog && !cell.selected ? this.theme.palette.accent :
                        cell.hasLog ? this.theme.palette.onAccent : this.theme.palette.cardBackground)
                  }
                  .width('100%')
                  .height(44)
                  .justifyContent(FlexAlign.Center)
                  .borderRadius(10)
                  .backgroundColor(cell.selected ? this.theme.palette.accent : this.theme.palette.cardBackground)
                  .onClick(() => {
                    this.selectDay(cell);
                  })
                }
              }, (cell: CalCell) => cell.key)
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
            .columnsGap(4)
            .rowsGap(4)
            .width('100%')
          }

          // ===== 当日明细（含当日 PR） =====
          SectionCard({ theme: this.theme, title: `当日明细 · ${this.selectedDateKey}` }) {
            if (this.dayLogs.length === 0) {
              Text('当日暂无训练记录')
                .fontSize(13)
                .fontColor(this.theme.palette.secondaryText)
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
              if (this.dayVolume > 0) {
                Text(`当日总容量：${this.dayVolume} kg`)
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.theme.palette.accent)
                  .margin({ top: 4 })
              }
            }
            if (this.dayPRs.length > 0) {
              ForEach(this.dayPRs, (event: DailyPREvent) => {
                Text(`🏅 ${event.exerciseName}：${event.message}`)
                  .fontSize(12)
                  .fontColor(this.theme.palette.warning)
                  .lineHeight(17)
                  .margin({ top: 6 })
              }, (event: DailyPREvent) => `${event.dateKey}-${event.exerciseName}-${event.message}`)
            }
          }

          // ===== 数据统计 =====
          SectionCard({ theme: this.theme, title: '数据统计' }) {
            // 周/月/年切换
            Row({ space: 8 }) {
              ForEach(this.periodModes, (mode: string) => {
                Button(mode === 'week' ? '周' : mode === 'month' ? '月' : '年')
                  .fontSize(13)
                  .fontColor(this.periodMode === mode ? this.theme.palette.onAccent : this.theme.palette.accent)
                  .backgroundColor(this.periodMode === mode ? this.theme.palette.accent : this.theme.palette.inputBackground)
                  .borderRadius(16)
                  .height(32)
                  .layoutWeight(1)
                  .onClick(() => {
                    this.setPeriod(mode);
                  })
              }, (mode: string) => mode)
            }
            .width('100%')
            .margin({ bottom: 8 })

            // 范围翻页
            Row() {
              Button('‹')
                .fontSize(16)
                .fontColor(this.theme.palette.accent)
                .backgroundColor(this.theme.palette.inputBackground)
                .borderRadius(16)
                .width(40)
                .height(32)
                .accessibilityText('上一周期')
                .onClick(() => {
                  this.shiftRange(-1);
                })
              Text(this.rangeLabel)
                .fontSize(14)
                .fontColor(this.theme.palette.primaryText)
                .textAlign(TextAlign.Center)
                .layoutWeight(1)
              Button('›')
                .fontSize(16)
                .fontColor(this.theme.palette.accent)
                .backgroundColor(this.theme.palette.inputBackground)
                .borderRadius(16)
                .width(40)
                .height(32)
                .accessibilityText('下一周期')
                .onClick(() => {
                  this.shiftRange(1);
                })
            }
            .width('100%')
            .margin({ bottom: 8 })

            if (this.rangeLogCount === 0 && this.durCurrent === 0) {
              Text('该周期暂无数据，完成训练记录后这里会展示统计')
                .fontSize(13)
                .fontColor(this.theme.palette.secondaryText)
                .lineHeight(18)
            } else {
              // ---- 部位热力（2.5D 立体；频次/组数/容量三指标切换；点击部位看详情） ----
              Row() {
                Text('部位热力')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.theme.palette.primaryText)
                Blank()
                Row({ space: 6 }) {
                  this.metricChip('sessions', '频次')
                  this.metricChip('effectiveSets', '组数')
                  this.metricChip('volumeKg', '容量')
                }
              }
              .width('100%')
              .margin({ top: 4, bottom: 6 })
              // 真人轮廓底图 + Canvas 热力发光斑叠加
              Stack() {
                Row({ space: 24 }) {
                  Image($r('app.media.body_front'))
                    .width(95)
                    .height(190)
                    .objectFit(ImageFit.Contain)
                  Image($r('app.media.body_back'))
                    .width(95)
                    .height(190)
                    .objectFit(ImageFit.Contain)
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                Canvas(this.heatCtx)
                  .width('100%')
                  .height(190)
                  .key(`${this.heatCanvasKey}-${this.theme.mode}`)
                  .accessibilityText('部位热力图，点击部位查看统计')
                  .onReady(() => {
                    this.drawHeat();
                  })
                  .onClick((event: ClickEvent) => {
                    this.onHeatTap(event.x, event.y);
                  })
                // 部位点击气泡（2 秒自动消失）
                if (this.heatTipVisible) {
                  Text(this.heatTip)
                    .fontSize(12)
                    .fontColor(this.theme.palette.onAccent)
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .backgroundColor(this.theme.palette.accent)
                    .borderRadius(10)
                    .margin({ top: 6, left: 6 })
                }
              }
              .width(320)
              .height(190)
              .alignSelf(ItemAlign.Center)
              .align(Alignment.TopStart)
              // 图例：色阶标签随指标切换
              Row({ space: 14 }) {
                this.legendChip(this.theme.palette.track, '0')
                this.legendChip(this.theme.palette.success,
                  this.heatMetric === 'sessions' ? '1–2 次' : (this.heatMetric === 'effectiveSets' ? '1–5 组' : '<50 kg'))
                this.legendChip(this.theme.palette.accent,
                  this.heatMetric === 'sessions' ? '3–4 次' : (this.heatMetric === 'effectiveSets' ? '6–15 组' : '50–150 kg'))
                this.legendChip(this.theme.palette.warning,
                  this.heatMetric === 'sessions' ? '≥5 次' : (this.heatMetric === 'effectiveSets' ? '>15 组' : '>150 kg'))
              }
              .width('100%')
              .margin({ top: 4 })
              // 部位图例（点击描边高亮对应部位，再点取消）
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(HEAT_MUSCLE_GROUPS, (group: string) => {
                  Row({ space: 4 }) {
                    Circle({ width: 8, height: 8 })
                      .fill(this.metricColor(group))
                    Text(group)
                      .fontSize(12)
                      .fontColor(this.heatHighlight === group ?
                        this.theme.palette.accent : this.theme.palette.secondaryText)
                  }
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(12)
                  .backgroundColor(this.heatHighlight === group ?
                    this.theme.palette.accentSoft : this.theme.palette.cardBackground)
                  .margin({ right: 6, top: 6 })
                  .accessibilityText(`高亮部位 ${group}`)
                  .onClick(() => {
                    this.heatHighlight = this.heatHighlight === group ? '' : group;
                    this.drawHeat();
                  })
                }, (group: string) => group)
              }
              .width('100%')
              .margin({ bottom: 10 })

              // ---- 部位组数分布环形图 ----
              Text('部位组数分布')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.theme.palette.primaryText)
                .margin({ bottom: 6 })
              if (this.totalSets === 0) {
                Text('无数据')
                  .fontSize(13)
                  .fontColor(this.theme.palette.secondaryText)
                  .margin({ bottom: 10 })
              } else {
                Canvas(this.donutCtx)
                  .width(200)
                  .height(200)
                  .key(`${this.donutCanvasKey}-${this.theme.mode}`)
                  .accessibilityText('部位组数分布环形图')
                  .onReady(() => {
                    this.drawDonut();
                  })
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.legendItems, (item: DonutLegendItem) => {
                    Row({ space: 4 }) {
                      Text('●')
                        .fontSize(10)
                        .fontColor(this.segColor(item.colorIndex))
                      Text(`${item.name} ${item.sets} 组`)
                        .fontSize(12)
                        .fontColor(this.theme.palette.secondaryText)
                    }
                    .margin({ right: 14, top: 4 })
                  }, (item: DonutLegendItem) => item.name)
                }
                .width('100%')
                .margin({ top: 6, bottom: 10 })
              }

              // ---- 训练时长环比 ----
              Text('训练时长')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.theme.palette.primaryText)
                .margin({ bottom: 6 })
              Canvas(this.durCtx)
                .width('100%')
                .height(150)
                .key(`${this.durCanvasKey}-${this.theme.mode}`)
                .accessibilityText('训练时长周期对比')
                .onReady(() => {
                  this.drawDuration();
                })
              Text(this.durationCompareText())
                .fontSize(12)
                .fontColor(this.theme.palette.secondaryText)
                .margin({ top: 4, bottom: 10 })

              // ---- 容量卡（分部位） ----
              Text('容量')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.theme.palette.primaryText)
                .margin({ bottom: 6 })
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(HEAT_MUSCLE_GROUPS, (muscle: string) => {
                  Button(`${muscle}`)
                    .fontSize(12)
                    .fontColor(this.volMuscle === muscle ? this.theme.palette.onAccent : this.theme.palette.accent)
                    .backgroundColor(this.volMuscle === muscle ? this.theme.palette.accent : this.theme.palette.inputBackground)
                    .borderRadius(14)
                    .height(28)
                    .margin({ right: 8, bottom: 8 })
                    .onClick(() => {
                      this.pickVolMuscle(muscle);
                    })
                }, (muscle: string) => muscle)
              }
              .width('100%')
              if (this.volTotal === 0) {
                Text('无数据')
                  .fontSize(13)
                  .fontColor(this.theme.palette.secondaryText)
              } else {
                Row({ space: 10 }) {
                  Column({ space: 4 }) {
                    Text('容量（kg）')
                      .fontSize(12)
                      .fontColor(this.theme.palette.secondaryText)
                    Text(`${this.volTotal}`)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.theme.palette.primaryText)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Column({ space: 4 }) {
                    Text('最佳训练日')
                      .fontSize(12)
                      .fontColor(this.theme.palette.secondaryText)
                    Text(this.volBestDate.length === 0 ? '-' : `${this.volBestDate}（${this.volBestKg} kg）`)
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.theme.palette.primaryText)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .margin({ top: 4 })
              }
            }
          }
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

  /** 热力图图例小色块 */
  @Builder
  legendChip(color: string, label: string) {
    Row({ space: 4 }) {
      Text('■')
        .fontSize(10)
        .fontColor(color)
      Text(label)
        .fontSize(11)
        .fontColor(this.theme.palette.secondaryText)
    }
  }

  /** 热力指标切换胶囊（频次/组数/容量；选中态直接读取 @State heatMetric 保持响应式） */
  @Builder
  metricChip(metric: string, label: string) {
    Text(label)
      .fontSize(12)
      .fontColor(this.heatMetric === metric ?
        this.theme.palette.onAccent : this.theme.palette.primaryText)
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .borderRadius(12)
      .backgroundColor(this.heatMetric === metric ?
        this.theme.palette.accent : this.theme.palette.inputBackground)
      .accessibilityText(`热力指标切换为${label}`)
      .onClick(() => {
        this.heatMetric = metric;
        this.drawHeat();
      })
  }
}
