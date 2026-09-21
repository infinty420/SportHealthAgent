/*
 * 文件标注：AI 生成 —— 食物数据模型与内置数据集（通用数据内容）
 *
 * 数据接入层 · 食物库（参考 Keep 饮食卡片：图片 + 名称 + 每 100g 营养参考值）
 * 扩充至 50 种，按 蛋白/碳水/脂肪/蔬菜/水果/主食 六类分类。
 * 前 11 种配真实照片（Wikimedia Commons），其余暂以应用图标兜底展示。
 * 营养数值为常见食物成分表的近似参考值，仅用于日常营养参考，非医疗用途。
 */

/** 食物条目 */
export interface FoodItem {
  /** 食物名称 */
  name: string;
  /** 分类：蛋白/碳水/脂肪/蔬菜/水果/主食 */
  category: string;
  /** 图片资源名（app.media.*；空串表示暂无专属图片，UI 兜底） */
  imageRes: string;
  /** 每 100g 热量（千卡） */
  kcalPer100g: number;
  /** 每 100g 蛋白质（克） */
  proteinPer100g: number;
  /** 每 100g 碳水（克） */
  carbPer100g: number;
  /** 每 100g 脂肪（克） */
  fatPer100g: number;
  /** 一句话食用提示 */
  tip: string;
}

/** 食物分类（FoodPicker 筛选顺序） */
export const FOOD_CATEGORIES: string[] = ['蛋白', '碳水', '脂肪', '蔬菜', '水果', '主食'];

