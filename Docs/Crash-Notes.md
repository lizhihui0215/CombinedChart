# CombinedChartFramework Crash Notes

本文用于记录当前项目的稳定性观察、潜在崩溃热点和排障建议。  
需要先明确一点：截至 2026-03-10，仓库内 `crash/` 目录没有有效的 crash 产物，因此本文主要基于源码结构、构建验证结果和已记录的问题线索做架构级分析，而不是完整的线上事故复盘。

## 1. 当前判断

从现有资料看，项目当前更突出的风险不是“高频进程崩溃”，而是：

- 构建层失败
- 平台边界不一致
- 滚动与显示状态脱节
- 双引擎行为差异导致的隐性缺陷

也就是说，当前阶段应将“稳定性”理解为三层：

1. 能否构建
2. 能否正确交互
3. 能否在不同模式下保持一致

## 2. 已确认的高优先级问题

### 2.1 Package 平台声明与源码依赖不一致

已验证现象：

- `Package.swift` 声明支持 `macOS(.v14)`
- `CombinedChartView+UIKitScrollContainer.swift` 无条件 `import UIKit`

结果：

- 执行 `swift test` 时，Package 在 macOS 构建阶段失败

这虽然不是运行时 crash，但在工程治理上属于一级稳定性问题，因为它直接破坏：

- CI 可构建性
- 平台兼容承诺
- Package 消费者信任

建议处理优先级：最高。

### 2.2 历史滚动状态脱节问题

从仓库现有变更记录可见，曾经存在一个高风险交互问题：

- 使用 `DragGesture.translation` 推导可见起始月
- 但该值并不等于真实滚动内容偏移

这类问题的后果通常不是直接崩溃，而是：

- pager 高亮错误
- debug 文案与画面不一致
- 选择态与实际可见内容脱节

从稳定性角度，它属于“高严重度非 crash 缺陷”，因为会破坏组件可信度。

## 3. 当前源码中的崩溃防御情况

从现有实现看，框架在若干关键点已经具备较好的防御性编码习惯。

### 3.1 索引访问防护

大量选择态、点位访问逻辑都使用：

- `indices.contains`
- `firstIndex`
- `guard let`

这显著降低了常见数组越界 crash 的概率。

### 3.2 几何与代理值防护

对于 `ChartProxy.position(forX:)`、`position(forY:)` 等坐标解析结果，当前实现普遍采用可选判断而不是强制解包。

这使得图表在布局尚未稳定时更倾向于“跳过绘制”而不是 crash。

### 3.3 数学边界防护

当前代码中对以下问题做了显式保护：

- domain span 为 0
- plot height 为 0
- unit width 为 0
- 滚动范围越界

这降低了以下风险：

- 非法除法
- 无穷/NaN 坐标
- 错误的 offset 收敛

## 4. 仍需重点关注的热点

### 4.1 UIKit 容器桥接

`UIKitScrollContainer` 是当前最需要重点回归测试的稳定性热点之一，因为它同时涉及：

- SwiftUI 与 UIKit 生命周期桥接
- `UIScrollViewDelegate`
- `UIHostingController`
- 内容宽度约束同步

虽然这段代码目前没有明显的业务逻辑 crash 痕迹，但一旦状态不同步，问题通常会表现为：

- 滚动抖动
- 偏移回弹异常
- delegate 时序问题
- 内容尺寸不一致

### 4.2 双渲染路径一致性

当前同时维护：

- `Charts`
- `Canvas`

两条渲染路径。

风险不在于某一条路径一定 crash，而在于：

- 一条路径修复后，另一条路径回归
- 坐标、命中、选择态语义出现分叉

这类问题如果不通过自动化测试及时发现，最终可能演化为深层稳定性问题。

### 4.3 Plot 同步状态

`plotSyncState` 用于同步：

- plotAreaMinY
- plotAreaHeight
- yAxisTickPositions

当前实现为了避免拖拽中抖动，在拖拽阶段会跳过同步。  
这是一种合理的工程折中，但需要注意：

- 若同步恢复条件判断不当，可能出现标签错位
- 若在引擎切换间时序不同，可能出现显示短暂不一致

这类问题虽然通常不会 crash，但属于高价值的稳定性观察点。

## 5. 当前未见明显高风险 crash 信号的区域

从源码结构判断，以下区域整体相对稳定：

- `SelectionResolver`
- `InteractionReducer`
- `PagerState`
- `BarSegmentResolver`
- `LineSegmentResolver`

原因是它们大多是：

- 纯计算
- 输入边界明确
- 已有单元测试覆盖

这类模块后续更适合作为稳定性基线，而不是优先怀疑对象。

## 6. 排障时应优先收集的信息

若后续出现 crash、卡死或严重状态异常，建议第一时间记录以下上下文：

### 6.1 运行配置

- iOS 版本
- 设备型号
- `rendering.engine`
- `pager.scrollImplementation`
- `pager.dragScrollMode`
- `selectedTab`
- 数据集规模

### 6.2 交互上下文

- 是点击、拖拽、翻页按钮还是切换 tab 时出现
- 出现问题前是否发生快速连续拖拽
- 是否开启了 debug overlay
- 是否处于快照测试或 UI 测试环境

### 6.3 状态观测

如果可复现，建议记录 `DebugState`，至少包括：

- `startIndex`
- `visibleStartIndex`
- `contentOffsetX`
- `targetContentOffsetX`
- `scrollImplementationTitle`
- `dragScrollModeTitle`
- `selectedPointXKey`

这会显著提高定位效率。

## 7. 推荐的稳定性分级

建议后续把所有问题按以下方式归类：

### P0

- 构建失败
- 启动 crash
- 明确的数据越界 crash

### P1

- 交互状态错乱
- 选择态错误
- pager 与可见内容不一致
- 引擎切换后严重显示错误

### P2

- 标签偏移
- debug 文案不一致
- 某些模式下的视觉轻微偏差

这样能避免把所有问题都粗暴地归入“崩溃问题”，从而影响治理优先级判断。

## 8. 建议的治理动作

从架构师视角，当前最值得做的稳定性治理有四项：

1. 先修复平台声明与 UIKit 依赖不一致的问题。
2. 把滚动偏移、可见起点和 pager 状态建立单一事实来源。
3. 为 `Charts` / `Canvas` 与 SwiftUI / UIKit 两组实现建立最小回归矩阵。
4. 把 `DebugState` 输出接入更标准的故障采样流程。

## 9. 建议的 crash/故障诊断流程

后续若发生问题，建议按这个顺序排查：

1. 先判断是构建问题、运行时 crash 还是状态错乱。
2. 再判断问题是否只出现在特定渲染引擎或滚动实现。
3. 记录 `DebugState` 和最小可复现场景。
4. 通过切换 `charts/canvas` 或 `swiftUIGesture/uiKitScrollView` 做隔离。
5. 最后再进入具体代码级修复。

## 10. 结论

当前项目的主要稳定性挑战不是传统意义上的“野指针式 crash”，而是复杂交互和多实现并存带来的状态一致性问题。  
短期应优先处理：

1. Package 平台构建失败
2. 滚动与可见状态的一致性
3. 双引擎行为回归验证

如果这三项治理到位，组件的整体稳定性会比单纯补几处保护判断更有实质提升。
