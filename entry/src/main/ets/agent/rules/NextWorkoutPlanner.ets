/*
 * 文件标注：自主业务逻辑 —— 模块③ 下一次互补训练规划规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 模块③
 * 确定性规则：运动互补原则——优先保护疲劳身体，再按本次训练类型推导互补刺激。
 * 规则表：
 *   load ≥ 80        → 强制「主动恢复（拉伸/散步）」，强度低，20 分钟
 *   力量训练         → 有氧慢跑 + 全身拉伸（低-中，25min）
 *   跑步/骑行/游泳   → 力量/核心（中，30min）
 *   跳绳/爬楼机      → 力量/核心（中，30min，中高冲击有氧同耐力分支）
 *   椭圆机/动感单车  → 力量/核心（中，30min，低冲击有氧同耐力分支）
 *   高强度间歇       → 主动恢复（低，20min）
 *   瑜伽/拉伸        → 力量/有氧（中，30min）
 *   步行             → 力量（中，25min）
 *   其他             → 交替上下肢（中，30min）
 */
import { HealthRecord, SportType } from '../../model/HealthRecord';
import { NextWorkoutPlan } from '../AnalysisResult';

/** 负荷「超标」阈值默认值（与赛事规则一致；可由 RuleConfig 覆盖） */
const DEFAULT_LOAD_HIGH: number = 80;

export class NextWorkoutPlanner {
  private readonly loadHigh: number;

  constructor(loadHigh: number = DEFAULT_LOAD_HIGH) {
    this.loadHigh = loadHigh;
  }

  plan(record: HealthRecord): NextWorkoutPlan {
    // 负荷超标：强制主动恢复，优先级高于类型推导
    if (record.trainingLoad >= this.loadHigh) {
      return {
        workoutType: '主动恢复（拉伸/散步）',
        intensity: '低',
        durationMin: 20,
        reason: '本次负荷超标，身体需要充分恢复；以低强度主动恢复促进血液循环、加速代谢废物清除，避免叠加疲劳。'
      };
    }

    switch (record.sportType) {
      case SportType.STRENGTH:
        return {
          workoutType: '有氧慢跑 + 全身拉伸',
          intensity: '低-中',
          durationMin: 25,
          reason: '力量训练以无氧供能与肌纤维微损伤为主，互补低-中强度有氧可促进恢复并提升心肺基础，拉伸缓解肌肉紧张。'
        };
      case SportType.RUN:
      case SportType.CYCLE:
      case SportType.SWIM:
      case SportType.JUMP_ROPE:
      case SportType.ELLIPTICAL:
      case SportType.SPINNING:
      case SportType.STAIR:
        return {
          workoutType: '力量/核心',
          intensity: '中',
          durationMin: 30,
          reason: '本次为有氧耐力训练，互补力量/核心训练可增强肌群支撑与动作经济性，降低运动损伤风险。'
        };
      case SportType.HIIT:
        return {
          workoutType: '主动恢复',
          intensity: '低',
          durationMin: 20,
          reason: '高强度间歇对神经与心肺系统刺激大，下一次以低强度主动恢复为主，防止过度疲劳累积。'
        };
      case SportType.YOGA:
        return {
          workoutType: '力量/有氧',
          intensity: '中',
          durationMin: 30,
          reason: '瑜伽/拉伸以柔韧与放松为主，互补中等强度力量或有氧训练，均衡发展力量与心肺能力。'
        };
      case SportType.WALK:
        return {
          workoutType: '力量',
          intensity: '中',
          durationMin: 25,
          reason: '步行强度较低，互补中等强度力量训练可有效提升肌肉量与基础代谢。'
        };
      default:
        return {
          workoutType: '交替上下肢',
          intensity: '中',
          durationMin: 30,
          reason: '本次训练类型较特殊，采用上下肢交替训练，在一侧肌群工作时另一侧恢复，实现互补刺激。'
        };
    }
  }
}
