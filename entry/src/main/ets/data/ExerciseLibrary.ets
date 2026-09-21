/*
 * 文件标注：AI 生成 —— 动作库数据模型与内置数据集（通用数据内容）
 *
 * 数据接入层 · 健身动作库（参考「快练」：顶部器械分类 + 左侧部位筛选 + 双列卡片网格）
 * 分类维度：器械（杠铃/哑铃/史密斯/绳索/自重/弹力带）× 部位（胸/背/腿/肩/手臂/臀/核心/全身）。
 * 部位细分子类：胸（上胸/中胸/下胸）、背（上背/下背/背阔肌/大小圆肌）、肩（前束/中束/后束/整体）等，
 * 通过 subMuscle 字段展示；全部数据与 3D 动作示例图本地内置（resources/base/media/ex2_*.jpg），不联网。
 */

/** 动作条目 */
export interface ExerciseItem {
  /** 唯一标识（用于路由传参与图片资源名） */
  id: string;
  /** 动作名称 */
  name: string;
  /** 器械分类：杠铃/哑铃/史密斯/绳索/自重/弹力带 */
  equipment: string;
  /** 主要训练部位：胸/背/腿/肩/手臂/臀/核心/全身 */
  muscle: string;
  /** 细分部位：如 中胸/背阔肌/前束/股四头肌 等 */
  subMuscle: string;
  /** 难度：初级 / 中级 / 高级 */
  difficulty: string;
  /** 训练建议（组数 × 次数/时长） */
  prescription: string;
  /** 目标肌群 */
  targetMuscles: string;
  /** 呼吸节奏 */
  breathing: string;
  /** 动作描述 */
  description: string;
  /** 动作步骤要领 */
  keyPoints: string[];
  /** 常见错误（新手易犯，用于纠错提示） */
  commonMistakes: string[];
  /** 3D 动作示例图资源名（app.media.ex2_*） */
  imageRes: string;
}

/** 器械分类（顺序即顶部标签栏展示顺序） */
export const EXERCISE_EQUIPMENTS: string[] = ['杠铃', '哑铃', '史密斯', '绳索', '自重', '弹力带', '器械'];

/** 部位分类（顺序即左侧边栏展示顺序） */
export const EXERCISE_MUSCLES: string[] = ['胸', '背', '腿', '肩', '二头', '三头', '小臂', '臀', '腹', '有氧', '拉伸', '全身'];

