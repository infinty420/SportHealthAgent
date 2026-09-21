/*
 * 文件标注：自主业务逻辑 —— 肌群平衡分析规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 肌群平衡模块
 * 按肌群汇总最近一周有效组数，计算 推:拉:腿 与 上肢:下肢 容量比；
 * 失衡时从动作库查表推荐补强动作。
 * 确定性规则计算，无网络请求、无模型推理。
 */
import { WorkoutLog } from '../../model/WorkoutLog';
import { ExerciseItem, ExerciseLibrary } from '../../data/ExerciseLibrary';
import { StrengthCalculator } from './StrengthCalculator';
import { ExerciseSafety } from './ExerciseSafety';

/** 失衡判定阈值：弱侧组数 < 强侧 × 0.75 视为失衡 */
const IMBALANCE_RATIO: number = 0.75;
/** 上下肢失衡阈值：下肢 < 上肢 × 0.5（推拉腿规则之外的兜底） */
const LOWER_UPPER_RATIO: number = 0.5;

/** 肌群平衡报告 */
export interface MuscleBalanceReport {
  /** 推类有效组数（胸 + 肩 + 三头） */
  pushSets: number;
  /** 拉类有效组数（背 + 二头） */
  pullSets: number;
  /** 腿类有效组数（腿 + 臀） */
  legSets: number;
  /** 上肢合计（推 + 拉 + 小臂） */
  upperSets: number;
  /** 下肢合计（腿 + 臀） */
  lowerSets: number;
  /** 失衡描述（无失衡时为空数组） */
  imbalances: string[];
  /** 补强动作名（从动作库确定性查表） */
  recommendations: string[];
}

export class MuscleBalanceAnalyzer {
  /**
   * 分析一周训练日志的肌群平衡。
   * 组数口径：有效组（RPE ≥ 7）；无法映射到动作库部位的日志不计入推拉腿比例。
   * injuredParts 可选：有伤病时补强推荐先过滤禁忌动作，全部禁忌则该肌群不再推荐。
   */
  static analyze(logs: WorkoutLog[], injuredParts: string[] = []): MuscleBalanceReport {
    const setsByMuscle: Map<string, number> = new Map<string, number>();
    logs.forEach((log: WorkoutLog) => {
      const exercise: ExerciseItem | null = ExerciseLibrary.findById(log.exerciseId);
      if (exercise === null) {
        return;
      }
      const effective: number = StrengthCalculator.effectiveSets(log);
      const current: number = setsByMuscle.get(exercise.muscle) ?? 0;
      setsByMuscle.set(exercise.muscle, current + effective);
    });

    const report: MuscleBalanceReport = {
      pushSets: MuscleBalanceAnalyzer.sumOf(setsByMuscle, ['胸', '肩', '三头']),
      pullSets: MuscleBalanceAnalyzer.sumOf(setsByMuscle, ['背', '二头']),
      legSets: MuscleBalanceAnalyzer.sumOf(setsByMuscle, ['腿', '臀']),
      upperSets: 0,
      lowerSets: 0,
      imbalances: [],
      recommendations: []
    };
    report.upperSets = report.pushSets + report.pullSets + MuscleBalanceAnalyzer.sumOf(setsByMuscle, ['小臂']);
    report.lowerSets = report.legSets;

    // 推 vs 拉
    if (report.pushSets > 0 && report.pullSets < report.pushSets * IMBALANCE_RATIO) {
      report.imbalances.push(`拉力训练不足（拉 ${report.pullSets} 组 vs 推 ${report.pushSets} 组），圆肩风险升高`);
      report.recommendations = report.recommendations.concat(MuscleBalanceAnalyzer.pickFrom(['背', '二头'], injuredParts));
    } else if (report.pullSets > 0 && report.pushSets < report.pullSets * IMBALANCE_RATIO) {
      report.imbalances.push(`推力训练不足（推 ${report.pushSets} 组 vs 拉 ${report.pullSets} 组）`);
      report.recommendations = report.recommendations.concat(MuscleBalanceAnalyzer.pickFrom(['胸', '肩'], injuredParts));
    }
    // 推拉 vs 腿
    const upperMain: number = Math.max(report.pushSets, report.pullSets);
    if (upperMain > 0 && report.legSets < upperMain * IMBALANCE_RATIO) {
      report.imbalances.push(`下肢训练不足（腿 ${report.legSets} 组），推拉腿比例失衡`);
      report.recommendations = report.recommendations.concat(MuscleBalanceAnalyzer.pickFrom(['腿', '臀'], injuredParts));
    }
    // 上肢 vs 下肢
    if (report.upperSets > 0 && report.lowerSets < report.upperSets * LOWER_UPPER_RATIO) {
      if (report.imbalances.indexOf('下肢占比过低') < 0 && report.legSets >= upperMain * IMBALANCE_RATIO) {
        report.imbalances.push('下肢占比过低，上下肢容量失衡');
      }
    }
    return report;
  }

  /** 汇总若干肌群的有效组数 */
  private static sumOf(setsByMuscle: Map<string, number>, muscles: string[]): number {
    let total: number = 0;
    muscles.forEach((muscle: string) => {
      total += setsByMuscle.get(muscle) ?? 0;
    });
    return total;
  }

  /** 从动作库为指定肌群各挑 1 个补强动作（确定性：取列表前部不同器械；有伤病时先过滤禁忌动作） */
  private static pickFrom(muscles: string[], injuredParts: string[] = []): string[] {
    const names: string[] = [];
    muscles.forEach((muscle: string) => {
      const list: ExerciseItem[] = ExerciseSafety.filterSafe(ExerciseLibrary.filter('全部', muscle), injuredParts);
      for (let i = 0; i < list.length && names.length < 4; i++) {
        if (names.indexOf(list[i].name) < 0) {
          names.push(list[i].name);
          break;
        }
      }
    });
    return names;
  }
}
