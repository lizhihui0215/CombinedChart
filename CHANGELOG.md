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

--

我先查一下 SwiftUI 现在有没有原生的滚动几何/位置监听 API，重点看能不能不下沉到 UIKit。

可以，但有前提。

结论
• 如果目标平台能用较新的 SwiftUI 滚动 API，那么可以纯 SwiftUI 做。
• 对你这个场景，最值得用的是 on​Scroll​Geometry​Change，不是我们刚才试过的那套 scroll​Position(id:) + scroll​Target​Layout()。

为什么
官方现在给了两个关键能力：

• on​Scroll​Geometry​Change
   • 可以从 Scroll​Geometry 里拿到真实的 content​Offset
   • 这才是你现在真正需要的东西
• on​Scroll​Phase​Change
   • 可以知道当前是 panning、decelerating、idle、animating
   • 适合在停止滚动后做收敛或同步

从文档看，on​Scroll​Geometry​Change 就是专门为“监听 scroll view 几何变化”设计的。它比我们现在：
• Geometry​Reader + ​Preference​Key
• Drag​Gesture​.translation

都更接近真实滚动状态。

为什么 scrollPosition(id:) 不适合你这里
这个 API 更适合：
• 列表/卡片
• item 本身就是 scroll target
• 绑定当前可见 item id

而你这个 chart 是：
• 一个大 chart 内容
• 上面叠了一层透明 month anchor
• chart 本体和 target 不是同一个视图层

所以它会把滚动目标系统和你的视觉布局搅在一起。这个你已经实际踩到了。

更适合你的 SwiftUI 方案
如果 deployment target 支持，我会建议改成：

• 保留 Scroll​View​Reader 做程序化 scroll​To
• 去掉现在这条不稳定的 offset/drag 推导链
• 用 on​Scroll​Geometry​Change 直接监听 horizontal content​Offset​.x
• 再由真实 offset 算 visible​Start​Month​Index

也就是：

1. 按钮翻页：继续 scroll​To(month​Index)
2. 手动拖拽：通过 on​Scroll​Geometry​Change 得到真实 offset
3. pager 状态：统一由真实 offset 推导

这才是“SwiftUI 层面、而且语义对”的办法。

边界
如果你的最低系统版本太低，不支持这套新 API，那就不行。
那时就只能：
• 继续用 UIKit introspection
或者
• 接受一个退化方案

我建议
下一步不要再讨论抽象，直接做一件事：
• 检查你项目的 deployment target
• 如果支持 on​Scroll​Geometry​Change，我就直接把当前这套 drag 推导删掉，改成纯 SwiftUI 的真实 scroll geometry 方案

如果你愿意，我下一步就直接按这个方向改。
