import SwiftUI

public struct CombinedChartView: View {
    let config: ChartConfig
    let groups: [ChartGroup]
    let tabs: [ChartTab]
    let viewSlots: ViewSlots
    let onPointTap: ((SelectionContext) -> Void)?
    @Binding var selectedTab: ChartTab
    @Binding var showDebugOverlay: Bool

    public init(
        config: ChartConfig = .default,
        groups: [ChartGroup],
        tabs: [ChartTab] = ChartTab.defaults,
        selectedTab: Binding<ChartTab> = .constant(.totalTrend),
        showDebugOverlay: Binding<Bool> = .constant(false),
        viewSlots: ViewSlots = .default,
        onPointTap: ((SelectionContext) -> Void)? = nil) {
        self.config = config
        self.groups = groups
        self.tabs = tabs
        self.viewSlots = viewSlots
        self.onPointTap = onPointTap
        _selectedTab = selectedTab
        _showDebugOverlay = showDebugOverlay
        _visibleSelection = State(
            initialValue: groups.first?.points.first.map {
                .init(
                    visibleIndex: 0,
                    pointID: $0.id)
            })
    }

    // UI state.
    @State var visibleSelection: VisibleSelection?
    @State var viewportState: ViewportState = .init(
        visibleStartMonthIndex: 0,
        contentOffsetX: 0)
    @State var layoutState: LayoutState = .empty

    @State var plotAreaInfo: PlotAreaInfo?
    @State var yTickPositions: [Double: CGFloat] = [:]
}
