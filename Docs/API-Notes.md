# CombinedChartFramework API Notes

[English](API-Notes.en.md) | 简体中文

本文基于 2026-03-10 的仓库现状编写，目标是从框架设计者视角说明当前公共 API 的边界、语义和推荐使用方式。

## 1. API 设计目标

当前公共 API 的设计目标不是暴露所有内部能力，而是提供一个：

- 单入口
- 强类型
- 可配置
- 可定制
- 便于未来演进

的 SwiftUI 图表组件接口。

主入口明确为：

- `CombinedChartView`

框架希望调用方围绕这个入口完成大部分集成，而不是直接接触内部状态对象、渲染上下文或交互 reducer。

## 1.1 当前 API 与终态 API 的关系

需要明确区分当前 API 和终态 API：

- 当前 API 是 `CombinedChart` 单组件的公共表面
- 终态 API 应演进为 `ChartKit` 多图表组件体系

根据 `Arch.md`，最终不仅要支持 `CombinedChart`，还要支持：

- `LineChart`
- `BarChart`
- `PieChart`
- `AreaChart`
- `CandlestickChart`

因此，当前 API 文档不能只从“这个组件怎么调用”来理解，还要从“它将来如何成为多图表平台的一部分”来理解。

## 2. 推荐公共入口

在业务代码中，推荐优先使用 `CombinedChartView` 作用域下的类型别名，而不是底层原始类型名。

推荐入口如下：

- `CombinedChartView.Config`
- `CombinedChartView.Tab`
- `CombinedChartView.DataGroup`
- `CombinedChartView.Point`
- `CombinedChartView.Slots`
- `CombinedChartView.Selection`

这样做的原因有两个：

1. 让调用代码始终以 `CombinedChartView` 为中心，降低认知分散。
2. 为未来内部类型重命名或模块拆分保留演进空间。

## 3. 主初始化器语义

当前推荐使用的初始化器形态为：

```swift
CombinedChartView(
    config: config,
    groups: groups,
    tabs: tabs,
    selectedTab: $selectedTab,
    showDebugOverlay: $showDebugOverlay,
    slots: slots,
    onPointTap: onPointTap,
    onDebugStateChange: onDebugStateChange
)
```

各参数的职责边界如下：

- `config`
  - 定义图表视觉、渲染、分页、交互和调试行为。
- `groups`
  - 业务输入数据，是图表的唯一内容来源。
- `tabs`
  - 定义可切换的展示模式，不同 tab 只改变展示语义，不应改变输入数据结构。
- `selectedTab`
  - 当前 tab 的受控状态。
- `showDebugOverlay`
  - 调试层显隐开关，不应用于业务功能。
- `slots`
  - 对局部 UI 的扩展点，而不是重写图表骨架。
- `onPointTap`
  - 供外部观察选择结果。
- `onDebugStateChange`
  - 供外部接入调试面板、日志采样或自动化验证。

## 4. 数据模型契约

### 4.1 `DataGroup`

`DataGroup` 表示一组逻辑上归属同一容器的数据，当前通常对应一年或一个业务分组。关键字段包括：

- `id`
- `displayTitle`
- `groupOrder`
- `points`

契约说明：

- 最终渲染顺序由 `groupOrder` 决定，而不是输入数组顺序。
- `displayTitle` 会被 pager 等显示层消费，因此应被视为对用户可见文案。

### 4.2 `Point`

`Point` 表示一个 x 轴位置上的逻辑点位。关键字段包括：

- `id`
- `xKey`
- `xLabel`
- `values`

契约说明：

- `id` 应保持稳定，推荐使用 `groupID + xKey`。
- `xKey` 用于渲染和查找，不建议在同一组内重复。
- `xLabel` 用于展示，可与 `xKey` 不同。
- `values` 中缺失的 series 会被框架视为 `0`。

### 4.3 `ChartSeriesKey`

当前公共序列键是一个受控枚举：

- `liabilities`
- `saving`
- `investment`
- `otherLiquid`
- `otherNonLiquid`

这意味着当前组件仍然是“固定领域键”的实现，而非完全开放的动态图表 schema。  
如果未来要支持通用图表平台，需要把这一层进一步抽象为可配置 series descriptor。

