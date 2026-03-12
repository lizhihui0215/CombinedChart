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

        func makeYAxisDescriptor(
            plotSyncState: PlotSyncState) -> YAxisDescriptor {
            plotSyncState.makeYAxisDescriptor(labelWidth: config.axis.yAxisWidth)
        }

        func makeYAxisLabelsContext(
            plotSyncState: PlotSyncState,
            yAxisDescriptor: YAxisDescriptor? = nil) -> YAxisLabelsContext {
            plotSyncState.makeYAxisLabelsContext(
                yAxisTickValues: yAxisTickValues,
                labelText: yAxisLabel,
                yAxisDescriptor: yAxisDescriptor,
                labelWidth: config.axis.yAxisWidth,
                labelFont: config.axis.yAxisLabelFont,
                labelColor: config.axis.yAxisLabelColor)
        }

        func makeRenderContext(
            plotAreaHeight: CGFloat,
            viewport: ViewportDescriptor,
            visibleSelection: VisibleSelection?) -> RenderContext {
            .init(
                selectedTab: selectedTab,
                visibleData: data,
                yAxisTickValues: yAxisTickValues,
                yAxisDisplayDomain: yAxisDisplayDomain,
                plotAreaHeight: plotAreaHeight,
                viewport: viewport,
                config: config,
                showDebugOverlay: showDebugOverlay,
                selectionOverlay: selectionOverlay,
                visibleSelection: visibleSelection)
        }
    }
}
