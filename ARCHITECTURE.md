# 衡练 · 端侧运动健康 Agent —— 架构设计说明书

> 鸿蒙（HarmonyOS）ArkTS + ArkUI（Stage 模型）参赛工程。
> 核心 Agent 完全运行在本地端侧：**纯规则引擎（路线 A）**，不调用任何云端大模型 API，运行时不发起任何网络请求。

---

## 1. 整体架构（分层）

```
┌─────────────────────────────────────────────────────────┐
│ 可视化 UI 层  pages/Index.ets + components/*             │
│   表单录入、三大模块结果卡片、宏量营养素占比条、负荷色标      │
├─────────────────────────────────────────────────────────┤
│ 主题中枢  theme/ThemeManager.ets                         │
│   lightPalette / darkPalette 唯一颜色定义，@Observed 全量重绘│
├─────────────────────────────────────────────────────────┤
│ 端侧 Agent 引擎  agent/                                  │
│   AnalysisEngine（接口）→ RuleAnalysisEngine（路线A装配）   │
│   ├─ 模块① rules/TrainingEvaluator.ets   本次训练评估     │
│   ├─ 模块② rules/DietPlanner.ets         饮食方案        │
│   └─ 模块③ rules/NextWorkoutPlanner.ets  互补训练规划     │
├─────────────────────────────────────────────────────────┤
│ 数据接入层  model/ + data/                               │
│   HealthRecord（数据模型/校验/负荷估算）                   │
│   HealthDataSource（接口）                                │
│   ├─ HealthKitSource（路线① 手表骨架，TODO 待补全）        │
│   └─ ManualInputSource（路线② 手动录入，本作演示主流程）    │
└─────────────────────────────────────────────────────────┘
```

### 各层职责

| 层 | 目录 | 职责 |
| --- | --- | --- |
| 数据接入层 | `model/`、`data/` | 定义 `HealthRecord`（运动时长/平均心率/配速/卡路里/运动类型/训练负荷），统一手表与手动录入两类来源；负荷缺失时本地估算 |
| 端侧 Agent 引擎 | `agent/` | 确定性规则（if/else + 评分表）输出三大模块建议；接口与 UI 解耦，可整体替换为路线 B 端侧小模型 |
| 三大分析模块 | `agent/rules/` | ① 训练评估（负荷分档 + 恢复时长）② 饮食方案（宏量营养素配比 + 食材 + 免责声明）③ 互补训练规划（运动互补原则） |
| 可视化 UI | `pages/`、`components/` | 简洁现代的深色/浅色界面；占比条、负荷色标等数据可视化；禁止硬编码色值 |
| 主题中枢 | `theme/` | 全局唯一颜色定义；切换主题只改 `mode`，`@Observed` 触发全量重绘 |

---

## 2. 目录结构

