# Changelog

[English](CHANGELOG.md) | 简体中文

本文件用于记录项目中所有值得跟踪的重要变更。

格式参考 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)，  
版本策略目标上遵循 [Semantic Versioning](https://semver.org/spec/v2.0.0.html)。

当前仓库还没有形成正式的版本化发布历史。  
下面的内容反映的是截至 2026-03-10 的当前未发布状态。

## [Unreleased]

### Added

- 增加 `CombinedChartView` 作为当前图表框架的主公共入口。
- 增加推荐的 `CombinedChartView` 作用域公共类型别名：
  - `Config`
  - `Tab`
  - `DataGroup`
  - `Point`
  - `Slots`
  - `Selection`
- 增加以下 slot 自定义能力：
  - empty state
  - selection overlay
  - pager
- 增加通过 `onPointTap` 暴露选择结果的回调能力。
- 增加通过 `onDebugStateChange` 暴露调试状态的能力。
- 增加双渲染支持：
  - `Charts`
  - `Canvas`
- 增加双横向交互实现：
  - 基于 SwiftUI 手势的滚动
  - 基于 UIKit `UIScrollView` 的滚动
- 增加以下单元测试覆盖：
  - derived state
  - viewport 和 paging state
  - selection / line / bar resolver
  - interaction reducer
- 增加核心图表场景的 UI 快照测试。
- 补全文档体系 `Docs/`，包括：
  - 架构文档
  - API 文档
  - 迁移说明
  - 路线图
  - iOS 16 已知问题
  - crash / 稳定性说明

### Changed

- 公共 API 使用建议改为优先使用 `slots:`，不再以旧的 `viewSlots:` 为首选。
- 公共调用建议改为优先使用 `CombinedChartView` 作用域别名，而不是直接暴露底层类型名。
- 仓库文档已对齐 `Arch.md` 中定义的长期 `ChartKit` 目标架构。
- 架构说明已明确当前仓库是从 `CombinedChart` 实现向多图表平台过渡的中间阶段，终态目标包括：
  - `CombinedChart`
  - `LineChart`
  - `BarChart`
  - `PieChart`
  - `AreaChart`
  - `CandlestickChart`

### Known Limitations

- package 当前声明支持 `macOS(.v14)`，但交互实现的一部分仍直接依赖 UIKit，因此在当前状态下通过 `swift test` 进行 macOS package 构建会失败。
- 当前仓库结构仍然是单一已交付图表组件加目录分层，尚未达到最终的 `Foundation / Components / SharedUI / Compatibility` 模块化 package 结构。
- 当前同时维护多套渲染和交互实现，虽然提升了灵活性，但也提高了语义对齐和回归验证成本：
  - `Charts` vs `Canvas`
  - SwiftUI gesture vs UIKit scroll view

### Migration Notes

- 下游集成应优先使用 `slots:`，不要继续新增 `viewSlots:` 依赖。
- 下游代码应优先使用 `selection.point.id` 作为稳定身份，而不是基于 UI 序列位置的 `index`。
- 当前 `ChartConfig` 应视为过渡态聚合配置模型；长期架构目标是演进为各图表独立的 `Configuration + Style` 类型。
