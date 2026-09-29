# 文件标注：AI 生成 —— 阶段4页面补丁脚本（开发期一次性工具，已执行留档）
import io

# ================= ProfilePage =================
p = 'entry/src/main/ets/pages/ProfilePage.ets'
s = io.open(p, encoding='utf-8').read()
old = "import { ProgressRing } from '../components/ProgressRing';"
assert s.count(old) == 1
s = s.replace(old, old + "\nimport { BackgroundLayer } from '../components/BackgroundLayer';")

old = """  build() {
    Column() {
      Row() {
        Button('‹ 返回')"""
new = """  build() {
    // 根布局：背景层（最底，固定不滚动）+ 原内容列
    Stack() {
      BackgroundLayer({ theme: this.theme })
      Column() {
      Row() {
        Button('‹ 返回')"""
assert s.count(old) == 1
s = s.replace(old, new)

old = """    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }"""
new = """      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }"""
assert s.count(old) == 1
s = s.replace(old, new)

# 画像摘要卡：外套 Column，顶部 4px 渐变条 + cardElevated 底
old = """          // ===== 画像摘要卡：圆形头像（accent 渐变描边）+ 信息 + 周目标 ProgressRing =====
          Row({ space: 16 }) {"""
new = """          // ===== 画像摘要卡：顶部渐变条 + 圆形头像（accent 渐变描边）+ 信息 + 周目标 ProgressRing =====
          Column() {
            Row()
              .width('100%')
              .height(4)
              .linearGradient({
                angle: 0,
                colors: [
                  [this.theme.palette.accentStart ?? this.theme.palette.accent, 0.0],
                  [this.theme.palette.accentEnd ?? this.theme.palette.accent, 1.0]
                ]
              })
              .accessibilityLevel('no')
            Row({ space: 16 }) {"""
assert s.count(old) == 1
s = s.replace(old, new)

old = """          .width('100%')
          .padding(16)
          .borderRadius(20)
          .backgroundColor(this.theme.palette.cardBackground)
          .shadow({ radius: 10, color: this.theme.palette.cardShadow, offsetX: 0, offsetY: 2 })
          .margin({ bottom: 14 })"""
new = """            .width('100%')
            .padding(16)
          }
          .width('100%')
          .borderRadius(20)
          .clip(true)
          .backgroundColor(this.theme.palette.cardElevated ?? this.theme.palette.cardBackground)
          .shadow({ radius: 10, color: this.theme.palette.cardShadow, offsetX: 0, offsetY: 2 })
          .margin({ bottom: 14 })"""
assert s.count(old) == 1
s = s.replace(old, new)
io.open(p, 'w', encoding='utf-8').write(s)
print('ProfilePage patched')

# ================= FoodPicker =================
p = 'entry/src/main/ets/pages/FoodPicker.ets'
s = io.open(p, encoding='utf-8').read()
old = "import { ThemeToggle } from '../components/ThemeToggle';"
assert s.count(old) == 1
s = s.replace(old, old + "\nimport { BackgroundLayer } from '../components/BackgroundLayer';")

old = """  build() {
    Column() {"""
new = """  build() {
    // 根布局：背景层（最底，固定不滚动）+ 原内容列
    Stack() {
      BackgroundLayer({ theme: this.theme })
      Column() {"""
assert s.count(old) == 1
s = s.replace(old, new)

old = """    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }"""
new = """      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }"""
assert s.count(old) == 1
s = s.replace(old, new)

# 搜索框左侧加 ic_search（Row 容器包裹）
old = """      // ===== 搜索框 =====
      TextInput({ placeholder: $r('app.string.food_picker_search'), text: this.keyword })
        .fontColor(this.theme.palette.primaryText)
        .placeholderColor(this.theme.palette.secondaryText)
        .backgroundColor(this.theme.palette.inputBackground)
        .caretColor(this.theme.palette.accent)
        .borderRadius(10)
        .margin({ left: 16, right: 16, bottom: 10 })
        .onChange((v: string) => {
          this.keyword = v;
          this.applyFilter();
        })"""
new = """      // ===== 搜索框（左侧 ic_search 线性图标） =====
      Row({ space: 8 }) {
        Image($r('app.media.ic_search'))
          .width(18)
          .height(18)
          .fillColor(this.theme.palette.secondaryText)
          .margin({ left: 12 })
          .accessibilityLevel('no')
        TextInput({ placeholder: $r('app.string.food_picker_search'), text: this.keyword })
          .fontColor(this.theme.palette.primaryText)
          .placeholderColor(this.theme.palette.secondaryText)
          .backgroundColor(this.theme.palette.inputBackground)
          .caretColor(this.theme.palette.accent)
          .layoutWeight(1)
          .onChange((v: string) => {
            this.keyword = v;
            this.applyFilter();
          })
      }
      .width('100%')
      .borderRadius(10)
      .backgroundColor(this.theme.palette.inputBackground)
      .padding({ left: 4, right: 12 })
      .margin({ left: 16, right: 16, bottom: 10 })"""
assert s.count(old) == 1
s = s.replace(old, new)

# 宏量胶囊：蛋白/碳水/脂肪 *Soft 底 + 语义色字
old = """              Text(`${item.kcalPer100g} kcal/100g · 蛋白 ${item.proteinPer100g}g`)
                .fontSize(11)
                .fontColor(this.theme.palette.secondaryText)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })"""
