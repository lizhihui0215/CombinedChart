# Refactor Status

Date: 2026-03-07

## Current verified state

- The app builds successfully in Xcode.
- The active project file is now `CombinedChartSample.xcodeproj`.
- The previous `ScrollChatTest.xcodeproj` is deleted in git and replaced by `CombinedChartSample.xcodeproj`.
- The only source file with local code changes is `ScrollChatTest/LineAndBarChart.swift` in git history, which corresponds to the current file at `CombinedChartSample/ScrollChatTest/LineAndBarChart.swift`.

## What the refactor already accomplished

The chart implementation has been shifted from a demo-only view into a more reusable component surface:

- `ChartSeriesKey` was made public.
- `ChartConfig` and its nested configuration types were made public.
- Explicit public initializers were added for config/data surface types.
- `CombinedChartView` was made public.
- Consumer-facing nested types under `CombinedChartView` were made public:
  - `DefaultEmptyStateView`
  - `PagerEntry`
  - `ViewSlots`
  - `SelectionOverlayContext`
  - `PagerContext`
  - `SelectionContext`
  - `ChartPresentationMode`
  - `ChartTab`
  - `ChartPointID`
  - `ChartPoint`
  - `ChartGroup`
- Internal implementation-only types were left internal:
  - `ChartDataPoint`
  - `ChartDataGroup`
  - `YearPageRange`
  - `PlotAreaInfo`

## Current structure in `LineAndBarChart.swift`

The file is already partially reorganized into clearer layers:

1. Public API and configuration surface.
2. Public `CombinedChartView` state and nested public types.
3. Data/pager derivation helpers.
4. Public `body`.
5. Private UI building blocks:
   - `ChartYAxisLabels`
   - `CombinedChartSection`
   - `CombinedChartPager`
   - `ChartContainer`
6. Private chart overlay and rendering helpers.
7. Preview host.

## Likely intent of the interrupted refactor

Based on the diff, the refactor direction appears to be:

- turn the chart into a reusable component API
- separate public model/config types from internal rendering details
- keep rendering internals private while exposing customization hooks through `ViewSlots`

## Remaining gaps

- `LineAndBarChart.swift` is still a very large single file and has not yet been split into multiple files.
- There is no dedicated test coverage for the new public configuration/data API.
- `XcodeRefreshCodeIssuesInFile` could not return diagnostics for the file, although a full project build succeeded.
- There is still debug `print(...)` logging in pager and selection paths.

## Recommended next steps

1. Split `LineAndBarChart.swift` by responsibility without changing behavior:
   - public API/config
   - data models
   - container view
   - chart rendering helpers
   - pager/overlay views
2. Add tests around signed values, trend line inclusion, pager range calculation, and selection width logic.
3. Decide whether the debug logging should remain behind a debug flag or be removed.
