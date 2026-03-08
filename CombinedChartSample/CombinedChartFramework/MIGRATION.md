# CombinedChartFramework Migration Notes

This file tracks the current preferred API surface after the recent framework cleanup.

## Preferred Entry Points

Prefer these `CombinedChartView`-scoped names in app code:

- `CombinedChartView.Config`
- `CombinedChartView.Tab`
- `CombinedChartView.DataGroup`
- `CombinedChartView.Point`
- `CombinedChartView.Slots`
- `CombinedChartView.Selection`

These aliases keep call sites centered on the primary view instead of exposing lower-level type names.

## Preferred Initializer

Prefer:

```swift
CombinedChartView(
    config: config,
    groups: groups,
    tabs: tabs,
    selectedTab: $selectedTab,
    showDebugOverlay: $showDebugOverlay,
    slots: slots,
    onPointTap: onPointTap
)
```

## Compatibility Entry Points

The following API remains available for migration compatibility:

- `viewSlots:` on `CombinedChartView`

Current status:

- Still supported
- Deprecated in favor of `slots:`
- Safe to keep temporarily while downstream code migrates

## Public Context Types

These context types now have explicit public initializers and are safe to construct in tests or adapter code:

- `CombinedChartView.Selection`
- `CombinedChartView.SelectionOverlay`
- `CombinedChartView.PagerContext`

## Recommended Cleanup Order

When moving downstream code to the new surface, use this order:

1. Replace `viewSlots:` with `slots:`
2. Prefer `CombinedChartView.Config` / `Tab` / `DataGroup` / `Point`
3. Keep advanced aliases only where they improve readability

## Future Removal Candidates

These should only be removed after downstream usage is migrated:

- Deprecated `viewSlots:` initializer
- Any aliases that remain unused outside framework internals and examples