new = """              Text(`${item.kcalPer100g} kcal/100g`)
                .fontSize(11)
                .fontColor(this.theme.palette.secondaryText)
                .maxLines(1)
              Row({ space: 4 }) {
                Text(`蛋${item.proteinPer100g}`)
                  .fontSize(9)
                  .fontColor(this.theme.palette.protein)
                  .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                  .borderRadius(8)
                  .backgroundColor(this.theme.palette.proteinSoft ?? this.theme.palette.inputBackground)
                Text(`碳${item.carbPer100g}`)
                  .fontSize(9)
                  .fontColor(this.theme.palette.carb)
                  .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                  .borderRadius(8)
                  .backgroundColor(this.theme.palette.carbSoft ?? this.theme.palette.inputBackground)
                Text(`脂${item.fatPer100g}`)
                  .fontSize(9)
                  .fontColor(this.theme.palette.fat)
                  .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                  .borderRadius(8)
                  .backgroundColor(this.theme.palette.fatSoft ?? this.theme.palette.inputBackground)
              }
              .accessibilityLevel('no')"""
assert s.count(old) == 1
s = s.replace(old, new)
io.open(p, 'w', encoding='utf-8').write(s)
print('FoodPicker patched')

# ================= BackupPage =================
p = 'entry/src/main/ets/pages/BackupPage.ets'
s = io.open(p, encoding='utf-8').read()
old = "import { SectionCard } from '../components/SectionCard';"
assert s.count(old) == 1
s = s.replace(old, old + "\nimport { BackgroundLayer } from '../components/BackgroundLayer';\nimport { IconBadge } from '../components/IconBadge';")

old = """  build() {
    Column() {"""
new = """  build() {
    // 根布局：背景层（最底，固定不滚动）+ 原内容列
    Stack() {
      BackgroundLayer({ theme: this.theme })
      Column() {"""
assert s.count(old) == 1
s = s.replace(old, new)

old = """    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }"""
new = """      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }"""
assert s.count(old) == 1
s = s.replace(old, new)

# 导出入口 → IconBadge 横卡
old = """          Button('导出全量备份')
            .fontSize(14)
            .fontColor(this.theme.palette.onAccent)
            .backgroundColor(this.theme.palette.accent)
            .borderRadius(20)
            .width('100%')
            .height(40)
            .margin({ top: 12 })
            .accessibilityText('导出全部数据到沙箱文件')
            .onClick(() => {
              this.doExport();
            })"""
new = """          Row({ space: 12 }) {
            IconBadge({ theme: this.theme, iconRes: 'app.media.ic_export', tone: 'blue', badgeSize: 40 })
            Column({ space: 2 }) {
              Text('导出全量备份')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.theme.palette.primaryText)
              Text('生成单文件到应用沙箱')
                .fontSize(11)
                .fontColor(this.theme.palette.secondaryText)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text('›')
              .fontSize(18)
              .fontColor(this.theme.palette.secondaryText)
              .accessibilityLevel('no')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(12)
          .margin({ top: 12 })
          .borderRadius(16)
          .backgroundColor(this.theme.palette.inputBackground)
          .stateStyles({
            pressed: { .scale({ x: 0.97, y: 0.97 }) },
            normal: { .scale({ x: 1.0, y: 1.0 }) }
          })
          .accessibilityText('导出全部数据到沙箱文件')
          .onClick(() => {
            this.doExport();
          })"""
assert s.count(old) == 1
s = s.replace(old, new)

# 恢复入口 → IconBadge 横卡
old = """          Button('从备份文件恢复')
            .fontSize(14)
            .fontColor(this.hasBackup ? this.theme.palette.onAccent : this.theme.palette.secondaryText)
            .backgroundColor(this.hasBackup ? this.theme.palette.danger : this.theme.palette.inputBackground)
            .borderRadius(20)
            .width('100%')
            .height(40)
            .margin({ top: 12 })
            .enabled(this.hasBackup)
            .accessibilityText('从备份文件覆盖恢复全部数据')
            .onClick(() => {
              this.confirmRestore();
            })"""
new = """          Row({ space: 12 }) {
            IconBadge({ theme: this.theme, iconRes: 'app.media.ic_import', tone: 'red', badgeSize: 40 })
            Column({ space: 2 }) {
              Text('从备份文件恢复')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.hasBackup ? this.theme.palette.primaryText : this.theme.palette.secondaryText)
              Text('覆盖当前全部本地数据，恢复前会二次确认')
                .fontSize(11)
                .fontColor(this.theme.palette.secondaryText)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text('›')
              .fontSize(18)
              .fontColor(this.theme.palette.secondaryText)
              .accessibilityLevel('no')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(12)
          .margin({ top: 12 })
          .borderRadius(16)
          .backgroundColor(this.theme.palette.inputBackground)
          .opacity(this.hasBackup ? 1 : 0.5)
          .stateStyles({
            pressed: { .scale({ x: 0.97, y: 0.97 }) },
            normal: { .scale({ x: 1.0, y: 1.0 }) }
          })
          .accessibilityText('从备份文件覆盖恢复全部数据')
          .onClick(() => {
            if (this.hasBackup) {
              this.confirmRestore();
            }
          })"""
assert s.count(old) == 1
s = s.replace(old, new)
io.open(p, 'w', encoding='utf-8').write(s)
print('BackupPage patched')
