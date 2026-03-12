# CombinedChartFramework Release Migration Brief

This file is the short team-facing migration brief for the current unreleased state as of 2026-03-11.

For the full architectural and API background, see:

- `Docs/Migration-Notes.md`
- `Docs/API-Notes.md`
- `Docs/iOS16-Known-Issues.md`

## What Changed

The framework has now converged on a clearer runtime strategy and a clearer public naming direction.

### Runtime Strategy

- iOS 17 and later:
  - `Charts + Apple Charts scroll`
- iOS 16:
  - `Canvas + SwiftUI Gesture`
- UIKit scroll:
  - fallback / diagnostics only

The framework currently does not support macOS.

### Preferred Public Names

Use these names for all new code:

- `slots:`
- `visibleValueCount`
- `scrollTargetBehavior`
- `scrollEngine`
- `startIndex`
- `targetIndex`
- `scrollEngineTitle`
- `scrollTargetBehaviorTitle`

Prefer these `CombinedChartView`-scoped types:

- `CombinedChartView.Config`
- `CombinedChartView.Tab`
- `CombinedChartView.DataGroup`
- `CombinedChartView.Point`
- `CombinedChartView.Slots`
- `CombinedChartView.Selection`

## What Teams Should Change

Update downstream code in this order:

1. Replace `viewSlots:` with `slots:`
2. Replace `monthsPerPage` with `visibleValueCount`
3. Replace `dragScrollMode` with `scrollTargetBehavior`
4. Replace `scrollImplementation` with `scrollEngine`
5. Replace `startMonthIndex` with `startIndex`
6. Replace `targetMonthIndex` with `targetIndex`
7. Prefer `selection.point.id` over `selection.index` for persisted identity

## Sample / Automation Flag Changes

If any local scripts, UI tests, or snapshot automation launch the sample app directly, migrate:

- `-snapshot-scroll-implementation` -> `-snapshot-scroll-engine`
- `-snapshot-drag-mode` -> `-snapshot-scroll-target-behavior`

The sample still accepts the older flags for compatibility, but new tooling should stop emitting them.

## Compatibility Status

The old names are still available as deprecated compatibility wrappers.

That means:

- current downstream integrations do not need to migrate in one step
- but no new code should be added using the deprecated names

## Validation Baseline

The current migration baseline has been verified with:

- Xcode build for `CombinedChartSample`
- `CombinedChartSampleTests`
- UI regression for horizontal scrolling on the iOS 17+ `Charts` path

## Recommended Team Message

Use this summary when communicating the change internally:

> CombinedChart has converged on iOS 17+ `Charts` and iOS 16 `Canvas` as the primary runtime model. New code should use `visibleValueCount`, `scrollTargetBehavior`, `scrollEngine`, `startIndex`, and `targetIndex`. Older names still work for migration, but they are now compatibility-only.
