/*
 * 文件标注：自主业务逻辑 —— 动作伤病禁忌推导与过滤规则（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 伤病安全模块
 * 不改 ExerciseItem 结构，按 动作名/部位/器械/难度 规则推导每个动作的
 * 禁忌部位（腰/膝/肩/腕）与风险等级，并提供伤病过滤器。
 * 确定性规则计算，无网络请求、无模型推理。
 */
import { ExerciseItem } from '../../data/ExerciseLibrary';

/** 动作安全信息（由规则推导，非数据表） */
export interface ExerciseSafetyInfo {
  /** 禁忌部位：腰/膝/肩/腕 子集 */
  contraindications: string[];
  /** 风险等级：低/中/高 */
  riskLevel: string;
}

export class ExerciseSafety {
  /** 推导单个动作的禁忌部位与风险等级 */
  static of(exercise: ExerciseItem): ExerciseSafetyInfo {
    const parts: string[] = [];
    const name: string = exercise.name;
    const lowerBack: boolean = exercise.subMuscle === '下背' ||
      name.indexOf('硬拉') >= 0 || name.indexOf('划船') >= 0 || name.indexOf('挺身') >= 0 ||
      name.indexOf('深蹲') >= 0 || name.indexOf('臀推') >= 0;
    const knee: boolean = name.indexOf('深蹲') >= 0 || name.indexOf('箭步') >= 0 ||
      name.indexOf('腿举') >= 0 || name.indexOf('腿屈伸') >= 0 || name.indexOf('哈克') >= 0 ||
      name.indexOf('跳') >= 0;
    const shoulder: boolean = exercise.muscle === '肩' || name.indexOf('推举') >= 0 ||
      name.indexOf('卧推') >= 0 || name.indexOf('飞鸟') >= 0 || name.indexOf('夹胸') >= 0 ||
      name.indexOf('平举') >= 0 || name.indexOf('引体') >= 0;
    const wrist: boolean = exercise.muscle === '小臂' || name.indexOf('腕') >= 0 ||
      name.indexOf('弯举') >= 0 || name.indexOf('握') >= 0;
    if (lowerBack) {
      parts.push('腰');
    }
    if (knee) {
      parts.push('膝');
    }
    if (shoulder) {
      parts.push('肩');
    }
    if (wrist) {
      parts.push('腕');
    }

    let risk: string = '低';
    if (exercise.muscle === '拉伸' || exercise.equipment === '自重' || exercise.equipment === '弹力带') {
      risk = '低';
    } else if (exercise.equipment === '器械' || exercise.equipment === '绳索') {
      risk = '中';
    } else if (exercise.equipment === '杠铃' || exercise.equipment === '史密斯' || exercise.difficulty === '高级') {
      risk = '高';
    } else {
      risk = '中';
    }
    const safety: ExerciseSafetyInfo = { contraindications: parts, riskLevel: risk };
    return safety;
  }

  /** 动作对当前伤病部位是否安全（无交集 = 安全） */
  static isSafeFor(exercise: ExerciseItem, injuredParts: string[]): boolean {
    if (injuredParts.length === 0) {
      return true;
    }
    const safety: ExerciseSafetyInfo = ExerciseSafety.of(exercise);
    for (let i = 0; i < injuredParts.length; i++) {
      if (safety.contraindications.indexOf(injuredParts[i]) >= 0) {
        return false;
      }
    }
    return true;
  }

  /** 从动作列表中过滤掉触碰当前伤病的动作 */
  static filterSafe(list: ExerciseItem[], injuredParts: string[]): ExerciseItem[] {
    if (injuredParts.length === 0) {
      return list;
    }
    return list.filter((item: ExerciseItem) => ExerciseSafety.isSafeFor(item, injuredParts));
  }
}
