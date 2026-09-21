/*
 * AI 生成 —— 单元测试脚手架（hypium 断言）
 * 被测对象：data/ExerciseLibrary.ets 动作库 + data/FoodLibrary.ets 食物库查询契约
 *
 * 覆盖点：
 *   1. 动作库总量与 6 类器械覆盖（杠铃/哑铃/史密斯/绳索/自重/弹力带）
 *   2. 双维筛选（器械 + 部位）与「全部」语义
 *   3. findById 命中/未命中
 *   4. 每个动作必备字段非空（含呼吸节奏 breathing、图片资源 imageRes）
 *   5. 食物库查询与营养参考值非负
 */
import { describe, it, expect } from '@ohos/hypium';
import {
  ExerciseItem,
  ExerciseLibrary,
  EXERCISE_EQUIPMENTS,
  EXERCISE_MUSCLES
} from '../main/ets/data/ExerciseLibrary';
import { FoodItem, FoodLibrary } from '../main/ets/data/FoodLibrary';

export default function libraryTest(): void {
  describe('LibraryTest', () => {

    it('exercise_total_and_equipment_coverage', 0, () => {
      expect(ExerciseLibrary.all().length).assertEqual(201);
      expect(EXERCISE_EQUIPMENTS.length).assertEqual(7);
      // 每类器械至少 4 个动作
      EXERCISE_EQUIPMENTS.forEach((equipment: string) => {
        const list: ExerciseItem[] = ExerciseLibrary.filter(equipment, '全部');
        expect(list.length >= 4).assertTrue();
        list.forEach((item: ExerciseItem) => {
          expect(item.equipment).assertEqual(equipment);
        });
      });
    });

    it('exercise_filter_two_dimensions', 0, () => {
      // 双维筛选：杠铃 + 胸
      const benchList: ExerciseItem[] = ExerciseLibrary.filter('杠铃', '胸');
      expect(benchList.length >= 1).assertTrue();
      benchList.forEach((item: ExerciseItem) => {
        expect(item.equipment).assertEqual('杠铃');
        expect(item.muscle).assertEqual('胸');
      });
      // 「全部 + 全部」等于全集
      expect(ExerciseLibrary.filter('全部', '全部').length).assertEqual(ExerciseLibrary.all().length);
      // 部位筛选结果都属于该部位
      ExerciseLibrary.filter('全部', '腹').forEach((item: ExerciseItem) => {
        expect(item.muscle).assertEqual('腹');
      });
      expect(ExerciseLibrary.filter('全部', '腹').length >= 9).assertTrue();
      expect(ExerciseLibrary.filter('全部', '有氧').length >= 9).assertTrue();
      expect(ExerciseLibrary.filter('全部', '拉伸').length).assertEqual(21);
      expect(EXERCISE_MUSCLES.length).assertEqual(12);
    });

    it('exercise_find_by_id', 0, () => {
      const found: ExerciseItem | null = ExerciseLibrary.findById('bb_bench');
      expect(found !== null).assertTrue();
      if (found !== null) {
        expect(found.name).assertEqual('杠铃卧推');
      }
      expect(ExerciseLibrary.findById('not_exist_id')).assertNull();
    });

    it('exercise_required_fields_non_empty', 0, () => {
      ExerciseLibrary.all().forEach((item: ExerciseItem) => {
        expect(item.id.length > 0).assertTrue();
        expect(item.name.length > 0).assertTrue();
        expect(item.subMuscle.length > 0).assertTrue();
        expect(item.prescription.length > 0).assertTrue();
        expect(item.breathing.length > 0).assertTrue();
        expect(item.targetMuscles.length > 0).assertTrue();
        expect(item.keyPoints.length >= 3).assertTrue();
        expect(item.commonMistakes.length >= 3).assertTrue();
        expect(item.imageRes.startsWith('app.media.ex2_')).assertTrue();
      });
    });

    it('food_library_lookup', 0, () => {
      const foods: FoodItem[] = FoodLibrary.all();
      expect(foods.length >= 50).assertTrue();
      foods.forEach((food: FoodItem) => {
        expect(food.name.length > 0).assertTrue();
        expect(food.category.length > 0).assertTrue();
        expect(food.proteinPer100g >= 0).assertTrue();
      });
      // 前 11 种保留真实照片
      const withPhoto: FoodItem[] = foods.filter((f: FoodItem) => f.imageRes.length > 0);
      expect(withPhoto.length).assertEqual(11);
      withPhoto.forEach((food: FoodItem) => {
        expect(food.imageRes.startsWith('app.media.food_')).assertTrue();
      });
    });
  });
}
