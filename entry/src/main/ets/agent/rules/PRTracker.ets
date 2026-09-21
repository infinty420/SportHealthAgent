/*
 * 文件标注：自主业务逻辑 —— 个人纪录（PR）追踪规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · PR 追踪模块
 * 按动作汇总历史训练日志，输出每个动作的最大重量与最大估算 1RM，
 * 并判定最近一次训练是否打破纪录（破纪录标记）。
 * 确定性规则计算，无网络请求、无模型推理。
 */
import { WorkoutLog, WorkoutSet } from '../../model/WorkoutLog';
import { StrengthCalculator } from './StrengthCalculator';
import { ExerciseItem, ExerciseLibrary } from '../../data/ExerciseLibrary';

/** 单个动作的纪录快照 */
export interface ExercisePR {
  /** 动作 id */
  exerciseId: string;
  /** 动作名（查表；找不到时用 id） */
  exerciseName: string;
  /** 历史最大重量（公斤；自重动作为 0） */
  maxWeightKg: number;
  /** 最大估算 1RM（公斤；自重动作为 0） */
  bestOneRepMax: number;
  /** 最大单次总次数（自重动作的主要标尺） */
  bestTotalReps: number;
  /** 训练次数 */
  sessions: number;
}

/** 最近一次训练是否破纪录的判定结果 */
export interface PRCheck {
  /** 是否破纪录（重量、1RM 或总次数任一创新高，且非首次记录） */
  isPR: boolean;
  /** 中文说明（含对比依据） */
  message: string;
}

/** 某一天发生的一次破纪录事件（按天分类查询用） */
export interface DailyPREvent {
  /** 日期键（YYYY-MM-DD，本地时区） */
  dateKey: string;
  /** 动作名（查表；找不到时用 id） */
  exerciseName: string;
  /** 破纪录说明（含对比依据） */
  message: string;
}

export class PRTracker {
  /** 汇总全部动作的纪录（按动作名排序输出） */
  static summarize(logs: WorkoutLog[]): ExercisePR[] {
    const byExercise: Map<string, WorkoutLog[]> = new Map<string, WorkoutLog[]>();
    logs.forEach((log: WorkoutLog) => {
      const bucket: WorkoutLog[] = byExercise.get(log.exerciseId) ?? [];
      bucket.push(log);
      byExercise.set(log.exerciseId, bucket);
    });
    const result: ExercisePR[] = [];
    byExercise.forEach((exerciseLogs: WorkoutLog[], exerciseId: string) => {
      const item: ExerciseItem | null = ExerciseLibrary.findById(exerciseId);
      let maxWeight: number = 0;
      let bestOrm: number = 0;
      let bestReps: number = 0;
      exerciseLogs.forEach((log: WorkoutLog) => {
        const best: WorkoutSet | null = log.bestSet();
        if (best !== null && best.weightKg > maxWeight) {
          maxWeight = best.weightKg;
        }
        const orm: number = StrengthCalculator.bestOneRepMax(log);
        if (orm > bestOrm) {
          bestOrm = orm;
        }
        const reps: number = log.totalReps();
        if (reps > bestReps) {
          bestReps = reps;
        }
      });
      const pr: ExercisePR = {
        exerciseId: exerciseId,
        exerciseName: item === null ? exerciseId : item.name,
        maxWeightKg: maxWeight,
        bestOneRepMax: Math.round(bestOrm * 10) / 10,
        bestTotalReps: bestReps,
        sessions: exerciseLogs.length
      };
      result.push(pr);
    });
    result.sort((a: ExercisePR, b: ExercisePR) => a.exerciseName < b.exerciseName ? -1 : 1);
    return result;
  }

