# CombinedChartFramework Roadmap

[简体中文](Roadmap.md) | English

This roadmap defines the repository's next architectural stages.  
It is not a feature wishlist. It is a prioritization plan for turning the current implementation into a sustainable chart framework.

## 1. Current Stage

As of 2026-03-10, the repository already contains:

- a reusable public chart entry point
- layered state and rendering logic
- dual rendering paths
- dual interaction paths
- unit and snapshot tests

But it is still in transition from:

- a single delivered `CombinedChart` implementation

to:

- a reusable multi-chart `ChartKit` platform

## 1.1 End-State Capability Map

According to `Arch.md`, the roadmap must lead to a platform that supports:

- `CombinedChart`
- `LineChart`
- `BarChart`
- `PieChart`
- `AreaChart`
- `CandlestickChart`

and that is structured around:

- `Foundation`
- `Components`
- `SharedUI`
- `Compatibility`

This means every roadmap stage must be judged by one criterion: does it move the repository toward that reusable platform architecture?

## 2. Roadmap Principles

Recommended sequencing:

1. stabilize the foundation before expanding the feature surface
2. converge on single sources of truth before layering more interaction features
3. establish real module boundaries before multiplying chart types
4. stabilize the API before optimizing aesthetics

## 3. Phase One: Foundational Stability

### Goals

- make platform support and build behavior trustworthy
- complete the documentation set
- normalize validation paths

### Focus Areas

- resolve the package platform declaration vs UIKit dependency mismatch
- clarify iOS 16 and iOS 17 default renderer and interaction strategy
- keep docs and public guidance aligned
- restore changelog hygiene

### Exit Criteria

- declared supported platforms build reliably
- docs are publishable and internally consistent
- at least one repeatable test path is stable locally and in CI

## 4. Phase Two: True Modularization

### Goals

Move from folder-level layering to real modular separation.

### Target Module Boundaries

- `Foundation`
- `Components/CombinedChart`
- `Components/LineChart`
- `Components/BarChart`
- `Components/PieChart`
- `SharedUI`
- `Compatibility`

### Focus Areas

- extract paging, selection, range, and math logic into `Foundation`
- move reusable UI such as axis and pager pieces toward `SharedUI`
- isolate UIKit bridges and version-specific behavior into `Compatibility`
- keep chart-specific composition inside `Components/<Chart>`

### Exit Criteria

- shared logic no longer depends on `CombinedChartView` namespacing
- compatibility code no longer leaks directly into all platform paths
- adding a second chart type does not require copying large chunks of component internals

## 5. Phase Three: Renderer Semantics Unification

### Goals

Reduce the long-term cost of maintaining `Charts` and `Canvas`.

### Focus Areas

- define shared upper-layer rendering semantics
- model bar segments, line segments, selection geometry, and axis layout explicitly
- add renderer parity validation
- decide which renderer is primary and which is fallback

### Exit Criteria

- renderer backends share the same semantic inputs
- selection and coordinate logic are not duplicated independently
- parity regressions are easier to detect

## 6. Phase Four: Interaction Convergence

### Goals

Make pager state, visible start, offset, and selection rely on one consistent truth model.

### Focus Areas

- unify viewport state ownership
- define the responsibility split between `startIndex` and `contentOffsetX`
- explicitly classify SwiftUI and UIKit interaction paths
- strengthen diagnostics through `DebugState`

### Exit Criteria

- different interaction implementations produce the same pager outcome
- debug state matches visible content
- fast drag, paging, and tab-switch scenarios stay semantically stable

## 7. Phase Five: Stable Public API

### Goals

Define a reliable public API for 1.0-level consumption.

### Focus Areas

- complete migration away from `viewSlots:`
- document public vs internal types clearly
- formalize deprecation and compatibility expectations
- align README, API notes, and examples

### Exit Criteria

- public entry points are stable
- deprecated APIs have a clear removal path
- internal types stop leaking into public guidance

## 8. Phase Six: Expand to the Multi-Chart Platform

### Goals

Move beyond the current `CombinedChart` delivery into the broader `ChartKit` family.

### Recommended Expansion Order

1. `LineChart`
2. `BarChart`
3. `PieChart`
4. `AreaChart`
5. `CandlestickChart`

Reasoning:

- `LineChart` and `BarChart` have the highest reuse with current cartesian foundations
- `PieChart` is explicitly required by the target architecture and should join the first platform wave
- `AreaChart` can follow once line and fill semantics are mature
- `CandlestickChart` should follow only after the data and range model is stronger

### Exit Criteria

- new chart types reuse foundations instead of bypassing them
- existing chart components do not need to be modified when new ones are added

## 9. Phase Seven: Productization and Scale

### Goals

Make the framework ready for broader production reuse.

### Focus Areas

- large-dataset performance
- downsampling
- accessibility
- theming and design tokens
- package and documentation publishing workflows
- stronger CI release discipline

### Exit Criteria

- the framework is suitable for multiple teams
- performance and accessibility are no longer demo-level concerns

## 10. What Not to Prioritize Yet

Do not make these top priority before the foundations are stable:

- more visual modes inside the current component
- layering more effects without shared abstractions
- adding many new chart types before modularization
- expanding platform support promises before compatibility is real

## 11. Priority Order

If only a few things can be done next, the recommended order is:

1. platform-boundary and build cleanup
2. modularization
3. rendering abstraction unification
4. interaction truth-model convergence
5. API stabilization

## 12. Conclusion

The repository is already worth managing as a framework effort rather than a demo effort.  
But the roadmap must remain disciplined.

The next real value comes from:

1. stability
2. modularization
3. semantic consistency

Only after those three are in place should the platform expand confidently across the full `ChartKit` chart family.
