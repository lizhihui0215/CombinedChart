# CombinedChartFramework Crash Notes

[简体中文](Crash-Notes.md) | English

This document captures current stability observations, probable failure hotspots, and debugging guidance.  
As of 2026-03-10, the repository does not contain concrete crash artifacts in `crash/`, so this document is based on source analysis, build validation, and recorded engineering issues rather than a full production crash postmortem.

## 1. Current Stability Assessment

The biggest risks in the current repository are not classic memory crashes.  
The more important risks are:

- build failures
- platform-boundary inconsistency
- visible state and interaction state drifting apart
- behavior mismatch across multiple rendering and interaction implementations

In practice, stability must be evaluated across three levels:

1. can it build
2. can it interact correctly
3. can it remain semantically consistent across modes

## 2. Highest-Priority Confirmed Issue

### 2.1 Package Platform Declaration vs UIKit Dependency

Confirmed facts:

- `Package.swift` declares `macOS(.v14)`
- `CombinedChartView+UIKitScrollContainer.swift` imports UIKit directly

Result:

- package builds through `swift test` fail on macOS in the current state

This is not a runtime crash, but architecturally it is still a P0-grade stability issue because it breaks:

- package portability
- CI build reliability
- trust in declared platform support

## 3. Historical High-Severity Non-Crash Risk

The repository history also shows a previously discussed state-desynchronization risk:

- deriving visible start state from `DragGesture.translation`
- while that value is not necessarily the same as the real scroll content offset

That class of issue usually produces:

- pager mismatch
- debug overlay mismatch
- selection state not matching visible content

These are non-crash failures, but they are still severe because they damage correctness and trust in the component.

## 4. Existing Defensive Coding Strengths

The current implementation already reduces many common crash risks through defensive patterns:

### 4.1 Index Guarding

The code often uses:

- `indices.contains`
- `firstIndex`
- `guard let`

This lowers the risk of array out-of-bounds crashes.

### 4.2 Optional Geometry Resolution

The renderer usually treats geometry and proxy resolution as optional rather than force-unwrapping positions from the chart system.

This means incomplete layout generally results in skipped rendering rather than a crash.

### 4.3 Math Boundary Protection

The implementation already protects against:

- zero plot height
- zero unit width
- zero or near-zero domain spans
- out-of-range content offsets

That reduces the chance of NaN/Inf rendering state and invalid math paths.

## 5. Main Hotspots Worth Monitoring

### 5.1 UIKit Scroll Bridge

`UIKitScrollContainer` is one of the most important stability hotspots because it mixes:

- SwiftUI lifecycle
- UIKit lifecycle
- `UIScrollViewDelegate`
- `UIHostingController`
- dynamic sizing and offset synchronization

This is a reasonable compatibility solution, but it is also the place where timing and synchronization defects are most likely to appear.

### 5.2 Dual Rendering Paths

The repository currently maintains:

- `Charts`
- `Canvas`

The problem is not that one of them must crash.  
The problem is that they can drift semantically if parity is not tested continuously.

### 5.3 Plot Sync State

`plotSyncState` coordinates plot geometry and y-axis label placement.  
The implementation intentionally avoids some updates during drag to reduce jitter.

That is a valid engineering tradeoff, but it means:

- timing assumptions matter
- renderer differences matter
- temporary geometry mismatch is possible if the sync path regresses

## 6. Areas That Currently Look Relatively Safe

The following areas are structurally lower risk because they are mostly pure logic and already covered by tests:

- `SelectionResolver`
- `InteractionReducer`
- `PagerState`
- `BarSegmentResolver`
- `LineSegmentResolver`

These should be treated as stability baselines rather than first suspects unless evidence points there.

## 7. What to Capture During Investigation

When diagnosing a crash, hang, or severe state mismatch, the most useful context is:

### 7.1 Runtime Configuration

- iOS version
- device type
- rendering engine
- scroll implementation
- drag mode
- selected tab
- dataset size

### 7.2 Interaction Context

- whether the issue happened during tap, drag, paging, or tab switching
- whether fast repeated drags were involved
- whether debug overlay was enabled
- whether the issue happened during automation or snapshot testing

### 7.3 Debug State

If reproducible, capture `DebugState`, especially:

- `startIndex`
- `visibleStartIndex`
- `contentOffsetX`
- `targetContentOffsetX`
- `scrollImplementationTitle`
- `dragScrollModeTitle`
- `selectedPointXKey`

## 8. Recommended Stability Priorities

From an architecture perspective, the most valuable next steps are:

1. fix the package platform-boundary issue
2. establish a single source of truth for visible position and pager state
3. add parity coverage across renderers and interaction implementations
4. use `DebugState` more systematically in diagnostics

## 9. Conclusion

The current repository's stability challenge is less about low-level crash mechanics and more about correctness under multiple implementations and compatibility paths.  
Short-term stability work should prioritize:

1. build consistency
2. state consistency
3. parity verification

That will improve the framework more meaningfully than isolated defensive checks alone.
