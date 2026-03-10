# CombinedChartFramework Migration Notes

[简体中文](Migration-Notes.md) | English

This document explains how the current repository should evolve from its earlier shape toward the current API and, eventually, toward the long-term `ChartKit` architecture described in `Arch.md`.

## 1. Migration Context

The framework is currently in an intermediate phase:

- public entry points are converging around `CombinedChartView`
- view-scoped aliases are being preferred
- customization is being normalized around `slots`
- internal logic is already splitting into data, interaction, and rendering concerns

Migration strategy must therefore achieve two things at once:

1. keep downstream integrations stable
2. leave room for modularization and platform cleanup

## 1.1 Target Migration Outcome

The destination is not merely a cleaner `CombinedChartView`.  
The destination is a reusable `ChartKit` platform supporting:

- `CombinedChart`
- `LineChart`
- `BarChart`
- `PieChart`
- `AreaChart`
- `CandlestickChart`

with a package structure aligned to:

- `Foundation`
- `Components`
- `SharedUI`
- `Compatibility`

## 2. Current Migration Direction

### 2.1 API Convergence

The clearest migration direction today is to converge on:

- `CombinedChartView.Config`
- `CombinedChartView.Tab`
- `CombinedChartView.DataGroup`
- `CombinedChartView.Point`
- `CombinedChartView.Slots`
- `CombinedChartView.Selection`

This is not just naming cleanup. It re-centers integration around the chart component instead of scattered lower-level types.

### 2.2 Extension Convergence

Preferred:

- `slots:`

Legacy compatibility:

- `viewSlots:`

All future local UI customization should converge toward the `slots` model rather than adding parallel extension APIs.

## 3. Recommended Migration Order

### Step 1: Replace the Legacy Parameter Label

Replace:

- `viewSlots:`

with:

- `slots:`

This is the safest and most direct source migration.

### Step 2: Normalize Type References

Prefer the `CombinedChartView`-scoped aliases in downstream code instead of lower-level type names.

### Step 3: Consolidate UI Customization

Move custom empty-state, selection, and pager behavior into `Slots` instead of wrapping and duplicating framework layout externally.

### Step 4: Persist Stable Identity, Not UI Index

If downstream systems persist selection, prefer:

- `selection.point.id`

instead of:

- `selection.index`

because `point.id` is the more stable long-term identity.

## 4. Typical Migration Scenarios

### 4.1 `viewSlots:` to `slots:`

Old:

```swift
CombinedChartView(
    config: config,
    groups: groups,
    viewSlots: slots
)
```

New:

```swift
CombinedChartView(
    config: config,
    groups: groups,
    slots: slots
)
```

### 4.2 Lower-Level Type Names to View-Scoped Aliases

Old:

```swift
let config = ChartConfig.default
let groups: [ChartGroup] = []
```

New:

```swift
let config = CombinedChartView.Config.default
let groups: [CombinedChartView.DataGroup] = []
```

### 4.3 External Pager Logic to `slots.pager`

If downstream code keeps a separate pager UI outside the chart and tries to synchronize page state manually, it should gradually migrate toward:

- framework-owned paging logic
- custom pager presentation through `PagerContext`

## 5. Compatibility Policy

The repository currently follows a soft-migration strategy:

- keep compatibility entry points
- deprecate them
- remove them only after consumers have migrated

That is the correct approach for a framework that is still converging on its stable public shape.

## 6. Structural Migration Warnings

Several deeper migrations are still expected.

### 6.1 Module Migration

Many capabilities currently live under `CombinedChartView`, but they are likely to move toward:

- `Foundation`
- `SharedUI`
- `Compatibility`
- `Components/CombinedChart`
- `Components/LineChart`
- `Components/BarChart`
- `Components/PieChart`

### 6.2 Configuration Model Migration

The current API still revolves around `ChartConfig`.  
The target architecture expects chart-specific separation into:

- `Configuration`
- `Style`
- `Renderer`

For example:

- `CombinedChartConfiguration` / `CombinedChartStyle`
- `LineChartConfiguration` / `LineChartStyle`
- `BarChartConfiguration` / `BarChartStyle`
- `PieChartConfiguration` / `PieChartStyle`

### 6.3 Platform Declaration Migration

The repository must eventually resolve the mismatch between declared package support and actual UIKit-dependent paths.

### 6.4 Renderer Strategy Migration

Downstream code should not assume the current default renderer behavior is a permanent API guarantee.

## 7. Regression Risks During Migration

The most common migration risks are:

- identity changes breaking selection persistence
- external pager state drifting away from framework paging logic
- downstream code depending on `index` instead of stable IDs
- use of debug state as business logic input
- behavioral differences across renderer or interaction implementations

## 8. Recommended Migration Validation

At minimum, validate:

1. build output with no new deprecation warnings
2. all call sites migrated to `slots:`
3. downstream types normalized to `CombinedChartView.*`
4. persisted selection based on `point.id`
5. no visible snapshot regressions
6. at least one non-default renderer or interaction path

## 9. Conclusion

The core migration goal is not just renaming APIs.  
It is moving downstream consumers toward a stable long-term integration path that can survive:

- modularization
- platform cleanup
- renderer strategy changes
- the evolution from one delivered chart component to a full `ChartKit` platform
