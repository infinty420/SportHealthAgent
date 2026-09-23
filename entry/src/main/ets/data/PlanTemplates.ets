/*
 * 文件标注：自主业务逻辑 —— 计划模板库（参赛者知识产权）
 *
 * 数据接入层 · 计划模板
 * 内置 5 套经典周期化模板（PPL 三分化 / 上下肢二分化 / 全身训练 / 新手线性 5x5 / 减脂有氧混合），
 * 一键生成中周期：模板参数（周数/每周次数）传入 MesocyclePlanner，无需改代码。
 * 全部数据本地内置，无网络请求。
 */

/** 训练计划模板 */
export interface PlanTemplate {
  /** 唯一标识 */
  id: string;
  /** 模板名称 */
  name: string;
  /** 一句话说明 */
  description: string;
  /** 每周训练次数 */
  daysPerWeek: number;
  /** 每日训练内容（按训练日顺序循环） */
  split: string[];
  /** 建议中周期周数（4–8） */
  lengthWeeks: number;
  /** 适用人群 */
  audience: string;
}

export class PlanTemplates {
  /** 内置模板清单（顺序即展示顺序） */
  static all(): PlanTemplate[] {
    const list: PlanTemplate[] = [];
    list.push({
      id: 'ppl', name: 'PPL 三分化', description: '推 / 拉 / 腿 三轮循环，肌群刺激频率高',
      daysPerWeek: 6, split: ['推（胸肩三头）', '拉（背二头）', '腿（臀腿核心）'],
      lengthWeeks: 6, audience: '进阶'
    });
    list.push({
      id: 'upper_lower', name: '上下肢二分化', description: '上肢 / 下肢隔天交替，恢复充分',
      daysPerWeek: 4, split: ['上肢', '下肢'],
      lengthWeeks: 6, audience: '进阶'
    });
    list.push({
      id: 'full_body', name: '全身训练', description: '每次练遍全身大肌群，时间利用率高',
      daysPerWeek: 3, split: ['全身 A（蹲+推+拉）', '全身 B（髋伸+推+拉）'],
      lengthWeeks: 8, audience: '新手 / 进阶'
    });
    list.push({
      id: 'linear_5x5', name: '新手线性 5×5', description: '三大项 5 组 5 次线性加重，快速打基础',
      daysPerWeek: 3, split: ['深蹲+卧推+划船', '深蹲+推举+硬拉'],
      lengthWeeks: 8, audience: '新手'
    });
    list.push({
      id: 'fat_loss', name: '减脂有氧混合', description: '力量保肌 + 有氧创造缺口，每周 2 次 HIIT',
      daysPerWeek: 5, split: ['力量（上肢）', '有氧（中等强度）', '力量（下肢）', 'HIIT', '有氧（低强度）'],
      lengthWeeks: 6, audience: '减脂'
    });
    return list;
  }

  /** 按 id 查模板；不存在返回 null */
  static byId(id: string): PlanTemplate | null {
    const list: PlanTemplate[] = PlanTemplates.all();
    for (let i: number = 0; i < list.length; i++) {
      if (list[i].id === id) {
        return list[i];
      }
    }
    return null;
  }
}