  /**
   * 判定最新一条日志是否打破该动作的历史纪录。
   * @param history 该动作全部日志（时间正序，最新在最后）
   */
  static checkLatest(history: WorkoutLog[]): PRCheck {
    const none: PRCheck = { isPR: false, message: '暂无该动作的历史记录' };
    if (history.length === 0) {
      return none;
    }
    if (history.length === 1) {
      const first: PRCheck = { isPR: false, message: '首次记录，将作为后续对比基准' };
      return first;
    }
    const latest: WorkoutLog = history[history.length - 1];
    const before: WorkoutLog[] = history.slice(0, history.length - 1);
    const bodyweight: boolean = latest.totalVolume() === 0;

    let prevBestOrm: number = 0;
    let prevBestReps: number = 0;
    let prevMaxWeight: number = 0;
    before.forEach((log: WorkoutLog) => {
      prevBestOrm = Math.max(prevBestOrm, StrengthCalculator.bestOneRepMax(log));
      prevBestReps = Math.max(prevBestReps, log.totalReps());
      const best: WorkoutSet | null = log.bestSet();
      if (best !== null) {
        prevMaxWeight = Math.max(prevMaxWeight, best.weightKg);
      }
    });

    const latestOrm: number = StrengthCalculator.bestOneRepMax(latest);
    const latestReps: number = latest.totalReps();
    const latestBest: WorkoutSet | null = latest.bestSet();
    const latestWeight: number = latestBest === null ? 0 : latestBest.weightKg;

    if (bodyweight) {
      if (latestReps > prevBestReps) {
        const pr: PRCheck = {
          isPR: true,
          message: `新纪录！总次数 ${latestReps}，超越历史最佳 ${prevBestReps}`
        };
        return pr;
      }
    } else {
      if (latestOrm > prevBestOrm) {
        const pr: PRCheck = {
          isPR: true,
          message: `新纪录！估算 1RM ${Math.round(latestOrm)}kg，超越历史最佳 ${Math.round(prevBestOrm)}kg`
        };
        return pr;
      }
      if (latestWeight > prevMaxWeight) {
        const pr: PRCheck = {
          isPR: true,
          message: `新纪录！最大重量 ${latestWeight}kg，超越历史最佳 ${prevMaxWeight}kg`
        };
        return pr;
      }
    }
    const noPr: PRCheck = { isPR: false, message: '未破纪录，继续累积' };
    return noPr;
  }

  /**
   * 按天聚合全部破纪录事件（发现页日历/按天查询用）。
   * 对每个动作按时间正序逐条回放，复用 checkLatest 判定每次训练是否破纪录，
   * 命中则归入该日志的 dateKey。返回按日期倒序的事件列表。
   */
  static dailyPREvents(logs: WorkoutLog[]): DailyPREvent[] {
    const byExercise: Map<string, WorkoutLog[]> = new Map<string, WorkoutLog[]>();
    logs.forEach((log: WorkoutLog) => {
      const bucket: WorkoutLog[] = byExercise.get(log.exerciseId) ?? [];
      bucket.push(log);
      byExercise.set(log.exerciseId, bucket);
    });
    const events: DailyPREvent[] = [];
    byExercise.forEach((exerciseLogs: WorkoutLog[], exerciseId: string) => {
      const asc: WorkoutLog[] = exerciseLogs.concat([]).sort((a: WorkoutLog, b: WorkoutLog) => a.timestamp - b.timestamp);
      const item: ExerciseItem | null = ExerciseLibrary.findById(exerciseId);
      const name: string = item === null ? exerciseId : item.name;
      for (let i: number = 1; i < asc.length; i++) {
        const history: WorkoutLog[] = asc.slice(0, i + 1);
        const check: PRCheck = PRTracker.checkLatest(history);
        if (check.isPR) {
          const event: DailyPREvent = {
            dateKey: asc[i].dateKey(),
            exerciseName: name,
            message: check.message
          };
          events.push(event);
        }
      }
    });
    events.sort((a: DailyPREvent, b: DailyPREvent) => a.dateKey < b.dateKey ? 1 : -1);
    return events;
  }
}
