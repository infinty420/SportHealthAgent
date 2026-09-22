/*
 * 文件标注：AI 生成 —— 人体部位热力色斑定位数据（纯本地数据，无网络）
 *
 * 数据层 · BodyPathData
 * 真人轮廓底图（media/body_front.png / body_back.png）上各部位的发光色斑定位：
 * 键为部位名（成对部位带左/右后缀），值为归一化 [x, y, r]（0–100，相对人体图宽/高）。
 * groupOf() 把左/右后缀键归并到 7 个部位组（胸/背/肩/腿/臀/腹/手臂）。
 */

export class BodyPathData {
  /** 正面色斑：肩/胸/腹/臀/手臂/腿 */
  static getFrontSpots(): Map<string, number[]> {
    const spots: Map<string, number[]> = new Map<string, number[]>();
    spots.set('肩左', [22, 15, 12]);
    spots.set('肩右', [78, 15, 12]);
    spots.set('胸', [50, 28, 17]);
    spots.set('腹', [50, 46, 13]);
    spots.set('臀', [50, 62, 15]);
    spots.set('手臂左', [8, 36, 10]);
    spots.set('手臂右', [92, 36, 10]);
    spots.set('腿左', [42, 83, 13]);
    spots.set('腿右', [58, 83, 13]);
    return spots;
  }

  /** 背面色斑：肩/背/臀/手臂/腿 */
  static getBackSpots(): Map<string, number[]> {
    const spots: Map<string, number[]> = new Map<string, number[]>();
    spots.set('肩左', [22, 15, 12]);
    spots.set('肩右', [78, 15, 12]);
    spots.set('背', [50, 34, 18]);
    spots.set('臀', [50, 62, 15]);
    spots.set('手臂左', [8, 36, 10]);
    spots.set('手臂右', [92, 36, 10]);
    spots.set('腿左', [42, 83, 13]);
    spots.set('腿右', [58, 83, 13]);
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
