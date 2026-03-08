import SwiftUI

extension CombinedChartView {
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

        func makeYAxisLabelsContext(
            yAxisTickValues: [Double],
            labelText: @escaping (Double) -> String) -> YAxisLabelsContext {
            .init(
                yAxisTickValues: yAxisTickValues,
                tickPositions: yTickPositions,
                plotAreaMinY: plotAreaMinY,
                plotAreaHeight: plotAreaHeight,
                labelText: labelText)
        }
    }

    struct VisibleSelection: Equatable {
        let index: Int
        let pointID: ChartPointID
    }
}
