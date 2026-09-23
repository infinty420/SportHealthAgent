/*
 * 文件标注：AI 生成 —— 人体部位热力色斑定位数据（纯本地数据，无网络）
 *
 * 数据层 · BodyPathData
 * 真人轮廓底图（media/body_front.png / body_back.png）上各部位的发光色斑定位：
 * 键为部位名（成对部位带左/右后缀），值为归一化 [x, y, r]（0–100，相对人体图宽/高）。
 * groupOf() 把左/右后缀键归并到 7 个部位组（胸/背/肩/腿/臀/腹/手臂）。
 */

export class BodyPathData {
  /** 正面色斑：肩/胸/腹/臀/手臂/腿（已按 AI 真人肌肉底图校准） */
  static getFrontSpots(): Map<string, number[]> {
    const spots: Map<string, number[]> = new Map<string, number[]>();
    spots.set('肩左', [25, 19, 12]);
    spots.set('肩右', [75, 19, 12]);
    spots.set('胸', [50, 21, 15]);
    spots.set('腹', [50, 33, 12]);
    spots.set('臀', [50, 46, 13]);
    spots.set('手臂左', [17, 37, 10]);
    spots.set('手臂右', [83, 37, 10]);
    spots.set('腿左', [40, 60, 13]);
    spots.set('腿右', [60, 60, 13]);
    return spots;
  }

  /** 背面色斑：肩/背/臀/手臂/腿（已按 AI 真人肌肉底图校准） */
  static getBackSpots(): Map<string, number[]> {
    const spots: Map<string, number[]> = new Map<string, number[]>();
    spots.set('肩左', [26, 18, 12]);
    spots.set('肩右', [74, 18, 12]);
    spots.set('背', [50, 31, 17]);
    spots.set('臀', [50, 47, 14]);
    spots.set('手臂左', [17, 36, 10]);
    spots.set('手臂右', [83, 36, 10]);
    spots.set('腿左', [42, 60, 13]);
    spots.set('腿右', [58, 60, 13]);
    return spots;
  }

  /** 色斑键 → 部位组名（左/右后缀归并，其余原样） */
  static groupOf(key: string): string {
    if (key === '手臂左' || key === '手臂右') {
      return '手臂';
    }
    if (key === '腿左' || key === '腿右') {
      return '腿';
    }
    if (key === '肩左' || key === '肩右') {
      return '肩';
    }
    return key;
  }
}
