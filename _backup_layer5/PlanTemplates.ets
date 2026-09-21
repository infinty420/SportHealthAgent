/*
 * 文件标注：自主业务逻辑 —— 训练计划模板库（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 计划模板模块
 * 内置 ≥5 套经典中周期模板（PPL / 上下肢 / 全身 / 新手线性 / 有氧恢复），
 * 一键生成：模板拆分（每周 7 天的部位安排）+ MesocyclePlanner 负荷波浪编排。
 * 确定性规则计算，无网络请求、无模型推理。
 */
import { MesocyclePlanner, MesocyclePlan, MesocycleWeek } from './MesocyclePlanner';

/** 一套计划模板 */
export interface PlanTemplate {
  /** 唯一标识 */
  id: string;
  /** 模板名 */
  name: string;
  /** 适用人群/目标说明 */
  description: string;
  /** 每周训练天数 */
  daysPerWeek: number;
  /** 一周 7 天的安排（周一到周日，休息日记「休息」） */
  weekDays: string[];
  /** 建议中周期周数（传给 MesocyclePlanner，钳制到 4–8） */
  recommendedWeeks: number;
}

/** 模板 + 中周期编排的合成结果（一键生成输出） */
export interface TemplateMesocycle {
  /** 模板名 */
  templateName: string;
  /** 每周部位安排（周一到周日） */
  weekDays: string[];
  /** 负荷编排（波浪渐进 + 减载） */
  plan: MesocyclePlan;
  /** 逐周中文说明（负荷 × 部位安排） */
  weekLines: string[];
}

export class PlanTemplates {
  private static readonly TEMPLATES: PlanTemplate[] = [
    {
      id: 'ppl',
      name: '推拉腿（PPL）',
      description: '进阶增肌：推/拉/腿循环，每周 6 练，部位频次高',
      daysPerWeek: 6,
      weekDays: ['推（胸+肩+三头）', '拉（背+二头）', '腿（腿+臀）',
        '推（胸+肩+三头）', '拉（背+二头）', '腿（腿+臀）', '休息'],
      recommendedWeeks: 6
    },
    {
      id: 'upper_lower',
      name: '上下肢分化',
      description: '中级增力：上肢/下肢交替，每周 4 练，恢复充足',
      daysPerWeek: 4,
      weekDays: ['上肢（胸+背+肩+手臂）', '下肢（腿+臀+腹）', '休息',
        '上肢（胸+背+肩+手臂）', '下肢（腿+臀+腹）', '休息', '休息'],
      recommendedWeeks: 6
    },
    {
      id: 'full_body',
      name: '全身训练',
      description: '时间紧张者：每次练全身，每周 3 练，动作以复合为主',
      daysPerWeek: 3,
      weekDays: ['全身（腿+胸+背+腹）', '休息', '全身（腿+背+肩+手臂）', '休息',
        '全身（腿+胸+背+腹）', '休息', '休息'],
      recommendedWeeks: 4
    },
    {
      id: 'novice_linear',
      name: '新手线性',
      description: '新手入门：A/B 全身课表轮换，每周 3 练，每次加重线性进阶',
      daysPerWeek: 3,
      weekDays: ['全身 A（深蹲+推类+拉类）', '休息', '全身 B（硬拉变式+推类+拉类）', '休息',
        '全身 A（深蹲+推类+拉类）', '休息', '休息'],
      recommendedWeeks: 4
    },
    {
      id: 'cardio_recovery',
      name: '有氧恢复',
      description: '减脂/恢复期：中低强度有氧 + 拉伸，每周 5 练，负荷温和',
      daysPerWeek: 5,
      weekDays: ['有氧低强度（快走/椭圆机）', '拉伸放松', '有氧中强度（慢跑/单车）', '休息',
        '有氧低强度（爬楼机/划船机）', '拉伸放松', '休息'],
      recommendedWeeks: 4
    }
  ];

  /** 全部模板（≥5 套） */
  static all(): PlanTemplate[] {
    return PlanTemplates.TEMPLATES;
  }

  /** 按 id 查找；找不到返回 null */
  static findById(id: string): PlanTemplate | null {
    for (let i: number = 0; i < PlanTemplates.TEMPLATES.length; i++) {
      if (PlanTemplates.TEMPLATES[i].id === id) {
        return PlanTemplates.TEMPLATES[i];
      }
    }
    return null;
  }

  /**
   * 一键生成中周期：模板部位安排 × MesocyclePlanner 负荷波浪。
   * @param templateId 模板 id（非法 id 返回 null）
   * @param fatigueIndex 当前疲劳指数（0–100）
   * @param plateau 是否处于平台期
   */
  static generateMesocycle(templateId: string, fatigueIndex: number = 0, plateau: boolean = false): TemplateMesocycle | null {
    const template: PlanTemplate | null = PlanTemplates.findById(templateId);
    if (template === null) {
      return null;
    }
    const plan: MesocyclePlan = MesocyclePlanner.plan(template.recommendedWeeks, fatigueIndex, plateau);
    const lines: string[] = [];
    plan.weeks.forEach((week: MesocycleWeek) => {
      if (week.isDeload) {
        lines.push(`第 ${week.weekIndex} 周 · ${week.note}（部位安排不变，组数减半）`);
      } else {
        lines.push(`第 ${week.weekIndex} 周 · ${week.note}，按课表执行 ${template.daysPerWeek} 练`);
      }
    });
    const result: TemplateMesocycle = {
      templateName: template.name,
      weekDays: template.weekDays,
      plan: plan,
      weekLines: lines
    };
    return result;
  }
}
