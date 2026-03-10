# CombinedChartFramework API Notes

[简体中文](API-Notes.md) | English

This document describes the current public API from a framework-design perspective.  
It focuses on API boundaries, intended usage, extension points, and how the current surface should evolve toward the long-term `ChartKit` target defined in `Arch.md`.

## 1. API Design Goal

The current public API is designed to provide:

- a clear entry point
- strong typing
- configurable behavior
- constrained extensibility
- room for future architecture evolution

The primary public entry point today is:

- `CombinedChartView`

Consumers should integrate through this entry point rather than depending on internal reducer, rendering, or state-derivation types.

## 1.1 Current API vs End-State API

The current API is the public surface of a single delivered chart component.  
The end-state API, according to `Arch.md`, must support a broader `ChartKit` family:

- `CombinedChart`
- `LineChart`
- `BarChart`
- `PieChart`
- `AreaChart`
- `CandlestickChart`

So the current API should be treated as:

- a stable current integration surface
- an intermediate step toward a multi-chart platform

## 2. Recommended Public Surface

In consumer code, prefer the `CombinedChartView`-scoped aliases:

- `CombinedChartView.Config`
- `CombinedChartView.Tab`
- `CombinedChartView.DataGroup`
- `CombinedChartView.Point`
- `CombinedChartView.Slots`
- `CombinedChartView.Selection`

This keeps call sites centered on the chart component and reduces exposure to lower-level internal naming.

## 3. Main Initializer Semantics

The preferred initializer shape is:

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

Responsibilities of the main parameters:

- `config`
  - controls behavior, visuals, rendering strategy, paging, and debug settings
- `groups`
  - the sole business-data input
- `tabs`
  - defines presentation modes, not alternate data models
- `selectedTab`
  - externally controlled tab state
- `showDebugOverlay`
  - debug-only visual state
- `slots`
  - localized UI replacement points
- `onPointTap`
  - resolved selection callback
- `onDebugStateChange`
  - observability hook for debugging or automated validation

## 4. Data Model Contracts

### 4.1 `DataGroup`

`DataGroup` represents a logical group of points, typically a year or another business grouping.  
Important fields:

- `id`
- `displayTitle`
- `groupOrder`
- `points`

Contract notes:

- visual order is resolved from `groupOrder`, not from raw input ordering
- `displayTitle` is user-facing and may be consumed by pager UI

### 4.2 `Point`

`Point` represents a logical x-axis point.  
Important fields:

- `id`
- `xKey`
- `xLabel`
- `values`

Contract notes:

- `id` should be stable
- `xKey` is the rendering and lookup key
- `xLabel` is display text
- missing series values are treated as `0`

### 4.3 `ChartSeriesKey`

The current series model uses a controlled enum:

- `liabilities`
- `saving`
- `investment`
- `otherLiquid`
- `otherNonLiquid`

That means the current component is still based on a fixed-domain series model, not yet a fully generic chart schema.  
For the final `ChartKit` direction, this should eventually evolve toward more reusable series descriptors.

## 5. Configuration Semantics

`ChartConfig` is the main configuration object today.  
It currently contains:

- `Rendering`
- `Bar`
- `Line`
- `Axis`
- `Pager`
- `Debug`

This is one of the strongest parts of the current API because it centralizes behavior and visuals into a value-based configuration object.

However, the end-state defined in `Arch.md` expects each chart component to expose clearer separation between:

- `Configuration`
- `Style`

Examples of the eventual direction:

- `CombinedChartConfiguration`
- `CombinedChartStyle`
- `LineChartConfiguration`
- `LineChartStyle`
- `BarChartConfiguration`
- `BarChartStyle`
- `PieChartConfiguration`
- `PieChartStyle`

So the current `ChartConfig` should be treated as a transitional aggregated configuration type.

### 5.1 `Rendering`

Supported rendering engines:

- `automatic`
- `charts`
- `canvas`

Recommended semantics:

- use `automatic` as the default production setting
- use `charts` for system-native rendering validation
- use `canvas` for compatibility fallback or renderer isolation

### 5.2 `Bar`

`Bar` governs stacked bar semantics and visuals, including:

- `series`
- `trendBarColorStyle`
- `segmentGap`
- `segmentGapColor`
- `barWidth`

Each `SeriesStyle` mixes visual and semantic behavior:

