import SwiftUI

/// A reusable combined bar-and-line chart view.
///
/// Use ``CombinedChartView`` as the primary entry point to render grouped chart data,
/// configure presentation, and provide custom slot content such as an empty state,
/// selection overlay, or pager UI.
///
/// The view manages paging, selection, and chart interaction internally. Most callers
/// only need to provide a configuration, the input groups, and an optional selected tab binding.
///
/// Example:
/// ```swift
/// CombinedChartView(
///     config: .default,
///     groups: groups,
///     selectedTab: $selectedTab,
///     slots: .init {
///         Text("No chart data")
///     }
/// )
/// ```
public struct CombinedChartView: View {
    let config: Config
    let groups: [DataGroup]
    let tabs: [Tab]
    let slots: Slots
    let onPointTap: ((Selection) -> Void)?
    @Binding var selectedTab: Tab
    @Binding var showDebugOverlay: Bool

    /// Creates a combined chart view using the preferred public API surface.
    ///
    /// Use this initializer for new call sites. It accepts the view-scoped shorthand
    /// types defined under ``CombinedChartView``, such as ``CombinedChartView/Config``,
    /// ``CombinedChartView/DataGroup``, and ``CombinedChartView/Slots``.
    ///
    /// - Parameters:
    ///   - config: Visual and interaction configuration for the chart.
    ///   - groups: The grouped data rendered by the chart.
    ///   - tabs: Presentation modes the user can switch between.
    ///   - selectedTab: The currently selected tab.
    ///   - showDebugOverlay: A binding that controls whether internal debug overlays are visible.
    ///   - slots: Optional custom content for empty state, selection overlay, and pager rendering.
    ///   - onPointTap: A callback invoked when the user selects a resolved chart point.
    public init(
        config: Config = .default,
        groups: [DataGroup],
        tabs: [Tab] = Tab.defaults,
        selectedTab: Binding<Tab> = .constant(.totalTrend),
        showDebugOverlay: Binding<Bool> = .constant(false),
        slots: Slots = .default,
        onPointTap: ((Selection) -> Void)? = nil) {
        self.config = config
        self.groups = groups
        self.tabs = tabs
        self.slots = slots
        self.onPointTap = onPointTap
        _selectedTab = selectedTab
        _showDebugOverlay = showDebugOverlay
        _preparedData = State(initialValue: PreparedData.make(from: groups))
        _visibleSelection = State(
            initialValue: groups.first?.points.first.map {
                .init(
                    index: 0,
                    pointID: $0.id)
            })
    }

    /// Creates a combined chart view using the legacy `viewSlots` label.
    ///
    /// This initializer remains available for source compatibility. Prefer the
    /// ``init(config:groups:tabs:selectedTab:showDebugOverlay:slots:onPointTap:)``
    /// overload for new code.
    ///
    /// - Parameters:
    ///   - config: Visual and interaction configuration for the chart.
    ///   - groups: The grouped data rendered by the chart.
    ///   - tabs: Presentation modes the user can switch between.
    ///   - selectedTab: The currently selected tab.
    ///   - showDebugOverlay: A binding that controls whether internal debug overlays are visible.
    ///   - viewSlots: Optional custom content for empty state, selection overlay, and pager rendering.
    ///   - onPointTap: A callback invoked when the user selects a resolved chart point.
    @available(*, deprecated, renamed: "init(config:groups:tabs:selectedTab:showDebugOverlay:slots:onPointTap:)")
    public init(
        config: Config = .default,
        groups: [DataGroup],
        tabs: [Tab] = Tab.defaults,
        selectedTab: Binding<Tab> = .constant(.totalTrend),
        showDebugOverlay: Binding<Bool> = .constant(false),
        viewSlots: Slots,
        onPointTap: ((Selection) -> Void)? = nil) {
        self.init(
            config: config,
            groups: groups,
            tabs: tabs,
            selectedTab: selectedTab,
            showDebugOverlay: showDebugOverlay,
            slots: viewSlots,
            onPointTap: onPointTap)
    }

    // UI state.
    @State var visibleSelection: VisibleSelection?
    @State var viewportState: ViewportState = .init(
        startIndex: 0,
        contentOffsetX: 0)
    @State var layoutState: LayoutState = .empty
    @State var plotSyncState: PlotSyncState = .empty
    @State var preparedData: PreparedData

    public var body: some View {
        let snapshot = orchestrationSnapshot
        let visibleStartLabel = snapshot.visibleStartLabel
        let hasData = snapshot.hasData
        let axisPointInfos = snapshot.axisPointInfos
        let sectionContext = makeSectionContext(
            snapshot: snapshot,
            axisPointInfos: axisPointInfos)
        let pagerContext = snapshot.makePagerContext(dispatch: dispatch)

        VStack(spacing: 12) {
            if showDebugOverlay, let visibleStartLabel {
                Text("Visible start index: \(viewportState.startIndex) (\(visibleStartLabel))")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Group {
                if hasData {
                    CombinedChartSection(
                        context: sectionContext,
                        visibleSelection: visibleSelection,
                        viewportState: $viewportState,
                        layoutState: $layoutState,
                        plotSyncState: $plotSyncState,
                        onDispatchAction: dispatch)
                } else {
                    slots.emptyState
                }
            }

            if hasData, config.pager.isVisible, let pagerContext {
                pagerView(context: pagerContext)
            }
        }
        .frame(height: config.chartHeight)
        .onChange(of: groupsFingerprint) { _ in
            preparedData = PreparedData.make(from: groups)
        }
    }

    var groupsFingerprint: Int {
        var hasher = Hasher()

        for group in groups {
            hasher.combine(group.id)
            hasher.combine(group.groupOrder)
            hasher.combine(group.points.count)

            for point in group.points {
                hasher.combine(point.id)
                hasher.combine(point.xLabel)
                hasher.combine(point.values.count)
            }
        }

        return hasher.finalize()
    }
}
