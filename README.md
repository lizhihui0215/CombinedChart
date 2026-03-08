# CombinedChartFramework

`CombinedChartView` is the primary entry point.

## Recommended API Surface

Prefer the shorthands scoped under `CombinedChartView`:

- `CombinedChartView.Config`
- `CombinedChartView.Tab`
- `CombinedChartView.DataGroup`
- `CombinedChartView.Point`
- `CombinedChartView.Slots`
- `CombinedChartView.Selection`

These map to the framework's public types but keep usage centered around the chart view.

## Basic Usage

```swift
CombinedChartView(
    config: config,
    groups: groups,
    tabs: tabs,
    selectedTab: $selectedTab,
    showDebugOverlay: $showDebugOverlay
)
```

## Custom Slots

Use `slots:` for empty state, selection overlay, and custom pager content.

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

Use `onPointTap` to observe resolved chart selections.

```swift
CombinedChartView(
    config: config,
    groups: groups,
    onPointTap: { selection in
        print(selection.point.id, selection.index)
    }
)
```

## Notes

- `slots:` is the preferred custom-content entry point.
- `viewSlots:` remains available for compatibility.
- `SelectionOverlayContext`, `PagerContext`, and `SelectionContext` all have public initializers for testing and external composition.
