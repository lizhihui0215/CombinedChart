# CombinedChart

English | [简体中文](README.zh-CN.md)

`CombinedChart` is a chart framework repository organized as:

- a Swift Package that currently ships `CombinedChartFramework`
- a Sample App used for demo, validation, UI debugging, and snapshot testing

The current delivered component is `CombinedChartView`.  
The long-term architecture target, defined in `Arch.md`, is to evolve this repository into a modular `ChartKit` platform that supports:

- `CombinedChart`
- `LineChart`
- `BarChart`
- `PieChart`
- `AreaChart`
- `CandlestickChart`

## Current Status

What is implemented today:

- Combined bar + trend line chart via `CombinedChartView`
- dual rendering engines: `Charts` and `Canvas`
- dual horizontal interaction implementations: SwiftUI gesture and UIKit `UIScrollView`
- configurable axis, pager, selection, debug, and rendering behavior
- custom slots for empty state, selection overlay, and pager
- unit tests for derived state, paging, reducers, and resolvers
- UI snapshot tests for key chart scenarios

What is not finished yet:

- the repository is not yet split into the final `Foundation / Components / SharedUI / Compatibility` module structure
- the current package still centers on `CombinedChart`
- platform boundaries are still being cleaned up, especially around UIKit compatibility paths

## Architecture Direction

The intended end-state is a reusable `ChartKit` with four layers:

1. `Foundation`
2. `Components`
3. `SharedUI`
4. `Compatibility`

Current code already has the early shape of this design, but still exists mostly as a single-target implementation organized by folders such as `Public`, `Core`, `Interaction`, `Rendering`, and `Support`.

For the detailed architecture assessment, see:

- `Docs/Architecture.md`
- `Docs/API-Notes.md`
- `Docs/Migration-Notes.md`
- `Docs/Roadmap.md`
- `Docs/iOS16-Known-Issues.md`
- `Docs/Crash-Notes.md`

## Package

The repository currently exposes one library product:

- `CombinedChartFramework`

Package definition:

```swift
.library(
    name: "CombinedChartFramework",
    targets: ["CombinedChartFramework"]
)
```

Framework sources currently live under:

```text
CombinedChartSample/CombinedChartSample/Sources/CombinedChartFramework
```

This works for the current stage, but is an intermediate structure rather than the final target package layout.

## Recommended API Surface

Prefer the `CombinedChartView`-scoped shorthands:

- `CombinedChartView.Config`
- `CombinedChartView.Tab`
- `CombinedChartView.DataGroup`
- `CombinedChartView.Point`
- `CombinedChartView.Slots`
- `CombinedChartView.Selection`

These aliases keep call sites centered on the chart component rather than exposing lower-level type names directly.

## Basic Usage

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

## Custom Slots

Use `slots:` to replace selected pieces of UI without rebuilding the chart shell.

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

## Point Selection

Use `onPointTap` to observe resolved selections:

```swift
CombinedChartView(
    config: config,
    groups: groups,
    onPointTap: { selection in
        print(selection.point.id, selection.index)
    }
)
```

If downstream code needs stable identity across refreshes or reordering, prefer `selection.point.id` over `selection.index`.

## Repository Structure

Current top-level structure:

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

Current responsibility split:

- `CombinedChartSample/`
  - app shell, demos, sample data loading, visual validation
- `CombinedChartFramework`
  - public API, state derivation, interaction logic, rendering, support UI
- `Docs/`
  - architecture, API, migration, roadmap, compatibility, crash notes

## Development Notes

Useful validation paths today:

- Swift Package tests for framework logic
- Xcode test plan for sample app tests and UI snapshot tests

Current known engineering caveat:

- the framework currently supports iOS only; macOS is not supported

See `Docs/Crash-Notes.md` and `Docs/iOS16-Known-Issues.md` for current limitations and platform-specific behavior.

## API Compatibility

Preferred:

- `slots:`

Still available for migration compatibility:

- `viewSlots:`

Public context types such as `SelectionContext`, `SelectionOverlayContext`, and `PagerContext` have public initializers and can be used in tests or adapter code.

## Roadmap Summary

Short-term priorities:

1. stabilize platform boundaries and package build behavior
2. split the current implementation toward `Foundation / Components / SharedUI / Compatibility`
3. unify rendering and interaction semantics across multiple engines

Only after those steps should the repository expand from the current `CombinedChart` implementation toward the full `ChartKit` family.
