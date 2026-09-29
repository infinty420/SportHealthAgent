# 文件标注：AI 生成 —— 线性图标批量产出脚本（开发期一次性工具）
#
# 视觉系统 · 图标生成
# 产出 13 个 24x24 viewBox、stroke 1.8、fill none、currentColor 单色的线性 SVG
# 到 resources/base/media/（运行时由 Image 的 fillColor 着色，深浅主题共用一份）。
# 用法：python tools/gen_icons.py
import os

ICONS = {
    # 哑铃：杠 + 两侧铃片
    'ic_training': '<path d="M4 9v6M7.5 7v10M16.5 7v10M20 9v6M7.5 12h9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
    # 餐碗：碗身弧线 + 蒸汽
    'ic_diet': '<path d="M4 12h16a8 8 0 0 1-16 0zM9 8c0-1.5 1.5-1.5 1.5-3M13.5 8c0-1.5 1.5-1.5 1.5-3" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
    # 日历：外框 + 挂耳 + 日期点
    'ic_plan': '<rect x="4" y="5.5" width="16" height="14.5" rx="2.5" stroke="currentColor" stroke-width="1.8"/><path d="M4 10.5h16M8.5 3.5v4M15.5 3.5v4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M8 14.5h2M14 14.5h2M8 17h2" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
    # 恢复：环形箭头
    'ic_recovery': '<path d="M4.5 12a7.5 7.5 0 1 1 2.2 5.3M4.5 12V7M4.5 12H9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
    # 目标靶心：双环 + 中心点
    'ic_goal': '<circle cx="12" cy="12" r="8" stroke="currentColor" stroke-width="1.8"/><circle cx="12" cy="12" r="4" stroke="currentColor" stroke-width="1.8"/><circle cx="12" cy="12" r="0.9" fill="currentColor"/>',
    # 奖杯：杯身 + 双耳 + 底座
    'ic_pr': '<path d="M8 4h8v4.5a4 4 0 0 1-8 0zM8 5.5H5a3 3 0 0 0 3 3M16 5.5h3a3 3 0 0 1-3 3M12 12.5v3.5M8.5 20h7M10 16h4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
    # 时钟：外圆 + 指针
    'ic_duration': '<circle cx="12" cy="12" r="8" stroke="currentColor" stroke-width="1.8"/><path d="M12 7.5V12l3 2" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
    # 火焰：卡路里
    'ic_calorie': '<path d="M12 3.5c1.5 3 5.5 5 5.5 9.5a5.5 5.5 0 0 1-11 0c0-2 1-3.5 2-4.5.3 1.3 1 2 2 2.5-.5-2.5 0-5.5 1.5-7.5z" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
    # 波形：频次/心率线
    'ic_frequency': '<path d="M3 12h4l2.5-6 4 12 2.5-6H21" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
    # 水滴
    'ic_water': '<path d="M12 3.5c3 4 6 7 6 10.5a6 6 0 0 1-12 0c0-3.5 3-6.5 6-10.5z" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>',
    # 体重秤：圆角方 + 表盘
    'ic_weight': '<rect x="4.5" y="4.5" width="15" height="15" rx="3" stroke="currentColor" stroke-width="1.8"/><path d="M9 9.5a3.5 3.5 0 0 1 6 0" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="12" cy="9.5" r="0.9" fill="currentColor"/>',
    # 奖章：圆牌 + 绶带
    'ic_badge': '<circle cx="12" cy="9.5" r="5" stroke="currentColor" stroke-width="1.8"/><path d="M9.5 13.5 8 20l4-2.2L16 20l-1.5-6.5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
    # 搜索：放大镜
    'ic_search': '<circle cx="11" cy="11" r="6" stroke="currentColor" stroke-width="1.8"/><path d="M15.5 15.5 20 20" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
}

TEMPLATE = ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<!-- 文件标注：AI 生成 —— 线性图标 {name}（24x24，stroke 1.8，fill none，currentColor 供 fillColor 着色） -->\n'
            '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">\n'
            '  {body}\n'
            '</svg>\n')


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out_dir = os.path.join(root, 'entry', 'src', 'main', 'resources', 'base', 'media')
    for name, body in ICONS.items():
        path = os.path.join(out_dir, name + '.svg')
        with open(path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(TEMPLATE.format(name=name, body=body))
        print('written %s (%d bytes)' % (name + '.svg', os.path.getsize(path)))
    print('total %d icons' % len(ICONS))


if __name__ == '__main__':
    main()