- visual label and color
- value sign normalization
- trend-line inclusion

### 5.3 `Line`

`Line` governs trend-line and selection behavior:

- positive and negative line colors
- line width
- line type
- selection configuration

This is where current line appearance and selection geometry semantics live.

### 5.4 `Axis`

`Axis` uses contextual closures:

- `xAxisLabel: (XLabelContext) -> String`
- `yAxisLabel: (YLabelContext) -> String`

This is stronger than a simple formatter because the formatter can reason about visible context, not just a raw value.

### 5.5 `Pager`

`Pager` currently mixes:

1. navigation behavior
2. pager visual settings

That is acceptable today, but long term it would be cleaner to separate pager behavior from pager styling.

### 5.6 `Debug`

`Debug` is not business API. It is part of framework observability and should be treated as such.

## 6. Presentation Mode API

The current chart uses `Tab` and `ChartPresentationMode` to group presentation semantics.

Built-in tabs:

- `CombinedChartView.Tab.totalTrend`
- `CombinedChartView.Tab.breakdown`

These represent different emphasis modes for the same data:

- `totalTrend`
  - emphasizes unified trend, trend line, and point selection
- `breakdown`
  - emphasizes per-series bar breakdown and band selection

This is a good current design because related visual semantics are grouped into one mode object rather than spread across many booleans.

That said, this is still a `CombinedChart`-specific abstraction.  
Only cross-chart concepts should eventually move into shared foundations.

## 7. Extension Points

### 7.1 `Slots`

`Slots` is the main public extensibility surface today.  
It supports custom:

- empty state
- selection overlay
- pager

The intended rule is:

- the framework keeps the structural skeleton
- consumers customize selected UI regions

### 7.2 `SelectionOverlayContext`

Custom selection UI receives:

- selected `point`
- resolved `value`
- `plotFrame`
- `indicatorFrame`
- `indicatorStyle`

This prevents consumers from having to recalculate geometry themselves.

### 7.3 `PagerContext`

Custom pager UI receives:

- available pager entries
- the highlighted entry
- previous/next availability
- previous/next/select callbacks

Consumers can restyle pager UI, but should not reimplement paging logic outside the framework.

## 8. Callback Semantics

### 8.1 `onPointTap`

Returns a resolved `SelectionContext` with:

- `point`
- `index`

Important distinction:

- `index` is view-local and ordering-sensitive
- `point.id` is the better long-term identity key

### 8.2 `onDebugStateChange`

Returns `DebugState` for:

- development-time debugging
- automation and screenshot validation
- interaction diagnostics

It should not be treated as a stable business contract.

## 9. Backward Compatibility

The main compatibility entry still available today is:

- `viewSlots:`

Status:

- still available
- deprecated
- should be removed only after downstream migration

That is the correct strategy for a framework still stabilizing its public surface.

## 10. Public API Boundary

Consumers may safely depend on:

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

Consumers should avoid depending on:

- `PreparedData`
- `DerivedState`
- `PagerState`
- `ScrollState`
- `InteractionReducer`
- `Renderer`

Those remain internal implementation details.

## 11. Recommended API Evolution

The next API evolution steps should be:

1. evolve `ChartSeriesKey` toward a more reusable series description model
2. split the current aggregated `ChartConfig` into chart-specific `Configuration + Style`
3. promote chart-agnostic primitives into a reusable foundation layer
4. separate behavior-oriented settings from observability settings more cleanly
5. preserve stable component entry points while internal modules are restructured

## 11.1 End-State API Shape

To align with `Arch.md`, the end-state API should look more like:

### Foundation

- shared input models
- reusable selection, range, and state logic
- chart-agnostic algorithms

### Components

Each chart type should eventually expose its own public entry point, for example:

- `CombinedChart`
- `LineChart`
- `BarChart`
- `PieChart`

Each component should own:

- `View`
- `Configuration`
- `Style`
- `Renderer`

### SharedUI

Axis, legend, overlay, tooltip, and theme concepts should be extracted out of chart-specific ownership where they are truly reusable.

## 12. Conclusion

The current API already has strong framework qualities:

- a clear entry point
- centralized configuration
- constrained extensibility
- compatibility-aware evolution

Its main weakness is not usability. It is lack of generality.  
The next step is to evolve from a strong single-component public surface into a family of chart APIs that can sit on top of a reusable `ChartKit` foundation.
