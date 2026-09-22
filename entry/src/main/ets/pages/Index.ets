/*
 * 文件标注：AI 生成 —— 主页面脚手架与通用 UI（表单、卡片装配、主题接线）
 *          自主业务逻辑 —— 无（全部规则算法位于 agent/rules/ 目录）
 *
 * 可视化 UI 层 · 主页面
 * 流程：手动录入/手表读取 → HealthRecord → RuleAnalysisEngine.analyze() → 三大模块卡片。
 * 主题约束：本文件不出现任何硬编码色值，一律读取 theme.palette.*；
 *           切换主题只改 ThemeManager.mode，由 @Observed 触发全量重绘。
 */
import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ThemeManager } from '../theme/ThemeManager';
import { HealthRecord, SPORT_TYPE_LIST } from '../model/HealthRecord';
import { UserProfile } from '../model/UserProfile';
import { ManualInputSource, ManualInputResult } from '../data/ManualInputSource';
import { HealthKitSource } from '../data/HealthKitSource';
import { MockHealthKitSource } from '../data/MockHealthKitSource';
import { HistoryStore, HistoryEntry, AdoptedState, PeriodStats } from '../data/HistoryStore';
import { SettingsStore } from '../data/SettingsStore';
import { UserProfileStore } from '../data/UserProfileStore';
import { GoalStore, TrainingGoal } from '../data/GoalStore';
import { DietLog, DietLogEntry } from '../data/DietLog';
import { NutritionCalculator, MacroAchievement } from '../data/NutritionCalculator';
import { FoodItem, FoodLibrary } from '../data/FoodLibrary';
import { RuleAnalysisEngine } from '../agent/RuleAnalysisEngine';
import { RuleAnalysisEngineV2 } from '../agent/RuleAnalysisEngineV2';
import { RuleConfig } from '../agent/RuleConfig';
import { WorkoutLogStore } from '../data/WorkoutLogStore';
import { WorkoutLog } from '../model/WorkoutLog';
import { InjuryStore } from '../data/InjuryStore';
import { WellnessLogStore, WellnessEntry } from '../data/WellnessLogStore';
import { FatigueModel, FatigueResult } from '../agent/rules/FatigueModel';
import { ReadinessScorer, ReadinessInput, ReadinessReport } from '../agent/rules/ReadinessScorer';
import { MuscleBalanceAnalyzer, MuscleBalanceReport } from '../agent/rules/MuscleBalanceAnalyzer';
import { StrengthCalculator } from '../agent/rules/StrengthCalculator';
import { HEAT_MUSCLE_GROUPS } from '../agent/rules/TrainingStatsAggregator';
import { PerspectiveProjector, ProjectedPoint } from '../utils/PerspectiveProjector';
import { BodyPathData } from '../data/BodyPathData';
import { AnalysisReport, WeeklyPlanDay } from '../agent/AnalysisResult';
import { ExerciseItem, ExerciseLibrary } from '../data/ExerciseLibrary';
import { ExerciseDetailParams, ExerciseLibraryPage } from './ExerciseLibrary';
import { HistoryCalendar } from './HistoryCalendar';
import { ThemeToggle } from '../components/ThemeToggle';
import { SectionCard } from '../components/SectionCard';
import { LoadBadge } from '../components/LoadBadge';
import { MacroBar } from '../components/MacroBar';

/** 规则设置滑杆参数（@Builder 按引用传参的对象字面量类型） */
interface SliderSpec {
  label: string;
  value: number;
  min: number;
  max: number;
  onSlide: (v: number) => void;
}

/** 分析结果 @Builder 按引用传参类型 */
interface ReportRef {
  report: AnalysisReport;
}

/** 食物卡片行 @Builder 按引用传参类型 */
interface FoodRowSpec {
  title: string;
  foods: string[];
}

@Entry
@Component
struct Index {
  // 主题中枢（@Observed 单例）：mode 变化触发全量重绘
  @State theme: ThemeManager = ThemeManager.instance;

  // 数据源与端侧 Agent 引擎（路线 A：纯规则引擎；V2 用于对比展示）
  private manualSource: ManualInputSource = new ManualInputSource();
  private healthKitSource: HealthKitSource = new HealthKitSource();
  private mockSource: MockHealthKitSource = new MockHealthKitSource();
  private engine: RuleAnalysisEngine = new RuleAnalysisEngine();
  private engineV2: RuleAnalysisEngineV2 = new RuleAnalysisEngineV2();
  private historyStore: HistoryStore | null = null;
  private settingsStore: SettingsStore | null = null;
  private profileStore: UserProfileStore | null = null;
  private goalStore: GoalStore | null = null;
  private dietLog: DietLog | null = null;
  private workoutStore: WorkoutLogStore | null = null;
  private injuryStore: InjuryStore | null = null;
  private wellnessStore: WellnessLogStore | null = null;

  // 每日状态录入（睡眠/酸痛/饮水）与准备度
  @State sleepHoursText: string = '7';
  @State sleepQuality: number = 3;
  @State soreness: number = 2;
  @State waterText: string = '1500';
  @State readiness: ReadinessReport | null = null;
  private readonly rateOptions: string[] = ['1', '2', '3', '4', '5'];

