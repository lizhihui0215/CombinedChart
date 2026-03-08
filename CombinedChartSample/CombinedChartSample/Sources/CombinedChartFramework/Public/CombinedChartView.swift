import SwiftUI

public struct CombinedChartView: View {
    let config: Config
    let groups: [DataGroup]
    let tabs: [Tab]
    let slots: Slots
    let onPointTap: ((Selection) -> Void)?
    @Binding var selectedTab: Tab
    @Binding var showDebugOverlay: Bool

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
        _visibleSelection = State(
            initialValue: groups.first?.points.first.map {
                .init(
                    index: 0,
                    pointID: $0.id)
            })
    }

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
}