```
SportHealthAgent/
├── ARCHITECTURE.md                        ← 本文件（可直接进设计说明书）
├── build-profile.json5 / oh-package.json5 / hvigorfile.ts / hvigor/  ← 工程级构建配置
├── AppScope/
│   ├── app.json5                          ← 应用级配置
│   └── resources/base/                    ← 应用名（string）+ 应用图标（media/app_icon.png）
├── tools/gen_icon.py                      ← 图标生成脚本（PIL）
├── tools/gen_exercise_images.py           ← 3D 动作示例图生成脚本（AI 图像生成）
├── tools/fetch_food_photos.py             ← 真实食物照片下载脚本（Wikimedia Commons）
└── entry/
    ├── build-profile.json5 / oh-package.json5 / hvigorfile.ts / obfuscation-rules.txt
    └── src/
        ├── main/
        │   ├── module.json5               ← 模块配置（含健康数据权限声明）
        │   ├── resources/base/
        │   │   ├── element/string.json    ← 模块字符串（含权限申请理由 + 新页面文案）
        │   │   ├── element/color.json     ← 启动窗背景色
        │   │   ├── media/app_icon.png     ← 应用图标
        │   │   ├── media/ex2_*.jpg        ← 98 张 3D 解剖风动作示例图（AI 生成，目标肌肉高亮）
        │   │   ├── media/food_*.jpg       ← 11 张真实食物照片（Wikimedia Commons）
        │   │   └── profile/main_pages.json← 页面路由表
        │   ├── en_US/element/string.json  ← 英文翻译（新页面文案双语）
        │   └── ets/
        │       ├── entryability/EntryAbility.ets  ← Stage 模型入口
        │       ├── model/
        │       │   ├── HealthRecord.ets           ← 数据模型 + 校验 + 负荷估算公式★（含个性化心率区间版）
        │       │   ├── UserProfile.ets            ← 用户画像模型（性别/年龄/身高/体重/静息心率/目标/经验）
        │       │   ├── InjuryRecord.ets           ← 伤病记录模型（腰/膝/肩/腕 + 起止日期 + 校验）
        │       │   └── WorkoutLog.ets             ← 训练日志模型（组数×次数×重量×RPE/RIR 双轨 + 校验 + 容量统计）
        │       ├── data/
        │       │   ├── HealthDataSource.ets       ← 数据源接口
        │       │   ├── HealthKitSource.ets        ← 路线① Health Kit 骨架（TODO，保持不动）
        │       │   ├── MockHealthKitSource.ets    ← 演示用模拟数据源（本地生成，无真实 API）
        │       │   ├── ManualInputSource.ets      ← 路线② 手动录入 + 校验（画像注入个性化估算）
        │       │   ├── HistoryStore.ets           ← 历史记录持久化（365 条/采纳反馈/周月统计/JSON 导出）
        │       │   ├── SettingsStore.ets          ← 规则设置本地持久化（preferences）
        │       │   ├── UserProfileStore.ets       ← 用户画像本地持久化（preferences）
        │       │   ├── BodyMetricsStore.ets       ← 体成分记录（体重/体脂/静息心率，365 条）
        │       │   ├── GoalStore.ets              ← 周目标（次数/时长/目标体重）持久化
        │       │   ├── DietLog.ets                ← 今日饮食日志（餐次/食物/份量）
        │       │   ├── WellnessLogStore.ets       ← 每日状态（睡眠/酸痛/饮水，按日分桶）
        │       │   ├── NutritionCalculator.ets    ← 宏量达成度计算（实际 vs 建议）★
        │       │   ├── ExerciseLibrary.ets        ← 动作库：7 器械 × 12 部位（含拉伸/有氧，细分部位）201 动作
        │       │   ├── FoodLibrary.ets            ← 食物库：50 种食材六分类营养参考数据
        │       │   ├── InjuryStore.ets            ← 伤病记录持久化（preferences，activeParts 查询）
        │       │   └── WorkoutLogStore.ets        ← 训练日志持久化（preferences，旧数据 RIR 兜底，预留 RDB 迁移接口）
        │       ├── agent/
        │       │   ├── AnalysisEngine.ets         ← 引擎接口（路线 B 替换点）
        │       │   ├── AnalysisResult.ets         ← 输出契约（三大模块 + WeeklyPlan + 疲劳指数）
        │       │   ├── RuleConfig.ets             ← 规则参数模型★（阈值/配比/下调系数）
        │       │   ├── RuleAnalysisEngine.ets     ← 路线 A 装配（画像个性化 + 疲劳修正 + 采纳反馈）
        │       │   ├── RuleAnalysisEngineV2.ets   ← 引擎 V2★（加权评分 0.6/0.4 + 历史趋势斜率）
        │       │   └── rules/                     ← ★ 自主业务逻辑（规则算法）
        │       │       ├── TrainingEvaluator.ets  ← 模块①
        │       │       ├── DietPlanner.ets        ← 模块②（+ Mifflin-St Jeor 日热量/双碳水/饮水目标）
        │       │       ├── NextWorkoutPlanner.ets ← 模块③
        │       │       ├── FatigueModel.ets       ← 疲劳模型（7 天负荷加权 → 0–100）
        │       │       ├── TrainingPlanPlanner.ets← 周计划（肌群分化 + 推荐动作 + 强度轮换 + 伤病禁忌过滤）
        │       │       ├── StrengthCalculator.ets ← 1RM 双公式估算 + 有效组数/容量（RPE/RIR 双轨）
        │       │       ├── ProgressiveOverloadPlanner.ets ← 渐进超负荷建议 + 平台期标记
        │       │       ├── MuscleBalanceAnalyzer.ets ← 推:拉:腿 / 上下肢容量平衡分析（伤病禁忌过滤）
        │       │       ├── WarmupGenerator.ets    ← 按 1RM 生成热身组序列
        │       │       ├── ExerciseSafety.ets     ← 动作伤病禁忌推导与过滤（腰/膝/肩/腕 + 风险等级）
        │       │       ├── MesocyclePlanner.ets   ← 4–8 周中周期（波浪渐进 + 减载周）
        │       │       ├── ReadinessScorer.ets    ← 准备度评分（疲劳/睡眠/酸痛 → 强度档 + 过度训练三级预警）
        │       │       ├── WeightTrendAnalyzer.ets← 体重 14 天最小二乘趋势 + 4 周预测 + 平台期
        │       │       ├── PRTracker.ets          ← 个人纪录追踪（最大重量/1RM + 破纪录判定）
        │       │       ├── BadgeEngine.ets        ← 20 枚成就徽章规则引擎（进度 + 命中规则说明）
        │       │       ├── InsightGenerator.ets   ← 训练洞察（模板化结论句 + 依据）
        │       │       └── WhatIfSimulator.ets    ← What-if 情景模拟（次数/热量 → 4/8 周负荷与体重）
        │       ├── theme/ThemeManager.ets         ← 主题中枢（深/浅调色板唯一定义）
        │       ├── components/                    ← 通用 UI（ThemeToggle/SectionCard/LoadBadge/MacroBar）
        │       └── pages/
        │           ├── Index.ets                  ← 主页面（录入/画像/每日状态/目标环/营养环/肌群热力/结果/周计划/V2对比/趋势）
        │           ├── ExerciseLibrary.ets        ← 动作库列表页（顶部器械栏 + 左侧部位栏 + 双列网格）
        │           ├── ExerciseDetail.ets         ← 动作详情页（3D 大图/标签/步骤/呼吸/常见错误/组间休息计时器）
        │           ├── FoodPicker.ets             ← 食物选择页（分类/搜索/份量 → 写入饮食日志）
        │           ├── Report.ets                 ← 周/月报表页（统计卡/目标环/准备度/体重趋势/中周期/日历热力/PR/徽章/洞察/What-if）
        │           ├── WorkoutLogPage.ets         ← 训练日志录入页（动作选择 + 组数表格 RPE/RIR 双轨 + 超负荷建议 + PR 提示）
        │           └── ProfilePage.ets            ← 用户画像录入页（含伤病记录区 + 体成分时间序列写入）
        └── test/
            ├── List.test.ets                ← 本地单元测试套件入口（hypium）
            ├── RuleEngine.test.ets          ← 三大规则模块 + 负荷估算 + 配置注入测试
            ├── Library.test.ets             ← 动作库/食物库查询契约测试
            └── Upgrade.test.ets             ← 升级模块测试（疲劳/周计划/画像/营养/V2/力量/伤病/中周期/准备度/体重趋势/PR/徽章/What-if）
```

