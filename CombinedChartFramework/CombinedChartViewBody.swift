import SwiftUI

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
