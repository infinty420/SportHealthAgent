/*
 * 文件标注：自主业务逻辑 —— 7 天周期训练计划规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 周计划模块
 * 基于最近 7 次历史记录 + 疲劳指数 + 用户画像，输出 7 天周期计划：
 * 肌群分化轮换（上肢推/上肢拉/下肢/有氧/核心）、休息日穿插、强度随波形轮换。
 * 确定性规则计算，无网络请求、无云端大模型调用。
 */
import { HealthRecord } from '../../model/HealthRecord';
import { HistoryEntry } from '../../data/HistoryStore';
import { FatigueModel, FatigueResult } from './FatigueModel';
import { ExperienceLevel, UserProfile } from '../../model/UserProfile';
import { WeeklyPlan, WeeklyPlanDay } from '../AnalysisResult';
import { ExerciseItem, ExerciseLibrary } from '../../data/ExerciseLibrary';
import { ExerciseSafety } from './ExerciseSafety';

const DAY_LABELS: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

/** 轮换槽位 → 对应肌群（用于从动作库挑选推荐动作） */
const SLOT_MUSCLES: string[][] = [
  ['胸', '肩', '三头'],
  ['背', '二头'],
  ['腿', '臀'],
  ['有氧', '有氧'],
  ['腹', '拉伸']
];

export class TrainingPlanPlanner {
  /**
   * 生成 7 天周期计划。
   * 规则：
   *   疲劳指数 ≥ 70 → 强度波形降一档，第 2/5 天休息
   *   经验新手 → 3 练 4 休；进阶 → 4 练；高阶 → 5 练
   *   肌群按 上肢推→上肢拉→下肢→有氧→核心 顺序轮换，避免连续两天同肌群
   */
  plan(record: HealthRecord, history: HistoryEntry[], profile: UserProfile,
    injuredParts: string[] = []): WeeklyPlan {
    const fatigue: FatigueResult = FatigueModel.compute(history);
    const trainDays: number = profile.experienceLevel === ExperienceLevel.ADVANCED ? 5 :
      (profile.experienceLevel === ExperienceLevel.INTERMEDIATE ? 4 : 3);

    const rotation: string[] = ['上肢推（胸/肩/三头）', '上肢拉（背/二头）', '下肢（腿/臀）', '有氧（跳绳/慢跑）', '核心与柔韧'];
    const days: WeeklyPlanDay[] = [];
    let trained: number = 0;
    let rotationIndex: number = 0;

    for (let i = 0; i < 7; i++) {
      // 疲劳高时强制周中多休息；每周训练日达标后其余休息
      const forceRest: boolean = fatigue.index >= 70 && (i === 1 || i === 4);
      const canTrain: boolean = trained < trainDays && !forceRest && (i === 0 || trained * 7 < i * trainDays + 1 || i >= 5);
      if (canTrain) {
        const intensity: string = this.intensityFor(fatigue.index, rotationIndex);
        const day: WeeklyPlanDay = {
          dayLabel: DAY_LABELS[i],
          workoutType: rotation[rotationIndex % rotation.length],
          intensity: intensity,
          durationMin: intensity === '低' ? 25 : (intensity === '低-中' ? 30 : 40),
          exerciseIds: this.pickExercises(rotationIndex % rotation.length, rotationIndex, injuredParts)
        };
        days.push(day);
        trained++;
        rotationIndex++;
      } else {
        const restDay: WeeklyPlanDay = {
          dayLabel: DAY_LABELS[i],
          workoutType: i === 6 ? '休息' : '主动恢复（拉伸/散步）',
          intensity: '低',
          durationMin: i === 6 ? 0 : 20,
          exerciseIds: []
        };
        days.push(restDay);
      }
    }

    const plan: WeeklyPlan = {
      days: days,
      fatigueIndex: fatigue.index,
      note: `当前疲劳指数 ${fatigue.index}（${fatigue.level}），本周安排 ${trained} 次训练；` +
        '肌群按推拉腿顺序分化轮换，高疲劳时自动增加休息。'
    };
    return plan;
  }

  /** 强度波形：中 → 低-中 → 中-高 轮换；疲劳高时整体降一档 */
  private intensityFor(fatigueIndex: number, slot: number): string {
    const wave: string[] = ['中', '低-中', '中-高'];
    const base: string = wave[slot % wave.length];
    if (fatigueIndex >= 70) {
      return '低';
    }
    if (fatigueIndex >= 40 && base === '中-高') {
      return '中';
    }
    return base;
  }

  /**
   * 按轮换槽位从动作库挑选推荐动作（每个肌群 1 个，确定性轮换）。
   * offset 随训练日递增，使不同周次的推荐动作不重复；
   * 伤病部位经 ExerciseSafety 禁忌过滤，全部禁忌时退回未过滤列表。
   */
  private pickExercises(slot: number, offset: number, injuredParts: string[]): string[] {
    const ids: string[] = [];
    const muscles: string[] = SLOT_MUSCLES[slot % SLOT_MUSCLES.length];
    muscles.forEach((muscle: string, idx: number) => {
      const all: ExerciseItem[] = ExerciseLibrary.filter('全部', muscle);
      const safe: ExerciseItem[] = ExerciseSafety.filterSafe(all, injuredParts);
      const list: ExerciseItem[] = safe.length > 0 ? safe : all;
      if (list.length > 0) {
        const pick: ExerciseItem = list[(offset + idx) % list.length];
        if (ids.indexOf(pick.id) < 0) {
          ids.push(pick.id);
        }
      }
    });
    return ids;
  }
}
