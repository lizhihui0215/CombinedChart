import Charts
import SwiftUI

extension CombinedChartView {
    struct ChartRenderContext {
        let selectedTab: ChartTab
        let visibleData: [ChartDataPoint]
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let plotAreaHeight: CGFloat
        let unitWidth: CGFloat
        let config: ChartConfig
        let showDebugOverlay: Bool
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        let visibleSelection: VisibleSelection?
    }

    struct AxisRenderContext {
        let monthValues: [String]
        let pointInfos: [ChartConfig.Axis.PointInfo]
        let pointInfoByKey: [String: ChartConfig.Axis.PointInfo]
    }

    struct MarksRenderContext {
        let selectedTab: ChartTab
        let visibleData: [ChartDataPoint]
        let yAxisDisplayDomain: ClosedRange<Double>
        let plotAreaHeight: CGFloat
        let config: ChartConfig
        let showDebugOverlay: Bool
        let visibleSelection: VisibleSelection?
    }

    struct OverlayRenderContext {
        let selectedTab: ChartTab
        let visibleData: [ChartDataPoint]
        let yAxisTickValues: [Double]
        let unitWidth: CGFloat
        let config: ChartConfig
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        let visibleSelection: VisibleSelection?
    }

    struct BarSegment {
        let start: Double
        let value: Double
        let color: Color
    }

    struct LineSegmentPath: Identifiable {
        let id: String
        let path: Path
        let color: Color
    }
}
