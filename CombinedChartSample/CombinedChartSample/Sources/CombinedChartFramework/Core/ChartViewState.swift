import SwiftUI

extension CombinedChartView {
    enum Implementation: Equatable {
        case charts
        case canvas
        case uiKit

        static func resolve(config: ChartConfig) -> Self {
            if supportsCharts {
                switch config.rendering.engine {
                case .charts:
                    return .charts
                case .canvas:
                    return resolveLegacyScrollImplementation(config.pager.scrollEngine)
                case .automatic:
                    switch config.pager.scrollEngine {
                    case .automatic:
                        return .charts
                    case .swiftUIGesture, .uiKitScrollView:
                        return resolveLegacyScrollImplementation(config.pager.scrollEngine)
                    }
                }
            }

            return resolveLegacyScrollImplementation(config.pager.scrollEngine)
        }

        var usesImmediatePlotSync: Bool {
            self != .charts
        }

        var scrollImplementationTitle: String {
            switch self {
            case .charts:
                "Apple Charts"
            case .canvas:
                "SwiftUI Gesture"
            case .uiKit:
                "UIKit ScrollView"
            }
        }

        private static func resolveLegacyScrollImplementation(
            _ scrollEngine: ChartConfig.Pager.ScrollEngine) -> Self {
            switch scrollEngine {
            case .uiKitScrollView:
                #if canImport(UIKit)
                return .uiKit
                #else
                return .canvas
                #endif
            case .automatic, .swiftUIGesture:
                return .canvas
            }
        }

        private static var supportsCharts: Bool {
            if #available(iOS 17, *) {
                return true
            }

            return false
        }
    }

    struct LayoutState: Equatable {
        var viewportWidth: CGFloat
        var unitWidth: CGFloat

        static let empty = Self(viewportWidth: 0, unitWidth: 0)

        mutating func update(
            viewportWidth: CGFloat,
            unitWidth: CGFloat) {
            let nextState = Self(
                viewportWidth: viewportWidth,
                unitWidth: unitWidth)
            guard self != nextState else { return }
            self = nextState
        }
    }

    struct PlotSyncState: Equatable {
        var plotAreaMinY: CGFloat?
        var plotAreaHeight: CGFloat
        var yTickPositions: [Double: CGFloat]

        static let empty = Self(plotAreaMinY: nil, plotAreaHeight: 0, yTickPositions: [:])

        mutating func updatePlotArea(with plotRect: CGRect) {
            guard plotAreaMinY != plotRect.minY || plotAreaHeight != plotRect.height else { return }
            plotAreaMinY = plotRect.minY
            plotAreaHeight = plotRect.height
        }

        mutating func updateYAxisTickPositions(_ positions: [Double: CGFloat]) {
            guard yTickPositions != positions else { return }
            yTickPositions = positions
        }

        mutating func update(with descriptor: PlotFrameDescriptor) {
            updatePlotArea(with: descriptor.plotRect)
            updateYAxisTickPositions(descriptor.yAxisTickPositions)
        }

        func makeYAxisLabelsContext(
            yAxisTickValues: [Double],
            labelText: @escaping (Double) -> String,
            yAxisDescriptor: YAxisDescriptor? = nil,
            labelWidth: CGFloat,
            labelFont: Font,
            labelColor: Color) -> YAxisLabelsContext {
            let resolvedYAxisDescriptor = yAxisDescriptor ?? makeYAxisDescriptor(labelWidth: labelWidth)

            return YAxisLabelsContext(
                yAxisTickValues: yAxisTickValues,
                descriptor: resolvedYAxisDescriptor,
                labelText: labelText,
                labelFont: labelFont,
                labelColor: labelColor)
        }

        func makeYAxisDescriptor(
            labelWidth: CGFloat,
            dividerSpacing: CGFloat = 8,
            dividerWidth: CGFloat = 1,
            fallbackPlotAreaHeight: CGFloat = 320) -> YAxisDescriptor {
            .resolve(
                plotAreaMinY: plotAreaMinY,
                plotAreaHeight: plotAreaHeight,
                tickPositions: yTickPositions,
                labelWidth: labelWidth,
                dividerSpacing: dividerSpacing,
                dividerWidth: dividerWidth,
                fallbackPlotAreaHeight: fallbackPlotAreaHeight)
        }
    }

    struct PlotFrameDescriptor: Equatable {
        let plotRect: CGRect
        let yAxisTickPositions: [Double: CGFloat]

        var maskFrame: CGRect {
            plotRect
        }

        var plotAreaMinY: CGFloat {
            plotRect.minY
        }

        var plotAreaHeight: CGFloat {
            plotRect.height
        }

        static func normalized(
            plotRect: CGRect,
            yAxisTickPositions: [Double: CGFloat]) -> Self {
            .init(
                plotRect: CGRect(
                    x: plotRect.minX,
                    y: max(plotRect.minY, 0),
                    width: max(plotRect.width, 0),
                    height: max(plotRect.height, 0)),
                yAxisTickPositions: yAxisTickPositions)
        }
    }

    struct YAxisDescriptor: Equatable {
        let tickPositions: [Double: CGFloat]
        let plotAreaTop: CGFloat
        let plotAreaHeight: CGFloat
        let totalHeight: CGFloat
        let labelWidth: CGFloat
        let dividerX: CGFloat
        let dividerWidth: CGFloat
        let containerWidth: CGFloat

        var dividerFrame: CGRect {
            CGRect(
                x: dividerX,
                y: plotAreaTop,
                width: dividerWidth,
                height: plotAreaHeight)
        }

        static func resolve(
            plotAreaMinY: CGFloat?,
            plotAreaHeight: CGFloat,
            tickPositions: [Double: CGFloat],
            labelWidth: CGFloat,
            dividerSpacing: CGFloat = 8,
            dividerWidth: CGFloat = 1,
            fallbackPlotAreaHeight: CGFloat = 320) -> Self {
            let tickRange = tickPositions.values.min().flatMap { minY in
                tickPositions.values.max().map { maxY in (minY, maxY) }
            }
            let normalizedPlotAreaTop = max(plotAreaMinY ?? tickRange?.0 ?? 0, 0)
            let fallbackHeight = tickRange.map { max($0.1 - $0.0, 0) } ?? fallbackPlotAreaHeight
            let normalizedPlotAreaHeight = max(plotAreaHeight > 0 ? plotAreaHeight : fallbackHeight, 0)
            let totalHeight = max(normalizedPlotAreaTop + normalizedPlotAreaHeight, 0)
            let dividerX = labelWidth + dividerSpacing
            let containerWidth = dividerX + dividerWidth

            return .init(
                tickPositions: tickPositions,
                plotAreaTop: normalizedPlotAreaTop,
                plotAreaHeight: normalizedPlotAreaHeight,
                totalHeight: totalHeight,
                labelWidth: labelWidth,
                dividerX: dividerX,
                dividerWidth: dividerWidth,
                containerWidth: containerWidth)
        }
    }

    struct VisibleSelection: Equatable {
        let index: Int
        let pointID: ChartPointID
    }
}
