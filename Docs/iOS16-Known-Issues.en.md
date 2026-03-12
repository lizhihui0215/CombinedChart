# iOS 16 Known Issues

[简体中文](iOS16-Known-Issues.md) | English

This document records the main limitations, risks, and recommended configuration strategies for running `CombinedChartFramework` on iOS 16.

The key framing is important:

- the framework now declares iOS 15.0 as its minimum supported version
- iOS 16 remains a supported compatibility target
- it is not yet the strongest execution target for the framework's architecture

## 1. Current Platform Behavior

Under the current implementation, automatic behavior on iOS 16 is conservative:

- `rendering.engine = .automatic` resolves to `canvas`
- `pager.scrollEngine = .automatic` resolves to `swiftUIGesture`

This means the default iOS 16 experience is effectively a compatibility-oriented path rather than the most system-native path.

## 1.1 Compatibility-Layer Direction

According to `Arch.md`, all iOS 16-specific workarounds should eventually be isolated under:

- `Compatibility/iOS16/`

That is the long-term direction for cleaning up iOS 16 support.

## 2. Main iOS 16 Constraints

### 2.1 More Limited Native Scroll Observation

On iOS 16, the framework cannot rely on newer scroll-observation capabilities available in later SwiftUI generations.  
As a result, it must rely on:

- custom drag behavior
- or UIKit scroll bridging

This increases complexity around state synchronization and observability.

### 2.2 Automatic Mode Does Not Default to `Charts`

Even though `Charts` exists on iOS 16, automatic mode currently does not treat it as the default engine.  
That implies the current architecture favors `Canvas` for predictability or compatibility on this platform.

### 2.3 Automatic Mode Does Not Default to UIKit Scroll Bridging

Automatic interaction currently prefers SwiftUI gesture handling on iOS 16.  
That is lighter, but it also means more of the visible-position semantics depend on custom interaction logic.

## 3. Main Risk Categories on iOS 16

### 3.1 Interaction Consistency Risk

The most important issues to watch for are not necessarily crashes, but consistency problems such as:

- pager title not matching visible content
- visible start state drifting from what is on screen
- selection highlight not matching the intended point
- behavior differences between interaction implementations

### 3.2 Rendering Consistency Risk

Because iOS 16 defaults to `Canvas`, several semantics that would otherwise be delegated to a more system-native path are manually implemented, including:

- coordinate conversion
- x-axis label layout
- tap hit mapping
- overlay positioning

This increases parity and maintenance cost.

### 3.3 Debug Timing Lag

Some geometry synchronization is intentionally delayed during drag to reduce jitter.  
That is a valid tradeoff, but it means debug visuals and labels may not always update with the exact same timing as motion during drag-heavy scenarios.

## 4. Recommended Configuration Strategy

### 4.1 General Use

For general usage, prefer:

- `rendering.engine = .automatic`
- `pager.scrollEngine = .automatic`

This keeps the app aligned with the framework's default compatibility decisions.

### 4.2 Scenarios Requiring More Accurate Offset Semantics

If accurate content offset behavior is especially important, evaluate:

- `pager.scrollEngine = .uiKitScrollView`

on iOS 16, because UIKit scrolling is more suitable for offset-driven interaction diagnostics.

### 4.3 Renderer Comparison and Validation

If a team needs to validate behavior explicitly, it may still force:

- `rendering.engine = .charts`

but that should be treated as deliberate validation, not an assumption that it is the best default for iOS 16.

## 5. Recommended Validation Matrix

When validating iOS 16 behavior, test at least:

1. `automatic` renderer + `automatic` interaction
2. `canvas` + `swiftUIGesture`
3. `canvas` + `uiKitScrollView`
4. `charts` when parity investigation is needed

Validate:

- initial page correctness
- tab switching behavior
- pager and visible content alignment
- selection overlay positioning
- drag and page-navigation consistency

## 6. Broader Architecture Signal

The current platform-boundary issue in the package is not itself an iOS 16 runtime defect, but it is relevant:

- the package declares wider platform support
- UIKit-dependent paths are not yet fully isolated

That is a reminder that the compatibility layer is still being formed.

## 7. Recommended Improvement Areas

### 7.1 Compatibility-Layer Isolation

Version-specific behavior and UIKit bridges should move into a dedicated compatibility layer.

### 7.2 Single Source of Truth for Visible Position

iOS 16 especially needs a clearer truth model for:

- visible start
- current offset
- pager highlight
- debug state

### 7.3 Renderer Parity Testing

The repository should maintain parity validation for `Charts` and `Canvas` to prevent the iOS 16 path from drifting away semantically.

## 8. Recommendation for Consumers

If iOS 16 is an important production platform for a downstream app:

1. test it as an explicit platform target, not a passive compatibility check
2. make deliberate renderer and interaction choices for critical flows

## 9. Conclusion

iOS 16 remains supported, but it should be understood as:

- supported
- regression-sensitive
- not yet the strongest target for architectural simplicity

The next gains on iOS 16 will come from better compatibility isolation, better truth-model convergence, and stronger parity validation.
