import SwiftUI

extension CombinedChartView {
    struct RenderContext {
        let selectedTab: ChartTab
        let visibleData: [ChartDataPoint]
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let plotAreaHeight: CGFloat
        let viewport: ViewportDescriptor
        let config: ChartConfig
        let showDebugOverlay: Bool
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        let visibleSelection: VisibleSelection?

        var unitWidth: CGFloat {
            viewport.unitWidth
        }
    }

    struct XAxisLabelDescriptor: Identifiable {
        let id: String
        let index: Int
        let xValue: Double
        let text: String
    }

    struct AxisPresentationDescriptor {
        let xLabels: [XAxisLabelDescriptor]
        let xDomain: ClosedRange<Double>
        let yGridValues: [Double]

        var xValues: [Double] {
            xLabels.map(\.xValue)
        }

        var dataCount: Int {
            xLabels.count
        }

        private var xLabelByIndex: [Int: XAxisLabelDescriptor] {
            Dictionary(uniqueKeysWithValues: xLabels.map { ($0.index, $0) })
        }

        func xLabel(forXValue xValue: Double) -> XAxisLabelDescriptor? {
            guard !xLabels.isEmpty else { return nil }
            let resolvedIndex = min(max(Int(xValue.rounded()), 0), max(xLabels.count - 1, 0))
            return xLabelByIndex[resolvedIndex]
        }

        func yGridPositions(in plotFrame: PlotFrameDescriptor) -> [CGFloat] {
            yGridValues.compactMap { plotFrame.yAxisTickPositions[$0] }
        }
    }

    struct BarMarkPresentationDescriptor: Identifiable {
        let id: String
        let xIndex: Int
        let xValue: Double
        let start: Double
        let end: Double
        let color: Color
        let width: CGFloat
        let kind: CombinedChartView.Renderer.BarMarkItem.Kind
    }

    struct RuleMarkPresentationDescriptor: Identifiable {
        let id: String
        let value: Double
        let color: Color
        let lineWidth: CGFloat
    }

    struct PointMarkPresentationDescriptor: Identifiable {
        let id: String
        let index: Int
        let xValue: Double
        let value: Double
        let color: Color
        let pointSize: CGFloat

        var symbolSize: CGFloat {
            pow(pointSize, 2)
        }
    }

    struct TrendLineStylePresentationDescriptor {
        let width: CGFloat
    }

    struct MarksPresentationDescriptor {
        let barMarks: [BarMarkPresentationDescriptor]
        let ruleMarks: [RuleMarkPresentationDescriptor]
        let pointMarks: [PointMarkPresentationDescriptor]
        let fallbackBarWidth: CGFloat
        let trendLineStyle: TrendLineStylePresentationDescriptor?

        var showsBarMarks: Bool {
            !barMarks.isEmpty
        }
    }

    struct ChartPresentationDescriptor {
        let axis: AxisPresentationDescriptor
        let marks: MarksPresentationDescriptor
    }

    struct MarksContext {
        let selectedTab: ChartTab
        let visibleData: [ChartDataPoint]
        let yAxisDisplayDomain: ClosedRange<Double>
        let plotAreaHeight: CGFloat
        let config: ChartConfig
        let showDebugOverlay: Bool
        let visibleSelection: VisibleSelection?
    }

    struct OverlayContext {
        let selectedTab: ChartTab
        let visibleData: [ChartDataPoint]
        let yAxisTickValues: [Double]
        let viewport: ViewportDescriptor
        let config: ChartConfig
        let selectionOverlay: ((SelectionOverlayContext) -> AnyView)?
        let visibleSelection: VisibleSelection?

        var unitWidth: CGFloat {
            viewport.unitWidth
        }
    }

    struct SelectionPresentationDescriptor {
        enum Mode: Equatable {
            case none
            case defaultOverlay
            case customOverlay
        }

        let mode: Mode
        let overlayState: SelectionOverlayState?
        let indicatorLineColor: Color?
        let indicatorFillColor: Color?

        var context: SelectionOverlayContext? {
            overlayState?.context
        }

        var selectionState: SelectionState? {
            overlayState?.selectionState
        }

        var indicatorFrame: CGRect? {
            overlayState?.layout.indicatorFrame
        }

        var pointCenter: CGPoint? {
            overlayState?.pointCenter
        }

        var showsOverlay: Bool {
            overlayState != nil
        }

        var showsDefaultOverlay: Bool {
            mode == .defaultOverlay && overlayState != nil
        }

        var showsCustomOverlay: Bool {
            mode == .customOverlay && overlayState != nil
        }

        var lineIndicatorX: CGFloat? {
            guard showsDefaultOverlay, context?.indicatorStyle == .line else { return nil }
            return indicatorFrame?.midX
        }

        var bandIndicatorFrame: CGRect? {
            guard showsDefaultOverlay, context?.indicatorStyle == .band else { return nil }
            return indicatorFrame
        }
    }

    struct LineMarkPresentationDescriptor: Identifiable {
        let id: String
        let segments: [LineSegmentPath]
        let lineWidth: CGFloat

        var showsLine: Bool {
            !segments.isEmpty
        }
    }

    struct GuideMarkPresentationDescriptor: Identifiable {
        enum Kind: String {
            case point
            case threshold
        }

        let id: String
        let kind: Kind
        let xPositions: [CGFloat]
        let color: Color
        let lineWidth: CGFloat
        let dash: [CGFloat]

        var showsGuides: Bool {
            !xPositions.isEmpty
        }
    }

    struct OverlayPresentationDescriptor {
        let lineMarks: [LineMarkPresentationDescriptor]
        let selection: SelectionPresentationDescriptor
        let guideMarks: [GuideMarkPresentationDescriptor]

        var showsTrendLine: Bool {
            lineMarks.contains { $0.showsLine }
        }

        var showsDebugGuides: Bool {
            guideMarks.contains { $0.showsGuides }
        }
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