  // 本周肌群容量热力（按部位有效组数；Canvas 人体色块直读）
  @State heatChest: number = 0;
  @State heatBack: number = 0;
  @State heatShoulder: number = 0;
  @State heatArm: number = 0;
  @State heatAbs: number = 0;
  @State heatGlute: number = 0;
  @State heatLeg: number = 0;
  @State balanceTips: string[] = [];
  @State heatCanvasKey: string = 'heat-0';
  /** 部位图例点击选中（描边高亮；空串表示未选中） */
  @State heatHighlight: string = '';
  // 2.5D 热力图自动摆动（±3°，40ms 一帧；仅首页 Tab 可见时重绘）
  private swingAngle: number = 0;
  private swingDir: number = 1;
  private swingTimer: number = -1;
  private heatCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));

  // 用户画像与目标
  @State profile: UserProfile = new UserProfile();
  @State goal: TrainingGoal = new TrainingGoal();

  // 表单状态（字符串暂存，提交时转数字并校验）
  @State sportType: string = SPORT_TYPE_LIST[1];
  @State durationText: string = '45';
  @State hrText: string = '140';
  @State paceText: string = '6\'00"/km';
  @State caloriesText: string = '400';
  @State loadText: string = '';

  // 底部 Tabs 导航（0 首页 / 1 训练 / 2 计划 / 3 动作库 / 4 发现）
  @State currentTab: number = 0;
  /** 发现页刷新信号：切到发现 Tab 时自增，触发日历数据重载 */
  @State discoverTick: number = 0;

  // 分析结果与校验错误（reportV2 为双引擎对比输出）
  @State report: AnalysisReport | null = null;
  @State reportV2: AnalysisReport | null = null;
  @State showV2: boolean = false;
  @State errors: string[] = [];

  // 历史记录与趋势（trend/recent 为 history 的派生变量，避免在 ForEach 中调用方法）
  @State history: HistoryEntry[] = [];
  @State trend: HistoryEntry[] = [];
  @State recent: HistoryEntry[] = [];
  @State trendRange: number = 7;
  @State trendCanvasKey: string = 'trend-7-0';

  // 今日营养达成（报告生成后按 DietLog 计算）
  @State intake: MacroAchievement | null = null;

  // 趋势图：范围选项与 Canvas 上下文
  private readonly trendRanges: number[] = [7, 30, 90];
  private trendCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));

  // 规则设置面板状态（与 RuleConfig 字段一一对应）
  @State highThreshold: number = 80;
  @State normalThreshold: number = 50;
  @State proteinPct: number = 30;
  @State carbPct: number = 50;
  @State configErrors: string[] = [];

  /** 页面创建：初始化本地存储，恢复设置/画像/目标与历史 */
  aboutToAppear(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.historyStore = new HistoryStore(context);
    this.settingsStore = new SettingsStore(context);
    this.profileStore = new UserProfileStore(context);
    this.goalStore = new GoalStore(context);
    this.dietLog = new DietLog(context);
    this.workoutStore = new WorkoutLogStore(context);
    this.injuryStore = new InjuryStore(context);
    this.wellnessStore = new WellnessLogStore(context);
    const config: RuleConfig = this.settingsStore.load();
    this.highThreshold = config.highThreshold;
    this.normalThreshold = config.normalThreshold;
    this.proteinPct = config.proteinPct;
    this.carbPct = config.carbPct;
    this.engine.setConfig(config);
    this.engineV2.setConfig(config);
    this.applyInjuries();
    this.reloadProfile();
    this.refreshHistory();
    this.loadWellness();
  }

  /** 从子页面返回时：重载画像、伤病、今日营养与肌群热力 */
  onPageShow(): void {
    this.reloadProfile();
    this.applyInjuries();
    this.refreshIntake();
    this.refreshMuscleHeat();
  }

  /** 页面销毁：停止热力图摆动动画定时器 */
  aboutToDisappear(): void {
    if (this.swingTimer >= 0) {
      clearInterval(this.swingTimer);
      this.swingTimer = -1;
    }
  }

  /** 启动 2.5D 热力图自动摆动（±3° 往返，40ms 一帧；切走首页 Tab 时暂停重绘） */
  private startSwing(): void {
    if (this.swingTimer >= 0) {
      return;
    }
    this.swingTimer = setInterval(() => {
      this.swingAngle += 0.15 * this.swingDir;
      if (Math.abs(this.swingAngle) >= 3) {
        this.swingDir = -this.swingDir;
      }
      if (this.currentTab === 0 && this.heatTotal() > 0) {
        this.drawMuscleHeat();
      }
    }, 40);
  }

  /** 读取当前伤病部位并注入两个引擎（影响计划生成与补强推荐的禁忌过滤） */
  private applyInjuries(): void {
    if (this.injuryStore === null) {
      return;
    }
    const parts: string[] = this.injuryStore.activeParts();
    this.engine.setInjuries(parts);
    this.engineV2.setInjuries(parts);
  }

  /** 载入今日状态到表单并刷新准备度 */
  private loadWellness(): void {
    if (this.wellnessStore === null) {
      return;
    }
    const entry: WellnessEntry | null = this.wellnessStore.getToday();
    if (entry !== null) {
      if (entry.sleepHours > 0) {
        this.sleepHoursText = `${entry.sleepHours}`;
      }
      if (entry.sleepQuality > 0) {
        this.sleepQuality = entry.sleepQuality;
      }
      if (entry.soreness > 0) {
        this.soreness = entry.soreness;
      }
      if (entry.waterMl > 0) {
        this.waterText = `${entry.waterMl}`;
      }
    }
    this.refreshReadiness();
  }

  /** 保存今日状态并刷新准备度 */
  private saveWellness(): void {
    if (this.wellnessStore === null) {
      return;
    }
    const entry: WellnessEntry = {
      dateKey: WellnessLogStore.todayKey(),
      sleepHours: Number(this.sleepHoursText) > 0 ? Number(this.sleepHoursText) : 0,
      sleepQuality: this.sleepQuality,
      soreness: this.soreness,
      waterMl: Number(this.waterText) > 0 ? Number(this.waterText) : 0
    };
    this.wellnessStore.save(entry);
    this.refreshReadiness();
    promptAction.showToast({ message: '今日状态已保存' });
  }

  /** 计算准备度（疲劳 + 今日睡眠/酸痛 + 距上次训练 + 连续训练天数） */
  private refreshReadiness(): void {
    const fatigue: FatigueResult = FatigueModel.compute(this.history);
    let hoursSince: number = -1;
    if (this.history.length > 0) {
      hoursSince = (Date.now() - this.history[0].timestamp) / 3600000;
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
    const input: ReadinessInput = {
      fatigueIndex: fatigue.index,
      sleepHours: sleepHours,
      sleepQuality: sleepQuality,
      soreness: soreness,
      hoursSinceLastTraining: hoursSince,
      consecutiveTrainingDays: this.consecutiveTrainingDays()
    };
    this.readiness = ReadinessScorer.score(input);
  }

  /** 连续训练天数（今天未训练时从昨天往前数） */
  private consecutiveTrainingDays(): number {
    const dayKeys: string[] = [];
    this.history.forEach((entry: HistoryEntry) => {
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

  /** 本周肌群容量热力：按部位汇总有效组数并触发 Canvas 重绘 */
  private refreshMuscleHeat(): void {
    if (this.workoutStore === null) {
      return;
    }
    const logs: WorkoutLog[] = this.workoutStore.weeklyLogs();
    const setsByMuscle: Map<string, number> = new Map<string, number>();
    logs.forEach((log: WorkoutLog) => {
      const exercise: ExerciseItem | null = ExerciseLibrary.findById(log.exerciseId);
      if (exercise === null) {
        return;
      }
      const effective: number = StrengthCalculator.effectiveSets(log);
      setsByMuscle.set(exercise.muscle, (setsByMuscle.get(exercise.muscle) ?? 0) + effective);
    });
    this.heatChest = setsByMuscle.get('胸') ?? 0;
    this.heatBack = setsByMuscle.get('背') ?? 0;
    this.heatShoulder = setsByMuscle.get('肩') ?? 0;
    this.heatArm = (setsByMuscle.get('二头') ?? 0) + (setsByMuscle.get('三头') ?? 0) + (setsByMuscle.get('小臂') ?? 0);
    this.heatAbs = setsByMuscle.get('腹') ?? 0;
    this.heatGlute = setsByMuscle.get('臀') ?? 0;
    this.heatLeg = setsByMuscle.get('腿') ?? 0;
    // 肌群平衡提示（失衡描述 + 补强动作分行展示；有伤病时过滤禁忌动作）
    const injuredParts: string[] = this.injuryStore === null ? [] : this.injuryStore.activeParts();
    const report: MuscleBalanceReport = MuscleBalanceAnalyzer.analyze(logs, injuredParts);
    const tips: string[] = [];
    report.imbalances.forEach((text: string) => {
      tips.push(text);
    });
    if (report.recommendations.length > 0) {
      tips.push(`补强推荐：${report.recommendations.join('、')}（动作库可查）`);
    }
    this.balanceTips = tips;
    this.heatCanvasKey = `heat-${logs.length}-${Date.now() % 100000}`;
  }

  /** 本周全部部位有效组数合计（空态判断用） */
  private heatTotal(): number {
    return this.heatChest + this.heatBack + this.heatShoulder +
      this.heatArm + this.heatAbs + this.heatGlute + this.heatLeg;
  }

  /** 有效组数 → 热力色（全部取自调色板） */
  private heatColor(sets: number): string {
    if (sets <= 0) {
      return this.theme.palette.track;
    }
    if (sets <= 4) {
      return this.theme.palette.success;
    }
    if (sets <= 9) {
      return this.theme.palette.accent;
    }
    return this.theme.palette.warning;
  }

  /** 部位组 → 本周有效组数（条件链取值，避免动态索引） */
  private heatOfGroup(group: string): number {
    if (group === '胸') {
      return this.heatChest;
    }
    if (group === '背') {
      return this.heatBack;
    }
    if (group === '肩') {
      return this.heatShoulder;
    }
    if (group === '手臂') {
      return this.heatArm;
    }
    if (group === '腹') {
      return this.heatAbs;
    }
    if (group === '臀') {
      return this.heatGlute;
    }
    if (group === '腿') {
      return this.heatLeg;
    }
    return 0;
  }

  /** Canvas 字体（vp 规格 → 物理 px，解决高分屏文字过小问题） */
  private canvasFont(vpSize: number, bold: boolean): string {
    const px: number = Math.round(vp2px(vpSize));
    return bold ? `bold ${px}px sans-serif` : `${px}px sans-serif`;
  }

  /** 绘制 2.5D 立体人体热力（正面 + 背面），颜色反映本周各部位有效组数，整体随 swingAngle 摆动 */
  private drawMuscleHeat(): void {
    const ctx: CanvasRenderingContext2D = this.heatCtx;
    ctx.clearRect(0, 0, 320, 190);
    // 图注
    ctx.fillStyle = this.theme.palette.secondaryText;
    ctx.font = this.canvasFont(12, false);
    ctx.textAlign = 'center';
    ctx.fillText('正面', 80, 12);
    ctx.fillText('背面', 240, 12);
    // 正面组整体倾斜 +swingAngle，背面组 -swingAngle（自动摆动 ±3°）
    this.drawBody25D(ctx, BodyPathData.getFrontPaths(), 30, 22, this.swingAngle);
    this.drawBody25D(ctx, BodyPathData.getBackPaths(), 190, 22, -this.swingAngle);
  }

  /** 单个人体：透视投影（近大远小）+ 45° 明暗渐变 + 底部投影 + 高频高光 + 选中描边 */
  private drawBody25D(ctx: CanvasRenderingContext2D, paths: Map<string, number[][]>,
    originX: number, originY: number, tiltDeg: number): void {
    const bodyW: number = 100;
    const bodyH: number = 158;
    const vanishingX: number = originX + bodyW / 2;
    const vanishingY: number = originY - 16;
    const rad: number = tiltDeg * Math.PI / 180;
    ctx.save();
    ctx.transform(1, Math.sin(rad), Math.sin(rad), 1, 0, 0);
    paths.forEach((points: number[][], key: string) => {
      const group: string = BodyPathData.groupOf(key);
      const sets: number = this.heatOfGroup(group);
      const base: string = this.heatColor(sets);
      const z: number = BodyPathData.depthOf(key);
      // 归一化坐标 → 画布坐标 → 透视投影，同时记录包围盒
      const projected: number[][] = [];
      let minX: number = 1000;
      let minY: number = 1000;
      let maxX: number = -1000;
      let maxY: number = -1000;
      points.forEach((pt: number[]) => {
        const sx: number = originX + pt[0] / 100 * bodyW;
        const sy: number = originY + pt[1] / 100 * bodyH;
        const pp: ProjectedPoint = PerspectiveProjector.project(sx, sy, z, vanishingX, vanishingY);
        projected.push([pp.px, pp.py]);
        minX = Math.min(minX, pp.px);
        minY = Math.min(minY, pp.py);
        maxX = Math.max(maxX, pp.px);
        maxY = Math.max(maxY, pp.py);
      });
      // 部位路径
      ctx.beginPath();
      projected.forEach((pt: number[], idx: number) => {
        if (idx === 0) {
          ctx.moveTo(pt[0], pt[1]);
        } else {
          ctx.lineTo(pt[0], pt[1]);
        }
      });
      ctx.closePath();
      // 左上 45° 明暗渐变（浅色在上、深色在下，明暗由调色板基色推导）
      const gradient: CanvasGradient = ctx.createLinearGradient(minX, minY, maxX, maxY);
      gradient.addColorStop(0, PerspectiveProjector.shadeColor(base, 0.35));
      gradient.addColorStop(1, PerspectiveProjector.shadeColor(base, -0.25));
      ctx.fillStyle = gradient;
      ctx.fill();
      // 底部投影（深色半透明椭圆，向下偏移 2px）
      ctx.save();
      ctx.globalAlpha = 0.15;
      ctx.fillStyle = this.theme.palette.primaryText;
      ctx.beginPath();
      ctx.ellipse((minX + maxX) / 2, maxY + 2, Math.max(2, (maxX - minX) / 2), 3, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
      // 高频部位（≥5 组）叠加 45° 斜向高光条（裁剪在部位路径内）
      if (sets >= 5) {
        ctx.save();
        ctx.clip();
        ctx.globalAlpha = 0.2;
        ctx.strokeStyle = this.theme.palette.onHero;
        ctx.lineWidth = 6;
        ctx.beginPath();
        ctx.moveTo(minX - 4, maxY + 4);
        ctx.lineTo(maxX + 4, minY - 4);
        ctx.stroke();
        ctx.restore();
      }
      // 部位图例点击选中：描边高亮
      if (this.heatHighlight === group) {
        ctx.beginPath();
        projected.forEach((pt: number[], idx: number) => {
          if (idx === 0) {
            ctx.moveTo(pt[0], pt[1]);
          } else {
            ctx.lineTo(pt[0], pt[1]);
          }
        });
        ctx.closePath();
        ctx.strokeStyle = this.theme.palette.accent;
        ctx.lineWidth = 2;
        ctx.stroke();
      }
    });
    ctx.restore();
  }

  /** 重载用户画像并注入引擎与录入源 */
  private reloadProfile(): void {
    if (this.profileStore === null) {
      return;
    }
    this.profile = this.profileStore.load();
    const profileOrNull: UserProfile | null = this.profile.filled ? this.profile : null;
    this.engine.setUserProfile(profileOrNull);
    this.engineV2.setUserProfile(profileOrNull);
    this.manualSource.setUserProfile(profileOrNull);
  }

  /** 从本地存储刷新历史与趋势（趋势按 trendRange 截取，按时间正序用于图表） */
  private refreshHistory(): void {
    if (this.historyStore === null) {
      return;
    }
    this.history = this.historyStore.list();
    const sliced: HistoryEntry[] = this.history.slice(0, this.trendRange);
    sliced.reverse();
    this.trend = sliced;
    this.recent = this.history.slice(0, 5);
    // 强制重建趋势 Canvas 触发重绘
    this.trendCanvasKey = `trend-${this.trendRange}-${this.history.length}-${Date.now() % 100000}`;
    this.engine.setHistory(this.history);
    this.engineV2.setHistory(this.history);
    this.refreshIntake();
    this.refreshReadiness();
  }

  /** 今日营养达成度（基于最近一次报告的宏量建议） */
  private refreshIntake(): void {
    if (this.dietLog === null || this.report === null) {
      this.intake = null;
      return;
    }
    const entries: DietLogEntry[] = this.dietLog.getDailyLog();
    this.intake = NutritionCalculator.achievement(entries, this.report.diet);
  }

  /** 分析成功后写入历史记录 */
  private recordHistory(record: HealthRecord, report: AnalysisReport): void {
    if (this.historyStore === null) {
      return;
    }
    const entry: HistoryEntry = {
      timestamp: Date.now(),
      sportType: record.sportType,
      durationMin: record.durationMin,
      calories: record.calories,
      load: report.assessment.load,
      loadStatus: report.assessment.loadStatus,
      recoveryHours: report.assessment.suggestedRecoveryHours,
      adopted: 'unmarked'
    };
    this.historyStore.save(entry);
    this.refreshHistory();
  }

  /** 标记一条历史建议为已采纳/已忽略（引擎按反馈微调下次建议强度） */
  private markEntry(timestamp: number, state: AdoptedState): void {
    if (this.historyStore === null) {
      return;
    }
    this.historyStore.markAdopted(timestamp, state);
    this.refreshHistory();
  }

  /** 导出历史记录为沙箱 JSON 文件（不分享、不联网） */
  private exportHistory(): void {
    if (this.historyStore === null) {
      return;
    }
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const path: string = this.historyStore.exportToFile(context);
      promptAction.showToast({ message: `已导出：${path}` });
    } catch (err) {
      promptAction.showToast({ message: '导出失败，请重试' });
    }
  }

  /** 动作 id → 名称（周计划推荐动作芯片展示用） */
  private exerciseName(id: string): string {
    const item: ExerciseItem | null = ExerciseLibrary.findById(id);
    return item === null ? id : item.name;
  }

  /** 跳转动作详情页（周计划推荐动作芯片点击） */
  private openExercise(id: string): void {
    const params: ExerciseDetailParams = new ExerciseDetailParams();
    params.id = id;
    router.pushUrl({ url: 'pages/ExerciseDetail', params: params })
      .catch((err: Error) => {
        console.error(`openExercise failed: ${err.message}`);
      });
  }

  /** 应用规则设置：校验 → 注入引擎 → 本地持久化 */
  private applyConfig(): void {
    const config: RuleConfig = new RuleConfig();
    config.highThreshold = this.highThreshold;
    config.normalThreshold = this.normalThreshold;
    config.proteinPct = this.proteinPct;
    config.carbPct = this.carbPct;
    this.configErrors = config.validate();
    if (this.configErrors.length > 0) {
      return;
    }
    this.engine.setConfig(config);
    this.engineV2.setConfig(config);
    if (this.settingsStore !== null) {
      this.settingsStore.save(config);
    }
  }


  /** 恢复倒计时提示（基于最近一次记录的建议恢复时长） */
  private recoveryHint(): string {
    if (this.history.length === 0) {
      return '';
    }
    const latest: HistoryEntry = this.history[0];
    const elapsedHours: number = (Date.now() - latest.timestamp) / 3600000;
    const remaining: number = Math.ceil(latest.recoveryHours - elapsedHours);
    if (remaining <= 0) {
      return '上次训练已完成建议恢复，可以开始下一次训练';
    }
    return `距离完全恢复约 ${remaining} 小时`;
  }

  /** 本周已完成训练次数 */
  private weeklySessionsDone(): number {
    if (this.historyStore === null) {
      return 0;
    }
    const stats: PeriodStats = this.historyStore.getWeeklyStats();
    return stats.sessions;
  }

  /** 本周已完成训练总时长（分钟） */
  private weeklyDurationDone(): number {
    if (this.historyStore === null) {
      return 0;
    }
    const stats: PeriodStats = this.historyStore.getWeeklyStats();
    return stats.totalDurationMin;
  }

  /** 本周目标达成率（次数与时长取较低者，更保守） */
  private weeklyGoalRate(): number {
    if (this.goal.weeklySessions <= 0) {
      return 0;
    }
    const sessionRate: number = this.weeklySessionsDone() * 100 / this.goal.weeklySessions;
    const durationRate: number = this.weeklyDurationDone() * 100 / this.goal.weeklyDurationMin;
    return Math.min(100, Math.round(Math.min(sessionRate, durationRate)));
  }

  /** 更新并持久化周目标（非法输入忽略） */
  private updateGoal(text: string, field: string): void {
    const value: number = Number(text);
    if (Number.isNaN(value)) {
      return;
    }
    const next: TrainingGoal = new TrainingGoal();
    next.weeklySessions = this.goal.weeklySessions;
    next.weeklyDurationMin = this.goal.weeklyDurationMin;
    next.targetWeightKg = this.goal.targetWeightKg;
    if (field === 'sessions') {
      next.weeklySessions = value;
    } else {
      next.weeklyDurationMin = value;
    }
    if (next.validate().length > 0) {
      return;
    }
    this.goal = next;
    if (this.goalStore !== null) {
      this.goalStore.save(next);
    }
  }

  /** 提交手动录入并运行端侧 Agent 分析（V1 主输出，V2 并行对比） */
  private runManualAnalysis(): void {
    const result: ManualInputResult = this.manualSource.submit(
      Number(this.durationText),
      Number(this.hrText),
      this.paceText,
      Number(this.caloriesText),
      this.sportType,
      this.loadText
    );
    this.errors = result.errors;
    if (result.record !== null) {
      this.report = this.engine.analyze(result.record);
      this.reportV2 = this.engineV2.analyze(result.record);
      this.recordHistory(result.record, this.report);
    } else {
      this.report = null;
      this.reportV2 = null;
    }
  }

  /** 生成一条模拟运动记录并分析（演示流程用，不接入真实 Health Kit） */
  private async runMockAnalysis(): Promise<void> {
    const record: HealthRecord | null = await this.mockSource.readLatest();
    if (record === null) {
      return;
    }
    this.errors = [];
    this.report = this.engine.analyze(record);
    this.reportV2 = this.engineV2.analyze(record);
    this.recordHistory(record, this.report);
  }

  /** 尝试从鸿蒙 Health Kit 读取（骨架：真实 API 由参赛者补全） */
  private async runHealthKitRead(): Promise<void> {
    const record: HealthRecord | null = await this.healthKitSource.readLatest();
    if (record === null) {
      promptAction.showToast({ message: '暂未读取到手表数据（Health Kit 待接入），请先手动录入' });
      return;
    }
    this.errors = [];
    this.report = this.engine.analyze(record);
    this.recordHistory(record, this.report);
  }

  build() {
    // ===== 底部五栏 Tabs 导航（参考快练：首页/训练/计划/动作库/发现） =====
    Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
      TabContent() {
        this.homeTab()
      }
      .tabBar(this.tabBarItem(0, '🏠', '首页'))
      TabContent() {
        this.trainTab()
      }
      .tabBar(this.tabBarItem(1, '⚡', '训练'))
      TabContent() {
        this.planTab()
      }
      .tabBar(this.tabBarItem(2, '🗓', '计划'))
      TabContent() {
        ExerciseLibraryPage()
      }
      .tabBar(this.tabBarItem(3, '🏋', '动作库'))
      TabContent() {
        HistoryCalendar({ refreshTick: this.discoverTick })
      }
      .tabBar(this.tabBarItem(4, '🧭', '发现'))
    }
    .width('100%')
    .height('100%')
    .barMode(BarMode.Fixed)
    .barHeight(64)
    .barBackgroundColor(this.theme.palette.cardBackground)
    .divider({ strokeWidth: 0.5, color: this.theme.palette.track })
    .animationDuration(200)
    .backgroundColor(this.theme.palette.pageBackground)
    .onChange((index: number) => {
      this.currentTab = index;
      // 切回首页时重载画像/伤病/营养/肌群热力（替代原 onPageShow 的跨页刷新）
      if (index === 0) {
        this.reloadProfile();
        this.applyInjuries();
        this.refreshIntake();
        this.refreshMuscleHeat();
      }
      // 切到发现页时通知日历重载训练日志
      if (index === 4) {
        this.discoverTick++;
      }
    })
  }

  /** 底部导航项（参考快练：选中项浅灰胶囊底 + 加粗标签，未选中灰色） */
  @Builder
  private tabBarItem(index: number, icon: string, label: string): void {
    Column({ space: 3 }) {
      Stack() {
        if (this.currentTab === index) {
          Row()
            .width(56)
            .height(30)
            .borderRadius(15)
            .backgroundColor(this.theme.palette.accentSoft)
        }
        Text(icon)
          .fontSize(18)
      }
      .width(56)
      .height(30)
      Text(label)
        .fontSize(11)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.currentTab === index ?
          this.theme.palette.accent : this.theme.palette.secondaryText)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .accessibilityText(`${label}标签`)
  }

  /** 首页 Tab：画像 / 每日状态 / 本周目标 / 今日营养 / 肌群热力 / 历史趋势 */
  @Builder
  private homeTab(): void {
    Column() {
      // ===== 顶部栏：标题 + 报表入口 + 深色/浅色切换 =====
      Row() {
        Column({ space: 2 }) {
          Text('衡练 · 运动健康 Agent')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.palette.primaryText)
          Text('端侧规则引擎 · 不联网 · 非医疗诊断')
            .fontSize(12)
            .fontColor(this.theme.palette.secondaryText)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Button('📊 报表')
          .fontSize(14)
          .fontColor(this.theme.palette.accent)
          .backgroundColor(this.theme.palette.inputBackground)
          .borderRadius(18)
          .height(36)
          .margin({ right: 8 })
          .accessibilityText('打开训练报表页')
          .onClick(() => {
            router.pushUrl({ url: 'pages/Report' })
              .catch((err: Error) => {
                console.error(`openReport failed: ${err.message}`);
              });
          })
        ThemeToggle({ theme: this.theme })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          // ===== 问候横幅：时段问候 + 日期 + 训练摘要 + 准备度圆环（渐变卡） =====
          Column() {
            Row() {
              Column({ space: 4 }) {
                Text(this.greeting())
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.theme.palette.onHero)
                Text(this.dateLabel())
                  .fontSize(12)
                  .fontColor(this.theme.palette.onHero)
                  .opacity(0.85)
                Text(`🔥 连续 ${this.consecutiveTrainingDays()} 天 · ⚡ 本周 ${this.weeklySessionsDone()} 次 · 🎯 ${this.weeklyGoalRate()}%`)
                  .fontSize(12)
                  .fontColor(this.theme.palette.onHero)
                  .margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              // 准备度圆环（右端大数字）
              Stack() {
                Progress({ value: this.readiness === null ? 0 : this.readiness.score, total: 100, type: ProgressType.Ring })
                  .width(64)
                  .height(64)
                  .color(this.theme.palette.onHero)
                  .backgroundColor(this.theme.palette.heroStart)
                Column() {
                  Text(this.readiness === null ? '--' : `${this.readiness.score}`)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.theme.palette.onHero)
                  Text('准备度')
                    .fontSize(9)
                    .fontColor(this.theme.palette.onHero)
                    .opacity(0.85)
                }
              }
              .accessibilityText(this.readiness === null ? '准备度未知' : `准备度 ${this.readiness.score} 分`)
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .linearGradient({ angle: 135, colors: [[this.theme.palette.heroStart, 0.0], [this.theme.palette.heroEnd, 1.0]] })
          .shadow({ radius: 14, color: this.theme.palette.cardShadow, offsetX: 0, offsetY: 4 })
          .margin({ bottom: 14 })

          // ===== 快速操作：记训练 / 记一餐 / 画像 / 报表 =====
          Row({ space: 10 }) {
            this.quickAction('📝', '记训练', () => {
              router.pushUrl({ url: 'pages/WorkoutLogPage' })
                .catch((err: Error) => {
                  console.error(`openWorkoutLog failed: ${err.message}`);
                });
            })
            this.quickAction('🍚', '记一餐', () => {
              router.pushUrl({ url: 'pages/FoodPicker' })
                .then(() => {
                  this.refreshIntake();
                })
                .catch((err: Error) => {
                  console.error(`openFoodPicker failed: ${err.message}`);
                });
            })
            this.quickAction('👤', '画像', () => {
              router.pushUrl({ url: 'pages/ProfilePage' })
                .catch((err: Error) => {
                  console.error(`openProfile failed: ${err.message}`);
                });
            })
            this.quickAction('📊', '报表', () => {
              router.pushUrl({ url: 'pages/Report' })
                .catch((err: Error) => {
                  console.error(`openReport failed: ${err.message}`);
                });
            })
          }
          .width('100%')
          .margin({ bottom: 14 })

          // ===== 用户画像卡片（未填写时引导；已填写显示摘要） =====
          SectionCard({ theme: this.theme, title: '用户画像' }) {
            if (this.profile.filled) {
              Text(`${this.profile.gender} · ${this.profile.age} 岁 · ${this.profile.weightKg} kg · ` +
                `${this.profile.goal} · ${this.profile.experienceLevel}`)
                .fontSize(14)
                .fontColor(this.theme.palette.primaryText)
                .margin({ bottom: 8 })
            } else {
              Text('填写画像后：心率区间按年龄修正、热量按体重估算、饮食配比按目标调整')
                .fontSize(13)
                .fontColor(this.theme.palette.secondaryText)
                .margin({ bottom: 8 })
            }
            Button(this.profile.filled ? '修改画像' : '填写画像')
              .fontSize(14)
              .fontColor(this.theme.palette.onAccent)
              .backgroundColor(this.theme.palette.accent)
              .borderRadius(18)
              .height(36)
              .accessibilityText('打开用户画像录入页')
              .onClick(() => {
                router.pushUrl({ url: 'pages/ProfilePage' })
                  .catch((err: Error) => {
                    console.error(`openProfile failed: ${err.message}`);
                  });
              })
          }

          // ===== 每日状态卡（睡眠/酸痛/饮水 + 准备度） =====
          SectionCard({ theme: this.theme, title: '每日状态' }) {
            Row({ space: 10 }) {
              this.numberField('睡眠（小时）', this.sleepHoursText, (v: string) => {
                this.sleepHoursText = v;
              })
              this.numberField('饮水（ml）', this.waterText, (v: string) => {
                this.waterText = v;
              })
            }
            .width('100%')
            Row({ space: 10 }) {
              this.rateSelect('睡眠质量', this.sleepQuality, (v: number) => {
                this.sleepQuality = v;
              })
              this.rateSelect('酸痛程度', this.soreness, (v: number) => {
                this.soreness = v;
              })
            }
            .width('100%')
            .margin({ top: 8 })
            Button('保存今日状态')
              .fontSize(14)
              .fontColor(this.theme.palette.onAccent)
              .backgroundColor(this.theme.palette.accent)
              .borderRadius(18)
              .height(36)
              .width('100%')
              .margin({ top: 10 })
              .accessibilityText('保存今日睡眠酸痛饮水状态')
              .onClick(() => {
                this.saveWellness();
              })
            if (this.readiness !== null) {
              this.readinessLine(this.readiness)
            }
          }

          // ===== 本周目标进度环 =====
          SectionCard({ theme: this.theme, title: '本周目标' }) {
            Row({ space: 16 }) {
              Stack() {
                Progress({ value: this.weeklyGoalRate(), total: 100, type: ProgressType.Ring })
                  .width(84)
                  .height(84)
                  .color(this.theme.palette.accent)
                  .backgroundColor(this.theme.palette.track)
                Text(`${this.weeklyGoalRate()}%`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.theme.palette.primaryText)
              }
              .accessibilityText(`本周目标达成率 ${this.weeklyGoalRate()}%`)
              Column({ space: 4 }) {
                Text(`目标：每周 ${this.goal.weeklySessions} 次 · ${this.goal.weeklyDurationMin} 分钟`)
                  .fontSize(13)
                  .fontColor(this.theme.palette.primaryText)
                Text(`已完成：${this.weeklySessionsDone()} 次 · ${this.weeklyDurationDone()} 分钟`)
                  .fontSize(13)
                  .fontColor(this.theme.palette.secondaryText)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            Row({ space: 10 }) {
              this.numberField('周次数目标', `${this.goal.weeklySessions}`, (v: string) => {
                this.updateGoal(v, 'sessions');
              })
              this.numberField('周时长目标（分钟）', `${this.goal.weeklyDurationMin}`, (v: string) => {
                this.updateGoal(v, 'duration');
              })
            }
            .width('100%')
            .margin({ top: 8 })
          }

          // ===== 今日营养达成环（完成一次分析后出现） =====
          this.intakeCard(this.intake)

          // ===== 本周肌群容量热力（训练日志驱动，Canvas 人体色块） =====
          SectionCard({ theme: this.theme, title: '本周肌群容量热力' }) {
            if (this.heatTotal() === 0) {
              Text('暂无力量训练日志，点右上角「📝 记训练」记录组数后，这里会按部位显示热力')
                .fontSize(13)
                .fontColor(this.theme.palette.secondaryText)
                .lineHeight(18)
            } else {
              Canvas(this.heatCtx)
                .width('100%')
                .height(190)
                .key(this.heatCanvasKey)
                .accessibilityText('本周肌群容量热力图')
                .onReady(() => {
                  this.drawMuscleHeat();
                  this.startSwing();
                })
              // 图例：有效组数分档
              Row({ space: 14 }) {
                this.legendChip(this.theme.palette.track, '0 组')
                this.legendChip(this.theme.palette.success, '1–4 组')
                this.legendChip(this.theme.palette.accent, '5–9 组')
                this.legendChip(this.theme.palette.warning, '≥10 组')
              }
              .width('100%')
              .margin({ top: 8 })
              // 部位图例（点击描边高亮对应部位，再点取消）
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(HEAT_MUSCLE_GROUPS, (group: string) => {
                  Row({ space: 4 }) {
                    Circle({ width: 8, height: 8 })
                      .fill(this.heatColor(this.heatOfGroup(group)))
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
                    this.drawMuscleHeat();
                  })
                }, (group: string) => group)
              }
              .width('100%')
              // 肌群平衡提示（MuscleBalanceAnalyzer 输出）
              ForEach(this.balanceTips, (tip: string) => {
                Text(tip)
                  .fontSize(12)
                  .fontColor(this.theme.palette.accent)
                  .lineHeight(17)
                  .margin({ top: 6 })
              }, (tip: string) => tip)
            }
          }

          // ===== 历史与负荷趋势（首页卡） =====
          SectionCard({ theme: this.theme, title: '历史与负荷趋势' }) {
            if (this.history.length === 0) {
              Text('暂无历史记录，完成一次分析后这里会展示负荷趋势')
                .fontSize(13)
                .fontColor(this.theme.palette.secondaryText)
            } else {
              if (this.recoveryHint().length > 0) {
                Text(this.recoveryHint())
                  .fontSize(13)
                  .fontColor(this.theme.palette.accent)
                  .margin({ bottom: 10 })
              }
              // 趋势范围切换（7/30/90 条记录）
              Row({ space: 8 }) {
                ForEach(this.trendRanges, (range: number) => {
                  Text(`${range}`)
                    .fontSize(12)
                    .fontColor(this.trendRange === range ?
                      this.theme.palette.onAccent : this.theme.palette.primaryText)
                    .textAlign(TextAlign.Center)
                    .padding({ left: 12, right: 12, top: 5, bottom: 5 })
                    .borderRadius(13)
                    .backgroundColor(this.trendRange === range ?
                      this.theme.palette.accent : this.theme.palette.inputBackground)
                    .onClick(() => {
                      this.trendRange = range;
                      this.refreshHistory();
                    })
                }, (range: number) => `${range}`)
              }
              .margin({ bottom: 10 })

              // 负荷趋势图：柱状 + 周均值折线叠加（纯 ArkUI Canvas）
              Stack() {
                Row({ space: 10 }) {
                  ForEach(this.trend, (entry: HistoryEntry) => {
                    Column({ space: 4 }) {
                      Text(`${entry.load}`)
                        .fontSize(10)
                        .fontColor(this.theme.palette.secondaryText)
                      Row()
                        .width(18)
                        .height(Math.max(4, entry.load * 0.6))
                        .borderRadius(4)
                        .backgroundColor(this.loadColor(entry.loadStatus))
                    }
                    .justifyContent(FlexAlign.End)
                    .height(90)
                  }, (entry: HistoryEntry) => entry.timestamp.toString())
                }
                .alignItems(VerticalAlign.Bottom)
                Canvas(this.trendCtx)
                  .width('100%')
                  .height(90)
                  .key(this.trendCanvasKey)
                  .onReady(() => {
                    this.drawWeeklyAverageLine();
                  })
              }
              .width('100%')
              .margin({ bottom: 12 })

              // 最近记录列表（最多 5 条，含采纳反馈）
              ForEach(this.recent, (entry: HistoryEntry) => {
                Row({ space: 8 }) {
                  Circle({ width: 8, height: 8 })
                    .fill(this.loadColor(entry.loadStatus))
                  Text(`${entry.sportType} · ${entry.durationMin}分钟 · ${entry.calories}千卡`)
                    .fontSize(13)
                    .fontColor(this.theme.palette.primaryText)
                    .layoutWeight(1)
                  Text(`负荷${entry.load}`)
                    .fontSize(12)
                    .fontColor(this.theme.palette.secondaryText)
                  Text(entry.adopted === 'adopted' ? '✓ 已采纳' : (entry.adopted === 'ignored' ? '✗ 已忽略' : '未标记'))
                    .fontSize(11)
                    .fontColor(entry.adopted === 'adopted' ? this.theme.palette.success :
                      (entry.adopted === 'ignored' ? this.theme.palette.danger : this.theme.palette.secondaryText))
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(10)
                    .backgroundColor(this.theme.palette.inputBackground)
                    .accessibilityText('点击切换采纳状态')
                    .onClick(() => {
                      const next: AdoptedState = entry.adopted === 'unmarked' ? 'adopted' :
                        (entry.adopted === 'adopted' ? 'ignored' : 'unmarked');
                      this.markEntry(entry.timestamp, next);
                    })
                }
                .width('100%')
                .margin({ bottom: 6 })
              }, (entry: HistoryEntry) => entry.timestamp.toString())

              Row({ space: 10 }) {
                Button('导出 JSON')
                  .fontSize(13)
                  .fontColor(this.theme.palette.accent)
                  .backgroundColor(this.theme.palette.inputBackground)
                  .borderRadius(16)
                  .height(32)
                  .layoutWeight(1)
                  .accessibilityText('导出历史记录到沙箱文件')
                  .onClick(() => {
                    this.exportHistory();
                  })
                Button('清空历史')
                  .fontSize(13)
                  .fontColor(this.theme.palette.danger)
                  .backgroundColor(this.theme.palette.inputBackground)
                  .borderRadius(16)
                  .height(32)
                  .layoutWeight(1)
                  .onClick(() => {
                    if (this.historyStore !== null) {
                      this.historyStore.clear();
                      this.refreshHistory();
                    }
                  })
              }
              .width('100%')
              .margin({ top: 6 })
            }
          }
        }
        .padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }

  /** 训练 Tab：运动数据录入 + 分析结果 + 力量训练日志入口 */
  @Builder
  private trainTab(): void {
    Column() {
      // ===== 顶部栏：标题 + 记训练入口 =====
      Row() {
        Column({ space: 2 }) {
          Text('训练')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.palette.primaryText)
          Text('录入运动数据，端侧 Agent 即时分析')
            .fontSize(12)
            .fontColor(this.theme.palette.secondaryText)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Button('📝 记训练')
          .fontSize(14)
          .fontColor(this.theme.palette.accent)
          .backgroundColor(this.theme.palette.inputBackground)
          .borderRadius(18)
          .height(36)
          .accessibilityText('打开训练日志录入页')
          .onClick(() => {
            router.pushUrl({ url: 'pages/WorkoutLogPage' })
              .catch((err: Error) => {
                console.error(`openWorkoutLog failed: ${err.message}`);
              });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          // ===== 今日小贴士（本地内置，按日期轮换） =====
          SectionCard({ theme: this.theme, title: '💡 今日小贴士' }) {
            Text(this.todayTip())
              .fontSize(13)
              .fontColor(this.theme.palette.primaryText)
              .lineHeight(20)
          }

          // ===== 数据录入卡片 =====
          SectionCard({ theme: this.theme, title: '运动数据录入' }) {
            // 运动类型下拉
            Text('运动类型')
              .fontSize(13)
              .fontColor(this.theme.palette.secondaryText)
              .margin({ bottom: 4 })
            Select(this.buildSportOptions())
              .value(this.sportType)
              .fontColor(this.theme.palette.primaryText)
              .backgroundColor(this.theme.palette.inputBackground)
              .onSelect((index: number) => {
                this.sportType = SPORT_TYPE_LIST[index];
              })
              .margin({ bottom: 10 })

            this.numberField('运动时长（分钟）', this.durationText, (v: string) => {
              this.durationText = v;
            })
            this.numberField('平均心率（次/分）', this.hrText, (v: string) => {
              this.hrText = v;
            })
            this.textField('配速（如 6\'00"/km，无则填 -）', this.paceText, (v: string) => {
              this.paceText = v;
            })
            this.numberField('消耗热量（千卡）', this.caloriesText, (v: string) => {
              this.caloriesText = v;
            })
            this.numberField('训练负荷（0–100，留空自动估算）', this.loadText, (v: string) => {
              this.loadText = v;
            })

            // 校验错误提示
            if (this.errors.length > 0) {
              Column({ space: 4 }) {
                ForEach(this.errors, (err: string) => {
                  Text(`· ${err}`)
                    .fontSize(13)
                    .fontColor(this.theme.palette.danger)
                }, (err: string) => err)
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .margin({ bottom: 10 })
            }

            Row({ space: 10 }) {
              Button('开始分析')
                .fontColor(this.theme.palette.onAccent)
                .backgroundColor(this.theme.palette.accent)
                .borderRadius(20)
                .layoutWeight(1)
                .onClick(() => {
                  this.runManualAnalysis();
                })
              Button('模拟数据')
                .fontColor(this.theme.palette.accent)
                .backgroundColor(this.theme.palette.inputBackground)
                .borderRadius(20)
                .layoutWeight(1)
                .accessibilityText('生成一条模拟运动记录并分析')
                .onClick(() => {
                  this.runMockAnalysis();
                })
            }
            .width('100%')
            Button('读取手表')
              .fontColor(this.theme.palette.accent)
              .backgroundColor(this.theme.palette.inputBackground)
              .borderRadius(20)
              .width('100%')
              .margin({ top: 10 })
              .onClick(() => {
                this.runHealthKitRead();
              })
          }

          // ===== 分析结果（按引用传参 $$，@State 变化时卡片同步刷新） =====
          if (this.report !== null) {
            this.resultCards({ report: this.report })
          }

        }
        .padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }

  /** 计划 Tab：本周训练计划 + 引擎 V2 对比 + 规则设置 */
  @Builder
  private planTab(): void {
    Column() {
      // ===== 顶部栏：标题 =====
      Row() {
        Column({ space: 2 }) {
          Text('计划')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.palette.primaryText)
          Text('周训练计划与端侧规则参数')
            .fontSize(12)
            .fontColor(this.theme.palette.secondaryText)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          // ===== 本周训练计划 + 引擎 V2 对比（完成一次分析后生成） =====
          if (this.report !== null) {
            this.planCards({ report: this.report })
          } else {
            SectionCard({ theme: this.theme, title: '本周训练计划' }) {
              Column({ space: 10 }) {
                Text('🗓️')
                  .fontSize(44)
                Text('还没有本周计划')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.theme.palette.primaryText)
                Text('完成一次运动数据分析后，这里会生成本周训练计划（含休息日与强度轮换）')
                  .fontSize(13)
                  .fontColor(this.theme.palette.secondaryText)
                  .lineHeight(18)
                  .textAlign(TextAlign.Center)
                Button('⚡ 去训练页分析')
                  .fontSize(14)
                  .fontColor(this.theme.palette.onAccent)
                  .backgroundColor(this.theme.palette.accent)
                  .borderRadius(18)
                  .height(36)
                  .margin({ top: 4 })
                  .accessibilityText('切换到训练页进行运动数据分析')
                  .onClick(() => {
                    this.currentTab = 1;
                  })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
              .padding({ top: 8, bottom: 8 })
            }
          }

          // ===== 规则设置 =====
          SectionCard({ theme: this.theme, title: '规则设置（端侧参数，实时生效）' }) {
            this.configSlider({
              label: `超标阈值：${this.highThreshold}`, value: this.highThreshold, min: 60, max: 90,
              onSlide: (v: number) => {
                this.highThreshold = v;
                this.applyConfig();
              }
            })
            this.configSlider({
              label: `正常下限：${this.normalThreshold}`, value: this.normalThreshold, min: 30, max: 60,
              onSlide: (v: number) => {
                this.normalThreshold = v;
                this.applyConfig();
              }
            })
            this.configSlider({
              label: `蛋白质占比：${this.proteinPct}%`, value: this.proteinPct, min: 10, max: 50,
              onSlide: (v: number) => {
                this.proteinPct = v;
                this.applyConfig();
              }
            })
            this.configSlider({
              label: `碳水占比：${this.carbPct}%`, value: this.carbPct, min: 20, max: 70,
              onSlide: (v: number) => {
                this.carbPct = v;
                this.applyConfig();
              }
            })
            Text(`脂肪占比自动：${100 - this.proteinPct - this.carbPct}% · 热量下调系数固定 0.6`)
              .fontSize(12)
              .fontColor(this.theme.palette.secondaryText)
              .margin({ top: 4 })
            Row({ space: 8 }) {
              Text('引擎 V2 对比（加权评分 + 趋势斜率）')
                .fontSize(13)
                .fontColor(this.theme.palette.primaryText)
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.showV2 })
                .selectedColor(this.theme.palette.accent)
                .accessibilityText('切换引擎 V2 对比展示')
                .onChange((on: boolean) => {
                  this.showV2 = on;
                })
            }
            .width('100%')
            .margin({ top: 8 })
            if (this.configErrors.length > 0) {
              ForEach(this.configErrors, (err: string) => {
                Text(`· ${err}`)
                  .fontSize(13)
                  .fontColor(this.theme.palette.danger)
              }, (err: string) => err)
            } else {
              Text('参数已生效并保存在本地，重新分析后应用')
                .fontSize(12)
                .fontColor(this.theme.palette.success)
                .margin({ top: 4 })
            }
          }
        }
        .padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }

  /** 星期几文字（dateLabel 用） */
  private readonly weekWords: string[] = ['日', '一', '二', '三', '四', '五', '六'];

  /** 训练小贴士（本地内置，按一年中的第几天轮换，确定性无随机） */
  private readonly trainingTips: string[] = [
    '训练前 5–10 分钟动态热身，能显著降低受伤风险',
    '同一个肌群两次训练之间，至少间隔 48 小时',
    '组间休息：增力 2–3 分钟，增肌 60–90 秒',
    '蛋白质分摊到每餐 20–40g，吸收利用率更高',
    '睡眠不足 6 小时时，主动降低训练强度',
    '渐进超负荷：每周尝试多加 1 次次数或 2.5kg 重量',
    '训练后 30 分钟内补充碳水 + 蛋白质，恢复更快',
    '动作质量永远优先于重量，先标准再加重',
    '有氧安排在力量训练之后，避免影响力量表现',
    '连续高强度训练 3 天以上，安排一个主动恢复日'
  ];

  /** 时段问候语（按当前小时） */
  private greeting(): string {
    const hour: number = new Date().getHours();
    if (hour < 6) {
      return '夜深了 🌙';
    }
    if (hour < 11) {
      return '早上好 ☀️';
    }
    if (hour < 14) {
      return '中午好 🍚';
    }
    if (hour < 18) {
      return '下午好 💪';
    }
    return '晚上好 🌙';
  }

  /** 今日日期标签（M月D日 周X） */
  private dateLabel(): string {
    const now: Date = new Date();
    return `${now.getMonth() + 1}月${now.getDate()}日 周${this.weekWords[now.getDay()]}`;
  }

  /** 今日小贴士（按一年中的第几天轮换） */
  private todayTip(): string {
    const now: Date = new Date();
    const start: Date = new Date(now.getFullYear(), 0, 0);
    const dayOfYear: number = Math.floor((now.getTime() - start.getTime()) / 86400000);
    return this.trainingTips[dayOfYear % this.trainingTips.length];
  }

  /** 快速操作圆角按钮（首页横幅下方一行四个） */
  @Builder
  private quickAction(icon: string, label: string, action: () => void): void {
    Column({ space: 6 }) {
      Text(icon)
        .fontSize(20)
      Text(label)
        .fontSize(11)
        .fontColor(this.theme.palette.primaryText)
    }
    .layoutWeight(1)
    .padding({ top: 12, bottom: 12 })
    .borderRadius(14)
    .backgroundColor(this.theme.palette.cardBackground)
    .shadow({ radius: 10, color: this.theme.palette.cardShadow, offsetX: 0, offsetY: 3 })
    .accessibilityText(label)
    .onClick(action)
  }

  /** 负荷状态 → 语义色（色值来自调色板，非硬编码） */
  private loadColor(status: string): string {
    if (status === '超标') {
      return this.theme.palette.danger;
    }
    if (status === '正常') {
      return this.theme.palette.success;
    }
    return this.theme.palette.warning;
  }

  /** 趋势图叠加周均值折线（每 7 条为一组求均值，纯 Canvas 绘制） */
  private drawWeeklyAverageLine(): void {
    const ctx: CanvasRenderingContext2D = this.trendCtx;
    const width: number = 320;
    const height: number = 90;
    ctx.clearRect(0, 0, width, height);
    if (this.trend.length < 7) {
      return;
    }
    // 每 7 条记录聚合成一个周均值点
    const points: number[] = [];
    for (let i = 0; i + 7 <= this.trend.length; i += 7) {
      let sum: number = 0;
      for (let j = i; j < i + 7; j++) {
        sum += this.trend[j].load;
      }
      points.push(sum / 7);
    }
    if (points.length < 2) {
      return;
    }
    const stepX: number = width / (points.length - 1);
    ctx.strokeStyle = this.theme.palette.accent;
    ctx.lineWidth = 2;
    ctx.beginPath();
    points.forEach((avg: number, idx: number) => {
      const x: number = idx * stepX;
      const y: number = height - Math.max(4, avg * 0.6) - 14;
      if (idx === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    });
    ctx.stroke();
  }

  /** 规则设置滑杆（按引用传参 $$，状态变化时标签与滑块位置同步刷新；颜色全部来自调色板） */
  @Builder
  private configSlider($$: SliderSpec): void {
    Column({ space: 2 }) {
      Text($$.label)
        .fontSize(13)
        .fontColor(this.theme.palette.secondaryText)
      Slider({ value: $$.value, min: $$.min, max: $$.max, step: 5 })
        .selectedColor(this.theme.palette.accent)
        .trackColor(this.theme.palette.track)
        .blockColor(this.theme.palette.accent)
        .onChange((v: number) => {
          $$.onSlide(Math.round(v));
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ bottom: 8 })
  }

  /** 分析结果卡片组：$$ 按引用传参，@State report 更新时全量刷新，类型安全 */
  @Builder
  private resultCards($$: ReportRef): void {
    // 模块① 本次训练评估
    SectionCard({ theme: this.theme, title: '模块① 本次训练评估' }) {
      LoadBadge({
        theme: this.theme,
        status: $$.report.assessment.loadStatus,
        load: $$.report.assessment.load
      })
      Row({ space: 8 }) {
        Text('恢复状态')
          .fontSize(14)
          .fontColor(this.theme.palette.secondaryText)
        Text($$.report.assessment.recoveryStatus)
          .fontSize(14)
          .fontColor(this.theme.palette.primaryText)
      }
      .margin({ top: 12 })
      Row({ space: 8 }) {
        Text('建议恢复时长')
          .fontSize(14)
          .fontColor(this.theme.palette.secondaryText)
        Text(`${$$.report.assessment.suggestedRecoveryHours} 小时`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.palette.accent)
      }
      .margin({ top: 6 })
      Row({ space: 8 }) {
        Text('疲劳指数')
          .fontSize(14)
          .fontColor(this.theme.palette.secondaryText)
        Text(`${$$.report.fatigueIndex} / 100`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.palette.warning)
      }
      .margin({ top: 6 })
      Text($$.report.assessment.advice)
        .fontSize(14)
        .fontColor(this.theme.palette.primaryText)
        .lineHeight(21)
        .margin({ top: 10 })
    }

    // 模块② 饮食方案（Keep 风格：宏量占比条 + 带图食物卡片）
    SectionCard({ theme: this.theme, title: '模块② 饮食方案' }) {
      Text(`建议补充热量 ${$$.report.diet.totalCalories} 千卡`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.theme.palette.primaryText)
        .margin({ bottom: 12 })
      MacroBar({
        theme: this.theme, label: '蛋白质',
        pct: $$.report.diet.proteinPct, grams: $$.report.diet.proteinGrams,
        barColor: this.theme.palette.protein
      })
      MacroBar({
        theme: this.theme, label: '碳水化合物',
        pct: $$.report.diet.carbPct, grams: $$.report.diet.carbGrams,
        barColor: this.theme.palette.carb
      })
      MacroBar({
        theme: this.theme, label: '脂肪',
        pct: $$.report.diet.fatPct, grams: $$.report.diet.fatGrams,
        barColor: this.theme.palette.fat
      })
      this.foodRow({ title: '蛋白食材', foods: $$.report.diet.proteinFoods })
      this.foodRow({ title: '碳水食材', foods: $$.report.diet.carbFoods })
      this.foodRow({ title: '脂肪食材', foods: $$.report.diet.fatFoods })
      if ($$.report.diet.note.length > 0) {
        Text($$.report.diet.note)
          .fontSize(13)
          .fontColor(this.theme.palette.warning)
          .margin({ top: 8 })
      }
      // 免责声明（合规要求，必须展示）
      Text($$.report.diet.disclaimer)
        .fontSize(12)
        .fontColor(this.theme.palette.secondaryText)
        .margin({ top: 10 })
    }

    // 模块③ 下一次互补训练规划
    SectionCard({ theme: this.theme, title: '模块③ 下一次互补训练规划' }) {
      Text($$.report.nextWorkout.workoutType)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme.palette.accent)
      Row({ space: 16 }) {
        Text(`强度：${$$.report.nextWorkout.intensity}`)
          .fontSize(14)
          .fontColor(this.theme.palette.primaryText)
        Text(`时长：${$$.report.nextWorkout.durationMin} 分钟`)
          .fontSize(14)
          .fontColor(this.theme.palette.primaryText)
      }
      .margin({ top: 8 })
      Text(`互补理由：${$$.report.nextWorkout.reason}`)
        .fontSize(14)
        .fontColor(this.theme.palette.secondaryText)
        .lineHeight(21)
        .margin({ top: 8 })
    }

    Text(`报告生成于 ${$$.report.generatedAt} · 全部计算在本地完成`)
      .fontSize(12)
      .fontColor(this.theme.palette.secondaryText)
      .margin({ bottom: 24 })
  }

  /** 计划 Tab 卡片组：本周训练计划 + 引擎 V2 对比（$$ 按引用传参，@State report 更新时刷新） */
  @Builder
  private planCards($$: ReportRef): void {
    // 扩展模块 本周训练计划（7 天周期，含休息日与强度轮换）
    SectionCard({ theme: this.theme, title: '本周训练计划' }) {
      ForEach($$.report.weeklyPlan.days, (day: WeeklyPlanDay) => {
        Column() {
          Row({ space: 8 }) {
            Text(day.dayLabel)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.theme.palette.primaryText)
              .width(44)
            Text(day.workoutType)
              .fontSize(13)
              .fontColor(this.theme.palette.primaryText)
              .layoutWeight(1)
            Text(day.durationMin > 0 ? `${day.intensity} · ${day.durationMin}分钟` : '休息')
              .fontSize(12)
              .fontColor(this.theme.palette.secondaryText)
          }
          .width('100%')
          // 推荐动作芯片（训练日）：点击跳转动作库详情页看 3D 示例
          if (day.exerciseIds.length > 0) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(day.exerciseIds, (eid: string) => {
                Text(this.exerciseName(eid))
                  .fontSize(12)
                  .fontColor(this.theme.palette.accent)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .borderRadius(12)
                  .backgroundColor(this.theme.palette.inputBackground)
                  .margin({ right: 6, bottom: 4 })
                  .accessibilityText(`查看动作 ${this.exerciseName(eid)} 的详情`)
                  .onClick(() => {
                    this.openExercise(eid);
                  })
              }, (eid: string) => eid)
            }
            .width('100%')
            .padding({ left: 52 })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 6 })
      }, (day: WeeklyPlanDay) => day.dayLabel)
      Text($$.report.weeklyPlan.note)
        .fontSize(12)
        .fontColor(this.theme.palette.secondaryText)
        .lineHeight(18)
        .margin({ top: 4 })
    }

    // 引擎 V2 对比（加权评分 + 趋势斜率；开关在规则设置区）
    SectionCard({ theme: this.theme, title: '引擎 V2 对比（实验）' }) {
      if (this.showV2 && this.reportV2 !== null) {
        Text(`V1 负荷评估：${$$.report.assessment.loadStatus}（负荷 ${$$.report.assessment.load}）`)
          .fontSize(13)
          .fontColor(this.theme.palette.primaryText)
        Text(`V2 负荷评估：${this.reportV2.assessment.loadStatus}（有效负荷 ${this.reportV2.assessment.load}）`)
          .fontSize(13)
          .fontColor(this.theme.palette.primaryText)
          .margin({ top: 4 })
        Text(`V2 下次训练：${this.reportV2.nextWorkout.workoutType} · ${this.reportV2.nextWorkout.intensity}`)
          .fontSize(13)
          .fontColor(this.theme.palette.secondaryText)
          .margin({ top: 4 })
      } else {
        Text('在下方「规则设置」中打开 V2 对比开关后，这里展示双引擎输出差异')
          .fontSize(13)
          .fontColor(this.theme.palette.secondaryText)
      }
    }
  }

  /** 一组食物卡片（Keep 风格：横向滑动，图片 + 名称 + 每 100g 热量） */
  @Builder
  private foodRow($$: FoodRowSpec): void {
    Text($$.title)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.theme.palette.secondaryText)
      .margin({ top: 8, bottom: 6 })
    Scroll() {
      Row({ space: 8 }) {
        ForEach($$.foods, (name: string) => {
          this.foodCard(name)
        }, (name: string) => name)
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  /** 单个食物卡片（名称来自食物库，查找逻辑在辅助方法中，builder 内保持声明式） */
  @Builder
  private foodCard(name: string): void {
    Column({ space: 4 }) {
      Image($r(this.foodImage(name)))
        .width(56)
        .height(56)
        .borderRadius(10)
      Text(name)
        .fontSize(12)
        .fontColor(this.theme.palette.primaryText)
        .maxLines(1)
      Text(this.foodKcalText(name))
        .fontSize(10)
        .fontColor(this.theme.palette.secondaryText)
        .maxLines(1)
    }
    .padding(8)
    .borderRadius(12)
    .backgroundColor(this.theme.palette.inputBackground)
  }

  /** 食物图片资源名（未收录或暂无图片时回退到应用图标） */
  private foodImage(name: string): string {
    const food: FoodItem | null = FoodLibrary.findByName(name);
    if (food === null || food.imageRes.length === 0) {
      return 'app.media.app_icon';
    }
    return food.imageRes;
  }

  /** 食物热量文案（未收录时仅显示名称） */
  private foodKcalText(name: string): string {
    const food: FoodItem | null = FoodLibrary.findByName(name);
    if (food === null) {
      return '';
    }
    return `${food.kcalPer100g} kcal/100g`;
  }

  /** 运动类型下拉选项 */
  private buildSportOptions(): SelectOption[] {
    return SPORT_TYPE_LIST.map((t: string): SelectOption => {
      return { value: t };
    });
  }

  /** 数字输入框（统一样式，颜色全部来自调色板） */
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

  /** 准备度摘要行（参数局部收窄，规避 ArkTS 对 this 成员不做智能收窄的限制） */
  @Builder
  private readinessLine(report: ReadinessReport | null): void {
    if (report !== null) {
      Row({ space: 8 }) {
        Text(`准备度 ${report.score}`)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(report.score >= 50 ?
            this.theme.palette.accent : this.theme.palette.warning)
        Text(`建议强度：${report.tier}`)
          .fontSize(13)
          .fontColor(this.theme.palette.primaryText)
        if (report.overtrainingLevel !== '无') {
          Text(`${report.overtrainingLevel}色预警`)
            .fontSize(13)
            .fontColor(this.theme.palette.danger)
        }
      }
      .width('100%')
      .margin({ top: 10 })
    }
  }

  /** 1–5 评分选择（睡眠质量/酸痛程度共用） */
  @Builder
  private rateSelect(label: string, current: number, onPick: (v: number) => void): void {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(13)
        .fontColor(this.theme.palette.secondaryText)
      Row({ space: 6 }) {
        ForEach(this.rateOptions, (option: string) => {
          Text(option)
            .fontSize(13)
            .fontColor(`${current}` === option ?
              this.theme.palette.onAccent : this.theme.palette.primaryText)
            .textAlign(TextAlign.Center)
            .width(32)
            .height(30)
            .borderRadius(8)
            .backgroundColor(`${current}` === option ?
              this.theme.palette.accent : this.theme.palette.inputBackground)
            .accessibilityText(`${label} ${option} 分`)
            .onClick(() => {
              onPick(Number(option));
            })
        }, (option: string) => option)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 10 })
  }

  /** 文本输入框（统一样式，颜色全部来自调色板） */
  @Builder
  private textField(label: string, value: string, onChange: (v: string) => void): void {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(13)
        .fontColor(this.theme.palette.secondaryText)
      TextInput({ text: value })
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

  /** 图例小方块 + 文字（热力图例用） */
  @Builder
  private legendChip(color: string, label: string): void {
    Row({ space: 4 }) {
      Column()
        .width(12)
        .height(12)
        .borderRadius(3)
        .backgroundColor(color)
      Text(label)
        .fontSize(11)
        .fontColor(this.theme.palette.secondaryText)
    }
  }

  /** 今日营养达成卡（参数局部收窄，规避 ArkTS 对 this 成员不做智能收窄的限制） */
  @Builder
  private intakeCard(intake: MacroAchievement | null): void {
    if (intake !== null) {
      SectionCard({ theme: this.theme, title: '今日营养达成' }) {
        Row({ space: 16 }) {
          Stack() {
            Progress({ value: intake.overallPct, total: 100, type: ProgressType.Ring })
              .width(84)
              .height(84)
              .color(this.theme.palette.success)
              .backgroundColor(this.theme.palette.track)
            Text(`${intake.overallPct}%`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.theme.palette.primaryText)
          }
          .accessibilityText(`今日营养达成率 ${intake.overallPct}%`)
          Column({ space: 4 }) {
            Text(`蛋白质 ${intake.actual.proteinGrams}g（${intake.proteinPct}%）`)
              .fontSize(13)
              .fontColor(this.theme.palette.primaryText)
            Text(`碳水 ${intake.actual.carbGrams}g（${intake.carbPct}%）`)
              .fontSize(13)
              .fontColor(this.theme.palette.primaryText)
            Text(`脂肪 ${intake.actual.fatGrams}g（${intake.fatPct}%）`)
              .fontSize(13)
              .fontColor(this.theme.palette.primaryText)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        Button('＋ 记一餐')
          .fontSize(14)
          .fontColor(this.theme.palette.accent)
          .backgroundColor(this.theme.palette.inputBackground)
          .borderRadius(18)
          .height(36)
          .margin({ top: 10 })
          .accessibilityText('打开食物选择页记录一餐')
          .onClick(() => {
            router.pushUrl({ url: 'pages/FoodPicker' })
              .then(() => {
                this.refreshIntake();
              })
              .catch((err: Error) => {
                console.error(`openFoodPicker failed: ${err.message}`);
              });
          })
      }
    }
  }
}