★ = 含「自主业务逻辑」标注的规则算法文件（参赛者知识产权）。

---

## 3. 核心规则算法摘要（自主业务逻辑）

- **负荷估算**（数据缺失时）：`负荷 = round(时长 × min(1, max(0.1, (平均心率-60)/140)))`，限幅 0–100。
- **模块① 训练评估**：`load ≥ 80` → 超标 / 36h；`50–79` → 正常 / 18h；`< 50` → 偏低 / 8h。
- **模块② 饮食方案**：蛋白质 30% / 碳水 50% / 脂肪 20%（4 / 4 / 9 kcal/g 换算）；`load ≥ 80` 时补充热量下调为 `calories × 0.6`；固定附免责声明。
- **模块③ 互补训练**：`load ≥ 80` 强制主动恢复（低，20min）；否则按本次类型查表推导互补训练（力量→有氧+拉伸；跑步/骑行/游泳→力量/核心；HIIT→主动恢复；瑜伽→力量/有氧；步行→力量；其他→交替上下肢）。
- **参数可配置**：以上阈值与配比集中在 `RuleConfig`（默认值与赛事规则表一致），UI「规则设置」面板调整后经 `RuleAnalysisEngine.setConfig()` 注入，本地持久化、重启自动恢复。

## 4. 增强功能（升级版）