/** 内置动作数据（201 个，每个动作均有专属 3D 解剖风示例图 ex2_<id>） */
const EXERCISES: ExerciseItem[] = [
  // ==================== 杠铃 ====================
  {
    id: 'bb_bench', name: '杠铃卧推', equipment: '杠铃', muscle: '胸', subMuscle: '中胸', difficulty: '中级',
    prescription: '4 组 × 8–10 次', targetMuscles: '胸大肌、三角肌前束、肱三头肌',
    breathing: '下放吸气，推起呼气',
    description: '胸部训练王牌动作，发展上肢推力的核心练习。',
    keyPoints: ['杠铃位于眼睛正上方，双手比肩稍宽握杠', '双脚踩实地面，臀部收紧，肩胛后缩下沉', '下放至胸肌正上方，杠铃距身体 1–2 厘米', '底端稍停，胸肌发力推起至锁骨正上方'],
    commonMistakes: ['腰部过度拱起、臀部离开凳面', '杠铃下放到颈部或上胸过高位置', '手腕后折承重，应让杠铃压在掌根'],
    imageRes: 'app.media.ex2_bb_bench'
  },
  {
    id: 'bb_squat', name: '杠铃深蹲', equipment: '杠铃', muscle: '腿', subMuscle: '股四头肌', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '股四头肌、臀大肌、核心',
    breathing: '下蹲吸气憋住，站起呼气',
    description: '下肢力量之王，全面发展腿部与臀部。',
    keyPoints: ['杠铃置于斜方肌上部，非颈椎', '双脚与肩同宽，脚尖略外八', '屈髋屈膝下蹲至大腿低于水平', '膝盖方向始终与脚尖一致'],
    commonMistakes: ['膝盖内扣，与脚尖方向不一致', '脚跟离地、重心压在前脚掌', '弓腰塌腰，核心没有预先收紧'],
    imageRes: 'app.media.ex2_bb_squat'
  },
  {
    id: 'bb_deadlift', name: '杠铃硬拉', equipment: '杠铃', muscle: '背', subMuscle: '下背', difficulty: '高级',
    prescription: '4 组 × 8 次', targetMuscles: '竖脊肌、臀大肌、腘绳肌',
    breathing: '拉起前深吸气憋住，放下呼气',
    description: '全身后链训练动作，力量举三大项之一。',
    keyPoints: ['杠铃贴近小腿，双手正握或正反握', '背部全程保持平直不弓腰', '蹬地伸髋拉起，杠铃贴身', '顶点站立锁定，不要后仰'],
    commonMistakes: ['弓腰拉起，腰椎代偿受力', '杠铃远离身体绕膝前拉', '顶点过度后仰挤压腰椎'],
    imageRes: 'app.media.ex2_bb_deadlift'
  },
  {
    id: 'bb_press', name: '杠铃肩上推举', equipment: '杠铃', muscle: '肩', subMuscle: '整体', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '三角肌前中束、肱三头肌',
    breathing: '推起呼气，下放吸气',
    description: '站姿过顶推举，打造肩部围度与上肢推力。',
    keyPoints: ['握距略宽于肩，杠铃置于锁骨', '核心收紧，臀部夹紧防后仰', '垂直推至头顶正上方', '下放控制至起始位'],
    commonMistakes: ['腰椎过度后仰把推举变成上斜卧推', '耸肩代偿，斜方肌借力过多', '推起轨迹前飘而非垂直向上'],
    imageRes: 'app.media.ex2_bb_press'
  },
  {
    id: 'bb_curl', name: '杠铃弯举', equipment: '杠铃', muscle: '二头', subMuscle: '整体', difficulty: '初级',
    prescription: '4 组 × 10–12 次', targetMuscles: '肱二头肌、肱肌',
    breathing: '弯举呼气，下放吸气',
    description: '肱二头肌围度基础动作，杠铃可上更大重量。',
    keyPoints: ['双手与肩同宽反握杠铃', '大臂贴紧体侧固定不动', '弯举至肩前充分收缩', '下放控制 2–3 秒'],
    commonMistakes: ['身体前后摆动借力甩起杠铃', '大臂离开体侧前移', '下放过快没有离心控制'],
    imageRes: 'app.media.ex2_bb_curl'
  },
  {
    id: 'bb_reversecurl', name: '杠铃反握弯举', equipment: '杠铃', muscle: '小臂', subMuscle: '肱桡肌', difficulty: '初级',
    prescription: '3 组 × 12 次', targetMuscles: '肱桡肌、小臂伸肌群',
    breathing: '弯举呼气，下放吸气',
    description: '正握弯举变式，强化小臂与肱桡肌，让手臂更粗壮。',
    keyPoints: ['双手正握（手心向下）与肩同宽', '大臂贴紧体侧固定', '弯举至前臂接近上臂', '下放缓慢控制'],
    commonMistakes: ['重量过大导致手腕代偿借力', '大臂摆动', '下放到底完全松掉张力'],
    imageRes: 'app.media.ex2_bb_reversecurl'
  },
  {
    id: 'bb_decline', name: '下斜杠铃卧推', equipment: '杠铃', muscle: '胸', subMuscle: '下胸', difficulty: '中级',
    prescription: '4 组 × 8–10 次', targetMuscles: '胸大肌下部、肱三头肌',
    breathing: '下放吸气，推起呼气',
    description: '下斜角度强化下胸线条，让胸型更饱满立体。',
    keyPoints: ['下斜凳固定双腿，角度 15–30 度', '握距略宽于肩', '下放至下胸位置', '垂直向上推起'],
    commonMistakes: ['下放位置过高变成平板卧推', '腿部固定不牢身体下滑', '弹胸借力推起'],
    imageRes: 'app.media.ex2_bb_decline'
  },
  {
    id: 'bb_row', name: '杠铃俯身划船', equipment: '杠铃', muscle: '背', subMuscle: '上背', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '背阔肌、斜方肌中束、菱形肌',
    breathing: '拉起呼气，下放吸气',
    description: '背部厚度核心动作，俯身位全程保持背部平直。',
    keyPoints: ['俯身约 45 度，背部平直', '正握略宽于肩', '沿大腿拉向下腹部', '顶峰收缩肩胛'],
    commonMistakes: ['弓腰驼背拉起', '身体上下晃动借力', '拉向胸部导致行程过短'],
    imageRes: 'app.media.ex2_bb_row'
  },
  {
    id: 'bb_rdl', name: '罗马尼亚硬拉', equipment: '杠铃', muscle: '背', subMuscle: '下背', difficulty: '中级',
    prescription: '4 组 × 10–12 次', targetMuscles: '腘绳肌、臀大肌、竖脊肌',
    breathing: '下放吸气，伸髋呼气',
    description: '腘绳肌与臀部的黄金拉伸-收缩动作，膝盖微屈固定。',
    keyPoints: ['站姿握杠，膝盖微屈固定', '屈髋后推臀部下放杠铃', '下放至小腿中段感受后侧拉伸', '伸髋夹臀回到直立'],
    commonMistakes: ['膝盖屈伸过多变成深蹲', '弓腰下放', '下放幅度不足没有拉伸感'],
    imageRes: 'app.media.ex2_bb_rdl'
  },
  {
    id: 'bb_tbarrow', name: 'T杠划船', equipment: '杠铃', muscle: '背', subMuscle: '上背', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '中背、背阔肌、菱形肌',
    breathing: '拉起呼气，下放吸气',
    description: '杠铃一端固定划船，中背厚度利器，轨迹稳定易上重量。',
    keyPoints: ['杠铃一端固定墙角或地雷架', '俯身背部平直', '双手握杠铃游离端', '拉向胸口顶峰收缩'],
    commonMistakes: ['弓腰借力', '站姿过高俯身不足', '左右晃动甩起重量'],
    imageRes: 'app.media.ex2_bb_tbarrow'
  },
  {
    id: 'bb_uprightrow', name: '杠铃直立划船', equipment: '杠铃', muscle: '肩', subMuscle: '中束', difficulty: '中级',
    prescription: '3 组 × 12 次', targetMuscles: '三角肌中束、斜方肌',
    breathing: '上拉呼气，下放吸气',
    description: '肩部宽度复合动作，沿身体上拉至胸高。',
    keyPoints: ['窄于肩握距正握', '杠铃贴身垂直上拉', '肘部始终高于手腕', '拉至胸骨高度即可'],
    commonMistakes: ['拉得过高挤压肩峰', '握距过窄手腕不适', '身体后仰借力'],
    imageRes: 'app.media.ex2_bb_uprightrow'
  },
  {
    id: 'bb_sumo', name: '相扑深蹲', equipment: '杠铃', muscle: '腿', subMuscle: '臀腿内侧', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '股四头肌、臀大肌、内收肌',
    breathing: '下蹲吸气，站起呼气',
    description: '宽站距深蹲变式，强化大腿内侧与臀部。',
    keyPoints: ['站距明显宽于肩，脚尖外展 45 度', '杠铃置于斜方肌上部', '膝盖沿脚尖方向打开下蹲', '站起时夹紧臀部'],
    commonMistakes: ['膝盖内扣', '站距过宽失去稳定', '上身前倾过多'],
    imageRes: 'app.media.ex2_bb_sumo'
  },
  {
    id: 'bb_preacher', name: '牧师凳弯举', equipment: '杠铃', muscle: '二头', subMuscle: '短头', difficulty: '中级',
    prescription: '3 组 × 10–12 次', targetMuscles: '肱二头肌短头',
    breathing: '弯举呼气，下放吸气',
    description: '牧师凳固定大臂，彻底孤立二头，杜绝借力。',
    keyPoints: ['腋窝贴紧凳面顶端', '反握杠铃下放至接近伸直', '弯举至肩前收缩', '下放缓慢不失控'],
    commonMistakes: ['下放到底超伸肘关节', '臀部离开凳子', '顶端耸肩借力'],
    imageRes: 'app.media.ex2_bb_preacher'
  },
  {
    id: 'bb_closegrip', name: '窄距杠铃卧推', equipment: '杠铃', muscle: '三头', subMuscle: '整体', difficulty: '中级',
    prescription: '4 组 × 8–10 次', targetMuscles: '肱三头肌、胸大肌内侧',
    breathing: '下放吸气，推起呼气',
    description: '三头力量王牌动作，可上大重量的复合练习。',
    keyPoints: ['握距与肩同宽', '肘部贴近身体下放至下胸', '三头发力推起', '手腕中立不后折'],
    commonMistakes: ['握距过窄手腕受压', '肘部外展变成胸部主导', '下放弹胸借力'],
    imageRes: 'app.media.ex2_bb_closegrip'
  },
  {
    id: 'bb_skullcrusher', name: '仰卧臂屈伸', equipment: '杠铃', muscle: '三头', subMuscle: '长头', difficulty: '中级',
    prescription: '3 组 × 10–12 次', targetMuscles: '肱三头肌长头',
    breathing: '屈肘吸气，伸肘呼气',
    description: '仰卧位三头孤立动作，充分拉伸长头。',
    keyPoints: ['仰卧凳面，双手窄握杠铃举过肩', '大臂垂直固定不动', '屈肘下放杠铃至额头上方', '三头发力伸直手臂'],
    commonMistakes: ['大臂前后晃动', '下放失控砸向面部', '肘部外张过宽'],
    imageRes: 'app.media.ex2_bb_skullcrusher'
  },
  // ==================== 哑铃 ====================
  {
    id: 'db_bench', name: '哑铃卧推', equipment: '哑铃', muscle: '胸', subMuscle: '中胸', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '胸大肌、肱三头肌',
    breathing: '下放吸气，推起呼气',
    description: '活动幅度大于杠铃卧推，胸部拉伸与收缩更充分。',
    keyPoints: ['仰卧凳面，肩胛收紧', '下放至大臂略低于躯干', '推起轨迹略呈弧线', '顶端哑铃不碰撞'],
    commonMistakes: ['顶端哑铃互相碰撞导致张力丢失', '手腕后折，哑铃没有压在掌根', '下放过快失去控制砸向胸部'],
    imageRes: 'app.media.ex2_db_bench'
  },
  {
    id: 'db_row', name: '单臂哑铃划船', equipment: '哑铃', muscle: '背', subMuscle: '背阔肌', difficulty: '中级',
    prescription: '4 组 × 12 次/侧', targetMuscles: '背阔肌、斜方肌中下束',
    breathing: '拉起呼气，下放吸气',
    description: '单侧拉力训练，改善左右背肌力量不均衡。',
    keyPoints: ['一手一膝撑凳，背部平直', '肘贴身体向后上方拉起', '顶点收缩停顿一秒', '下放充分拉伸背阔肌'],
    commonMistakes: ['身体旋转借力甩起哑铃', '只动手臂不收缩肩胛', '弓腰驼背，背部没有保持平直'],
    imageRes: 'app.media.ex2_db_row'
  },
  {
    id: 'db_lunge', name: '哑铃弓步蹲', equipment: '哑铃', muscle: '腿', subMuscle: '股四头肌', difficulty: '中级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '股四头肌、臀大肌',
    breathing: '下蹲吸气，蹬起呼气',
    description: '负重单侧下肢训练，兼顾力量与平衡稳定。',
    keyPoints: ['双手持哑铃置于体侧', '躯干直立，步幅适中', '前腿发力蹬起身体', '后膝轻接近地面不触地'],
    commonMistakes: ['步幅过小导致前膝过度前移受压', '身体前倾，重量压到腰上', '后膝重重砸地失去控制'],
    imageRes: 'app.media.ex2_db_lunge'
  },
  {
    id: 'db_lateral', name: '哑铃侧平举', equipment: '哑铃', muscle: '肩', subMuscle: '中束', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '三角肌中束',
    breathing: '抬起呼气，下放吸气',
    description: '肩部宽度孤立动作，宁轻勿重做标准。',
    keyPoints: ['肘部微屈固定角度', '抬至与肩同高即可', '避免耸肩与身体摆动', '下放控制 2–3 秒'],
    commonMistakes: ['重量过大靠甩动借力', '耸肩导致斜方肌代偿', '抬得过高超过肩峰挤压肩关节'],
    imageRes: 'app.media.ex2_db_lateral'
  },
  {
    id: 'db_curl', name: '哑铃弯举', equipment: '哑铃', muscle: '二头', subMuscle: '整体', difficulty: '初级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '肱二头肌、肱肌',
    breathing: '弯举呼气，下放吸气',
    description: '可交替可单手，旋后弯举对二头刺激更完整。',
    keyPoints: ['双手各握哑铃置于体侧', '大臂贴紧体侧', '弯举同时手腕外旋（旋后）', '顶端收缩停顿后控制下放'],
    commonMistakes: ['甩腰借力', '大臂前移变成肩前束发力', '下放不伸直，只做半程'],
    imageRes: 'app.media.ex2_db_curl'
  },
  {
    id: 'db_wristcurl', name: '哑铃腕弯举', equipment: '哑铃', muscle: '小臂', subMuscle: '屈肌群', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '小臂屈肌群',
    breathing: '卷腕呼气，回放吸气',
    description: '小臂围度与握力的直接训练，前臂置于凳面孤立发力。',
    keyPoints: ['前臂贴凳面，手腕悬出凳沿', '手心向上握哑铃', '只用手腕向上卷起哑铃', '回放至手指充分伸展'],
    commonMistakes: ['前臂离开凳面借力', '幅度过小没有全程卷腕', '重量过大导致动作变形'],
    imageRes: 'app.media.ex2_db_wristcurl'
  },
  {
    id: 'db_incline', name: '上斜哑铃卧推', equipment: '哑铃', muscle: '胸', subMuscle: '上胸', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '胸大肌上部、三角肌前束',
    breathing: '下放吸气，推起呼气',
    description: '上斜 30–45 度主攻上胸，改善胸型上沿饱满度。',
    keyPoints: ['凳面调至 30–45 度', '哑铃下放至上胸两侧', '推起轨迹略呈弧线', '顶端哑铃不碰撞'],
    commonMistakes: ['凳角过大变成肩部推举', '下放过低拉伤肩前侧', '腰部过度拱起'],
    imageRes: 'app.media.ex2_db_incline'
  },
  {
    id: 'db_fly', name: '哑铃飞鸟', equipment: '哑铃', muscle: '胸', subMuscle: '中胸', difficulty: '中级',
    prescription: '3 组 × 12 次', targetMuscles: '胸大肌（外沿与中缝）',
    breathing: '下放吸气，夹起呼气',
    description: '胸部孤立拉伸动作，刻画胸肌外沿与中缝。',
    keyPoints: ['仰卧凳面，手臂微屈固定角度', '向两侧弧线下方打开', '感受胸部拉伸后夹拢', '顶端挤压胸部一秒'],
    commonMistakes: ['手臂伸太直伤肩', '重量过大变成推举', '下放过深肩关节受压'],
    imageRes: 'app.media.ex2_db_fly'
  },
  {
    id: 'db_press', name: '站姿哑铃推举', equipment: '哑铃', muscle: '肩', subMuscle: '整体', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '三角肌前中束、肱三头肌',
    breathing: '推起呼气，下放吸气',
    description: '站姿哑铃过顶推举，核心参与度高，肩部全面发展。',
    keyPoints: ['哑铃置于肩部高度', '核心收紧臀部夹紧', '垂直推至头顶上方', '下放控制至耳侧'],
    commonMistakes: ['腰椎后仰借力', '哑铃前飘而非垂直', '顶端猛烈锁死肘关节'],
    imageRes: 'app.media.ex2_db_press'
  },
  {
    id: 'db_frontraise', name: '哑铃前平举', equipment: '哑铃', muscle: '肩', subMuscle: '前束', difficulty: '初级',
    prescription: '3 组 × 12 次', targetMuscles: '三角肌前束',
    breathing: '抬起呼气，下放吸气',
    description: '肩前束孤立动作，可双手交替进行。',
    keyPoints: ['哑铃置于大腿前侧', '手臂微屈向前抬起', '抬至与肩同高', '下放控制不甩动'],
    commonMistakes: ['借力甩起哑铃', '抬得过高斜方肌代偿', '身体后仰'],
    imageRes: 'app.media.ex2_db_frontraise'
  },
  {
    id: 'db_rearfly', name: '俯身哑铃飞鸟', equipment: '哑铃', muscle: '肩', subMuscle: '后束', difficulty: '中级',
    prescription: '3 组 × 15 次', targetMuscles: '三角肌后束、斜方肌中下束',
    breathing: '打开呼气，下放吸气',
    description: '肩后束孤立动作，改善圆肩体态。',
    keyPoints: ['俯身背部平直', '手臂微屈向两侧打开', '肘部引领动作', '顶峰收缩后束'],
    commonMistakes: ['弓腰驼背', '重量过大靠摆动借力', '手臂过直伤肘'],
    imageRes: 'app.media.ex2_db_rearfly'
  },
  {
    id: 'db_arnold', name: '阿诺德推举', equipment: '哑铃', muscle: '肩', subMuscle: '整体', difficulty: '中级',
    prescription: '3 组 × 10 次', targetMuscles: '三角肌前中束',
    breathing: '旋转推起呼气，下放吸气',
    description: '旋转式推举，一次动作覆盖肩前中束更大行程。',
    keyPoints: ['起始掌心朝向自己置于肩前', '推起同时旋转手腕至掌心朝前', '顶端手臂接近伸直', '下放时反向旋转还原'],
    commonMistakes: ['旋转过快失去控制', '腰椎后仰借力', '下放时手腕旋转不同步'],
    imageRes: 'app.media.ex2_db_arnold'
  },
  {
    id: 'db_bulgarian', name: '保加利亚分腿蹲', equipment: '哑铃', muscle: '腿', subMuscle: '股四头肌', difficulty: '高级',
    prescription: '3 组 × 10 次/侧', targetMuscles: '股四头肌、臀大肌',
    breathing: '下蹲吸气，蹬起呼气',
    description: '后脚抬高的单腿深蹲变式，单侧力量与平衡的高阶训练。',
    keyPoints: ['后脚脚背置于凳面', '前腿下蹲至大腿平行', '躯干保持直立', '前脚跟发力蹬起'],
    commonMistakes: ['站距过近膝盖过度前移', '身体前倾', '后脚用力蹬凳借力'],
    imageRes: 'app.media.ex2_db_bulgarian'
  },
  {
    id: 'db_concentration', name: '集中弯举', equipment: '哑铃', muscle: '二头', subMuscle: '短头', difficulty: '初级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '肱二头肌（峰度）',
    breathing: '弯举呼气，下放吸气',
    description: '坐姿单臂集中弯举，肘抵大腿内侧，二头峰度利器。',
    keyPoints: ['坐姿，肘部抵住大腿内侧', '手臂全幅下放', '弯举至肩前顶峰收缩', '缓慢下放还原'],
    commonMistakes: ['身体后仰借力', '半程动作下放不充分', '顶端甩腕'],
    imageRes: 'app.media.ex2_db_concentration'
  },
  {
    id: 'db_hammer', name: '锤式弯举', equipment: '哑铃', muscle: '二头', subMuscle: '肱肌', difficulty: '初级',
    prescription: '3 组 × 12 次', targetMuscles: '肱肌、肱桡肌、肱二头肌',
    breathing: '弯举呼气，下放吸气',
    description: '中立握法弯举，增厚手臂侧面，兼顾小臂。',
    keyPoints: ['掌心相对握哑铃', '大臂贴紧体侧', '保持中立握法弯举', '顶端稍停控制下放'],
    commonMistakes: ['大臂前移', '甩动借力', '下放到底张力丢失'],
    imageRes: 'app.media.ex2_db_hammer'
  },
  {
    id: 'db_overheadext', name: '颈后臂屈伸', equipment: '哑铃', muscle: '三头', subMuscle: '长头', difficulty: '中级',
    prescription: '3 组 × 12 次', targetMuscles: '肱三头肌长头',
    breathing: '屈肘吸气，伸肘呼气',
    description: '过顶位充分拉伸三头长头，坐姿站姿皆可。',
    keyPoints: ['双手托住一只哑铃举过头顶', '大臂贴近耳侧固定', '屈肘下放至颈后', '三头发力向上伸直'],
    commonMistakes: ['大臂外张', '弓腰代偿', '下放过快失控'],
    imageRes: 'app.media.ex2_db_overheadext'
  },
  {
    id: 'db_kickback', name: '俯身哑铃臂屈伸', equipment: '哑铃', muscle: '三头', subMuscle: '整体', difficulty: '初级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '肱三头肌',
    breathing: '后伸呼气，回收吸气',
    description: '俯身位三头孤立动作，顶端收缩感强。',
    keyPoints: ['俯身背部平直，大臂与躯干平行固定', '向后伸直手臂', '顶端收缩停顿一秒', '缓慢屈肘回收'],
    commonMistakes: ['大臂下垂未固定', '甩动哑铃借力', '顶端没有停顿'],
    imageRes: 'app.media.ex2_db_kickback'
  },
  {
    id: 'db_reversewrist', name: '反向腕弯举', equipment: '哑铃', muscle: '小臂', subMuscle: '伸肌群', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '小臂伸肌群',
    breathing: '卷腕呼气，回放吸气',
    description: '掌心向下卷腕，强化小臂背侧伸肌，平衡屈肌发展。',
    keyPoints: ['前臂贴凳面，掌心向下', '手腕悬出凳沿', '向上背伸卷起哑铃', '缓慢回放'],
    commonMistakes: ['前臂离凳借力', '重量过大', '幅度过小'],
    imageRes: 'app.media.ex2_db_reversewrist'
  },
  {
    id: 'db_farmerwalk', name: '农夫行走', equipment: '哑铃', muscle: '小臂', subMuscle: '握力', difficulty: '初级',
    prescription: '3 组 × 30–40 米', targetMuscles: '握力、小臂、斜方肌、核心',
    breathing: '全程均匀呼吸',
    description: '双手持重行走，握力与全身稳定性的实用训练。',
    keyPoints: ['双手持重哑铃置于体侧', '挺胸收肩核心收紧', '小步幅稳定行走', '全程保持身体直立'],
    commonMistakes: ['弓腰驼背', '身体左右摇晃', '重量过大步态变形'],
    imageRes: 'app.media.ex2_db_farmerwalk'
  },
  // ==================== 史密斯 ====================
  {
    id: 'sm_bench', name: '史密斯卧推', equipment: '史密斯', muscle: '胸', subMuscle: '中胸', difficulty: '初级',
    prescription: '4 组 × 10 次', targetMuscles: '胸大肌、三角肌前束',
    breathing: '下放吸气，推起呼气',
    description: '固定轨迹卧推，新手友好且便于冲击重量。',
    keyPoints: ['调整凳位使杠铃落于胸部正上方', '握距略宽于肩', '利用固定轨迹专注胸部发力', '旋转手腕即可安全锁定'],
    commonMistakes: ['凳位没对准导致杠铃落在颈部', '借助固定轨迹猛推猛放失去控制', '手腕后折承重'],
    imageRes: 'app.media.ex2_sm_bench'
  },
  {
    id: 'sm_squat', name: '史密斯深蹲', equipment: '史密斯', muscle: '腿', subMuscle: '股四头肌', difficulty: '初级',
    prescription: '4 组 × 12 次', targetMuscles: '股四头肌、臀大肌',
    breathing: '下蹲吸气，站起呼气',
    description: '固定轨迹深蹲，降低平衡要求，专注腿部刺激。',
    keyPoints: ['双脚略向前站，背靠杠铃', '下蹲至大腿平行地面', '膝盖不内扣', '蹬脚跟发力站起'],
    commonMistakes: ['双脚站位太靠后，下蹲像"坐断"腰椎', '膝盖内扣', '下蹲过浅，刺激不足'],
    imageRes: 'app.media.ex2_sm_squat'
  },
  {
    id: 'sm_press', name: '史密斯肩上推举', equipment: '史密斯', muscle: '肩', subMuscle: '整体', difficulty: '初级',
    prescription: '4 组 × 10 次', targetMuscles: '三角肌前中束',
    breathing: '推起呼气，下放吸气',
    description: '固定轨迹过顶推举，适合肩部新手打基础。',
    keyPoints: ['凳面调至靠背微倾', '杠铃下放到下巴高度', '垂直推起不锁死肘关节', '核心收紧稳定躯干'],
    commonMistakes: ['靠背角度太斜变成上斜卧推', '顶端锁死肘关节冲击关节', '耸肩借力代偿'],
    imageRes: 'app.media.ex2_sm_press'
  },
  {
    id: 'sm_hipthrust', name: '史密斯臀推', equipment: '史密斯', muscle: '臀', subMuscle: '臀大肌', difficulty: '中级',
    prescription: '4 组 × 12 次', targetMuscles: '臀大肌、腘绳肌',
    breathing: '顶髋呼气，下放吸气',
    description: '臀部维度黄金动作，固定轨迹更易上大重量。',
    keyPoints: ['上背靠凳沿，杠铃置于髋部并垫护垫', '顶髋至躯干与大腿成一直线', '顶点用力夹臀停顿', '小腿始终垂直地面'],
    commonMistakes: ['顶髋过高腰椎过伸代偿', '脚位太远导致腘绳肌主导', '不垫护垫让杠铃直接压髋骨'],
    imageRes: 'app.media.ex2_sm_hipthrust'
  },
  {
    id: 'sm_closegrip', name: '史密斯窄距卧推', equipment: '史密斯', muscle: '三头', subMuscle: '整体', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '肱三头肌、胸大肌内侧',
    breathing: '下放吸气，推起呼气',
    description: '窄握卧推变式，固定轨迹下安全冲击三头力量。',
    keyPoints: ['握距与肩同宽或略窄', '肘部贴近身体下放到下胸', '三头发力垂直推起', '手腕保持中立不后折'],
    commonMistakes: ['握距过窄导致手腕不适', '肘部外展变成胸部主导', '下放过快砸向胸口'],
    imageRes: 'app.media.ex2_sm_closegrip'
  },
  // ==================== 绳索 ====================
  {
    id: 'cb_fly', name: '绳索夹胸', equipment: '绳索', muscle: '胸', subMuscle: '中胸', difficulty: '中级',
    prescription: '3 组 × 12 次', targetMuscles: '胸大肌（内侧）',
    breathing: '夹拢呼气，回放吸气',
    description: '全程持续张力的胸部孤立动作，刻画胸中缝。',
    keyPoints: ['滑轮调至高位，双手各握把手', '身体前倾单腿前弓步站稳', '手臂微屈向体前下方夹拢', '顶峰挤压胸部一秒'],
    commonMistakes: ['手臂伸太直变成拉的动作伤肩', '重量过大靠身体晃动借力', '回放过快没有控制张力'],
    imageRes: 'app.media.ex2_cb_fly'
  },
  {
    id: 'cb_pulldown', name: '高位绳索下拉', equipment: '绳索', muscle: '背', subMuscle: '背阔肌', difficulty: '初级',
    prescription: '4 组 × 12 次', targetMuscles: '背阔肌、大圆肌',
    breathing: '下拉呼气，回放吸气',
    description: '引体向上的替代动作，打造背部宽度。',
    keyPoints: ['宽握横杆，大腿固定于护垫下', '躯干微后仰保持固定', '下拉至上胸部', '避免耸肩与甩动借力'],
    commonMistakes: ['大幅度后仰甩腰借力', '拉到颈后增加肩关节压力', '耸肩导致斜方肌上束代偿'],
    imageRes: 'app.media.ex2_cb_pulldown'
  },
  {
    id: 'cb_facepull', name: '绳索面拉', equipment: '绳索', muscle: '肩', subMuscle: '后束', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '三角肌后束、斜方肌中下束',
    breathing: '后拉呼气，回放吸气',
    description: '改善圆肩体态的黄金动作，强化肩后束。',
    keyPoints: ['滑轮与面部同高，双绳握法', '拉向面部两侧，肘部抬高', '顶峰外旋肩膀', '回放控制速度'],
    commonMistakes: ['滑轮位置过低变成划船', '肘部下压没有抬高', '重量过大靠后仰借力'],
    imageRes: 'app.media.ex2_cb_facepull'
  },
  {
    id: 'cb_pushdown', name: '绳索臂屈伸', equipment: '绳索', muscle: '三头', subMuscle: '整体', difficulty: '初级',
    prescription: '3 组 × 12 次', targetMuscles: '肱三头肌',
    breathing: '下压呼气，回放吸气',
    description: '肱三头肌孤立训练，刻画手臂后侧线条。',
    keyPoints: ['大臂贴紧体侧固定', '只屈伸小臂下压', '底端充分收缩停顿', '身体不前倾借力'],
    commonMistakes: ['大臂离开体侧前后摆动', '身体前倾用体重下压', '回放过高让绳索张力松掉'],
    imageRes: 'app.media.ex2_cb_pushdown'
  },
  {
    id: 'cb_seatedrow', name: '坐姿绳索划船', equipment: '绳索', muscle: '背', subMuscle: '上背', difficulty: '初级',
    prescription: '4 组 × 12 次', targetMuscles: '中背、背阔肌、菱形肌',
    breathing: '后拉呼气，回放吸气',
    description: '坐姿水平划船，中背厚度与体态改善的基础动作。',
    keyPoints: ['坐姿脚踏踏板，膝盖微屈', '躯干直立不前倾后仰', '拉把手至下腹', '顶峰肩胛收缩停顿'],
    commonMistakes: ['身体大幅前后摆动借力', '耸肩', '回放过快失去张力'],
    imageRes: 'app.media.ex2_cb_seatedrow'
  },
  {
    id: 'cb_straightarm', name: '直臂下压', equipment: '绳索', muscle: '背', subMuscle: '背阔肌', difficulty: '初级',
    prescription: '3 组 × 12–15 次', targetMuscles: '背阔肌',
    breathing: '下压呼气，回放吸气',
    description: '手臂接近伸直下压，孤立背阔肌发力感受。',
    keyPoints: ['高位滑轮，正握横杆', '手臂微屈固定角度', '用背阔肌将杆压向大腿', '回放控制拉伸背阔'],
    commonMistakes: ['屈肘变成臂屈伸', '身体前倾下压借力', '回放失控'],
    imageRes: 'app.media.ex2_cb_straightarm'
  },
  {
    id: 'cb_underpulldown', name: '反手高位下拉', equipment: '绳索', muscle: '背', subMuscle: '背阔肌', difficulty: '初级',
    prescription: '4 组 × 12 次', targetMuscles: '背阔肌下部、肱二头肌',
    breathing: '下拉呼气，回放吸气',
    description: '反握下拉更侧重背阔肌下部，手臂参与更多易上手。',
    keyPoints: ['反握与肩同宽', '躯干微后仰固定', '下拉至上胸', '顶峰收缩背阔肌'],
    commonMistakes: ['后仰甩腰借力', '拉到颈后', '耸肩代偿'],
    imageRes: 'app.media.ex2_cb_underpulldown'
  },
  {
    id: 'cb_curl', name: '绳索弯举', equipment: '绳索', muscle: '二头', subMuscle: '整体', difficulty: '初级',
    prescription: '3 组 × 12–15 次', targetMuscles: '肱二头肌',
    breathing: '弯举呼气，下放吸气',
    description: '绳索全程恒定张力，二头收缩感持续到底。',
    keyPoints: ['低位滑轮接直杆或绳索', '大臂贴紧体侧', '弯举至肩前', '顶峰挤压后控制回放'],
    commonMistakes: ['大臂前移', '身体后仰借力', '回放到底张力松掉'],
    imageRes: 'app.media.ex2_cb_curl'
  },
  // ==================== 自重 ====================
  {
    id: 'bw_pushup', name: '俯卧撑', equipment: '自重', muscle: '胸', subMuscle: '中胸', difficulty: '初级',
    prescription: '3 组 × 12–15 次', targetMuscles: '胸大肌、三角肌前束、肱三头肌',
    breathing: '下放吸气，推起呼气',
    description: '最经典的徒手推力动作，随时随地可练。',
    keyPoints: ['双手略宽于肩撑地', '身体保持一条直线，核心收紧', '下放至胸部接近地面', '推起时肘部不锁死'],
    commonMistakes: ['塌腰撅臀，身体没有成一条直线', '肘部外展 90 度增加肩压', '半程幅度不下放到胸部贴近地面'],
    imageRes: 'app.media.ex2_bw_pushup'
  },
  {
    id: 'bw_pullup', name: '引体向上', equipment: '自重', muscle: '背', subMuscle: '背阔肌', difficulty: '高级',
    prescription: '4 组 × 力竭', targetMuscles: '背阔肌、肱二头肌',
    breathing: '上拉呼气，下放吸气',
    description: '上肢拉力天花板动作，背部宽度利器。',
    keyPoints: ['正握略宽于肩', '启动时肩胛先下沉', '上拉至下巴过杠', '下放充分不摆动借力'],
    commonMistakes: ['摆动身体借力甩上去', '只做半程下方不伸直', '耸肩含胸导致手臂主导发力'],
    imageRes: 'app.media.ex2_bw_pullup'
  },
  {
    id: 'bw_plank', name: '平板支撑', equipment: '自重', muscle: '腹', subMuscle: '上腹', difficulty: '初级',
    prescription: '3 组 × 45–60 秒', targetMuscles: '腹横肌、腹直肌',
    breathing: '全程均匀呼吸不憋气',
    description: '核心稳定性基础，保护腰椎的静态训练。',
    keyPoints: ['前臂撑地，肘在肩正下方', '身体一条直线不塌腰不撅臀', '腹部持续收紧', '目光看向地面保持颈部中立'],
    commonMistakes: ['塌腰让腰椎受压', '臀部抬太高失去核心刺激', '憋气硬撑，应均匀呼吸'],
    imageRes: 'app.media.ex2_bw_plank'
  },
  {
    id: 'bw_burpee', name: '波比跳', equipment: '自重', muscle: '全身', subMuscle: '全身复合', difficulty: '高级',
    prescription: '3 组 × 12 次', targetMuscles: '全身（心肺高强度）',
    breathing: '俯身吸气，跳起呼气',
    description: '高强度全身复合动作，单位时间燃脂效率极高。',
    keyPoints: ['下蹲撑地后跳成平板位', '完成一次俯卧撑', '收腿起跳击掌', '量力而行关注心率'],
    commonMistakes: ['平板位塌腰，腰椎受压', '收腿落地时膝盖内扣', '速度过快动作变形，质量优先'],
    imageRes: 'app.media.ex2_bw_burpee'
  },
  {
    id: 'bw_dips', name: '双杠臂屈伸', equipment: '自重', muscle: '三头', subMuscle: '整体', difficulty: '中级',
    prescription: '4 组 × 8–12 次', targetMuscles: '肱三头肌、胸大肌下沿',
    breathing: '下放吸气，撑起呼气',
    description: '上肢自重推力王牌，躯干直立时三头主导。',
    keyPoints: ['双手撑双杠，手臂伸直支撑', '躯干保持直立偏三头，前倾偏胸', '下放至大臂平行地面', '撑起时肘部不锁死'],
    commonMistakes: ['下放过深冲击肩关节', '耸肩含胸', '摆动双腿借力'],
    imageRes: 'app.media.ex2_bw_dips'
  },
  {
    id: 'bw_crunch', name: '卷腹', equipment: '自重', muscle: '腹', subMuscle: '上腹', difficulty: '初级',
    prescription: '3 组 × 20 次', targetMuscles: '腹直肌上部',
    breathing: '卷起呼气，下放吸气',
    description: '上腹基础动作，幅度小但集中，避免颈部代偿。',
    keyPoints: ['仰卧屈膝，手轻扶耳侧', '用上腹发力卷起肩胛离地', '腰部始终贴地', '顶端停顿后缓慢下放'],
    commonMistakes: ['双手抱头拉脖子', '腰部离地变成仰卧起坐', '靠惯性快速弹起'],
    imageRes: 'app.media.ex2_bw_crunch'
  },
  {
    id: 'bw_legraise', name: '仰卧举腿', equipment: '自重', muscle: '腹', subMuscle: '下腹', difficulty: '中级',
    prescription: '3 组 × 15 次', targetMuscles: '腹直肌下部、髂腰肌',
    breathing: '举腿呼气，下放吸气',
    description: '下腹针对性训练，控制下放速度是关键。',
    keyPoints: ['仰卧双手置于体侧或臀下', '双腿并拢微屈', '下腹发力抬腿至垂直', '下放至接近地面不触地'],
    commonMistakes: ['腰部拱起离开地面', '利用惯性甩腿', '下放过快失去张力'],
    imageRes: 'app.media.ex2_bw_legraise'
  },
  {
    id: 'bw_sideplank', name: '侧平板支撑', equipment: '自重', muscle: '腹', subMuscle: '侧腹', difficulty: '初级',
    prescription: '3 组 × 30–45 秒/侧', targetMuscles: '腹斜肌、腰方肌',
    breathing: '全程均匀呼吸不憋气',
    description: '侧腹与核心抗侧屈能力训练，紧致腰线。',
    keyPoints: ['单侧前臂撑地，肘在肩正下方', '髋部抬起身体成一条直线', '侧腹持续收紧不下沉', '两侧交替等量完成'],
    commonMistakes: ['髋部下沉', '身体前后旋转不中正', '憋气硬撑'],
    imageRes: 'app.media.ex2_bw_sideplank'
  },
  {
    id: 'bw_pushupplus', name: '俯卧撑前锯推起', equipment: '自重', muscle: '腹', subMuscle: '前锯肌', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '前锯肌',
    breathing: '推起呼气，回收吸气',
    description: '前锯肌孤立激活动作，改善肩胛稳定与体态。',
    keyPoints: ['俯卧撑顶端姿势，手臂伸直', '保持肘部锁定不动', '肩胛前伸把上背推向天花板', '再控制回收肩胛'],
    commonMistakes: ['屈肘变成俯卧撑', '塌腰核心松散', '幅度过小没有充分前伸'],
    imageRes: 'app.media.ex2_bw_pushupplus'
  },
  {
    id: 'bw_jumpingjack', name: '开合跳', equipment: '自重', muscle: '有氧', subMuscle: '全身燃脂', difficulty: '初级',
    prescription: '4 组 × 40 秒', targetMuscles: '全身（心肺中等强度）',
    breathing: '全程自然呼吸有节奏',
    description: '经典热身与燃脂动作，快速提升心率。',
    keyPoints: ['站姿双脚并拢', '跳起分腿同时双手头顶击掌', '再跳回并拢', '前脚掌轻盈落地缓冲'],
    commonMistakes: ['落地直膝无缓冲', '动作懒散节奏过慢', '膝盖内扣'],
    imageRes: 'app.media.ex2_bw_jumpingjack'
  },
  {
    id: 'bw_jumprope', name: '跳绳', equipment: '自重', muscle: '有氧', subMuscle: '心肺耐力', difficulty: '初级',
    prescription: '4 组 × 60 秒', targetMuscles: '心肺、小腿、肩袖',
    breathing: '全程鼻吸口呼有节奏',
    description: '高效有氧工具，10 分钟跳绳约等于 30 分钟慢跑。',
    keyPoints: ['绳长合适：踩绳手柄至腋下', '手腕摇绳而非大臂', '前脚掌小幅度起落', '膝盖微屈缓冲'],
    commonMistakes: ['跳得过高浪费体力', '大臂大幅摆动', '足跟着地冲击关节'],
    imageRes: 'app.media.ex2_bw_jumprope'
  },
  {
    id: 'bw_mountainclimber', name: '登山跑', equipment: '自重', muscle: '有氧', subMuscle: '核心燃脂', difficulty: '中级',
    prescription: '4 组 × 30 秒', targetMuscles: '腹直肌、髋屈肌、心肺',
    breathing: '全程快速浅呼吸有节奏',
    description: '有氧与核心结合的高强度动作，燃脂效率高。',
    keyPoints: ['俯卧撑起始位，核心收紧', '交替快速提膝向胸部', '身体保持一条直线', '由慢到快循序渐进'],
    commonMistakes: ['臀部抬得过高', '塌腰', '只求速度动作散掉'],
    imageRes: 'app.media.ex2_bw_mountainclimber'
  },
  {
    id: 'bw_backext', name: '山羊挺身', equipment: '自重', muscle: '背', subMuscle: '下背', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '竖脊肌、臀大肌',
    breathing: '挺身呼气，下放吸气',
    description: '罗马椅挺身，强化下背与后链，护腰基础。',
    keyPoints: ['髋部抵住罗马椅垫', '身体下放至接近垂直', '下背发力挺身至身体平直', '顶点不过度后仰'],
    commonMistakes: ['顶点过度后仰挤压腰椎', '速度过快借力弹起', '幅度过小'],
    imageRes: 'app.media.ex2_bw_backext'
  },
  {
    id: 'bw_reversecrunch', name: '反向卷腹', equipment: '自重', muscle: '腹', subMuscle: '下腹', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '腹直肌下部',
    breathing: '卷起呼气，回放吸气',
    description: '抬腿卷骨盆的反向卷腹，下腹刺激集中且护颈。',
    keyPoints: ['仰卧双手置于体侧', '屈膝抬腿至大腿垂直', '下腹发力卷起骨盆离地', '缓慢回放不甩腿'],
    commonMistakes: ['利用惯性甩腿', '回放时腰部拱起', '幅度过大变成摇摆'],
    imageRes: 'app.media.ex2_bw_reversecrunch'
  },
  {
    id: 'bw_russiantwist', name: '俄罗斯转体', equipment: '自重', muscle: '腹', subMuscle: '侧腹', difficulty: '中级',
    prescription: '3 组 × 20 次/侧', targetMuscles: '腹斜肌、腹直肌',
    breathing: '转体呼气，回正吸气',
    description: '坐姿转体训练侧腹，可徒手或负重进阶。',
    keyPoints: ['坐姿屈膝，上身后倾 45 度', '核心收紧保持稳定', '躯干左右交替旋转', '目光随手转动'],
    commonMistakes: ['弓腰驼背', '只摆手臂不转躯干', '速度过快失去控制'],
    imageRes: 'app.media.ex2_bw_russiantwist'
  },
  {
    id: 'bw_deadbug', name: '死虫式', equipment: '自重', muscle: '腹', subMuscle: '上腹', difficulty: '初级',
    prescription: '3 组 × 10 次/侧', targetMuscles: '腹横肌、深层核心',
    breathing: '伸展呼气，回收吸气',
    description: '深层核心稳定训练，对腰椎最友好的腹部动作之一。',
    keyPoints: ['仰卧手臂上举，双腿屈膝 90 度抬起', '腰部始终贴紧地面', '对侧手臂与腿缓慢伸展', '回收换另一侧'],
    commonMistakes: ['腰部离地拱起', '动作过快', '屏气完成动作'],
    imageRes: 'app.media.ex2_bw_deadbug'
  },
  {
    id: 'bw_hanglegraise', name: '悬垂举腿', equipment: '自重', muscle: '腹', subMuscle: '下腹', difficulty: '高级',
    prescription: '3 组 × 10–12 次', targetMuscles: '腹直肌下部、髋屈肌',
    breathing: '举腿呼气，下放吸气',
    description: '悬挂位举腿，下腹高阶动作，兼顾握力。',
    keyPoints: ['正握单杠悬垂', '收紧核心稳定身体', '下腹发力抬腿至水平或更高', '缓慢下放不摆动'],
    commonMistakes: ['摆动身体借力', '只抬到一半靠髋屈肌', '下放失控甩动'],
    imageRes: 'app.media.ex2_bw_hanglegraise'
  },
  {
    id: 'bw_jog', name: '慢跑', equipment: '自重', muscle: '有氧', subMuscle: '心肺耐力', difficulty: '初级',
    prescription: '每次 20–40 分钟', targetMuscles: '心肺系统、下肢耐力',
    breathing: '两步一吸两步一呼',
    description: '最基础的有氧方式，提升心肺与脂肪供能比例。',
    keyPoints: ['配速以能完整说话为宜', '前脚掌或全掌着地', '摆臂自然放松', '结束后慢走 5 分钟冷身'],
    commonMistakes: ['起步过快心率飙升', '步幅过大刹车效应', '跑前不热身'],
    imageRes: 'app.media.ex2_bw_jog'
  },
  {
    id: 'bw_walk', name: '快走', equipment: '自重', muscle: '有氧', subMuscle: '心肺耐力', difficulty: '初级',
    prescription: '每次 30–45 分钟', targetMuscles: '心肺系统、下肢',
    breathing: '全程自然深呼吸',
    description: '低冲击有氧，适合大体重与恢复日。',
    keyPoints: ['步频维持在每分钟 110–130 步', '摆臂加大至 90 度', '抬头挺胸核心微收', '脚跟到前掌滚动着地'],
    commonMistakes: ['速度过慢达不到燃脂心率', '含胸低头', '穿不合适的鞋'],
    imageRes: 'app.media.ex2_bw_walk'
  },
  {
    id: 'bw_hiit', name: 'HIIT 间歇训练', equipment: '自重', muscle: '有氧', subMuscle: '全身燃脂', difficulty: '高级',
    prescription: '20 秒高强度 + 40 秒休息 × 8–10 轮', targetMuscles: '全身、心肺（高强度）',
    breathing: '高强度期快速呼吸，间歇深呼吸恢复',
    description: '高低强度交替，短时高效燃脂并产生后燃效应。',
    keyPoints: ['充分热身 5–10 分钟', '高强度期全力以赴', '间歇期慢走不静止', '每周 2–3 次不过量'],
    commonMistakes: ['间歇期完全静止', '动作变形仍追求速度', '训练频率过高恢复不足'],
    imageRes: 'app.media.ex2_bw_hiit'
  },
  // ==================== 弹力带 ====================
  {
    id: 'bd_row', name: '弹力带划船', equipment: '弹力带', muscle: '背', subMuscle: '背阔肌', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '背阔肌、斜方肌',
    breathing: '后拉呼气，回放吸气',
    description: '居家背部训练首选，便携低门槛。',
    keyPoints: ['弹力带固定于胸前高度', '双手握带肘部后拉', '肩胛骨主动收紧', '回放控制张力不松垮'],
    commonMistakes: ['只动手臂不收肩胛', '回放完全松掉张力', '身体后仰借力'],
    imageRes: 'app.media.ex2_bd_row'
  },
  {
    id: 'bd_squat', name: '弹力带深蹲', equipment: '弹力带', muscle: '腿', subMuscle: '股四头肌', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '股四头肌、臀大肌',
    breathing: '下蹲吸气，站起呼气',
    description: '弹力带增加向上阻力，强化腿部伸髋力量。',
    keyPoints: ['双脚踩带与肩同宽', '双手提带至肩部高度', '下蹲大腿平行地面', '膝盖与脚尖同向'],
    commonMistakes: ['膝盖内扣', '下蹲过浅刺激不足', '脚跟离地重心前移'],
    imageRes: 'app.media.ex2_bd_squat'
  },
  {
    id: 'bd_lateral', name: '弹力带侧平举', equipment: '弹力带', muscle: '肩', subMuscle: '中束', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '三角肌中束',
    breathing: '侧举呼气，下放吸气',
    description: '居家肩部训练，弹力带张力顶端最大刺激更强。',
    keyPoints: ['双脚踩住弹力带中部', '手臂微屈向两侧抬起', '抬至肩高停顿', '下放控制对抗张力'],
    commonMistakes: ['耸肩让斜方肌代偿', '手臂完全伸直增加肘部压力', '抬得过高挤压肩峰'],
    imageRes: 'app.media.ex2_bd_lateral'
  },
  {
    id: 'bd_glutebridge', name: '弹力带臀桥', equipment: '弹力带', muscle: '臀', subMuscle: '臀大肌', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '臀大肌、腘绳肌',
    breathing: '顶髋呼气，下放吸气',
    description: '激活臀部的基础动作，弹力带外展加强臀中肌。',
    keyPoints: ['仰卧屈膝，弹力带套于膝盖上方', '顶髋至身体成一直线', '双膝主动外撑弹力带', '顶点夹臀停顿一秒'],
    commonMistakes: ['顶髋过高腰椎过伸', '膝盖内扣不主动外撑', '下放过快没有控制'],
    imageRes: 'app.media.ex2_bd_glutebridge'
  },
  // ==================== 器械 ====================
  {
    id: 'mc_chestpress', name: '器械推胸', equipment: '器械', muscle: '胸', subMuscle: '中胸', difficulty: '初级',
    prescription: '4 组 × 10–12 次', targetMuscles: '胸大肌、肱三头肌',
    breathing: '推出呼气，回放吸气',
    description: '坐姿固定轨迹推胸，新手友好，安全上重量。',
    keyPoints: ['调整座椅使把手对准胸中部', '背部贴紧靠垫', '推至手臂接近伸直', '回放控制不失张力'],
    commonMistakes: ['座椅高度不对推成肩部', '回放到底撞击配重片', '肩部前伸借力'],
    imageRes: 'app.media.ex2_mc_chestpress'
  },
  {
    id: 'mc_pecfly', name: '蝴蝶机夹胸', equipment: '器械', muscle: '胸', subMuscle: '中胸', difficulty: '初级',
    prescription: '3 组 × 12 次', targetMuscles: '胸大肌（内侧）',
    breathing: '夹拢呼气，回放吸气',
    description: '固定轨迹夹胸，顶峰挤压感强，刻画胸中缝。',
    keyPoints: ['调整座椅使上臂与地面平行', '前臂贴住挡垫', '胸部发力向中间夹拢', '顶峰挤压停顿一秒'],
    commonMistakes: ['重量过大用惯性摆动', '回放过度拉伸肩前侧', '含胸耸肩'],
    imageRes: 'app.media.ex2_mc_pecfly'
  },
  {
    id: 'mc_lateral', name: '器械侧平举', equipment: '器械', muscle: '肩', subMuscle: '中束', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '三角肌中束',
    breathing: '抬起呼气，下放吸气',
    description: '固定轨迹侧平举，比哑铃更易孤立中束。',
    keyPoints: ['上臂贴住挡垫', '肘部引领向两侧抬起', '抬至与肩同高', '缓慢下放控制'],
    commonMistakes: ['耸肩代偿', '抬得过高', '重量过大靠摆动'],
    imageRes: 'app.media.ex2_mc_lateral'
  },
  {
    id: 'mc_assistpullup', name: '辅助引体向上', equipment: '器械', muscle: '背', subMuscle: '背阔肌', difficulty: '初级',
    prescription: '4 组 × 10 次', targetMuscles: '背阔肌、肱二头肌',
    breathing: '上拉呼气，下放吸气',
    description: '配重辅助版引体，做不了标准引体的最佳过渡。',
    keyPoints: ['调好辅助配重（越重越省力）', '跪上踏板正握横杆', '肩胛下沉启动上拉', '下巴过杠后控制下放'],
    commonMistakes: ['辅助配重过大没有真实刺激', '耸肩含胸', '下放不伸直'],
    imageRes: 'app.media.ex2_mc_assistpullup'
  },
  {
    id: 'mc_legpress', name: '腿举', equipment: '器械', muscle: '腿', subMuscle: '股四头肌', difficulty: '初级',
    prescription: '4 组 × 10–12 次', targetMuscles: '股四头肌、臀大肌',
    breathing: '下放吸气，蹬起呼气',
    description: '固定轨迹腿部推举，大重量刺激下肢的安全选择。',
    keyPoints: ['背部臀部贴紧靠垫', '双脚与肩同宽踩踏板中部', '下放至大腿接近胸部', '蹬起不锁死膝盖'],
    commonMistakes: ['下放过深臀部离垫（骨盆眨眼）', '顶端锁死膝关节', '膝盖内扣'],
    imageRes: 'app.media.ex2_mc_legpress'
  },
  {
    id: 'mc_legext', name: '腿屈伸', equipment: '器械', muscle: '腿', subMuscle: '股四头肌', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '股四头肌',
    breathing: '抬起呼气，下放吸气',
    description: '股四头肌孤立动作，顶峰收缩刻画腿部前侧线条。',
    keyPoints: ['脚背勾住挡垫', '背部贴紧靠垫', '股四头发力抬起至接近伸直', '顶峰停顿后缓慢下放'],
    commonMistakes: ['利用惯性甩起', '顶端猛烈锁膝', '下放过快'],
    imageRes: 'app.media.ex2_mc_legext'
  },
  {
    id: 'mc_legcurl', name: '腿弯举', equipment: '器械', muscle: '腿', subMuscle: '腘绳肌', difficulty: '初级',
    prescription: '3 组 × 12–15 次', targetMuscles: '腘绳肌',
    breathing: '弯举呼气，回放吸气',
    description: '俯卧腿弯举孤立腘绳肌，平衡股四头发展。',
    keyPoints: ['俯卧挡垫置于脚踝上方', '膝盖对齐轴心', '弯举至小腿接近大腿', '缓慢回放'],
    commonMistakes: ['臀部抬起借力', '回放失控', '挡垫位置过高'],
    imageRes: 'app.media.ex2_mc_legcurl'
  },
  {
    id: 'mc_standingcalf', name: '站姿提踵', equipment: '器械', muscle: '腿', subMuscle: '小腿', difficulty: '初级',
    prescription: '4 组 × 15 次', targetMuscles: '腓肠肌',
    breathing: '提踵呼气，下放吸气',
    description: '小腿围度主打动作，全程幅度是关键。',
    keyPoints: ['前脚掌踩踏板边缘', '充分下放感受小腿拉伸', '提踵至最高点停顿', '缓慢下放重复'],
    commonMistakes: ['幅度过小只做半程', '速度过快弹跳借力', '膝盖弯曲泄力'],
    imageRes: 'app.media.ex2_mc_standingcalf'
  },
  {
    id: 'mc_seatedcalf', name: '坐姿提踵', equipment: '器械', muscle: '腿', subMuscle: '小腿', difficulty: '初级',
    prescription: '4 组 × 15 次', targetMuscles: '比目鱼肌',
    breathing: '提踵呼气，下放吸气',
    description: '屈膝位提踵侧重比目鱼肌，小腿厚度来源。',
    keyPoints: ['大腿置于挡垫下', '前脚掌踩踏板', '全幅提踵', '顶端停顿缓慢下放'],
    commonMistakes: ['幅度过小', '靠反弹借力', '重量过大动作变形'],
    imageRes: 'app.media.ex2_mc_seatedcalf'
  },
  {
    id: 'mc_wristroller', name: '卷腕器训练', equipment: '器械', muscle: '小臂', subMuscle: '屈肌群', difficulty: '初级',
    prescription: '3 组 × 上下各 1 次', targetMuscles: '小臂屈伸肌群、握力',
    breathing: '卷起呼气，回放吸气',
    description: '卷腕器卷起悬挂重物，小臂灼烧感极强的经典训练。',
    keyPoints: ['双手前伸握卷腕器与肩同高', '交替卷腕卷起配重', '顶端后控制回放', '保持手臂稳定不借力'],
    commonMistakes: ['手臂下垂借力', '回放直接松手', '速度过快'],
    imageRes: 'app.media.ex2_mc_wristroller'
  },
  {
    id: 'mc_elliptical', name: '椭圆机', equipment: '器械', muscle: '有氧', subMuscle: '低冲击燃脂', difficulty: '初级',
    prescription: '每次 20–40 分钟', targetMuscles: '心肺、下肢（低冲击）',
    breathing: '全程均匀呼吸',
    description: '零冲击有氧器械，膝关节敏感人群的首选。',
    keyPoints: ['全脚掌踩实踏板', '手握活动摆臂协同发力', '阻力调至微喘能说话', '身体直立不前倾'],
    commonMistakes: ['阻力过低脚踩惯性空转', '身体过度前倾', '脚跟抬起'],
    imageRes: 'app.media.ex2_mc_elliptical'
  },
  {
    id: 'mc_bike', name: '动感单车', equipment: '器械', muscle: '有氧', subMuscle: '心肺耐力', difficulty: '中级',
    prescription: '每次 30–45 分钟', targetMuscles: '心肺、股四头肌、臀肌',
    breathing: '随踏频有节奏呼吸',
    description: '高燃脂团课级有氧，坐姿站姿交替刺激。',
    keyPoints: ['坐垫与髋同高', '踩踏至最低点膝盖微屈', '核心收紧上身稳定', '阻力与踏频平衡'],
    commonMistakes: ['坐垫过低伤膝', '身体左右摇晃', '阻力为零空踩'],
    imageRes: 'app.media.ex2_mc_bike'
  },
  {
    id: 'mc_stair', name: '爬楼机', equipment: '器械', muscle: '有氧', subMuscle: '臀腿燃脂', difficulty: '中级',
    prescription: '每次 15–30 分钟', targetMuscles: '心肺、臀大肌、股四头肌',
    breathing: '全程均匀呼吸',
    description: '模拟爬楼梯，臀腿参与度高，燃脂效率高。',
    keyPoints: ['全脚掌踩实台阶', '身体直立少扶把手', '步幅适中节奏稳定', '收紧臀部发力'],
    commonMistakes: ['倚靠把手大幅减重', '只用前脚掌', '速度忽快忽慢'],
    imageRes: 'app.media.ex2_mc_stair'
  },
  // ==================== 拉伸（器械：自重） ====================
  {
    id: 'st_doorframe', name: '门框胸大肌拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '胸大肌', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '胸大肌、肩前侧',
    breathing: '全程缓慢深呼吸',
    description: '训练后胸部拉伸，缓解卧推后的紧张与圆肩。',
    keyPoints: ['前臂贴门框，肘与肩同高', '身体向前倾感受胸部拉伸', '保持 30 秒均匀呼吸', '换另一侧'],
    commonMistakes: ['手臂抬得过高', '用力过猛弹震拉伸', '憋气'],
    imageRes: 'app.media.ex2_st_doorframe'
  },
  {
    id: 'st_crossshoulder', name: '肩部交叉拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '三角肌', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '三角肌、肩后侧',
    breathing: '全程缓慢深呼吸',
    description: '手臂横跨胸前拉伸肩部，推举训练后必备。',
    keyPoints: ['一侧手臂横跨胸前', '另一侧手轻拉其肘部', '保持肩部下沉', '感受肩后侧牵拉感'],
    commonMistakes: ['拉肘过猛', '耸肩', '身体扭转代偿'],
    imageRes: 'app.media.ex2_st_crossshoulder'
  },
  {
    id: 'st_reardelt', name: '三角肌后束拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '三角肌后束', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '三角肌后束',
    breathing: '全程缓慢深呼吸',
    description: '俯身位针对肩后束的拉伸，改善肩关节后侧紧张。',
    keyPoints: ['手臂横过胸前', '微俯身加大拉伸角度', '肩部放松下沉', '保持静态不弹震'],
    commonMistakes: ['身体旋转', '拉伸侧耸肩', '憋气硬拉'],
    imageRes: 'app.media.ex2_st_reardelt'
  },
  {
    id: 'st_childspose', name: '婴儿式放松', equipment: '自重', muscle: '拉伸', subMuscle: '腰背', difficulty: '初级',
    prescription: '2 组 × 40 秒', targetMuscles: '腰背、臀、肩',
    breathing: '深长缓慢呼吸',
    description: '经典放松体式，拉伸整个后侧链，平静心率。',
    keyPoints: ['跪姿臀部坐向脚跟', '双臂向前伸展贴地', '额头触地', '呼吸时感受背部起伏'],
    commonMistakes: ['臀部抬起离开脚跟', '憋气', '腰部紧张不放松'],
    imageRes: 'app.media.ex2_st_childspose'
  },
  {
    id: 'st_backstretch', name: '单臂背部拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '背阔肌', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '背阔肌、大圆肌',
    breathing: '全程缓慢深呼吸',
    description: '抓握固定物后坐，单侧拉伸背阔肌。',
    keyPoints: ['单手握住固定物', '身体向后坐感受拉伸', '手臂保持伸直', '换另一侧'],
    commonMistakes: ['屈臂耸肩', '身体旋转', '拉伸过猛'],
    imageRes: 'app.media.ex2_st_backstretch'
  },
  {
    id: 'st_quad', name: '大腿前侧拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '股四头肌', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '股四头肌',
    breathing: '全程缓慢深呼吸',
    description: '站姿抓脚踝拉伸大腿前侧，腿部训练后必做。',
    keyPoints: ['站姿单手抓同侧脚踝', '双膝并拢', '髋部微前推', '核心收紧保持平衡'],
    commonMistakes: ['膝盖外张', '腰椎过伸后仰', '拉向臀部过猛'],
    imageRes: 'app.media.ex2_st_quad'
  },
  {
    id: 'st_hamstring', name: '大腿后侧腘绳拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '腘绳肌', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '腘绳肌',
    breathing: '全程缓慢深呼吸',
    description: '仰卧或坐姿拉伸大腿后侧，改善柔韧性保护腰椎。',
    keyPoints: ['一腿伸直脚尖回勾', '上身从髋部前倾', '背部保持平直', '感受大腿后侧牵拉'],
    commonMistakes: ['弓腰用手够脚', '膝盖弯曲', '弹震拉伸'],
    imageRes: 'app.media.ex2_st_hamstring'
  },
  {
    id: 'st_pigeon', name: '鸽子式臀部拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '臀部', difficulty: '中级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '臀大肌、梨状肌',
    breathing: '深长缓慢呼吸',
    description: '深度拉伸臀部与梨状肌，缓解久坐与深蹲后的紧张。',
    keyPoints: ['前腿屈膝横放身前', '后腿向后伸直', '上身前倾', '臀部均匀着地'],
    commonMistakes: ['前腿脚踝角度别扭强压膝盖', '身体歪斜', '憋气硬压'],
    imageRes: 'app.media.ex2_st_pigeon'
  },
  {
    id: 'st_calf', name: '小腿靠墙拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '小腿', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '腓肠肌、比目鱼肌',
    breathing: '全程缓慢深呼吸',
    description: '推墙拉伸小腿，跑步跳跃类训练后必做。',
    keyPoints: ['双手推墙前后弓步', '后脚跟着地腿伸直', '身体前倾加大拉伸', '换另一侧'],
    commonMistakes: ['后脚跟离地', '后腿弯曲', '身体扭转'],
    imageRes: 'app.media.ex2_st_calf'
  },
  {
    id: 'st_catcow', name: '猫牛式', equipment: '自重', muscle: '拉伸', subMuscle: '脊柱', difficulty: '初级',
    prescription: '2 组 × 10 次循环', targetMuscles: '脊柱灵活度、竖脊肌',
    breathing: '弓背呼气，塌腰吸气',
    description: '脊柱逐节活动的动态拉伸，训练前后都适用。',
    keyPoints: ['四足跪姿手在肩下', '吸气塌腰抬头（牛式）', '呼气弓背低头（猫式）', '动作缓慢逐节进行'],
    commonMistakes: ['速度过快', '肘部弯曲', '幅度过大挤压腰椎'],
    imageRes: 'app.media.ex2_st_catcow'
  },
  {
    id: 'st_sidebend', name: '躯干侧屈拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '侧腹', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '腹斜肌、腰方肌、背阔肌',
    breathing: '全程缓慢深呼吸',
    description: '站姿侧屈拉伸躯干侧链，改善体态平衡。',
    keyPoints: ['站姿一手上举', '身体向对侧侧屈', '髋部保持中正不前倾', '换另一侧'],
    commonMistakes: ['身体前倾或后仰', '耸肩', '侧屈过猛'],
    imageRes: 'app.media.ex2_st_sidebend'
  },
  {
    id: 'st_bicep', name: '肱二头肌拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '肱二头肌', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '肱二头肌、肩前侧',
    breathing: '全程缓慢深呼吸',
    description: '身后扶固定物转体，拉伸二头与肩前束。',
    keyPoints: ['手臂后伸扶住固定物', '掌心向下', '身体缓慢向前转离', '感受二头牵拉'],
    commonMistakes: ['转体过猛', '肩部前顶', '憋气'],
    imageRes: 'app.media.ex2_st_bicep'
  },
  {
    id: 'st_tricep', name: '肱三头肌拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '肱三头肌', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '肱三头肌',
    breathing: '全程缓慢深呼吸',
    description: '手臂过头屈肘拉伸三头，臂屈伸训练后必做。',
    keyPoints: ['一侧手臂举过头顶屈肘', '另一侧手轻压其肘部', '躯干保持直立', '换另一侧'],
    commonMistakes: ['压肘过猛', '腰椎侧弯代偿', '头部前倾'],
    imageRes: 'app.media.ex2_st_tricep'
  },
  {
    id: 'st_forearm', name: '小臂拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '小臂', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '小臂屈伸肌群',
    breathing: '全程缓慢深呼吸',
    description: '屈伸手腕双向拉伸小臂，握力训练后放松必备。',
    keyPoints: ['手臂前伸掌心向下轻压手背', '再翻掌向上轻拉手指', '各保持 30 秒', '力度温和'],
    commonMistakes: ['按压过猛', '肘部弯曲', '只拉一侧方向'],
    imageRes: 'app.media.ex2_st_forearm'
  },
  // ==================== 扩充批次（103 个）：示例图复用同器械同部位代表图，后续可逐张替换 ====================
  // ---------- 胸 ----------
  {
    id: 'mc_inclinepress', name: '上斜器械推胸', equipment: '器械', muscle: '胸', subMuscle: '上胸', difficulty: '初级',
    prescription: '4 组 × 10–12 次', targetMuscles: '上胸、三角肌前束、肱三头肌',
    breathing: '推起呼气，回放吸气',
    description: '固定轨迹的上斜推举，安全稳定地强化上胸。',
    keyPoints: ['调节座椅使把手对准上胸位置', '靠背贴紧，肩胛后缩下沉', '推起至手臂接近伸直但不锁死肘关节', '回放至把手接近胸部上方即可'],
    commonMistakes: ['座椅高度不对导致轨迹偏移到肩部', '推起时耸肩借力', '回放过快失控'],
    imageRes: 'app.media.ex2_mc_inclinepress'
  },
  {
    id: 'cb_inclinefly', name: '上斜绳索飞鸟', equipment: '绳索', muscle: '胸', subMuscle: '上胸', difficulty: '中级',
    prescription: '4 组 × 12 次', targetMuscles: '上胸、胸大肌内侧',
    breathing: '打开吸气，合拢呼气',
    description: '仰卧上斜凳上做绳索飞鸟，全程张力刺激上胸。',
    keyPoints: ['上斜凳置于双滑轮中间，滑轮调低位', '双臂微屈保持固定弧度', '沿弧线向上合拢至胸上方', '顶峰收缩 1 秒后缓慢回放'],
    commonMistakes: ['手臂屈伸变成推举', '重量过大导致耸肩', '回放时放任绳索拉动肩部'],
    imageRes: 'app.media.ex2_cb_inclinefly'
  },
  {
    id: 'db_declinefly', name: '下斜哑铃飞鸟', equipment: '哑铃', muscle: '胸', subMuscle: '下胸', difficulty: '中级',
    prescription: '3 组 × 12 次', targetMuscles: '下胸、胸大肌外沿',
    breathing: '打开吸气，合拢呼气',
    description: '下斜角度飞鸟，勾勒下胸轮廓。',
    keyPoints: ['下斜凳固定双腿防止下滑', '哑铃置于胸上方，掌心相对', '微屈肘沿弧线向两侧打开', '感受下胸拉伸后合拢回顶点'],
    commonMistakes: ['打开过深拉伤肩前束', '手腕晃动', '用惯性甩起哑铃'],
    imageRes: 'app.media.ex2_db_declinefly'
  },
  {
    id: 'bw_kneepushup', name: '跪姿俯卧撑', equipment: '自重', muscle: '胸', subMuscle: '中胸', difficulty: '初级',
    prescription: '3 组 × 12–15 次', targetMuscles: '胸大肌、肱三头肌',
    breathing: '下放吸气，推起呼气',
    description: '减负荷版俯卧撑，适合新手建立推力基础。',
    keyPoints: ['双膝着地，小腿交叉抬起', '身体从膝到肩成一条直线', '下放至胸近地面', '胸肌发力推起'],
    commonMistakes: ['臀部后坐变成跪姿磕头', '塌腰', '下放幅度不足'],
    imageRes: 'app.media.ex2_bw_kneepushup'
  },
  {
    id: 'bw_closepushupchest', name: '窄距俯卧撑（胸侧重）', equipment: '自重', muscle: '胸', subMuscle: '中胸', difficulty: '中级',
    prescription: '3 组 × 10–12 次', targetMuscles: '胸大肌内侧、肱三头肌',
    breathing: '下放吸气，推起呼气',
    description: '窄手距俯卧撑，强化胸中缝内侧线条。',
    keyPoints: ['双手间距窄于肩，食指拇指近似成三角', '身体保持平板一条线', '肘部贴近身体两侧下放', '推起时想象挤压胸内侧'],
    commonMistakes: ['肘部外撇过多', '塌腰翘臀', '只做半程'],
    imageRes: 'app.media.ex2_bw_closepushupchest'
  },
  {
    id: 'bw_weightedpushup', name: '负重俯卧撑', equipment: '自重', muscle: '胸', subMuscle: '中胸', difficulty: '中级',
    prescription: '4 组 × 8–10 次', targetMuscles: '胸大肌、肱三头肌、核心',
    breathing: '下放吸气，推起呼气',
    description: '背部负重片或负重背心的俯卧撑，突破推力平台期。',
    keyPoints: ['负重置于上背部中央并保持稳定', '核心收紧身体成直线', '全程控制下放至胸近地', '爆发推起'],
    commonMistakes: ['负重滑动导致重心偏移', '腰部下沉', '下放速度过快'],
    imageRes: 'app.media.ex2_bw_weightedpushup'
  },
  {
    id: 'mc_seatedfly', name: '器械夹胸（坐姿）', equipment: '器械', muscle: '胸', subMuscle: '中胸', difficulty: '初级',
    prescription: '4 组 × 12 次', targetMuscles: '胸大肌、胸内侧',
    breathing: '合拢呼气，打开吸气',
    description: '坐姿夹胸机，固定轨迹孤立挤压胸肌。',
    keyPoints: ['调节座椅使上臂与地面平行', '前臂贴紧挡垫', '胸肌发力将双臂合拢于体前', '顶峰收缩后缓慢打开'],
    commonMistakes: ['用手臂力量硬拉挡垫', '打开时完全卸力', '耸肩借力'],
    imageRes: 'app.media.ex2_mc_seatedfly'
  },
  {
    id: 'bb_platesqueeze', name: '杠铃片夹胸', equipment: '杠铃', muscle: '胸', subMuscle: '中胸', difficulty: '初级',
    prescription: '3 组 × 12–15 次', targetMuscles: '胸大肌内侧',
    breathing: '推出呼气，收回吸气',
    description: '双手夹住杠铃片向前推出，持续挤压胸中缝。',
    keyPoints: ['双手掌根夹紧杠铃片置于胸前', '全程保持向内夹紧的压力', '向前推出至手臂接近伸直', '缓慢收回胸前'],
    commonMistakes: ['夹片压力不足导致滑落', '推出时肩部前送过多', '使用过重杠铃片'],
    imageRes: 'app.media.ex2_bb_platesqueeze'
  },
  {
    id: 'bd_fly', name: '弹力带夹胸', equipment: '弹力带', muscle: '胸', subMuscle: '中胸', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '胸大肌、胸内侧',
    breathing: '合拢呼气，打开吸气',
    description: '弹力带绕背做夹胸，居家胸训好选择。',
    keyPoints: ['弹力带绕过上背部，双手握两端', '双臂微屈保持弧度', '向前合拢至双手接近', '控制回放感受离心张力'],
    commonMistakes: ['手臂伸屈变成推', '弹力带位置过低滑到腰部', '回放过快'],
    imageRes: 'app.media.ex2_bd_fly'
  },
  {
    id: 'bw_inclinepushup', name: '上斜俯卧撑', equipment: '自重', muscle: '胸', subMuscle: '下胸', difficulty: '初级',
    prescription: '3 组 × 12–15 次', targetMuscles: '下胸、肱三头肌',
    breathing: '下放吸气，推起呼气',
    description: '双手撑高处的俯卧撑，负荷较低，侧重下胸。',
    keyPoints: ['双手撑在稳固台面上与肩同宽', '身体成一条直线', '下放至胸轻触台面边缘', '推起至手臂伸直'],
    commonMistakes: ['台面不稳晃动', '臀部前送', '只低头不屈肘'],
    imageRes: 'app.media.ex2_bw_inclinepushup'
  },
  {
    id: 'bw_closeincline', name: '窄距上斜俯卧撑', equipment: '自重', muscle: '胸', subMuscle: '下胸', difficulty: '中级',
    prescription: '3 组 × 10–12 次', targetMuscles: '下胸内侧、肱三头肌',
    breathing: '下放吸气，推起呼气',
    description: '上斜窄距组合，兼顾下胸内侧与手臂。',
    keyPoints: ['双手窄距撑于台面', '身体直线核心收紧', '肘部贴身下放', '推起挤压胸内侧'],
    commonMistakes: ['肘部过度外张', '台面过高失去训练强度', '塌腰'],
    imageRes: 'app.media.ex2_bw_closeincline'
  },
  {
    id: 'bw_declinepushup', name: '下斜俯卧撑', equipment: '自重', muscle: '胸', subMuscle: '上胸', difficulty: '中级',
    prescription: '3 组 × 10–12 次', targetMuscles: '上胸、三角肌前束',
    breathing: '下放吸气，推起呼气',
    description: '双脚垫高的俯卧撑，负荷上移刺激上胸。',
    keyPoints: ['双脚置于凳上，双手撑地比肩稍宽', '身体成直线不塌腰', '下放至胸近地面', '推起时感受上胸发力'],
    commonMistakes: ['凳面过高导致肩压过大', '腰部下塌', '下放幅度不足'],
    imageRes: 'app.media.ex2_bw_declinepushup'
  },
  {
    id: 'bw_onearmpushup', name: '单手俯卧撑（辅助）', equipment: '自重', muscle: '胸', subMuscle: '中胸', difficulty: '高级',
    prescription: '3 组 × 5–8 次/侧', targetMuscles: '胸大肌、肱三头肌、核心抗旋转',
    breathing: '下放吸气，推起呼气',
    description: '单臂推力的高阶练习，另一手扶矮物辅助过渡。',
    keyPoints: ['双脚分开加宽支撑面', '辅助手扶矮凳分担部分重量', '主侧手臂控制下放', '核心抗旋转保持骨盆稳定'],
    commonMistakes: ['身体过度旋转', '辅助手借力过多', '下放失控摔落'],
    imageRes: 'app.media.ex2_bw_onearmpushup'
  },
  {
    id: 'bb_floorpress', name: '地板卧推', equipment: '杠铃', muscle: '胸', subMuscle: '中胸', difficulty: '中级',
    prescription: '4 组 × 8–10 次', targetMuscles: '胸大肌、肱三头肌',
    breathing: '下放吸气，推起呼气',
    description: '仰卧地板推杠铃，缩短行程保护肩关节。',
    keyPoints: ['仰卧地面，屈膝踩实', '杠铃从髋部滚至胸上方或用保护杠', '下放至上臂轻触地面即停', '垂直推起至锁骨上方'],
    commonMistakes: ['肘部砸地反弹借力', '握距过窄', '手腕后折'],
    imageRes: 'app.media.ex2_bb_floorpress'
  },
  {
    id: 'cb_lowfly', name: '绳索低位夹胸', equipment: '绳索', muscle: '胸', subMuscle: '上胸', difficulty: '中级',
    prescription: '4 组 × 12 次', targetMuscles: '上胸、胸大肌内侧',
    breathing: '合拢呼气，回放吸气',
    description: '滑轮置低位，由低向高夹拢，精准打击上胸。',
    keyPoints: ['双侧滑轮调至最低位', '双手握把站于中间', '沿弧线向上合拢至胸前上方', '顶峰收缩后缓慢回放'],
    commonMistakes: ['身体前倾借力', '手臂弯曲过多变成拉', '回放失控'],
    imageRes: 'app.media.ex2_cb_lowfly'
  },
  // ---------- 肩 ----------
  {
    id: 'db_seatedpress', name: '坐姿哑铃推举', equipment: '哑铃', muscle: '肩', subMuscle: '整体', difficulty: '中级',
    prescription: '4 组 × 8–10 次', targetMuscles: '三角肌整体、肱三头肌',
    breathing: '推起呼气，下放吸气',
    description: '坐姿靠背推举，稳定躯干专注肩部发力。',
    keyPoints: ['靠背调至上斜近 90 度', '哑铃置于肩侧，掌心朝前', '垂直推起至头顶上方', '下放至耳侧高度'],
    commonMistakes: ['腰部过度反弓', '哑铃前后晃动', '下放过低拉伤肩袖'],
    imageRes: 'app.media.ex2_db_seatedpress'
  },
  {
    id: 'cb_lateralraise', name: '绳索侧平举', equipment: '绳索', muscle: '肩', subMuscle: '中束', difficulty: '初级',
    prescription: '3 组 × 12–15 次/侧', targetMuscles: '三角肌中束',
    breathing: '抬起呼气，下放吸气',
    description: '低位滑轮侧平举，张力曲线更平缓持续。',
    keyPoints: ['滑轮调最低位，侧身站立', '对侧手握把，绳索从体前穿过', '微屈肘向侧上方抬起至肩高', '缓慢下放不碰身体'],
    commonMistakes: ['耸肩用斜方肌借力', '抬过肩高', '身体晃动甩起'],
    imageRes: 'app.media.ex2_cb_lateralraise'
  },
  {
    id: 'mc_reversefly', name: '反向蝴蝶机飞鸟', equipment: '器械', muscle: '肩', subMuscle: '后束', difficulty: '初级',
    prescription: '4 组 × 12 次', targetMuscles: '三角肌后束、斜方肌中束',
    breathing: '打开呼气，回放吸气',
    description: '面坐蝴蝶机反向飞鸟，孤立强化肩后束。',
    keyPoints: ['胸部贴紧靠垫，双手握前把', '双臂微屈向两侧后方打开', '感受后束收缩顶峰稍停', '控制回放不撞片'],
    commonMistakes: ['用背阔肌下压代替后束发力', '肘部下垂', '回放过快'],
    imageRes: 'app.media.ex2_mc_reversefly'
  },
  {
    id: 'db_extrotation', name: '哑铃外旋', equipment: '哑铃', muscle: '肩', subMuscle: '后束', difficulty: '初级',
    prescription: '3 组 × 12–15 次/侧', targetMuscles: '肩袖肌群（冈下肌、小圆肌）',
    breathing: '外旋呼气，回放吸气',
    description: '侧卧哑铃外旋，强化肩袖稳定性，预防肩部伤病。',
    keyPoints: ['侧卧，上侧手臂屈肘 90 度贴体侧', '肘部固定不动', '以前臂为杠杆向外上方旋转', '缓慢回放'],
    commonMistakes: ['重量过大导致动作变形', '肘部离开身体', '速度过快'],
    imageRes: 'app.media.ex2_db_extrotation'
  },
  {
    id: 'db_shrug', name: '哑铃耸肩', equipment: '哑铃', muscle: '肩', subMuscle: '整体', difficulty: '初级',
    prescription: '4 组 × 12–15 次', targetMuscles: '斜方肌上束',
    breathing: '耸起呼气，下放吸气',
    description: '垂直耸肩，打造厚实上斜方肌。',
    keyPoints: ['双手持哑铃垂于体侧', '双肩垂直向上耸向耳朵', '顶峰收缩 1–2 秒', '缓慢下放至完全拉伸'],
    commonMistakes: ['绕肩画圈增加颈椎风险', '屈肘借力', '重量过大缩短行程'],
    imageRes: 'app.media.ex2_db_shrug'
  },
  {
    id: 'db_onearmpress', name: '单臂哑铃推举', equipment: '哑铃', muscle: '肩', subMuscle: '整体', difficulty: '中级',
    prescription: '3 组 × 10 次/侧', targetMuscles: '三角肌整体、核心抗侧屈',
    breathing: '推起呼气，下放吸气',
    description: '单臂推举激活核心稳定，纠正左右力量差。',
    keyPoints: ['站姿或坐姿，单手持哑铃于肩侧', '核心收紧防止侧倾', '垂直推起至头顶', '缓慢下放回肩侧'],
    commonMistakes: ['身体侧屈借力', '推起轨迹前飘', '左右次数不一致'],
    imageRes: 'app.media.ex2_db_onearmpress'
  },
  {
    id: 'cb_bentfly', name: '俯身绳索飞鸟', equipment: '绳索', muscle: '肩', subMuscle: '后束', difficulty: '中级',
    prescription: '3 组 × 12 次', targetMuscles: '三角肌后束',
    breathing: '打开呼气，回放吸气',
    description: '低位滑轮俯身交叉飞鸟，后束全程张力。',
    keyPoints: ['双滑轮置低位，俯身约 45 度', '左右手交叉握对侧把', '微屈肘向两侧打开', '感受后束收缩后回放'],
    commonMistakes: ['起身借力', '手臂伸屈变成划船', '低头弓背'],
    imageRes: 'app.media.ex2_cb_bentfly'
  },
  {
    id: 'bd_facepull', name: '弹力带面拉', equipment: '弹力带', muscle: '肩', subMuscle: '后束', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '三角肌后束、斜方肌中下束',
    breathing: '拉向面部呼气，回放吸气',
    description: '弹力带版面拉，居家改善圆肩体态。',
    keyPoints: ['弹力带固定于面部高度', '双手握带向后拉向面部两侧', '肘部高于手背', '顶峰挤压肩胛后回放'],
    commonMistakes: ['固定点过低', '用手臂力量拉而非后束', '回放过快'],
    imageRes: 'app.media.ex2_bd_facepull'
  },
  {
    id: 'cb_seatedpress', name: '坐姿绳索推举', equipment: '绳索', muscle: '肩', subMuscle: '整体', difficulty: '中级',
    prescription: '4 组 × 10–12 次', targetMuscles: '三角肌整体、肱三头肌',
    breathing: '推起呼气，下放吸气',
    description: '背向滑轮坐姿推举，阻力方向独特。',
    keyPoints: ['背对滑轮坐于凳上，滑轮置低位', '双手握把于肩侧', '垂直向上推起', '控制下放'],
    commonMistakes: ['躯干前倾借力', '推起时耸肩', '回放失控'],
    imageRes: 'app.media.ex2_cb_seatedpress'
  },
  {
    id: 'cb_standingpress', name: '站姿绳索推举', equipment: '绳索', muscle: '肩', subMuscle: '整体', difficulty: '中级',
    prescription: '3 组 × 10–12 次', targetMuscles: '三角肌整体、核心',
    breathing: '推起呼气，下放吸气',
    description: '站姿绳索推举，兼顾肩部力量与核心稳定。',
    keyPoints: ['背对低位滑轮站立', '双手握把于肩前', '收紧核心垂直推起', '缓慢下放'],
    commonMistakes: ['腰部反弓', '双腿蹬地借力', '下放过快'],
    imageRes: 'app.media.ex2_cb_standingpress'
  },
  {
    id: 'db_ypress', name: '哑铃Y字推举', equipment: '哑铃', muscle: '肩', subMuscle: '中束', difficulty: '中级',
    prescription: '3 组 × 10–12 次', targetMuscles: '三角肌中束、斜方肌下束',
    breathing: '推起呼气，下放吸气',
    description: '沿 Y 字轨迹上推，兼顾肩部推举与肩胛上旋。',
    keyPoints: ['双手持哑铃于肩侧', '向外上方呈 Y 字推起', '顶端双臂与躯干成 Y 形', '沿原轨迹下放'],
    commonMistakes: ['轨迹垂直变成普通推举', '耸肩缩脖', '重量过大'],
    imageRes: 'app.media.ex2_db_ypress'
  },
  {
    id: 'db_wraise', name: '哑铃W字外展', equipment: '哑铃', muscle: '肩', subMuscle: '后束', difficulty: '初级',
    prescription: '3 组 × 12 次', targetMuscles: '三角肌后束、肩袖肌群',
    breathing: '外展呼气，回放吸气',
    description: '俯身 W 轨迹外展，后束与肩袖联合强化。',
    keyPoints: ['俯身 45 度，双臂屈肘垂于体前', '向后上方打开双臂同时外旋', '顶端呈 W 形挤压后束', '缓慢回放'],
    commonMistakes: ['起身借力', '外旋不足', '弓背'],
    imageRes: 'app.media.ex2_db_wraise'
  },
  {
    id: 'db_onearmlateral', name: '单臂哑铃侧平举', equipment: '哑铃', muscle: '肩', subMuscle: '中束', difficulty: '初级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '三角肌中束',
    breathing: '抬起呼气，下放吸气',
    description: '单臂侧平举可扶固定物，更孤立刺激中束。',
    keyPoints: ['一手扶固定物，身体微倾向训练侧', '微屈肘向侧上方抬至肩高', '顶峰稍停', '缓慢下放'],
    commonMistakes: ['抬过肩高引发肩峰撞击', '甩动借力', '身体旋转'],
    imageRes: 'app.media.ex2_db_onearmlateral'
  },
  {
    id: 'db_onearmrearfly', name: '俯身单臂哑铃飞鸟', equipment: '哑铃', muscle: '肩', subMuscle: '后束', difficulty: '中级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '三角肌后束',
    breathing: '打开呼气，回放吸气',
    description: '单臂俯身飞鸟，集中注意力于单侧后束。',
    keyPoints: ['一手扶凳，俯身背部平直', '持哑铃微屈肘', '向侧上方打开至与肩平', '缓慢回放感受离心'],
    commonMistakes: ['旋转躯干借力', '手臂过直', '弓背'],
    imageRes: 'app.media.ex2_db_onearmrearfly'
  },
  // ---------- 背 ----------
  {
    id: 'cb_closepulldown', name: '窄握高位下拉', equipment: '绳索', muscle: '背', subMuscle: '背阔肌', difficulty: '初级',
    prescription: '4 组 × 10–12 次', targetMuscles: '背阔肌下部、肱二头肌',
    breathing: '下拉呼气，回放吸气',
    description: '窄握下拉重心下移，侧重背阔肌下部厚度。',
    keyPoints: ['双手窄握横杆掌心相对或正握', '挺胸沉肩坐稳', '下拉至锁骨上方', '缓慢回放至手臂接近伸直'],
    commonMistakes: ['后仰甩腰借力', '拉到颈后', '回放时耸肩卸力'],
    imageRes: 'app.media.ex2_cb_closepulldown'
  },
  {
    id: 'cb_onearmpulldown', name: '单臂绳索下拉', equipment: '绳索', muscle: '背', subMuscle: '背阔肌', difficulty: '中级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '背阔肌单侧',
    breathing: '下拉呼气，回放吸气',
    description: '单臂高位下拉，纠正左右背肌不平衡。',
    keyPoints: ['单手握把侧对滑轮', '躯干保持稳定不旋转', '沿体侧弧线拉向髋部方向', '缓慢回放感受拉伸'],
    commonMistakes: ['躯干旋转借力', '用手臂拉而非背阔', '回放失控'],
    imageRes: 'app.media.ex2_cb_onearmpulldown'
  },
  {
    id: 'mc_row', name: '器械划船', equipment: '器械', muscle: '背', subMuscle: '上背', difficulty: '初级',
    prescription: '4 组 × 10–12 次', targetMuscles: '斜方肌中束、背阔肌、菱形肌',
    breathing: '拉回呼气，回放吸气',
    description: '固定轨迹划船机，安全堆背上背厚度。',
    keyPoints: ['调节胸垫高度使把手对准下胸', '胸部贴紧靠垫', '肘部贴体侧向后拉', '顶峰挤压肩胛后回放'],
    commonMistakes: ['胸离开靠垫借力', '耸肩', '回放撞片'],
    imageRes: 'app.media.ex2_mc_row'
  },
  {
    id: 'bw_weightedpullup', name: '负重引体向上', equipment: '自重', muscle: '背', subMuscle: '背阔肌', difficulty: '高级',
    prescription: '4 组 × 6–8 次', targetMuscles: '背阔肌、肱二头肌',
    breathing: '拉起呼气，下放吸气',
    description: '腰挂负重的引体向上，进阶背部王牌。',
    keyPoints: ['负重腰带挂片或用哑铃夹腿', '正握比肩稍宽', '拉起至下巴过杠', '全程控制下放'],
    commonMistakes: ['摆动借力', '半程下放', '握距过窄'],
    imageRes: 'app.media.ex2_bw_weightedpullup'
  },
  {
    id: 'bw_proneext', name: '俯卧挺身', equipment: '自重', muscle: '背', subMuscle: '下背', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '竖脊肌、臀大肌',
    breathing: '抬起呼气，下放吸气',
    description: '俯卧地面抬起上半身，强化下背与体态。',
    keyPoints: ['俯卧，双手置于耳侧或前伸', '收紧下背抬起胸肩部', '顶峰稍停', '缓慢下放'],
    commonMistakes: ['抬头过猛压迫颈椎', '抬得过高超伸腰椎', '速度过快'],
    imageRes: 'app.media.ex2_bw_proneext'
  },
  {
    id: 'bw_chinup', name: '引体向上（反手窄握）', equipment: '自重', muscle: '背', subMuscle: '背阔肌', difficulty: '中级',
    prescription: '4 组 × 6–10 次', targetMuscles: '背阔肌、肱二头肌',
    breathing: '拉起呼气，下放吸气',
    description: '反手窄握引体，手臂参与更多，新手更易上手。',
    keyPoints: ['反手握杠与肩同宽', '悬挂沉肩启动', '背阔发力拉起至下巴过杠', '缓慢下放至接近伸直'],
    commonMistakes: ['蹬腿摆动借力', '耸肩', '下放不完全'],
    imageRes: 'app.media.ex2_bw_chinup'
  },
  {
    id: 'cb_onearmlatpull', name: '单臂高位下拉', equipment: '绳索', muscle: '背', subMuscle: '背阔肌', difficulty: '中级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '背阔肌单侧',
    breathing: '下拉呼气，回放吸气',
    description: '高位滑轮单臂下拉，行程更长拉伸更充分。',
    keyPoints: ['单臂握把面对滑轮坐稳', '充分伸展手臂感受背阔拉伸', '拉向同侧肩外侧', '控制回放'],
    commonMistakes: ['身体侧倒借力', '耸肩', '只拉半程'],
    imageRes: 'app.media.ex2_cb_onearmlatpull'
  },
  {
    id: 'mc_tbarrowseated', name: '坐姿T杠划船', equipment: '器械', muscle: '背', subMuscle: '上背', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '背阔肌、斜方肌中束、菱形肌',
    breathing: '拉回呼气，回放吸气',
    description: '胸垫支撑式 T 杠划船，免去腰部负担专注背部。',
    keyPoints: ['胸部贴紧斜垫，双脚踩稳踏板', '双手握住划船把手', '沿弧线拉向腹部', '顶峰挤压肩胛'],
    commonMistakes: ['胸离垫挺身借力', '拉向颈部', '回放耸肩'],
    imageRes: 'app.media.ex2_mc_tbarrowseated'
  },
  {
    id: 'db_chestrow', name: '俯卧哑铃划船', equipment: '哑铃', muscle: '背', subMuscle: '上背', difficulty: '中级',
    prescription: '4 组 × 10–12 次', targetMuscles: '背阔肌、斜方肌中束',
    breathing: '拉起呼气，下放吸气',
    description: '俯卧上斜凳划船，杜绝腰部借力。',
    keyPoints: ['俯卧于上斜 45 度凳', '双臂持哑铃垂直下垂', '肘部贴体侧拉向髋部', '顶峰收缩后缓慢下放'],
    commonMistakes: ['抬头弓颈', '用惯性甩起', '下放不完全'],
    imageRes: 'app.media.ex2_db_chestrow'
  },
  {
    id: 'bb_hexdeadlift', name: '六角杠硬拉', equipment: '杠铃', muscle: '背', subMuscle: '下背', difficulty: '中级',
    prescription: '4 组 × 8 次', targetMuscles: '股四头肌、臀大肌、竖脊肌',
    breathing: '拉起前吸气憋住，锁定后呼气',
    description: '站入六角杠中硬拉，躯干更直立，对腰更友好。',
    keyPoints: ['站于杠铃框中央，握两侧把手', '屈髋屈膝下蹲握杠', '背部平直蹬地拉起', '顶端髋膝锁定'],
    commonMistakes: ['弓腰拉起', '先抬臀再拉', '顶端过度后仰'],
    imageRes: 'app.media.ex2_bb_hexdeadlift'
  },
  {
    id: 'bd_straightarm', name: '弹力带直臂下压', equipment: '弹力带', muscle: '背', subMuscle: '背阔肌', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '背阔肌',
    breathing: '下压呼气，回放吸气',
    description: '弹力带高位直臂下压，居家孤立背阔肌。',
    keyPoints: ['弹力带固定于头顶上方', '双臂接近伸直微屈', '沿弧线下压至大腿前', '缓慢回放'],
    commonMistakes: ['屈肘变成臂屈伸', '身体前倾借力', '固定点不牢'],
    imageRes: 'app.media.ex2_bd_straightarm'
  },
  {
    id: 'cb_onearmstraight', name: '单臂直臂绳索下压', equipment: '绳索', muscle: '背', subMuscle: '背阔肌', difficulty: '中级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '背阔肌单侧',
    breathing: '下压呼气，回放吸气',
    description: '单臂直臂下压，感受单侧背阔全程收缩。',
    keyPoints: ['高位滑轮单臂握把', '手臂接近伸直', '沿体侧弧线压向大腿', '顶峰收缩后回放'],
    commonMistakes: ['屈肘借力', '躯干旋转', '回放失控'],
    imageRes: 'app.media.ex2_cb_onearmstraight'
  },
  {
    id: 'bw_invertedrow', name: '反向划船（低单杠）', equipment: '自重', muscle: '背', subMuscle: '上背', difficulty: '中级',
    prescription: '3 组 × 10–12 次', targetMuscles: '背阔肌、斜方肌中束、肱二头肌',
    breathing: '拉起呼气，下放吸气',
    description: '低杠下仰卧划船，自重练背的进阶选择。',
    keyPoints: ['仰卧于低杠下方，正握比肩稍宽', '身体成直线脚跟撑地', '拉至胸触杠', '缓慢下放至手臂伸直'],
    commonMistakes: ['臀部下沉塌腰', '拉向颈部', '下放不完全'],
    imageRes: 'app.media.ex2_bw_invertedrow'
  },
  // ---------- 腿/臀 ----------
  {
    id: 'mc_hacksquat', name: '哈克深蹲', equipment: '器械', muscle: '腿', subMuscle: '股四头肌', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '股四头肌、臀大肌',
    breathing: '下蹲吸气，站起呼气',
    description: '固定轨迹斜向深蹲，大重量刺激股四头肌。',
    keyPoints: ['双肩抵住靠垫，双脚踩于踏板中前部', '解锁保险缓慢下蹲', '蹲至大腿低于平行', '蹬伸站起不锁死膝'],
    commonMistakes: ['脚跟抬起', '膝盖内扣', '蹲得过浅'],
    imageRes: 'app.media.ex2_mc_hacksquat'
  },
  {
    id: 'db_hipthrust', name: '哑铃臀推', equipment: '哑铃', muscle: '臀', subMuscle: '臀大肌', difficulty: '中级',
    prescription: '4 组 × 10–12 次', targetMuscles: '臀大肌、腘绳肌',
    breathing: '顶起呼气，下放吸气',
    description: '上背靠凳、哑铃压髋的臀推，居家翘臀首选。',
    keyPoints: ['上背部靠凳，哑铃置于髋部褶皱处', '双脚与肩同宽踩实', '臀部发力顶髋至躯干大腿一线', '顶峰夹臀 1 秒后下放'],
    commonMistakes: ['顶端腰椎超伸', '脚距过近变成腿发力', '下放触地反弹'],
    imageRes: 'app.media.ex2_db_hipthrust'
  },
  {
    id: 'mc_abductor', name: '髋外展机', equipment: '器械', muscle: '臀', subMuscle: '臀中肌', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '臀中肌、臀小肌',
    breathing: '外展呼气，回收吸气',
    description: '坐姿髋外展，填补侧臀凹陷。',
    keyPoints: ['坐稳靠背，双腿贴紧外侧挡垫', '用髋部力量向外打开', '顶峰稍停', '控制回收不撞片'],
    commonMistakes: ['身体前倾借力', '重量过大行程缩短', '回收失控'],
    imageRes: 'app.media.ex2_mc_abductor'
  },
  {
    id: 'mc_adductor', name: '髋内收机', equipment: '器械', muscle: '腿', subMuscle: '大腿内侧', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '大腿内收肌群',
    breathing: '内收呼气，回放吸气',
    description: '坐姿髋内收，紧致大腿内侧。',
    keyPoints: ['双腿分开贴紧内侧挡垫', '向内夹拢双腿', '顶峰收缩 1 秒', '缓慢回放'],
    commonMistakes: ['用爆发力猛夹', '回放时完全卸力', '弓腰离开靠背'],
    imageRes: 'app.media.ex2_mc_adductor'
  },
  {
    id: 'mc_onelegcurl', name: '单腿腿弯举', equipment: '器械', muscle: '腿', subMuscle: '腘绳肌', difficulty: '中级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '腘绳肌单侧',
    breathing: '弯举呼气，回放吸气',
    description: '单腿弯举纠正后侧链左右失衡。',
    keyPoints: ['俯卧或坐姿固定骨盆', '单腿勾住滚垫', '弯举至小腿接近大腿', '缓慢回放'],
    commonMistakes: ['抬臀借力', '回放过快', '双膝受力不均'],
    imageRes: 'app.media.ex2_mc_onelegcurl'
  },
  {
    id: 'mc_onelegext', name: '单腿腿屈伸', equipment: '器械', muscle: '腿', subMuscle: '股四头肌', difficulty: '中级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '股四头肌单侧',
    breathing: '伸膝呼气，下放吸气',
    description: '单腿屈伸孤立股四头，兼顾两侧均衡。',
    keyPoints: ['坐稳靠背贴紧', '单踝勾住滚垫', '伸膝至腿接近水平', '顶峰收缩后缓慢下放'],
    commonMistakes: ['甩动借力', '锁膝撞击', '下放失控'],
    imageRes: 'app.media.ex2_mc_onelegext'
  },
  {
    id: 'bw_onelegcalf', name: '单腿提踵', equipment: '自重', muscle: '腿', subMuscle: '小腿', difficulty: '中级',
    prescription: '3 组 × 15 次/侧', targetMuscles: '腓肠肌、比目鱼肌',
    breathing: '提起呼气，下放吸气',
    description: '台阶边单腿提踵，小腿增粗的徒手利器。',
    keyPoints: ['前脚掌踩台阶边缘，手扶固定物', '下放脚跟至充分拉伸', '发力提踵至最高', '顶峰收缩 1 秒'],
    commonMistakes: ['弹震式借力', '下放幅度不足', '膝盖晃动'],
    imageRes: 'app.media.ex2_bw_onelegcalf'
  },
  {
    id: 'db_rdl', name: '哑铃罗马尼亚硬拉', equipment: '哑铃', muscle: '腿', subMuscle: '腘绳肌', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '腘绳肌、臀大肌',
    breathing: '下放吸气，拉起呼气',
    description: '哑铃版罗马尼亚硬拉，后侧链拉伸感更强。',
    keyPoints: ['双手持哑铃垂于大腿前', '屈髋后推臀部，膝微屈', '下放至小腿中段感受腘绳拉伸', '髋部前推站直'],
    commonMistakes: ['弓腰', '膝盖过度前屈变成深蹲', '下放过低失去张力'],
    imageRes: 'app.media.ex2_db_rdl'
  },
  {
    id: 'bw_sidelunge', name: '侧向箭步蹲', equipment: '自重', muscle: '腿', subMuscle: '大腿内侧', difficulty: '中级',
    prescription: '3 组 × 10 次/侧', targetMuscles: '大腿内收肌、股四头肌、臀大肌',
    breathing: '下蹲吸气，蹬回呼气',
    description: '侧向跨步下蹲，训练额状面腿部力量。',
    keyPoints: ['向侧方跨出一大步', '重心移向跨出腿屈髋下蹲', '另一腿伸直脚尖朝上', '蹬地收回起始位'],
    commonMistakes: ['膝盖内扣', '跨步过小', '上身过度前倾'],
    imageRes: 'app.media.ex2_bw_sidelunge'
  },
  {
    id: 'bw_onelegbridge', name: '单腿臀桥', equipment: '自重', muscle: '臀', subMuscle: '臀大肌', difficulty: '中级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '臀大肌单侧、核心',
    breathing: '顶起呼气，下放吸气',
    description: '单腿臀桥，强化单侧臀肌与骨盆稳定。',
    keyPoints: ['仰卧，一脚踩地另一腿伸直抬起', '臀部发力顶髋', '顶端肩髋膝一线', '缓慢下放不触地'],
    commonMistakes: ['骨盆旋转倾斜', '腰椎超伸', '速度过快'],
    imageRes: 'app.media.ex2_bw_onelegbridge'
  },
  {
    id: 'bd_abduction', name: '弹力带臀外展', equipment: '弹力带', muscle: '臀', subMuscle: '臀中肌', difficulty: '初级',
    prescription: '3 组 × 15 次/侧', targetMuscles: '臀中肌',
    breathing: '外展呼气，回收吸气',
    description: '弹力带套膝外展，激活侧臀经典热身与塑形动作。',
    keyPoints: ['弹力带套于膝上方，四足跪姿或站姿', '单腿向侧方打开', '顶峰稍停感受侧臀', '控制回收'],
    commonMistakes: ['骨盆翻转借力', '弹力带过松', '回收过快'],
    imageRes: 'app.media.ex2_bd_abduction'
  },
  {
    id: 'db_onelegrdl', name: '单腿罗马尼亚硬拉', equipment: '哑铃', muscle: '腿', subMuscle: '腘绳肌', difficulty: '高级',
    prescription: '3 组 × 10 次/侧', targetMuscles: '腘绳肌单侧、臀大肌、核心平衡',
    breathing: '下放吸气，拉起呼气',
    description: '单腿哑铃硬拉，力量与平衡的双重考验。',
    keyPoints: ['单腿站立手持对侧哑铃', '屈髋下放同时后腿后抬', '背部平直下放至膝下', '臀部发力回正'],
    commonMistakes: ['骨盆旋转', '弓腰', '膝盖锁死晃动'],
    imageRes: 'app.media.ex2_db_onelegrdl'
  },
  {
    id: 'mc_reversehack', name: '反向哈克深蹲', equipment: '器械', muscle: '腿', subMuscle: '股四头肌', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '臀大肌、腘绳肌',
    breathing: '下蹲吸气，站起呼气',
    description: '面向靠垫的哈克深蹲变式，重心后移侧重臀腿后侧。',
    keyPoints: ['面对靠背站立，肩抵靠垫', '双脚略前移', '屈髋下蹲至大腿平行', '蹬地站起'],
    commonMistakes: ['膝盖过度前移', '下蹲过浅', '顶端锁膝'],
    imageRes: 'app.media.ex2_mc_reversehack'
  },
  {
    id: 'mc_standabductor', name: '站姿髋外展器械', equipment: '器械', muscle: '臀', subMuscle: '臀中肌', difficulty: '初级',
    prescription: '3 组 × 15 次/侧', targetMuscles: '臀中肌、臀小肌',
    breathing: '外展呼气，回收吸气',
    description: '站姿髋外展机，负重模式下雕刻侧臀。',
    keyPoints: ['站姿扶稳把手，腿外侧贴挡垫', '向外后方抬起腿', '顶峰收缩', '缓慢回放'],
    commonMistakes: ['身体侧倾借力', '抬腿过高代偿', '回收撞片'],
    imageRes: 'app.media.ex2_mc_standabductor'
  },
  // ---------- 二头 ----------
  {
    id: 'cb_onearmcurl', name: '单臂绳索弯举', equipment: '绳索', muscle: '二头', subMuscle: '整体', difficulty: '初级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '肱二头肌单侧',
    breathing: '弯举呼气，下放吸气',
    description: '低位滑轮单臂弯举，张力恒定刺激肱二头。',
    keyPoints: ['低位滑轮侧站，单手握把', '上臂固定贴体侧', '弯举至肩前顶峰收缩', '缓慢下放至接近伸直'],
    commonMistakes: ['甩腰借力', '上臂前移', '下放过快'],
    imageRes: 'app.media.ex2_cb_onearmcurl'
  },
  {
    id: 'cb_hammercurl', name: '锤式绳索弯举', equipment: '绳索', muscle: '二头', subMuscle: '肱肌', difficulty: '初级',
    prescription: '3 组 × 12 次', targetMuscles: '肱肌、肱桡肌',
    breathing: '弯举呼气，下放吸气',
    description: '绳索对握锤式弯举，增加手臂围度与厚度。',
    keyPoints: ['低位滑轮双手握绳两端', '掌心相对保持中立握', '肘部固定弯举至肩前', '缓慢回放'],
    commonMistakes: ['肘部前移', '身体后仰借力', '腕部晃动'],
    imageRes: 'app.media.ex2_cb_hammercurl'
  },
  {
    id: 'db_inclinecurl', name: '斜托弯举', equipment: '哑铃', muscle: '二头', subMuscle: '长头', difficulty: '中级',
    prescription: '3 组 × 10–12 次', targetMuscles: '肱二头肌长头',
    breathing: '弯举呼气，下放吸气',
    description: '仰卧上斜凳弯举，长头充分拉伸收缩。',
    keyPoints: ['上斜凳 45–60 度仰卧', '双臂垂于体侧充分伸展', '屈肘弯举至肩前', '缓慢下放至完全伸展'],
    commonMistakes: ['肩部前送借力', '下放不完全', '凳角过高失去拉伸位'],
    imageRes: 'app.media.ex2_db_inclinecurl'
  },
  {
    id: 'bb_21s', name: '21s弯举', equipment: '杠铃', muscle: '二头', subMuscle: '整体', difficulty: '中级',
    prescription: '3 组 × 21 次（7+7+7）', targetMuscles: '肱二头肌整体',
    breathing: '弯举呼气，下放吸气',
    description: '下半程 7 次 + 上半程 7 次 + 全程 7 次的泵感轰炸。',
    keyPoints: ['先做大臂垂直到与地面平行的下半程 7 次', '再做平行到顶峰的上半程 7 次', '最后全程 7 次', '全程肘部固定不借力'],
    commonMistakes: ['甩腰借力', '肘部前后移动', '重量过大导致动作变形'],
    imageRes: 'app.media.ex2_bb_21s'
  },
  {
    id: 'db_spidercurl', name: '蜘蛛弯举', equipment: '哑铃', muscle: '二头', subMuscle: '短头', difficulty: '中级',
    prescription: '3 组 × 12 次', targetMuscles: '肱二头肌短头',
    breathing: '弯举呼气，下放吸气',
    description: '俯卧上斜凳悬臂弯举，杜绝借力孤立短头。',
    keyPoints: ['俯卧于上斜凳，双臂垂直下垂', '肘部位置固定', '弯举至肩前', '缓慢下放至完全伸展'],
    commonMistakes: ['抬头弓颈', '肘部后摆', '用惯性甩起'],
    imageRes: 'app.media.ex2_db_spidercurl'
  },
  {
    id: 'bd_curl', name: '弹力带弯举', equipment: '弹力带', muscle: '二头', subMuscle: '整体', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '肱二头肌',
    breathing: '弯举呼气，下放吸气',
    description: '脚踩弹力带弯举，居家手臂训练基础。',
    keyPoints: ['双脚踩住弹力带中段', '双手握两端掌心向前', '肘部固定弯举至肩前', '缓慢回放保持张力'],
    commonMistakes: ['肘部前移', '身体晃动', '回放卸力'],
    imageRes: 'app.media.ex2_bd_curl'
  },
  {
    id: 'db_supinatecurl', name: '哑铃旋腕弯举', equipment: '哑铃', muscle: '二头', subMuscle: '整体', difficulty: '初级',
    prescription: '3 组 × 12 次', targetMuscles: '肱二头肌、肱肌',
    breathing: '弯举呼气，下放吸气',
    description: '弯举过程中旋转手腕，完整激活肱二头肌功能。',
    keyPoints: ['起始掌心朝向身体', '弯举前半程保持中立', '过腹侧后向外旋腕至掌心朝上', '顶峰收缩后原路回放'],
    commonMistakes: ['旋腕过早', '甩动借力', '肘部外张'],
    imageRes: 'app.media.ex2_db_supinatecurl'
  },
  // ---------- 三头 ----------
  {
    id: 'cb_onearmpushdown', name: '单臂绳索下压', equipment: '绳索', muscle: '三头', subMuscle: '整体', difficulty: '初级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '肱三头肌单侧',
    breathing: '下压呼气，回放吸气',
    description: '单臂绳索下压，修正三头两侧差距。',
    keyPoints: ['高位滑轮单臂握把', '上臂贴体侧固定', '下压至手臂伸直', '顶峰收缩后缓慢回放'],
    commonMistakes: ['上臂前移', '身体侧倒借力', '回放过高失去张力'],
    imageRes: 'app.media.ex2_cb_onearmpushdown'
  },
  {
    id: 'cb_overheadext', name: '绳索颈后臂屈伸', equipment: '绳索', muscle: '三头', subMuscle: '长头', difficulty: '中级',
    prescription: '3 组 × 12 次', targetMuscles: '肱三头肌长头',
    breathing: '伸肘呼气，回放吸气',
    description: '背向低位滑轮颈后臂屈伸，充分拉伸三头长头。',
    keyPoints: ['背对滑轮双手握绳举过头顶', '上臂贴耳固定', '伸肘向前上方推出', '缓慢回放至颈后'],
    commonMistakes: ['肘部外张', '弓腰代偿', '回放失控砸颈'],
    imageRes: 'app.media.ex2_cb_overheadext'
  },
  {
    id: 'db_closebench', name: '窄距哑铃卧推', equipment: '哑铃', muscle: '三头', subMuscle: '整体', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '肱三头肌、胸内侧',
    breathing: '下放吸气，推起呼气',
    description: '哑铃对握窄推，三头肌大重量复合训练。',
    keyPoints: ['仰卧凳面，哑铃对握并拢置于胸前', '肘部贴体侧下放', '三头发力垂直推起', '顶端保持哑铃并拢'],
    commonMistakes: ['肘部外张变成普通卧推', '下放砸胸', '腕部晃动'],
    imageRes: 'app.media.ex2_db_closebench'
  },
  {
    id: 'db_floorext', name: '地板臂屈伸', equipment: '哑铃', muscle: '三头', subMuscle: '长头', difficulty: '中级',
    prescription: '3 组 × 12 次', targetMuscles: '肱三头肌',
    breathing: '伸肘呼气，回放吸气',
    description: '仰卧地板做哑铃臂屈伸，行程受限更安全。',
    keyPoints: ['仰卧地面，双手持哑铃举于胸上', '上臂垂直固定', '屈肘下放哑铃至耳侧轻触地面', '三头发力伸肘回顶'],
    commonMistakes: ['上臂晃动', '砸地借力', '肘部外张'],
    imageRes: 'app.media.ex2_db_floorext'
  },
  {
    id: 'bd_pushdown', name: '弹力带臂屈伸', equipment: '弹力带', muscle: '三头', subMuscle: '整体', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '肱三头肌',
    breathing: '下压呼气，回放吸气',
    description: '弹力带高位下压，居家三头孤立训练。',
    keyPoints: ['弹力带固定于头顶上方', '双手握带，上臂贴体侧', '伸肘下压至手臂伸直', '缓慢回放'],
    commonMistakes: ['上臂前移', '固定点不牢', '回放过高'],
    imageRes: 'app.media.ex2_bd_pushdown'
  },
  {
    id: 'db_lyingext', name: '仰卧哑铃臂屈伸', equipment: '哑铃', muscle: '三头', subMuscle: '长头', difficulty: '中级',
    prescription: '3 组 × 10–12 次', targetMuscles: '肱三头肌长头',
    breathing: '伸肘呼气，回放吸气',
    description: '仰卧双臂哑铃臂屈伸，长头全程受力。',
    keyPoints: ['仰卧凳面，双手各持哑铃举于上方', '上臂保持垂直', '屈肘下放至额侧', '三头发力伸肘回顶'],
    commonMistakes: ['上臂前后晃动', '下放失控碰头', '肘部外张'],
    imageRes: 'app.media.ex2_db_lyingext'
  },
  {
    id: 'bw_closepushuptri', name: '窄距俯卧撑（侧重三头）', equipment: '自重', muscle: '三头', subMuscle: '整体', difficulty: '中级',
    prescription: '3 组 × 10–12 次', targetMuscles: '肱三头肌、胸内侧',
    breathing: '下放吸气，推起呼气',
    description: '窄距俯卧撑三头版，肘部紧贴体侧强化手臂后侧。',
    keyPoints: ['双手窄距撑地，食指拇指成三角', '身体平板一线', '肘部贴紧体侧向后下方屈', '三头发力推起'],
    commonMistakes: ['肘部外张', '塌腰', '只做半程'],
    imageRes: 'app.media.ex2_bw_closepushuptri'
  },
  // ---------- 小臂 ----------
  {
    id: 'cb_wristcurl', name: '绳索腕弯举', equipment: '绳索', muscle: '小臂', subMuscle: '屈肌群', difficulty: '初级',
    prescription: '3 组 × 15 次', targetMuscles: '小臂屈肌群',
    breathing: '卷腕呼气，回放吸气',
    description: '低位滑轮腕弯举，张力恒定打磨小臂。',
    keyPoints: ['低位滑轮，前臂置于大腿或凳面', '掌心向上握把', '仅手腕发力向上卷曲', '缓慢回放至充分伸展'],
    commonMistakes: ['前臂抬起借力', '幅度过小', '回放过快'],
    imageRes: 'app.media.ex2_cb_wristcurl'
  },
  {
    id: 'bw_deadhang', name: '抓握悬挂', equipment: '自重', muscle: '小臂', subMuscle: '握力', difficulty: '初级',
    prescription: '3 组 × 30–45 秒', targetMuscles: '小臂握力肌群、背阔肌',
    breathing: '全程均匀呼吸',
    description: '单杠静态悬挂，提升握力与肩关节健康。',
    keyPoints: ['正握单杠与肩同宽', '肩胛微沉不耸肩', '全身静止悬挂', '力竭前落地'],
    commonMistakes: ['摆动身体', '耸肩缩脖', '憋气'],
    imageRes: 'app.media.ex2_bw_deadhang'
  },
  {
    id: 'db_pinchhold', name: '捏握哑铃静态保持', equipment: '哑铃', muscle: '小臂', subMuscle: '握力', difficulty: '中级',
    prescription: '3 组 × 30 秒/侧', targetMuscles: '指屈肌、拇指肌群',
    breathing: '全程均匀呼吸',
    description: '捏住哑铃片边缘静态保持，强化指捏握力。',
    keyPoints: ['用手指与拇指捏住哑铃片光滑面', '手臂自然下垂', '保持至力竭', '换侧进行'],
    commonMistakes: ['用掌心托住作弊', '身体晃动', '憋气'],
    imageRes: 'app.media.ex2_db_pinchhold'
  },
  {
    id: 'db_hammerhold', name: '锤式静态弯举', equipment: '哑铃', muscle: '小臂', subMuscle: '肱桡肌', difficulty: '中级',
    prescription: '3 组 × 20–30 秒/侧', targetMuscles: '肱桡肌、肱肌',
    breathing: '全程均匀呼吸',
    description: '锤式弯举顶峰静态保持，等长收缩强化肱桡肌。',
    keyPoints: ['对握哑铃弯举至前臂与地面平行', '肘部固定保持不动', '目视前方核心收紧', '计时保持至力竭'],
    commonMistakes: ['肘部前后移动', '身体后仰', '憋气'],
    imageRes: 'app.media.ex2_db_hammerhold'
  },
  {
    id: 'bb_platepinch', name: '杠铃片捏握', equipment: '杠铃', muscle: '小臂', subMuscle: '握力', difficulty: '中级',
    prescription: '3 组 × 30 秒/侧', targetMuscles: '指屈肌、握力肌群',
    breathing: '全程均匀呼吸',
    description: '捏住杠铃片光滑面行走或静立，握力专项训练。',
    keyPoints: ['拇指与其余四指捏住杠铃片', '手臂垂于体侧', '保持或慢速行走', '力竭前放下'],
    commonMistakes: ['杠铃片贴腿借力', '耸肩', '憋气'],
    imageRes: 'app.media.ex2_bb_platepinch'
  },
  {
    id: 'bd_wristflex', name: '弹力带腕屈伸', equipment: '弹力带', muscle: '小臂', subMuscle: '屈肌群', difficulty: '初级',
    prescription: '3 组 × 15 次/侧', targetMuscles: '小臂屈伸肌群',
    breathing: '卷曲呼气，回放吸气',
    description: '脚踩弹力带做腕屈伸，随时随地练小臂。',
    keyPoints: ['一脚踩住弹力带，前臂置于膝上', '掌心向上握带', '仅手腕发力卷曲', '缓慢回放'],
    commonMistakes: ['手臂晃动借力', '幅度不足', '弹力带过松'],
    imageRes: 'app.media.ex2_bd_wristflex'
  },
  // ---------- 腹 ----------
  {
    id: 'bw_sidecrunch', name: '侧卷腹', equipment: '自重', muscle: '腹', subMuscle: '侧腹', difficulty: '初级',
    prescription: '3 组 × 15 次/侧', targetMuscles: '腹外斜肌、腹内斜肌',
    breathing: '卷起呼气，下放吸气',
    description: '侧卧向卷腹，收紧侧腰线条。',
    keyPoints: ['侧卧双腿叠放微屈', '上手扶耳侧', '侧腹发力卷起上半身', '顶峰收缩后缓慢下放'],
    commonMistakes: ['手拉颈部', '卷起过高变成仰卧起坐', '速度过快'],
    imageRes: 'app.media.ex2_bw_sidecrunch'
  },
  {
    id: 'bw_birddog', name: '鸟狗式', equipment: '自重', muscle: '腹', subMuscle: '深层核心', difficulty: '初级',
    prescription: '3 组 × 10 次/侧', targetMuscles: '腹横肌、多裂肌、臀大肌',
    breathing: '伸展呼气，回收吸气',
    description: '四足对侧伸展，核心稳定与腰背健康的基础课。',
    keyPoints: ['四足跪姿，手腕在肩下、膝在髋下', '同时前伸一手后伸对侧腿', '保持骨盆不旋转', '顶峰稍停后换侧'],
    commonMistakes: ['腰椎下沉', '骨盆翻转', '抬腿过高'],
    imageRes: 'app.media.ex2_bw_birddog'
  },
  {
    id: 'bw_planktap', name: '平板交替触肩', equipment: '自重', muscle: '腹', subMuscle: '深层核心', difficulty: '中级',
    prescription: '3 组 × 20 次', targetMuscles: '腹横肌、核心抗旋转',
    breathing: '触肩呼气，回撑吸气',
    description: '平板支撑交替摸肩，抗旋转核心训练。',
    keyPoints: ['高位平板支撑，双脚分开加宽', '单手离地摸对侧肩', '骨盆保持稳定不晃动', '左右交替'],
    commonMistakes: ['骨盆左右摇摆', '塌腰', '速度过快变成甩动'],
    imageRes: 'app.media.ex2_bw_planktap'
  },
  {
    id: 'bw_bicycle', name: '空中蹬车', equipment: '自重', muscle: '腹', subMuscle: '侧腹', difficulty: '中级',
    prescription: '3 组 × 20 次', targetMuscles: '腹外斜肌、腹直肌',
    breathing: '转体呼气，回正吸气',
    description: '仰卧对侧肘膝相触，腹直肌与侧腹同步轰炸。',
    keyPoints: ['仰卧双手扶耳，双腿抬起屈膝', '转体以对侧肘触膝', '另一腿同时前伸', '左右交替节奏均匀'],
    commonMistakes: ['手拉颈部', '只扭头不转体', '速度过快失去控制'],
    imageRes: 'app.media.ex2_bw_bicycle'
  },
  {
    id: 'bw_plankleg', name: '平板抬腿', equipment: '自重', muscle: '腹', subMuscle: '下腹', difficulty: '中级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '下腹、臀大肌',
    breathing: '抬腿呼气，下放吸气',
    description: '平板支撑位交替抬腿，下腹与臀部双重刺激。',
    keyPoints: ['前臂平板支撑', '单腿伸直向后上方抬起', '骨盆保持水平不翻转', '缓慢下放换侧'],
    commonMistakes: ['腰椎下塌', '抬腿过高代偿', '骨盆旋转'],
    imageRes: 'app.media.ex2_bw_plankleg'
  },
  {
    id: 'bw_sideplanktwist', name: '侧平板转体', equipment: '自重', muscle: '腹', subMuscle: '侧腹', difficulty: '中级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '腹外斜肌、腹横肌',
    breathing: '转体呼气，回正吸气',
    description: '侧平板加腋下穿伸转体，侧腹动态强化。',
    keyPoints: ['前臂侧平板支撑', '上侧手臂向上伸直', '转体将上臂穿过腋下', '回旋展开还原'],
    commonMistakes: ['髋部下塌', '支撑肩耸起', '转体过快失控'],
    imageRes: 'app.media.ex2_bw_sideplanktwist'
  },
  {
    id: 'bb_weightedcrunch', name: '负重卷腹', equipment: '杠铃', muscle: '腹', subMuscle: '上腹', difficulty: '中级',
    prescription: '4 组 × 12 次', targetMuscles: '腹直肌上部',
    breathing: '卷起呼气，下放吸气',
    description: '怀抱杠铃片卷腹，腹肌也需要渐进超负荷。',
    keyPoints: ['仰卧屈膝，杠铃片抱于胸前', '下背贴地', '腹直肌发力卷起上背部', '顶峰挤压后缓慢下放'],
    commonMistakes: ['双手抱头拉颈', '卷起过高腰椎离地过多', '负重过大动作变形'],
    imageRes: 'app.media.ex2_bb_weightedcrunch'
  },
  {
    id: 'bw_sidebirddog', name: '侧鸟狗式', equipment: '自重', muscle: '腹', subMuscle: '侧腹', difficulty: '中级',
    prescription: '3 组 × 10 次/侧', targetMuscles: '腹外斜肌、臀中肌',
    breathing: '伸展呼气，回收吸气',
    description: '侧支撑位对侧伸展，侧腹与骨盆稳定训练。',
    keyPoints: ['侧平板支撑姿势', '上侧手脚同时向两端伸展', '保持身体一线不后倒', '回收换侧'],
    commonMistakes: ['髋部下沉', '身体后仰', '憋气'],
    imageRes: 'app.media.ex2_bw_sidebirddog'
  },
  {
    id: 'mc_abwheel', name: '腹轮卷腹（健腹轮）', equipment: '器械', muscle: '腹', subMuscle: '上腹', difficulty: '高级',
    prescription: '3 组 × 10 次', targetMuscles: '腹直肌、腹横肌、肩部稳定肌',
    breathing: '推出吸气，收回呼气',
    description: '健腹轮跪姿前推，核心抗伸展的硬核动作。',
    keyPoints: ['跪姿双手握轮置于膝前', '收紧核心缓慢向前推出', '推至身体接近地面保持 1 秒', '腹部发力拉回'],
    commonMistakes: ['腰椎下沉塌腰', '推出过远失控', '用手臂拉回而非腹部'],
    imageRes: 'app.media.ex2_mc_abwheel'
  },
  {
    id: 'bw_plankarm', name: '平板交替抬手', equipment: '自重', muscle: '腹', subMuscle: '深层核心', difficulty: '中级',
    prescription: '3 组 × 12 次/侧', targetMuscles: '腹横肌、肩部稳定肌',
    breathing: '抬手呼气，回落吸气',
    description: '平板支撑位交替前抬手臂，抗旋转进阶。',
    keyPoints: ['前臂平板支撑', '单臂向前抬起与地面平行', '骨盆稳定不旋转', '回落换侧'],
    commonMistakes: ['塌腰翘臀', '身体晃动', '抬手过快'],
    imageRes: 'app.media.ex2_bw_plankarm'
  },
  // ---------- 有氧 ----------
  {
    id: 'mc_rower', name: '划船机', equipment: '器械', muscle: '有氧', subMuscle: '全身燃脂', difficulty: '中级',
    prescription: '20–30 分钟，心率区间 2–3', targetMuscles: '背阔肌、股四头肌、心肺系统',
    breathing: '拉动呼气，回放吸气',
    description: '全身参与率最高的有氧器械，燃脂效率极佳。',
    keyPoints: ['蹬腿 → 后倒 → 拉把的顺序发力', '回放顺序相反：手臂 → 躯干 → 屈膝', '保持节奏稳定', '阻力适中不追求最大'],
    commonMistakes: ['先拉手臂后蹬腿', '弓背划船', '阻力调满硬拉'],
    imageRes: 'app.media.ex2_mc_rower'
  },
  {
    id: 'bw_fartlek', name: '变速跑', equipment: '自重', muscle: '有氧', subMuscle: '心肺耐力', difficulty: '中级',
    prescription: '20 分钟（快慢交替）', targetMuscles: '心肺系统、下肢耐力',
    breathing: '快段加深呼吸，慢段调整恢复',
    description: '快跑与慢跑自由交替，打破匀速跑的平台期。',
    keyPoints: ['充分热身 5 分钟慢跑', '快段以 80% 速度跑 1–2 分钟', '慢段慢跑或快走恢复', '循环至总时长'],
    commonMistakes: ['快段冲刺过猛', '不热身直接变速', '慢段完全停下'],
    imageRes: 'app.media.ex2_bw_fartlek'
  },
  {
    id: 'bw_boxjump', name: '台阶跳', equipment: '自重', muscle: '有氧', subMuscle: '全身燃脂', difficulty: '中级',
    prescription: '4 组 × 10 次', targetMuscles: '股四头肌、臀大肌、心肺系统',
    breathing: '起跳呼气，落地调匀',
    description: '跳箱或台阶跳跃，爆发力与心率双提升。',
    keyPoints: ['选择稳固高度适中的台阶', '屈髋摆臂蓄力', '双脚同时跳上台阶全脚掌落地', '走下台阶不跳下'],
    commonMistakes: ['跳下台阶伤膝', '落地膝盖内扣', '台阶过高逞强'],
    imageRes: 'app.media.ex2_bw_boxjump'
  },
  {
    id: 'mc_battlerope', name: '战绳训练', equipment: '器械', muscle: '有氧', subMuscle: '全身燃脂', difficulty: '中级',
    prescription: '30 秒 × 8 组，组间歇 30 秒', targetMuscles: '肩部、核心、心肺系统',
    breathing: '甩动时短促呼吸，间歇深呼吸',
    description: '战绳波浪甩动，高强度间歇燃脂利器。',
    keyPoints: ['双脚与肩同宽微屈膝', '双手握绳交替上下甩动形成波浪', '核心收紧躯干稳定', '组间歇走动恢复'],
    commonMistakes: ['只用手臂甩腰部松散', '站距过窄', '憋气'],
    imageRes: 'app.media.ex2_mc_battlerope'
  },
  {
    id: 'mc_mountainbike', name: '山地骑行', equipment: '器械', muscle: '有氧', subMuscle: '心肺耐力', difficulty: '中级',
    prescription: '30–60 分钟', targetMuscles: '股四头肌、心肺系统',
    breathing: '爬坡加深呼吸，平路保持节奏',
    description: '户外山地骑行，兼顾心肺与下肢力量耐力。',
    keyPoints: ['调整坐垫至腿接近伸直', '爬坡提前变速', '保持 70–90 踏频', '佩戴头盔选择安全路线'],
    commonMistakes: ['坐垫过低伤膝', '猛踩重档位', '不补水'],
    imageRes: 'app.media.ex2_mc_mountainbike'
  },
  {
    id: 'bw_doubleunder', name: '跳绳双摇', equipment: '自重', muscle: '有氧', subMuscle: '心肺耐力', difficulty: '高级',
    prescription: '10 组 × 30 秒，组间歇 30 秒', targetMuscles: '小腿、心肺系统、协调性',
    breathing: '保持轻盈节奏呼吸',
    description: '一次起跳两次摇绳，跳绳进阶燃脂。',
    keyPoints: ['先熟练掌握单摇', '起跳略高，手腕加速摇两周', '前脚掌落地缓冲', '失误立即调整继续'],
    commonMistakes: ['用手臂摇绳', '跳得过高浪费体力', '弯腰低头'],
    imageRes: 'app.media.ex2_bw_doubleunder'
  },
  {
    id: 'mc_skierg', name: '滑雪机', equipment: '器械', muscle: '有氧', subMuscle: '全身燃脂', difficulty: '中级',
    prescription: '15–20 分钟', targetMuscles: '背阔肌、肩部、心肺系统',
    breathing: '下拉呼气，回位吸气',
    description: '模拟越野滑雪上肢拉动，上肢主导的有氧选择。',
    keyPoints: ['双手高位握把', '屈髋配合双臂下拉', '节奏均匀不猛拉', '核心收紧'],
    commonMistakes: ['只用手臂不屈髋', '弓腰', '速度忽快忽慢'],
    imageRes: 'app.media.ex2_mc_skierg'
  },
  {
    id: 'mc_stepper', name: '踏步机', equipment: '器械', muscle: '有氧', subMuscle: '臀腿燃脂', difficulty: '初级',
    prescription: '20–30 分钟', targetMuscles: '股四头肌、臀大肌、心肺系统',
    breathing: '保持均匀呼吸',
    description: '迷你踏步机持续踏步，低冲击居家有氧。',
    keyPoints: ['身体直立不扶握过紧', '全脚掌踩踏', '保持匀速节奏', '微屈膝缓冲'],
    commonMistakes: ['倚靠扶手过多', '速度过快失控', '膝盖内扣'],
    imageRes: 'app.media.ex2_mc_stepper'
  },
  {
    id: 'bw_sprint', name: '间歇冲刺跑', equipment: '自重', muscle: '有氧', subMuscle: '心肺耐力', difficulty: '高级',
    prescription: '8 组 × 30 秒冲刺，组间歇 90 秒', targetMuscles: '下肢爆发力、心肺系统',
    breathing: '冲刺时短促呼吸，间歇深呼吸恢复',
    description: '短距全力冲刺加充分恢复，提升最大摄氧量。',
    keyPoints: ['充分热身动态拉伸', '全力冲刺 30 秒', '慢走 90 秒完全恢复', '选择平整安全路面'],
    commonMistakes: ['热身不足拉伤', '恢复时间过短', '在不平路面冲刺'],
    imageRes: 'app.media.ex2_bw_sprint'
  },
  {
    id: 'bw_trailwalk', name: '越野快走', equipment: '自重', muscle: '有氧', subMuscle: '心肺耐力', difficulty: '初级',
    prescription: '30–45 分钟', targetMuscles: '下肢耐力、心肺系统',
    breathing: '保持深而匀的呼吸',
    description: '郊野起伏路面快走，低门槛长时间燃脂。',
    keyPoints: ['穿着防滑运动鞋', '步频快于日常散步', '上坡缩小步幅', '随身携带饮水'],
    commonMistakes: ['步幅过大', '穿普通板鞋', '饭后立即快走'],
    imageRes: 'app.media.ex2_bw_trailwalk'
  },
  // ---------- 拉伸 ----------
  {
    id: 'st_pecminor', name: '胸小肌拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '胸部', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '胸小肌',
    breathing: '全程缓慢深呼吸',
    description: '门框高位拉伸，缓解圆肩改善体态。',
    keyPoints: ['前臂贴门框，肘部高于肩', '身体向前旋转远离该侧', '感受胸前深层牵拉', '保持 30 秒换侧'],
    commonMistakes: ['肘部过低变成胸大肌拉伸', '用力过猛', '憋气'],
    imageRes: 'app.media.ex2_st_pecminor'
  },
  {
    id: 'st_hipflexor', name: '髂腰肌拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '髋部', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '髂腰肌、股直肌',
    breathing: '全程缓慢深呼吸',
    description: '弓步跪姿髋屈拉伸，久坐人群必做。',
    keyPoints: ['单膝跪地另一腿前跨成弓步', '骨盆微微后倾', '髋部向前下沉', '感受后腿髋前侧牵拉'],
    commonMistakes: ['腰椎过度前凸代偿', '前膝超过脚尖过多', '重心晃动'],
    imageRes: 'app.media.ex2_st_hipflexor'
  },
  {
    id: 'st_brachio', name: '肱桡肌拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '小臂', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '肱桡肌、小臂伸肌',
    breathing: '全程缓慢深呼吸',
    description: '伸肘内旋加腕屈，拉伸小臂外侧肱桡肌。',
    keyPoints: ['手臂前伸掌心朝下', '前臂内旋', '另一手轻压手背向身体方向', '感受小臂外侧牵拉'],
    commonMistakes: ['肘部弯曲', '按压过猛', '肩部耸起'],
    imageRes: 'app.media.ex2_st_brachio'
  },
  {
    id: 'st_uppertrap', name: '上斜方肌拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '斜方肌', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '上斜方肌',
    breathing: '全程缓慢深呼吸',
    description: '坐姿侧屈颈部，放松肩颈紧张。',
    keyPoints: ['坐直，一手压于臀下固定肩部', '头向对侧缓慢侧屈', '可用另一手轻压加深', '保持 30 秒换侧'],
    commonMistakes: ['耸肩', '旋转头部', '用力过猛'],
    imageRes: 'app.media.ex2_st_uppertrap'
  },
  {
    id: 'st_frontdelt', name: '三角肌前束拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '三角肌前束', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '三角肌前束、胸大肌',
    breathing: '全程缓慢深呼吸',
    description: '背后扶固定物转体，拉伸肩前束。',
    keyPoints: ['手臂后伸扶住固定物', '掌心向下手臂接近伸直', '身体缓慢向对侧旋转', '感受肩前侧牵拉'],
    commonMistakes: ['肘部弯曲', '旋转过快', '肩部耸起'],
    imageRes: 'app.media.ex2_st_frontdelt'
  },
  {
    id: 'st_midlowtrap', name: '斜方肌中下束拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '斜方肌', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '斜方肌中下束、菱形肌',
    breathing: '全程缓慢深呼吸',
    description: '含胸抱肩前伸，舒展上背部。',
    keyPoints: ['双臂胸前环抱对侧肩胛', '含胸低头将肩胛向外撑开', '感受两肩胛之间牵拉', '保持呼吸'],
    commonMistakes: ['挺胸', '抱得过紧压迫呼吸', '快速弹震'],
    imageRes: 'app.media.ex2_st_midlowtrap'
  },
  {
    id: 'st_piriformis', name: '梨状肌拉伸', equipment: '自重', muscle: '拉伸', subMuscle: '臀部', difficulty: '初级',
    prescription: '2 组 × 30 秒/侧', targetMuscles: '梨状肌、臀部深层',
    breathing: '全程缓慢深呼吸',
    description: '仰卧 4 字拉伸，缓解臀部深层紧张与坐骨压迫感。',
    keyPoints: ['仰卧，一侧脚踝置于对侧大腿成 4 字', '双手抱住支撑腿大腿后侧', '轻柔拉向胸部', '保持 30 秒换侧'],
    commonMistakes: ['拉小腿而非大腿', '颈部抬起', '用力过猛'],
    imageRes: 'app.media.ex2_st_piriformis'
  }
];

/** 动作库查询入口 */
export class ExerciseLibrary {
  /** 全部动作 */
  static all(): ExerciseItem[] {
    return EXERCISES;
  }

  /** 双维筛选：器械 + 部位；任一维度传「全部」表示不筛选 */
  static filter(equipment: string, muscle: string): ExerciseItem[] {
    return EXERCISES.filter((item: ExerciseItem) => {
      const equipOk: boolean = equipment === '全部' || item.equipment === equipment;
      const muscleOk: boolean = muscle === '全部' || item.muscle === muscle;
      return equipOk && muscleOk;
    });
  }

  /** 按 id 查找（详情页用）；找不到返回 null */
  static findById(id: string): ExerciseItem | null {
    for (let i = 0; i < EXERCISES.length; i++) {
      if (EXERCISES[i].id === id) {
        return EXERCISES[i];
      }
    }
    return null;
  }
}
