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
    }

    // UI state.
    @State var selectedIndex: Int? = 0
    @State var visibleStartMonthIndex: Int = 0
    @State var contentOffsetX: CGFloat = 0
    @State var unitWidth: CGFloat = 0
    @State var viewportWidth: CGFloat = 0

    @State var plotAreaInfo: PlotAreaInfo?
    @State var yTickPositions: [Double: CGFloat] = [:]
}

public extension CombinedChartView {
    var body: some View {
        VStack(spacing: 12) {
            if showDebugOverlay, let visibleStartMonthLabel {
                Text("Visible start month: \(visibleStartMonthIndex) (\(visibleStartMonthLabel))")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Group {
                if hasData {
                    CombinedChartSection(
                        context: sectionContext,
                        selectedIndex: $selectedIndex,
                        visibleStartMonthIndex: $visibleStartMonthIndex,
                        contentOffsetX: $contentOffsetX,
                        unitWidth: $unitWidth,
                        viewportWidth: $viewportWidth,
                        plotAreaInfo: $plotAreaInfo,
                        yTickPositions: $yTickPositions,
                        onSelectIndex: { dispatch(.selectPoint(index: $0)) })
                } else {
                    viewSlots.emptyState
                }
            }

            if hasData, config.pager.isVisible {
                pagerView
            }
        }
        .frame(height: config.chartHeight)
    }
}