| 功能 | 实现 | 端侧合规 |
| --- | --- | --- |
| 历史记录持久化 | `HistoryStore`（系统 preferences，沙箱内键值存储，最多 365 条），每条含采纳状态标记（未标记/已采纳/已忽略），支持导出 JSON 至应用沙箱文件目录 | 纯本地，无网络 |
| 负荷趋势图 | 最近 7 次负荷柱状图，纯 ArkUI 组件绘制，颜色按状态语义色取自调色板 | 纯本地 |
| 恢复倒计时 | 基于最近一条记录的建议恢复时长与经过时间计算 | 纯本地 |
| 规则设置面板 | 超标阈值/正常下限/蛋白/碳水占比滑杆，脂肪自动推导，非法参数即时拦截 | 纯本地 |
| 单元测试 | `entry/src/test/`（hypium），覆盖三档边界、饮食两条路径、互补全分支、配置注入 | `hvigorw test -p module=entry` |
| 健身动作库 | 7 器械（杠铃/哑铃/史密斯/绳索/自重/弹力带/器械）× 12 部位（胸/背/腿/肩/二头/三头/小臂/臀/腹/有氧/拉伸/全身）双维分类，部位再细分（胸：上/中/下胸，背：上背/下背/背阔肌，肩：前/中/后束/整体，腹：上腹/下腹/前锯肌/侧腹等），201 动作（`ExerciseLibrary`），列表页双列网格 + 详情页 3D 解剖风示例大图（每个动作一张专属 AI 生成图，目标肌肉高亮）+ 编号步骤 + 呼吸节奏 + 常见错误 | 纯本地，无网络 |
| 有氧接入主页面 | SportType 新增跳绳/椭圆机/动感单车/爬楼机（慢跑/快走对应跑步/步行），录入下拉自动生效；模块③互补规划将有氧类统一推导为「力量/核心」互补训练 | 纯本地规则 |
| 饮食食物卡片 | 模块②食材升级为带图卡片（参考 Keep），`FoodLibrary` 提供每 100g 营养参考值，配真实食物照片（Wikimedia Commons） | 纯本地，无网络 |
| 用户画像 | `UserProfile` + `UserProfileStore`：性别/年龄/身高/体重/目标/经验录入与持久化，`ProfilePage` 录入页；最大心率按 `220 - 年龄` 估算 | 纯本地，无网络 |
| 疲劳模型 | `FatigueModel`：近 7 天负荷加权 [7..1] 得 0–100 疲劳指数，≥70 高（恢复系数 ×1.5），≥40 中（×1.2） | 纯本地规则 |
| 周训练计划 | `TrainingPlanPlanner`：7 天肌群分化轮换，经验决定每周 3/4/5 练，高疲劳强制第 2/5 天休息；每个训练日附动作库推荐动作（可点击跳转详情页看 3D 示例），结果区「本周训练计划」卡片展示 | 纯本地规则 |
| 个性化引擎 | `RuleAnalysisEngine` 接入画像与历史：热量缺失按体重×0.12×时长估算、减脂/增肌调整宏配比、恢复时长乘疲劳系数、高忽略率自动降强度；个性化负荷估算公式（静息/最大心率归一） | 纯本地规则 |
| 饮食日志与营养闭环 | `DietLog` 按日分桶记录餐食，`FoodPicker` 分类/搜索/份量录入，`NutritionCalculator` 汇总当日摄入并对照模块②目标算达成率，主页面「今日营养达成环」展示 | 纯本地，无网络 |
| 训练目标 | `GoalStore`：每周次数/时长/目标体重，主页面「本周目标达成环」实时进度，可就地改目标 | 纯本地，无网络 |
| 周/月报表页 | `Report.ets`：周/月切换，次数/时长/热量/平均负荷统计卡 + 周目标达成环 | 纯本地，无网络 |
| 趋势范围切换 | 历史趋势图支持 7/30/90 条范围，Canvas 叠加每 7 条均值折线 | 纯本地 |
| 引擎 V2 | `RuleAnalysisEngineV2`：有效负荷 = 0.6×负荷 + 0.4×疲劳指数，近 5 次负荷线性回归斜率自动降/升强度；可在规则设置区开关并与 V1 对比 | 纯本地规则 |
| 双语资源 | 新页面文案走 `string.json`，`en_US` 英文翻译与 base 键完全对齐 | 资源本地化 |
| 训练日志 | `WorkoutLog`（组数×次数×重量×RPE，含校验）+ `WorkoutLogStore`（preferences，预留 RDB 迁移接口）+ 录入页（双维动作选择 → 组数表格） | 纯本地，无网络 |
| 力量科学内核 | `StrengthCalculator`：Epley/Brzycki 双公式估算 1RM、有效组数（RPE≥7）与有效容量；`WarmupGenerator` 按 1RM 生成热身组序列 | 纯本地规则 |
| 渐进超负荷 | `ProgressiveOverloadPlanner`：对比同动作历史最佳（估算 1RM / 自重总次数），输出加重/加次建议，连续 2 次无进步标记平台期并建议加组；录入页选中动作即显示 | 纯本地规则 |
| 肌群平衡与热力图 | `MuscleBalanceAnalyzer`：推:拉:腿与上下肢有效组数比，失衡时从动作库推荐补强动作；首页「本周肌群容量热力」卡片（Canvas 正/背面人体色块，颜色全取调色板） | 纯本地规则 |
| 伤病禁忌过滤 | `InjuryRecord` + `InjuryStore` + `ExerciseSafety`：按名称/部位/器械推导动作禁忌部位（腰/膝/肩/腕）与风险等级；画像页录入伤病后，周计划与补强推荐自动过滤禁忌动作 | 纯本地规则 |
| RPE/RIR 双轨 | `WorkoutSet.rir`（-1 未填 / 0–5）；有效强度 = 填 RIR 则 10−RIR 否则 RPE；旧数据自动兜底 -1 | 纯本地规则 |
| 组间休息计时器 | 动作详情页内置倒计时：复合动作（多肌群/杠铃/史密斯）150/180 秒，孤立动作 60/90 秒 | 纯本地 UI |
| 中周期负荷编排 | `MesocyclePlanner`：4–8 周波浪渐进（每周容量 +10%），每 4 周与末周减载（容量 60%）；疲劳≥70 且平台期时建议立即减载 | 纯本地规则 |
| 每日状态与准备度 | `WellnessLogStore`（睡眠/酸痛/饮水按日分桶）+ `ReadinessScorer`：疲劳/睡眠/酸痛/距上次训练 → 0–100 准备度与强度档；过度训练 黄/橙/红 三级预警（疲劳≥70、准备度<40、连练≥6 天三条件计数） | 纯本地规则 |
| 营养升级 | `DietPlanner.dailyPlan`：Mifflin-St Jeor BMR（10×kg+6.25×cm−5×age+5/−161）× 活动系数 = TDEE，目标 ±300/−500 kcal，训练日/非训练日双碳水（非训练日 −50g），饮水 35ml/kg + 训练前后餐时机建议 | 纯本地规则 |
| 体重趋势 | `WeightTrendAnalyzer`：14 天最小二乘斜率（kg/周）+ 4 周预测；近 10 天波动 <0.3kg 判平台期；画像保存自动写入体成分序列 | 纯本地规则 |
| PR 追踪 | `PRTracker`：每动作最大重量/最大估算 1RM/自重总次数，最近一次破纪录即时提示（录入页 toast）与报表页纪录榜 | 纯本地规则 |
| 训练日历与个人纪录（合并卡） | 报表页月日历（周一开头、标具体年月、‹ › 翻月），按当日训练次数着色（历史记录与力量日志合并计数），当天加粗、选中加边框；点击某天切换到「当日记录」视图（当日动作明细 + 总容量 + 当日破纪录事件 `PRTracker.dailyPREvents`），再点一次或「‹ 全部纪录」回到 PR 总榜 | 纯本地规则 |
| 成就徽章 | `BadgeEngine`：20 枚本地规则徽章（首练/连练/累计时长/容量翻倍/破纪录/动作探索等），含进度与命中规则说明 | 纯本地规则 |
| 训练洞察 | `InsightGenerator`：统计 → 模板化中文结论句，每条附依据（输入值 + 命中规则名），可解释 | 纯本地规则 |
| What-if 模拟 | `WhatIfSimulator`：假设每周次数/每日热量增减 → 4/8 周负荷累积与体重推算（7700 kcal ≈ 1kg），减重过快提示 | 纯本地规则 |
| 发现页（训练历史日历） | `HistoryCalendar.ets`：月日历（周一开头、邻月补齐灰格、翻月），有训练的日子标圆点；选中日显示动作明细、当日容量与当日破纪录事件（`PRTracker.dailyPREvents` 按天聚合） | 纯本地规则 |
| 数据统计（发现页） | `TrainingStatsAggregator`：周/月/年范围切换 + 翻页；部位频次人体热力（Canvas 正/背面）、部位组数环形图（Canvas 中心总组数）、训练时长环比双柱（本周期 vs 上一周期 + 增减文案）、分部位容量卡（容量 + 最佳训练日） | 纯本地规则 |

