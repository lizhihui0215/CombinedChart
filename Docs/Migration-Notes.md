# CombinedChartFramework Migration Notes

本文用于说明当前仓库从早期实现向当前 API 形态迁移时的原则、步骤和风险。  
它关注的是“如何稳定演进”，而不是简单列出替换项。

## 1. 当前迁移背景

从仓库现状看，框架正处于一个典型的中间阶段：

- 对外入口已经开始收敛到 `CombinedChartView`
- 公共类型开始以 view-scoped aliases 暴露
- 自定义能力开始统一到 `slots`
- 内部实现逐步分化为数据、交互、渲染三个层次

这意味着迁移策略必须兼顾两件事：

1. 保持下游调用代码尽量稳定
2. 为后续模块化和平台治理留出空间

## 1.1 对齐 Arch.md 的终态迁移目标

根据 `Arch.md`，这次迁移的终点不是“让 `CombinedChartView` 更顺手”，而是把仓库推进到可承载多图表的 `ChartKit`：

- `CombinedChart`
- `LineChart`
- `BarChart`
- `PieChart`
- `AreaChart`
- `CandlestickChart`

同时，终态包结构应收敛为：

- `Foundation`
- `Components`
- `SharedUI`
- `Compatibility`

因此当前所有迁移动作都应服务于一个长期目标：  
让今天的 `CombinedChart` API 和实现，能够平滑演进为未来 ChartKit 平台的一部分。

## 2. 当前迁移主线

### 2.1 API 收敛

当前最明确的迁移方向是把调用方式收敛到以下表面：

- `CombinedChartView.Config`
- `CombinedChartView.Tab`
- `CombinedChartView.DataGroup`
- `CombinedChartView.Point`
- `CombinedChartView.Slots`
- `CombinedChartView.Selection`

这一步的目标不是语法简化，而是把“框架主入口”从一组散落类型重新收束回 `CombinedChartView`。

但需要明确，这只是当前阶段的收敛目标。  
终态并不应只有一个 `CombinedChartView` 主入口，而应形成：

- `CombinedChart`
- `LineChart`
- `BarChart`
- `PieChart`

各自稳定、风格统一的组件入口。

### 2.2 扩展点收敛

当前推荐使用：

- `slots:`

不再推荐继续扩大：

- `viewSlots:`

这是一次明确的扩展点规范化：未来所有局部 UI 替换都应优先通过 `slots` 模式接入，而不是增加新的平行参数。

## 3. 推荐迁移顺序

建议下游调用方按以下顺序迁移。

### 第一步：先替换初始化参数名

优先把：

- `viewSlots:`

替换为：

- `slots:`

原因：

- 这是最小、最直接、最安全的源码迁移。
- 迁移后可以立刻降低后续 deprecation 成本。

### 第二步：统一类型引用方式

将调用代码中散落的底层类型名逐步统一为 `CombinedChartView` 作用域下的别名，例如：

- `ChartConfig` -> `CombinedChartView.Config`
- `ChartGroup` -> `CombinedChartView.DataGroup`
- `ChartPoint` -> `CombinedChartView.Point`

原因：

- 有助于让外部代码从“依赖内部命名”迁移到“依赖组件主入口”。
- 后续即便内部 target、命名空间或模块发生变化，外部适配成本也更低。

### 第三步：清理自定义 UI 接入方式

所有空态、选择态、pager 自定义，建议统一改造成 `Slots` 风格，而不是在外围额外包装或复制内部布局。

这一步的收益是：

- 降低重复 UI 骨架
- 降低升级时的破坏面
- 让业务层只关心局部定制，而不是重写组件结构

### 第四步：分离业务持久化与临时索引

如果下游逻辑仍在依赖选中回调中的 `index` 做持久化，建议迁移为依赖：

- `selection.point.id`

原因：

- `index` 更接近当前可见序列位置
- `point.id` 才是跨数据刷新和重排更稳定的身份键

## 4. 典型迁移场景

### 4.1 从旧参数名迁移到 `slots:`

旧写法：

```swift
CombinedChartView(
    config: config,
    groups: groups,
    viewSlots: slots
)
```

新写法：

```swift
CombinedChartView(
    config: config,
    groups: groups,
    slots: slots
)
```

### 4.2 从底层类型名迁移到 view-scoped aliases

旧写法：

```swift
let config = ChartConfig.default
let groups: [ChartGroup] = []
```

新写法：

```swift
let config = CombinedChartView.Config.default
let groups: [CombinedChartView.DataGroup] = []
```

