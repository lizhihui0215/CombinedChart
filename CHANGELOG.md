# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

# 无法修复问题

这组截图和日志已经把问题说明白了。

结论：
• visible​Start​Month​Index 现在是按 Drag​Gesture​.translation 推出来的
• 但这 不是 ScrollView 的真实滚动位置
• 所以 debug 文案和你肉眼看到的内容已经脱节了

证据很明确：

1. 日志里拖拽结束后得到的是：

2. 但截图里真实看到的第一个月不是 2020​-03
而是更靠后的内容，甚至已经到了 2021​-02

这说明：
• 手指拖了 152pt，按 82​.5pt​/月 算出来是 2 个月
• 但真实 ScrollView 内容因为惯性继续滚了很远
• 我们的 visible​Start​Month​Index 没有跟着真实内容继续更新

所以根因不是 pager，也不是动画，而是：

DragGesture.translation 只能表示手指位移，不能表示 ScrollView 最终内容偏移。

这也是为什么现在会出现：
• debug 显示 Visible start month: 2 (2020​-03)
• 屏幕上实际看到的是 2021​-02

这两个已经不同步了。

结论性的下一步
不要继续用 Drag​Gesture​.translation 推 visible​Start​Month​Index 了。
这条路从原理上就不可靠，尤其有惯性滚动时一定会错。

更稳的做法只剩两条：

1. 用真正的 ScrollView content offset
需要一个能拿到底层 UIScroll​View​.content​Offset 的方案

2. 直接做成“无惯性、按页吸附”的滚动模型
让拖拽结束时强制落到某个月起点/某一页
这样状态和视觉更容易一致

基于你这个组件，我建议走第 1 条：
• 想办法拿到真实 content​Offset
• 再由它换算 visible​Start​Month​Index

因为你现在明显想保留“自由拖拽 + pager 联动”，那就不能靠手指 translation 估算。

如果你同意，我下一步就不再修现有手势推导了，直接改成：
• 接入底层 UIScroll​View offset 监听
• 用真实 offset 驱动 pager 状态