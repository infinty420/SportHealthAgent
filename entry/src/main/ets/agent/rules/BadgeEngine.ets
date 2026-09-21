/*
 * 文件标注：自主业务逻辑 —— 成就徽章规则引擎（参赛者知识产权）
 *
 * 端侧 Agent 引擎 · 徽章模块
 * 基于本地统计输入按确定性规则判定 20 枚徽章的达成情况与进度，
 * 每枚徽章附命中规则说明（可解释）。
 * 确定性规则计算，无网络请求、无模型推理。
 */

/** 徽章统计输入（由调用方聚合本地数据后传入） */
export interface BadgeStats {
  /** 累计训练次数 */
  totalSessions: number;
  /** 累计训练时长（分钟） */
  totalDurationMin: number;
  /** 当前连续训练天数 */
  currentStreak: number;
  /** 历史最长连续天数 */
  bestStreak: number;
  /** 本周训练次数 */
  weeklySessions: number;
  /** 周目标次数 */
  weeklyTarget: number;
  /** 本周容量（公斤） */
  weeklyVolumeKg: number;
  /** 上周容量（公斤） */
  prevWeeklyVolumeKg: number;
  /** 累计容量（公斤） */
  totalVolumeKg: number;
  /** 已破纪录的动作数 */
  prCount: number;
  /** 练过的不同动作数 */
  exercisesTried: number;
  /** 是否已填写画像 */
  profileFilled: boolean;
}

/** 单枚徽章 */
export interface Badge {
  id: string;
  name: string;
  description: string;
  /** 是否已达成 */
  earned: boolean;
  /** 达成进度 0–100 */
  progress: number;
  /** 命中规则说明 */
  rule: string;
}

export class BadgeEngine {
  private static pct(current: number, target: number): number {
    if (target <= 0) {
      return 0;
    }
    return Math.min(100, Math.round(current * 100 / target));
  }

  /** 评估全部徽章（固定顺序输出，未达成的排在后面由 UI 自行置灰） */
  static evaluate(stats: BadgeStats): Badge[] {
    const badges: Badge[] = [];
    const add = (id: string, name: string, desc: string, current: number, target: number, rule: string): void => {
      const badge: Badge = {
        id: id,
        name: name,
        description: desc,
        earned: current >= target,
        progress: BadgeEngine.pct(current, target),
        rule: rule
      };
      badges.push(badge);
    };

    add('first_session', '首练', '完成第 1 次训练', stats.totalSessions, 1, '累计次数 ≥ 1');
    add('sessions_7', '渐入佳境', '累计训练 7 次', stats.totalSessions, 7, '累计次数 ≥ 7');
    add('sessions_30', '习惯养成', '累计训练 30 次', stats.totalSessions, 30, '累计次数 ≥ 30');
    add('sessions_100', '百次俱乐部', '累计训练 100 次', stats.totalSessions, 100, '累计次数 ≥ 100');
    add('streak_3', '三日不断', '连续训练 3 天', stats.currentStreak, 3, '当前连练 ≥ 3 天');
    add('streak_7', '七日连击', '连续训练 7 天', stats.currentStreak, 7, '当前连练 ≥ 7 天');
    add('streak_21', '三七之约', '连续训练 21 天', stats.bestStreak, 21, '最长连练 ≥ 21 天');
    add('duration_300', '五小时', '累计训练 300 分钟', stats.totalDurationMin, 300, '累计时长 ≥ 300 分钟');
    add('duration_1000', '千分钟', '累计训练 1000 分钟', stats.totalDurationMin, 1000, '累计时长 ≥ 1000 分钟');
    add('duration_5000', '五千分钟', '累计训练 5000 分钟', stats.totalDurationMin, 5000, '累计时长 ≥ 5000 分钟');
    add('full_week', '全勤周', '本周次数达成周目标', stats.weeklySessions,
      Math.max(1, stats.weeklyTarget), '本周次数 ≥ 周目标');
    add('volume_double', '容量翻倍', '本周容量达上周 2 倍', stats.prevWeeklyVolumeKg > 0 ?
      Math.round(stats.weeklyVolumeKg * 100 / stats.prevWeeklyVolumeKg) : 0, 200, '本周容量 ≥ 上周 × 2');
    add('volume_1t', '周举一吨', '本周容量 1000 公斤', stats.weeklyVolumeKg, 1000, '本周容量 ≥ 1000kg');
    add('volume_10t', '万吨巨轮', '累计容量 10000 公斤', stats.totalVolumeKg, 10000, '累计容量 ≥ 10000kg');
    add('first_pr', '首次破纪录', '任一动作打破纪录', stats.prCount, 1, '破纪录动作数 ≥ 1');
    add('pr_5', '多点开花', '5 个动作打破纪录', stats.prCount, 5, '破纪录动作数 ≥ 5');
    add('explorer_10', '动作探索者', '练过 10 个不同动作', stats.exercisesTried, 10, '不同动作数 ≥ 10');
    add('explorer_30', '动作收藏家', '练过 30 个不同动作', stats.exercisesTried, 30, '不同动作数 ≥ 30');
    add('profile_done', '认识你自己', '填写用户画像', stats.profileFilled ? 1 : 0, 1, '画像已填写');
    add('streak_30', '月度铁人', '最长连续训练 30 天', stats.bestStreak, 30, '最长连练 ≥ 30 天');
    return badges;
  }

  /** 已达成数量 */
  static earnedCount(badges: Badge[]): number {
    let count: number = 0;
    badges.forEach((badge: Badge) => {
      if (badge.earned) {
        count++;
      }
    });
    return count;
  }
}