## 5. 配置对象语义

`ChartConfig` 是当前最重要的 API 入口之一，内部包含六个配置域：

- `Rendering`
- `Bar`
- `Line`
- `Axis`
- `Pager`
- `Debug`

从当前代码看，这种“聚合配置”设计非常适合单组件阶段。  
但按照 `Arch.md` 的终态要求，未来每种图表都应进一步拆分出清晰的：

- `Configuration`
- `Style`

例如：

- `CombinedChartConfiguration`
- `CombinedChartStyle`
- `LineChartConfiguration`
- `LineChartStyle`
- `BarChartConfiguration`
- `BarChartStyle`
- `PieChartConfiguration`
- `PieChartStyle`

也就是说，当前 `ChartConfig` 更适合作为过渡态配置中心，而不是多图表平台的最终 API 形式。

### 5.1 `Rendering`

渲染引擎支持：

- `automatic`
- `charts`
- `canvas`

语义建议：

- `automatic` 作为生产默认选项。
- `charts` 用于验证系统原生路径。
- `canvas` 用于兼容性回退、视觉对齐或问题隔离。

当前自动策略的实际行为是：

- iOS 17 及以上优先 `Charts`
- 更低版本默认 `Canvas`

### 5.2 `Bar`

`Bar` 负责柱图的视觉与数据语义映射，重点包括：

- `series`
- `trendBarColorStyle`
- `segmentGap`
- `segmentGapColor`
- `barWidth`

关键语义：

- 每个 `SeriesStyle` 同时携带视觉信息和数值语义。
- `valuePolarity` 会影响符号归一化。
- `trendLineInclusion` 会影响聚合趋势线计算。

这意味着“哪些数据进入 trend line”是配置语义，而不是硬编码逻辑。

### 5.3 `Line`

`Line` 控制趋势线与选择态表现，核心参数包括：

- `positiveLineColor`
- `negativeLineColor`
- `lineWidth`
- `lineType`
- `selection`

关键语义：

- 线颜色可以表达数值极性。
- `lineType` 支持线性和光滑路径。
- `selection` 同时影响命中后的点、线、带状高亮表现。

### 5.4 `Axis`

`Axis` 通过上下文闭包暴露格式化能力：

- `xAxisLabel: (XLabelContext) -> String`
- `yAxisLabel: (YLabelContext) -> String`

这是一种比直接传 formatter 更强的设计，因为：

- x 轴格式化可以感知当前点和可见点集
- y 轴格式化可以感知当前数值和当前 viewport 内容

调用方可以借此实现更复杂的上下文格式化策略。

### 5.5 `Pager`

`Pager` 当前承担两类职责：

1. 交互导航策略
2. UI 呈现策略

关键配置包括：

- `arrowScrollMode`
- `dragScrollMode`
- `scrollImplementation`
- `visibleStartThreshold`
- 字体和按钮颜色

当前设计把“行为”和“样式”都放在 `Pager` 中，短期合理，长期可考虑拆成 `PagerBehavior` 与 `PagerStyle`。

### 5.6 `Debug`

`Debug` 不是业务 API，而是内部可观测性 API 的一部分，主要服务于：

- 调试 overlay
- 交互日志
- 自动化验证

对于复杂图表组件，这是保留长期可维护性的必要能力，建议不要轻易删除。

## 6. 展示模式 API

当前图表通过 `Tab` 和 `ChartPresentationMode` 组合出展示策略。

内建 tab 包括：

- `CombinedChartView.Tab.totalTrend`
- `CombinedChartView.Tab.breakdown`

它们代表的是“展示重点”差异，而不是不同的数据源：

- `totalTrend`
  - 强调统一颜色趋势、趋势线和点选择
- `breakdown`
  - 强调分序列颜色和带状高亮

架构上，这种设计优于创建多个分散的开关字段，因为它将一组相关视觉语义收束为一个模式对象。

但从终态多图表平台角度看，这套模式对象目前仍然是 `CombinedChart` 专属抽象。  
未来只有“所有图表共享的语义”才应进入公共 Foundation 或 SharedUI，图表专属语义则应留在对应组件模块内部。

## 7. 扩展点 API

### 7.1 `Slots`

