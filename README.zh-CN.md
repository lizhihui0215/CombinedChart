# CombinedChart

[English](README.md) | 简体中文

`CombinedChart` 是一个图表框架仓库，当前采用以下组织方式：

- 一个当前产出为 `CombinedChartFramework` 的 Swift Package
- 一个用于 demo、验证、UI 调试和快照测试的 Sample App

当前已经交付的核心组件是 `CombinedChartView`。  
根据 `Arch.md`，仓库的长期目标是演进为模块化的 `ChartKit` 平台，并最终支持：

- `CombinedChart`
- `LineChart`
- `BarChart`
- `PieChart`
- `AreaChart`
- `CandlestickChart`

## 当前状态

当前已经实现的能力：

- 基于 `CombinedChartView` 的组合柱状图 + 趋势线图表
- 双渲染引擎：`Charts` 和 `Canvas`
- 双横向交互实现：SwiftUI 手势与 UIKit `UIScrollView`
- 可配置的轴、分页、选择态、调试和渲染行为
- 空态、选择态覆盖层、pager 的自定义 slot
- 针对派生状态、分页、reducer 和 resolver 的单元测试
- 关键图表场景的 UI 快照测试

当前尚未完成的部分：

- 仓库还没有拆分到最终的 `Foundation / Components / SharedUI / Compatibility` 模块结构
- 当前交付的 package 仍然以 `CombinedChart` 为中心
- 平台边界仍在治理中，尤其是 UIKit 兼容路径相关部分

## 架构方向

目标终态是一个具有四层结构的可复用 `ChartKit`：

1. `Foundation`
2. `Components`
3. `SharedUI`
4. `Compatibility`

当前代码已经具备这个设计的早期雏形，但仍主要以单 target 实现存在，内部通过 `Public`、`Core`、`Interaction`、`Rendering`、`Support` 等目录进行逻辑分层。

详细架构文档见：

- `Docs/Architecture.md`
- `Docs/API-Notes.md`
- `Docs/Migration-Notes.md`
- `Docs/Roadmap.md`
- `Docs/iOS16-Known-Issues.md`
- `Docs/Crash-Notes.md`

## Package

当前仓库只暴露一个 library product：

- `CombinedChartFramework`

对应的 Package 定义如下：

```swift
.library(
    name: "CombinedChartFramework",
    targets: ["CombinedChartFramework"]
)
```

当前框架源码位于：

```text
CombinedChartSample/CombinedChartSample/Sources/CombinedChartFramework
```

这种结构适合当前阶段，但还不是最终目标中的 package 布局。

## 推荐 API 表面

推荐优先使用 `CombinedChartView` 作用域下的简写类型：

- `CombinedChartView.Config`
- `CombinedChartView.Tab`
- `CombinedChartView.DataGroup`
- `CombinedChartView.Point`
- `CombinedChartView.Slots`
- `CombinedChartView.Selection`

这些别名能让调用代码始终围绕图表组件本身展开，而不会过度暴露底层类型名。

## 基础用法

```swift
import CombinedChartFramework
import SwiftUI

struct ExampleView: View {
    @State private var selectedTab: CombinedChartView.Tab = .totalTrend
    @State private var showDebugOverlay = false

    let groups: [CombinedChartView.DataGroup]
    let config: CombinedChartView.Config

    var body: some View {
        CombinedChartView(
            config: config,
            groups: groups,
            tabs: CombinedChartView.Tab.defaults,
            selectedTab: $selectedTab,
            showDebugOverlay: $showDebugOverlay
        )
    }
}
```

## 自定义 Slots

使用 `slots:` 替换局部 UI，而不是重写整个图表骨架。

```swift
CombinedChartView(
    config: config,
    groups: groups,
    tabs: tabs,
    selectedTab: $selectedTab,
    slots: .init(
        emptyState: {
            Text("No chart data")
        },
        selectionOverlay: { context in
            Text(context.point.xLabel)
        },
        pager: { context in
            Text(context.highlightedEntry?.displayTitle ?? "-")
        }
    )
)
```

## 点选回调

通过 `onPointTap` 观察解析后的选择结果：

```swift
CombinedChartView(
    config: config,
    groups: groups,
    onPointTap: { selection in
        print(selection.point.id, selection.index)
    }
)
```

如果下游逻辑需要跨刷新或重排保持稳定身份，优先依赖 `selection.point.id`，不要依赖 `selection.index`。

## 仓库结构

当前顶层结构如下：

```text
CombinedChart/
├── CombinedChartSample.xcodeproj
├── Package.swift
├── CombinedChartSample/
├── CombinedChartSampleUITests/
├── Docs/
├── Arch.md
├── MIGRATION.md
└── CHANGELOG.md
```

当前职责划分：

- `CombinedChartSample/`
  - App 壳层、demo、样例数据加载、可视化验证
- `CombinedChartFramework`
  - 公共 API、状态推导、交互逻辑、渲染、支持性 UI
- `Docs/`
  - 架构、API、迁移、路线图、兼容性和稳定性说明

## 开发说明

当前可用的验证路径：

- Swift Package 逻辑测试
- Xcode test plan 下的 Sample App 测试与 UI 快照测试

当前已知工程限制：

- 当前 framework 仅支持 iOS；不支持 macOS

更多限制和平台差异可参考：

- `Docs/Crash-Notes.md`
- `Docs/iOS16-Known-Issues.md`

## API 兼容性

推荐使用：

- `slots:`

仍保留用于迁移兼容：

- `viewSlots:`

`SelectionContext`、`SelectionOverlayContext` 和 `PagerContext` 等公共上下文类型都提供了 public initializer，可用于测试或适配层代码。

## 路线图摘要

短期优先级：

1. 稳定平台边界和 package 构建行为
2. 将当前实现拆分到 `Foundation / Components / SharedUI / Compatibility`
3. 统一多渲染和多交互路径的语义

只有在这些基础工作完成之后，仓库才应该从当前 `CombinedChart` 实现扩展到完整的 `ChartKit` 图表家族。
