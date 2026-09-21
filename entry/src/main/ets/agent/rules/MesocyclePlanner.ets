/*
 * 文件标注：自主业务逻辑 —— 中周期负荷编排规则算法（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 中周期规划模块
 * 按 4–8 周编排训练负荷：每周容量在 100% 基准上按 +10% 波浪递增，
 * 每 4 周（以及末周）安排减载周（容量降至 60%），
 * 高疲劳且平台期时给出"立即减载"建议。
 * 确定性规则计算，无网络请求、无模型推理。
 */

/** 单周负荷安排 */
export interface MesocycleWeek {
  /** 周序号（从 1 开始） */
  weekIndex: number;
  /** 容量百分比（100 = 基准周容量；减载周为 60） */
  volumePct: number;
  /** 强度百分比（相对个人 1RM 的建议重量系数） */
  intensityPct: number;
  /** 是否减载周 */
  isDeload: boolean;
  /** 本周中文提示 */
  note: string;
}

/** 完整中周期计划 */
export interface MesocyclePlan {
  /** 各周安排（按 weekIndex 升序） */
  weeks: MesocycleWeek[];
  /** 周期总周数（4–8） */
  lengthWeeks: number;
  /** 是否建议立即减载（疲劳指数 ≥ 70 且处于平台期） */
  deloadAdvised: boolean;
  /** 计划整体中文说明 */
  note: string;
}

export class MesocyclePlanner {
  /** 周期周数上下限 */
  private static readonly MIN_WEEKS: number = 4;
  private static readonly MAX_WEEKS: number = 8;
  /** 渐进周容量步进（%） */
  private static readonly VOLUME_STEP: number = 10;
  /** 减载周容量（%）：减载 40% */
  private static readonly DELOAD_VOLUME: number = 60;
  /** 减载周强度（%） */
  private static readonly DELOAD_INTENSITY: number = 70;
  /** 立即减载的疲劳指数阈值 */
  private static readonly DELOAD_FATIGUE_MIN: number = 70;

  /**
   * 生成中周期计划。
   * @param lengthWeeks 期望周数（钳制到 4–8）
   * @param fatigueIndex 当前疲劳指数（FatigueModel.compute 输出，0–100）
   * @param plateau 是否处于平台期（渐进超负荷模块判定）
   */
  static plan(lengthWeeks: number = 6, fatigueIndex: number = 0, plateau: boolean = false): MesocyclePlan {
    const length: number = Math.min(MesocyclePlanner.MAX_WEEKS,
      Math.max(MesocyclePlanner.MIN_WEEKS, Math.round(lengthWeeks)));
    const weeks: MesocycleWeek[] = [];
    let buildStep: number = 0;
    for (let week: number = 1; week <= length; week++) {
      // 末周固定减载；此前每 4 周穿插一个减载周
      const deload: boolean = week === length || week % 4 === 0;
      if (deload) {
        const deloadWeek: MesocycleWeek = {
          weekIndex: week,
          volumePct: MesocyclePlanner.DELOAD_VOLUME,
          intensityPct: MesocyclePlanner.DELOAD_INTENSITY,
          isDeload: true,
          note: week === length ?
            '减载周：容量降至 60%，主动恢复，迎接下一周期' :
            '阶段减载：容量降至 60%，缓解累积疲劳'
        };
        weeks.push(deloadWeek);
        buildStep = 0;
      } else {
        buildStep++;
        const volume: number = 100 + buildStep * MesocyclePlanner.VOLUME_STEP;
        const intensity: number = Math.min(95, 85 + buildStep * 2.5);
        const buildWeek: MesocycleWeek = {
          weekIndex: week,
          volumePct: volume,
          intensityPct: Math.round(intensity * 10) / 10,
          isDeload: false,
          note: `渐进周 ${buildStep}：容量 ${volume}%，强度 ${Math.round(intensity * 10) / 10}%`
        };
        weeks.push(buildWeek);
      }
    }
    const advised: boolean = fatigueIndex >= MesocyclePlanner.DELOAD_FATIGUE_MIN && plateau;
    const plan: MesocyclePlan = {
      weeks: weeks,
      lengthWeeks: length,
      deloadAdvised: advised,
      note: advised ?
        `当前疲劳 ${fatigueIndex} 且进入平台期，建议本周立即执行减载（容量 60%）` :
        `${length} 周中周期：波浪渐进 + 末周减载`
    };
    return plan;
  }
}