/** 内置食物数据（50 种） */
const FOODS: FoodItem[] = [
  // ==================== 蛋白 ====================
  { name: '鸡胸肉', category: '蛋白', imageRes: 'app.media.food_chicken',
    kcalPer100g: 133, proteinPer100g: 19.4, carbPer100g: 2.5, fatPer100g: 5.0, tip: '高蛋白低脂肪，训练后优选' },
  { name: '鸡蛋', category: '蛋白', imageRes: 'app.media.food_egg',
    kcalPer100g: 144, proteinPer100g: 13.3, carbPer100g: 2.8, fatPer100g: 8.8, tip: '营养密度高，早餐好搭档' },
  { name: '希腊酸奶', category: '蛋白', imageRes: 'app.media.food_yogurt',
    kcalPer100g: 97, proteinPer100g: 9.0, carbPer100g: 3.6, fatPer100g: 5.0, tip: '选无糖款，蛋白含量更高' },
  { name: '豆腐', category: '蛋白', imageRes: 'app.media.food_tofu',
    kcalPer100g: 82, proteinPer100g: 6.6, carbPer100g: 3.4, fatPer100g: 5.3, tip: '植物蛋白来源，易消化' },
  { name: '三文鱼', category: '蛋白', imageRes: '',
    kcalPer100g: 208, proteinPer100g: 20.4, carbPer100g: 0, fatPer100g: 13.4, tip: '富含 Omega-3，每周 1–2 次' },
  { name: '虾', category: '蛋白', imageRes: '',
    kcalPer100g: 99, proteinPer100g: 20.9, carbPer100g: 0.9, fatPer100g: 1.1, tip: '低脂高蛋白，白灼最佳' },
  { name: '瘦牛肉', category: '蛋白', imageRes: '',
    kcalPer100g: 152, proteinPer100g: 26.3, carbPer100g: 0, fatPer100g: 5.0, tip: '富含铁与肌酸，增肌友好' },
  { name: '牛奶', category: '蛋白', imageRes: '',
    kcalPer100g: 64, proteinPer100g: 3.3, carbPer100g: 4.8, fatPer100g: 3.6, tip: '训练后搭配碳水吸收更好' },
  { name: '蛋白粉', category: '蛋白', imageRes: '',
    kcalPer100g: 380, proteinPer100g: 75.0, carbPer100g: 8.0, fatPer100g: 4.0, tip: '饮食不足时的便捷补充' },
  { name: '金枪鱼', category: '蛋白', imageRes: '',
    kcalPer100g: 116, proteinPer100g: 25.5, carbPer100g: 0, fatPer100g: 1.0, tip: '选水浸罐头更低脂' },
  { name: '鸡腿肉', category: '蛋白', imageRes: '',
    kcalPer100g: 177, proteinPer100g: 18.6, carbPer100g: 0, fatPer100g: 11.1, tip: '去皮后脂肪大幅下降' },
  { name: '豆浆', category: '蛋白', imageRes: '',
    kcalPer100g: 31, proteinPer100g: 2.8, carbPer100g: 1.4, fatPer100g: 1.6, tip: '无糖款更适合减脂期' },
  // ==================== 碳水 ====================
  { name: '燕麦', category: '碳水', imageRes: 'app.media.food_oats',
    kcalPer100g: 389, proteinPer100g: 16.9, carbPer100g: 66.3, fatPer100g: 6.9, tip: '缓释碳水，训练前 1–2 小时食用' },
  { name: '糙米', category: '碳水', imageRes: 'app.media.food_rice',
    kcalPer100g: 368, proteinPer100g: 7.9, carbPer100g: 77.0, fatPer100g: 2.8, tip: '升糖更平稳，替代精白米' },
  { name: '红薯', category: '碳水', imageRes: 'app.media.food_sweetpotato',
    kcalPer100g: 86, proteinPer100g: 1.6, carbPer100g: 20.1, fatPer100g: 0.1, tip: '富含膳食纤维，饱腹感强' },
  { name: '全麦面包', category: '碳水', imageRes: 'app.media.food_bread',
    kcalPer100g: 247, proteinPer100g: 13.0, carbPer100g: 41.0, fatPer100g: 3.4, tip: '看配料表选全麦粉排第一位的' },
  { name: '藜麦', category: '碳水', imageRes: '',
    kcalPer100g: 368, proteinPer100g: 14.1, carbPer100g: 64.2, fatPer100g: 6.1, tip: '完全蛋白谷物，营养全面' },
  { name: '山药', category: '碳水', imageRes: '',
    kcalPer100g: 118, proteinPer100g: 1.9, carbPer100g: 27.9, fatPer100g: 0.2, tip: '温和碳水，肠胃负担小' },
  { name: '意面', category: '碳水', imageRes: '',
    kcalPer100g: 371, proteinPer100g: 13.0, carbPer100g: 74.7, fatPer100g: 1.5, tip: '低升糖，适合训练前正餐' },
  { name: '土豆', category: '碳水', imageRes: '',
    kcalPer100g: 77, proteinPer100g: 2.0, carbPer100g: 17.5, fatPer100g: 0.1, tip: '蒸煮最佳，饱腹感名列前茅' },
  { name: '荞麦面', category: '碳水', imageRes: '',
    kcalPer100g: 336, proteinPer100g: 12.6, carbPer100g: 70.6, fatPer100g: 1.7, tip: '芦丁含量高，冷面更爽口' },
  { name: '南瓜', category: '碳水', imageRes: '',
    kcalPer100g: 26, proteinPer100g: 1.0, carbPer100g: 6.5, fatPer100g: 0.1, tip: '热量极低，替代部分主食' },
  // ==================== 脂肪 ====================
  { name: '牛油果', category: '脂肪', imageRes: 'app.media.food_avocado',
    kcalPer100g: 160, proteinPer100g: 2.0, carbPer100g: 8.5, fatPer100g: 14.7, tip: '优质不饱和脂肪，适量即可' },
  { name: '坚果', category: '脂肪', imageRes: 'app.media.food_nuts',
    kcalPer100g: 607, proteinPer100g: 20.0, carbPer100g: 21.0, fatPer100g: 54.0, tip: '热量密度高，每天一小把' },
  { name: '橄榄油', category: '脂肪', imageRes: 'app.media.food_oliveoil',
    kcalPer100g: 884, proteinPer100g: 0, carbPer100g: 0, fatPer100g: 100.0, tip: '凉拌或低温烹调更健康' },
  { name: '花生酱', category: '脂肪', imageRes: '',
    kcalPer100g: 588, proteinPer100g: 25.1, carbPer100g: 20.0, fatPer100g: 50.0, tip: '选无添加糖款，抹全麦面包' },
  { name: '奇亚籽', category: '脂肪', imageRes: '',
    kcalPer100g: 486, proteinPer100g: 16.5, carbPer100g: 42.1, fatPer100g: 30.7, tip: '泡发后加酸奶，膳食纤维丰富' },
  { name: '芝士', category: '脂肪', imageRes: '',
    kcalPer100g: 402, proteinPer100g: 25.0, carbPer100g: 1.3, fatPer100g: 33.1, tip: '钙含量高，控制份量' },
  { name: '黑巧克力', category: '脂肪', imageRes: '',
    kcalPer100g: 546, proteinPer100g: 4.9, carbPer100g: 61.2, fatPer100g: 31.3, tip: '选 70% 以上可可，少量即可' },
  { name: '椰子油', category: '脂肪', imageRes: '',
    kcalPer100g: 862, proteinPer100g: 0, carbPer100g: 0, fatPer100g: 100.0, tip: '中链脂肪酸，耐高温烹调' },
  // ==================== 蔬菜 ====================
  { name: '西兰花', category: '蔬菜', imageRes: '',
    kcalPer100g: 34, proteinPer100g: 2.8, carbPer100g: 6.6, fatPer100g: 0.4, tip: '十字花科，健身餐标配' },
  { name: '菠菜', category: '蔬菜', imageRes: '',
    kcalPer100g: 23, proteinPer100g: 2.9, carbPer100g: 3.6, fatPer100g: 0.4, tip: '焯水去草酸，补铁补镁' },
  { name: '番茄', category: '蔬菜', imageRes: '',
    kcalPer100g: 18, proteinPer100g: 0.9, carbPer100g: 3.9, fatPer100g: 0.2, tip: '番茄红素熟食更易吸收' },
  { name: '黄瓜', category: '蔬菜', imageRes: '',
    kcalPer100g: 15, proteinPer100g: 0.7, carbPer100g: 3.6, fatPer100g: 0.1, tip: '水分高，加餐无负担' },
  { name: '胡萝卜', category: '蔬菜', imageRes: '',
    kcalPer100g: 41, proteinPer100g: 0.9, carbPer100g: 9.6, fatPer100g: 0.2, tip: 'β-胡萝卜素，油炒吸收好' },
  { name: '生菜', category: '蔬菜', imageRes: '',
    kcalPer100g: 15, proteinPer100g: 1.4, carbPer100g: 2.9, fatPer100g: 0.2, tip: '沙拉基底，生吃最方便' },
  { name: '彩椒', category: '蔬菜', imageRes: '',
    kcalPer100g: 31, proteinPer100g: 1.0, carbPer100g: 6.0, fatPer100g: 0.3, tip: '维 C 含量超橙子' },
  { name: '芦笋', category: '蔬菜', imageRes: '',
    kcalPer100g: 20, proteinPer100g: 2.2, carbPer100g: 3.9, fatPer100g: 0.1, tip: '叶酸丰富，白灼即可' },
  // ==================== 水果 ====================
  { name: '香蕉', category: '水果', imageRes: '',
    kcalPer100g: 89, proteinPer100g: 1.1, carbPer100g: 22.8, fatPer100g: 0.3, tip: '训练前后快速补能' },
  { name: '蓝莓', category: '水果', imageRes: '',
    kcalPer100g: 57, proteinPer100g: 0.7, carbPer100g: 14.5, fatPer100g: 0.3, tip: '花青素抗氧化，训练后恢复' },
  { name: '苹果', category: '水果', imageRes: '',
    kcalPer100g: 52, proteinPer100g: 0.3, carbPer100g: 13.8, fatPer100g: 0.2, tip: '带皮吃纤维更足' },
  { name: '橙子', category: '水果', imageRes: '',
    kcalPer100g: 47, proteinPer100g: 0.9, carbPer100g: 11.8, fatPer100g: 0.1, tip: '补维 C，直接吃优于榨汁' },
  { name: '草莓', category: '水果', imageRes: '',
    kcalPer100g: 32, proteinPer100g: 0.7, carbPer100g: 7.7, fatPer100g: 0.3, tip: '低糖水果，减脂期友好' },
  { name: '猕猴桃', category: '水果', imageRes: '',
    kcalPer100g: 61, proteinPer100g: 1.1, carbPer100g: 14.7, fatPer100g: 0.5, tip: '维 C 密度极高' },
  // ==================== 主食 ====================
  { name: '米饭', category: '主食', imageRes: '',
    kcalPer100g: 116, proteinPer100g: 2.6, carbPer100g: 25.9, fatPer100g: 0.3, tip: '训练后快碳，控制碗量' },
  { name: '面条', category: '主食', imageRes: '',
    kcalPer100g: 110, proteinPer100g: 3.9, carbPer100g: 22.3, fatPer100g: 0.4, tip: '选全麦或荞麦更优' },
  { name: '馒头', category: '主食', imageRes: '',
    kcalPer100g: 223, proteinPer100g: 7.0, carbPer100g: 47.0, fatPer100g: 1.1, tip: '发酵主食，易消化' },
  { name: '玉米', category: '主食', imageRes: '',
    kcalPer100g: 106, proteinPer100g: 3.5, carbPer100g: 22.8, fatPer100g: 1.2, tip: '粗粮替代，一根约 200g' },
  { name: '杂粮饭', category: '主食', imageRes: '',
    kcalPer100g: 118, proteinPer100g: 3.0, carbPer100g: 24.5, fatPer100g: 0.6, tip: '升糖平稳，日常主食优选' },
  { name: '包子', category: '主食', imageRes: '',
    kcalPer100g: 227, proteinPer100g: 8.2, carbPer100g: 35.6, fatPer100g: 6.0, tip: '早餐方便，注意馅料油脂' }
];

/** 食物库查询入口 */
export class FoodLibrary {
  /** 返回全部内置食物 */
  static all(): FoodItem[] {
    return FOODS;
  }

  /** 按名称查找；找不到返回 null（UI 做兜底展示） */
  static findByName(name: string): FoodItem | null {
    for (let i = 0; i < FOODS.length; i++) {
      if (FOODS[i].name === name) {
        return FOODS[i];
      }
    }
    return null;
  }

  /** 按分类筛选；传「全部」返回全集 */
  static byCategory(category: string): FoodItem[] {
    if (category === '全部') {
      return FOODS;
    }
    return FOODS.filter((item: FoodItem) => item.category === category);
  }
}