### 4.3 从外围自定义 pager 迁移到 `slots.pager`

如果业务层当前是在图表外部维护独立 pager，并手动同步页码，建议逐步迁移到：

- 框架计算页状态
- 业务只通过 `PagerContext` 自定义外观

这样可以避免外部逻辑和内部分页算法并行演化。

## 5. 当前兼容策略

仓库当前采用的是“保留兼容入口，逐步废弃”的策略，而不是激进的破坏式升级。

这在当前阶段是合理的，因为：

- 框架 API 仍在收敛中
- Sample App 之外的实际接入面可能尚不完全稳定
- 后续还存在更大的模块化重构可能

但需要明确一点：  
兼容入口应被视为过渡层，而不是长期双轨制。

## 6. 后续结构性迁移预警

从架构演进角度，后续高概率会发生以下迁移：

### 6.1 模块迁移

当前很多能力仍挂在 `CombinedChartView` 名下，未来可能拆向：

- `Foundation`
- `SharedUI`
- `Compatibility`
- `Components/CombinedChart`
- `Components/LineChart`
- `Components/BarChart`
- `Components/PieChart`

这类迁移原则上不应破坏 `CombinedChartView` 主入口，但会影响内部依赖和二次封装代码。

### 6.1.1 配置模型迁移

当前 API 仍以 `ChartConfig` 为中心。  
按照 `Arch.md` 的终态设计，后续高概率会演进为每个组件单独提供：

- `Configuration`
- `Style`
- `Renderer`

例如：

- `CombinedChartConfiguration` / `CombinedChartStyle`
- `LineChartConfiguration` / `LineChartStyle`
- `BarChartConfiguration` / `BarChartStyle`
- `PieChartConfiguration` / `PieChartStyle`

因此下游应避免把当前单一 `ChartConfig` 形态视为永久不变的 API 契约。

### 6.2 平台声明迁移

当前 `Package.swift` 声明支持 `macOS(.v14)`，但源码中存在 UIKit 直接依赖。  
后续必须二选一：

- 真的补齐跨平台兼容实现
- 或收缩平台声明

这会影响下游对平台支持矩阵的理解和集成方式。

### 6.3 渲染策略迁移

当前存在：

- `Charts`
- `Canvas`

两条渲染路径。

后续如果团队决定收敛主路径或重构渲染抽象，下游不应依赖任何具体引擎默认值作为业务行为前提。

## 7. 迁移过程中的回归风险

迁移时最容易出问题的地方包括：

- 数据 identity 变化导致选择态丢失
- 自定义 pager 与内部页状态不同步
- 依赖 `index` 而非 `point.id`
- 将调试能力误用为业务状态来源
- 在不同渲染/滚动引擎间产生视觉与交互差异

因此建议每次迁移至少验证以下内容：

- 默认 tab 是否正确显示
- `totalTrend` 与 `breakdown` 是否可切换
- 选择态回调是否仍能命中正确点位
- pager 标题与可见内容是否一致
- 自定义 slot 是否保持布局预期

## 8. 推荐迁移验证清单

每次进行下游迁移时，建议至少完成以下验证：

1. 编译通过且无新增 deprecation 警告。
2. 核心调用点已全部改为 `slots:`。
3. 业务侧类型引用已统一到 `CombinedChartView.*`。
4. 选中态持久化逻辑依赖稳定 ID，而非索引。
5. 快照或截图结果无明显视觉回归。
6. 至少验证一组 `Charts` 或 `Canvas` 兼容路径。

## 9. 建议的迁移治理方式

如果该组件将在多个业务仓库落地，建议采用以下治理方式：

- 先发布“推荐 API 使用规范”
- 再发布“兼容入口废弃时间表”
- 最后做“破坏式清理”

不要跳过第一步直接进入删除阶段，否则调用方往往会在不理解设计方向的情况下被动适配。

## 10. 结论

当前迁移工作的核心不是“把名字换一遍”，而是把调用方式迁移到一条更稳定的长期 API 轨道上。  
短期最重要的是完成三项收敛：

1. `viewSlots:` -> `slots:`
2. 底层类型名 -> `CombinedChartView` 作用域别名
3. 业务持久化从 `index` 转向 `point.id`

完成这三项后，下游代码将更容易承接后续的：

- `Foundation / Components / SharedUI / Compatibility` 模块化
- chart-specific `Configuration + Style` API 演进
- 从单一 `CombinedChart` 向多图表 `ChartKit` 平台的扩展
