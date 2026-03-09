import SwiftUI

extension CombinedChartView {
    struct SectionContext {
        let config: ChartConfig
        let selectedTab: ChartTab
        let data: [ChartDataPoint]
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let showDebugOverlay: Bool
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        let pagingContext: PagingContext
        let yAxisLabel: (Double) -> String

        func makeYAxisLabelsContext(
            plotSyncState: PlotSyncState) -> YAxisLabelsContext {
            plotSyncState.makeYAxisLabelsContext(
                yAxisTickValues: yAxisTickValues,
                labelText: yAxisLabel,
                labelFont: config.axis.yAxisLabelFont,
                labelColor: config.axis.yAxisLabelColor)
        }

        func makeRenderContext(
            plotAreaHeight: CGFloat,
            unitWidth: CGFloat,
            visibleSelection: VisibleSelection?) -> RenderContext {
            .init(
                selectedTab: selectedTab,
                visibleData: data,
                yAxisTickValues: yAxisTickValues,
                yAxisDisplayDomain: yAxisDisplayDomain,
                plotAreaHeight: plotAreaHeight,
                unitWidth: unitWidth,
                config: config,
                showDebugOverlay: showDebugOverlay,
                selectionOverlay: selectionOverlay,
                visibleSelection: visibleSelection)
        }
    }
}