## 5. 深色/浅色主题契约（防失效关键）

1. 全应用颜色**唯一**定义在 `ThemeManager` 的 `lightPalette` 与 `darkPalette`；
2. 组件**禁止**任何硬编码色值（不得出现 `'#xxxxxx'`），只能读取 `theme.palette.*`；
3. 切换主题只改 `mode`，由 `@Observed` 触发全量重绘；
4. **后续每次修改代码仅扩展功能，不改动 ThemeManager 契约。**

## 5. 合规要点

- **端侧推理**：全部计算为本地确定性规则，无网络请求、无云端大模型 API，满足赛事「端侧推理、不联网」硬性约束；历史与设置持久化使用系统 preferences（沙箱内本地存储），同样不触网。
- **权限合规**：`module.json5` 声明 `ohos.permission.READ_HEALTH_DATA`（SDK 预定义权限，user_grant），真实接入时动态申请授权。
- **健康边界**：饮食方案固定展示免责声明「以上为日常营养参考，非医疗诊断；如有基础疾病请遵医嘱。」；页面顶部标注「非医疗诊断」。
- **AI 辅助开发标注**：每个文件头部注释区分「AI 生成」（脚手架/通用 UI/数据模型）与「自主业务逻辑」（规则算法）。
- **可演进性**：升级路线 B（端侧小模型）时仅替换 `agent/` 实现，`AnalysisEngine` 接口与 UI 保持不变。

## 6. 赛前 TODO

| 优先级 | 事项 | 位置 |
| --- | --- | --- |
| P0 | 补全 Health Kit 真实 API：动态授权 + healthStore 查询 + 字段映射 | `data/HealthKitSource.ets` 两处 TODO |
| P0 | 真机验证深色/浅色切换无局部样式失效 | 全页面 |
| P0 | 用 DevEco Studio 打开工程，同步 hvigor 包装器（hvigorw）并配置签名后编译运行 | 工程根目录 |
| P1 | ~~补充资源文件（app_icon、string/color 资源、main_pages.json）~~ ✅ 已完成 | `AppScope/resources`、`entry/src/main/resources` |
| P1 | 运行本地单元测试：`hvigorw test -p module=entry`，确认 Upgrade 套件 25 个用例及其余套件全绿 | `entry/src/test/` |
| P1 | 规则参数评审（负荷阈值、宏量配比、互补映射表；默认值即赛事规则） | `agent/RuleConfig.ets` |
| P2 | 手表 SportType 枚举映射表核对 | `data/HealthKitSource.ets` |
| P2 | （可选）路线 B：端侧小模型替换 `RuleAnalysisEngine` | `agent/` |