`Slots` 是当前最重要的可定制能力，支持替换：

- empty state
- selection overlay
- pager

设计原则应理解为：

- 允许替换局部 UI
- 不允许绕过框架核心布局和交互模型

这是一种典型的“骨架稳定，局部可插拔”框架策略。

### 7.2 `SelectionOverlayContext`

自定义选中态 UI 时可获得：

- 选中的 `point`
- 当前 `value`
- `plotFrame`
- `indicatorFrame`
- `indicatorStyle`

这保证外部自定义 UI 不需要自行推导坐标和选择态语义。

### 7.3 `PagerContext`

自定义 pager 时可获得：

- `entries`
- `highlightedEntry`
- 可前进/后退状态
- 前进/后退/选中回调

这意味着业务方可以重做 pager 样式，但不应重写分页计算逻辑。

## 8. 回调语义

### 8.1 `onPointTap`

`onPointTap` 返回的是已解析后的 `SelectionContext`，包含：

- `point`
- `index`

语义注意点：

- `index` 是当前可见数据序列中的位置。
- `point.id` 才是跨重排、跨刷新更稳定的身份键。

因此，业务侧如果需要持久化选择结果，应该优先依赖 `point.id`，而不是 `index`。

### 8.2 `onDebugStateChange`

该回调暴露了完整的 `DebugState`，适合：

- 开发期调试
- 自动化截图时记录状态
- 复杂滚动场景的观测

它不应被业务逻辑依赖，因为字段集合可能随着调试需求演进而变化。

## 9. 向后兼容策略

当前保留的兼容入口主要是：

- `viewSlots:`

状态为：

- 仍可用
- 已废弃
- 应在下游完成迁移后移除

这说明当前 API 演进策略是“软迁移优先”，而不是直接破坏式升级。  
对一个处于快速演进期的框架来说，这是正确做法。

## 10. 当前 API 边界

调用方目前应依赖的内容包括：

- `CombinedChartView`
- `ChartConfig`
- `ChartSeriesKey`
- `ChartGroup`
- `ChartPoint`
- `ChartTab`
- `SelectionContext`
- `SelectionOverlayContext`
- `PagerContext`
- `DebugState`

调用方不应依赖的内容包括：

- `PreparedData`
- `DerivedState`
- `PagerState`
- `ScrollState`
- `InteractionReducer`
- `Renderer`

这些都属于内部实现细节，未来极可能在模块化改造中移动、重命名或拆分。

## 11. API 演进建议

从架构师视角，下一阶段 API 演进应重点关注以下方向：

1. 将 `ChartSeriesKey` 从固定枚举演进为更通用的 series descriptor。
2. 将当前聚合式 `ChartConfig` 逐步拆为 chart-specific `Configuration + Style`。
3. 将图表无关输入模型沉淀为统一 Foundation 数据模型，例如 `ChartPoint`、`ChartSeries`、`VisibleRange`。
4. 将 `Pager` 与 `Debug` 进一步区分为行为配置和观测配置。
5. 在未来模块拆分时，保持图表主入口稳定，避免让调用方感知内部结构重组。

## 11.1 终态 API 设计方向

为了对齐 `Arch.md`，终态 API 应满足以下结构：

### Foundation 层

- 提供统一输入模型
- 提供可复用状态与算法
- 不依赖具体图表

### Components 层

每一种图表都应有独立公共入口，例如：

- `CombinedChart`
- `LineChart`
- `BarChart`
- `PieChart`

并且每个组件都应提供：

- `View`
- `Configuration`
- `Style`
- `Renderer`

### SharedUI 层

轴、图例、tooltip、overlay 不应继续作为 `CombinedChart` 专属 API 存在，而应演进为共享能力。

## 12. 结论

当前 API 已经具备一个成熟组件库应有的基本特征：

- 主入口清晰
- 配置集中
- 扩展点可控
- 兼容策略明确

它的主要不足不在于“不会用”，而在于“还不够通用”。  
因此后续 API 设计的重点应放在增强通用性和稳定性，并逐步对齐 `Arch.md` 所定义的多图表 ChartKit 终态，而不是继续在当前 `CombinedChartView + ChartConfig` 形态上无限叠加零散开关。
