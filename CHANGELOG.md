# Changelog

English | [简体中文](CHANGELOG.zh-CN.md)

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),  
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This repository does not yet have a formal release history captured in versioned entries.  
The section below reflects the current unreleased state of the repository as of 2026-03-10.

## [Unreleased]

### Added

- `CombinedChartView` as the primary reusable public entry point for the current chart framework.
- preferred `CombinedChartView`-scoped type aliases for public usage:
  - `Config`
  - `Tab`
  - `DataGroup`
  - `Point`
  - `Slots`
  - `Selection`
- custom slot support for:
  - empty state
  - selection overlay
  - pager
- selection callback support through `onPointTap`.
- debug state reporting through `onDebugStateChange`.
- dual rendering support with:
  - `Charts`
  - `Canvas`
- dual horizontal interaction implementations with:
  - SwiftUI gesture-driven scrolling
  - UIKit `UIScrollView`-backed scrolling
- unit tests covering:
  - derived state
  - viewport and paging state
  - selection and line/bar resolvers
  - interaction reducer behavior
- UI snapshot tests for core chart scenarios.
- architecture and engineering documentation under `Docs/`, including:
  - architecture notes
  - API notes
  - migration notes
  - roadmap
  - iOS 16 known issues
  - crash notes
- `ChartRenderingLayout` to centralize chart layout calculations for `topInset`, `xAxisHeight`, plot area height, and Canvas tick positioning.
- focused layout regression tests covering rendering layout height clamping and Canvas tick edge mapping.

### Changed

- public API guidance now prefers `slots:` over the legacy `viewSlots:` label.
- public usage guidance now prefers `CombinedChartView`-scoped names instead of exposing lower-level type names directly.
- repository documentation has been aligned with the long-term `ChartKit` target architecture defined in `Arch.md`.
- architecture guidance now explicitly positions the current codebase as an intermediate step from a `CombinedChart` implementation toward a multi-chart platform supporting:
  - `CombinedChart`
  - `LineChart`
  - `BarChart`
  - `PieChart`
  - `AreaChart`
  - `CandlestickChart`
- chart layout configuration now exposes `rendering.topInset` and `rendering.xAxisHeight` through the sample app and preview entry points.
- chart and Y-axis layout synchronization now treats Canvas chart content and the Y-axis column as a shared layout unit, reducing height-change drift and pager visibility alignment regressions.
- sample playground controls now allow direct comparison of `Charts` and `Canvas` renderers with tunable layout parameters.

### Known Limitations

- the package currently declares `macOS(.v14)` support while part of the interaction implementation imports UIKit directly, which prevents successful package builds on macOS through `swift test` in the current state.
- the current repository structure is still a single delivered chart component with internal folder-level layering, not yet the final `Foundation / Components / SharedUI / Compatibility` modular package structure.
- rendering and interaction currently maintain multiple implementation paths, which improves flexibility but increases parity and regression risk:
  - `Charts` vs `Canvas`
  - SwiftUI gesture vs UIKit scroll view

### Migration Notes

- downstream integrations should prefer `slots:` over `viewSlots:`.
- downstream code should prefer stable point identity via `selection.point.id` over UI-local index-based persistence.
- current `ChartConfig` should be treated as a transitional aggregated configuration model; long-term architecture expects chart-specific `Configuration + Style` types.
