import Charts
import SwiftUI

extension CombinedChartView {
    // MARK: - Layout

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

    struct ChartDragState {
        let contentOffsetX: CGFloat
        let startIndex: Int
        let monthsPerPage: Int
        let maxStartMonthIndex: Int
        let dragScrollMode: ChartConfig.Pager.DragScrollMode

        private func displayTranslationX(from dragTranslationX: CGFloat) -> CGFloat {
            switch dragScrollMode {
            case .byPage:
                0
            case .freeSnapping, .free:
                dragTranslationX
            }
        }

        private func clampedDragTranslationX(
            from dragTranslationX: CGFloat,
            maxContentOffsetX: CGFloat) -> CGFloat {
            let maxRightDragOffset = contentOffsetX
            let maxLeftDragOffset = max(maxContentOffsetX - contentOffsetX, 0)

            return min(
                max(dragTranslationX, -maxLeftDragOffset),
                maxRightDragOffset)
        }

        func clampedDisplayTranslationX(
            from dragTranslationX: CGFloat,
            maxContentOffsetX: CGFloat) -> CGFloat {
            clampedDragTranslationX(
                from: displayTranslationX(from: dragTranslationX),
                maxContentOffsetX: maxContentOffsetX)
        }

        func currentContentOffsetX(
            dragTranslationX: CGFloat,
            settlingOffsetX: CGFloat,
            maxContentOffsetX: CGFloat) -> CGFloat {
            -contentOffsetX + settlingOffsetX + clampedDisplayTranslationX(
                from: dragTranslationX,
                maxContentOffsetX: maxContentOffsetX)
        }

        func targetOffsetX(
            for rawTranslationX: CGFloat,
            computedUnitWidth: CGFloat,
            computedViewportWidth: CGFloat) -> CGFloat {
            let maxContentOffsetX = CGFloat(maxStartMonthIndex) * computedUnitWidth
            let clampedTranslationX = clampedDragTranslationX(
                from: rawTranslationX,
                maxContentOffsetX: maxContentOffsetX)
            let proposedContentOffsetX = min(
                max(contentOffsetX - clampedTranslationX, 0),
                maxContentOffsetX)

            switch dragScrollMode {
            case .byPage:
                let threshold = computedViewportWidth * 0.2
                let pageDelta: Int = if clampedTranslationX <= -threshold {
                    monthsPerPage
                } else if clampedTranslationX >= threshold {
                    -monthsPerPage
                } else {
                    0
                }
                let targetMonthIndex = min(
                    max(startIndex + pageDelta, 0),
                    maxStartMonthIndex)
                return CGFloat(targetMonthIndex) * computedUnitWidth
            case .freeSnapping:
                let snappedMonthIndex = min(
                    max(Int(round(proposedContentOffsetX / computedUnitWidth)), 0),
                    maxStartMonthIndex)
                return CGFloat(snappedMonthIndex) * computedUnitWidth
            case .free:
                return proposedContentOffsetX
            }
        }

        func targetMonthIndex(
            for targetContentOffsetX: CGFloat,
            computedUnitWidth: CGFloat) -> Int {
            min(
                max(Int(floor(targetContentOffsetX / computedUnitWidth)), 0),
                maxStartMonthIndex)
        }
    }

    // MARK: - Derived State

    struct ChartDerivedState {
        let hasData: Bool
        let axisPointInfos: [ChartConfig.Axis.PointInfo]
        let yDomain: ClosedRange<Double>
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let viewport: ChartViewportDerivedState

        init(
            config: ChartConfig,
            sortedGroups: [ChartDataGroup],
            data: [ChartDataPoint],
            startIndex: Int,
            contentOffsetX: CGFloat,
            unitWidth: CGFloat) {
            hasData = !data.isEmpty
            axisPointInfos = data.enumerated().map { index, point in
                point.axisPointInfo(index: index)
            }

            let minValue = data
                .map { $0.stackedExtents(using: config).min }
                .min() ?? -20
            let maxValue = data
                .map { $0.stackedExtents(using: config).max }
                .max() ?? 20
            let padding = max((maxValue - minValue) * 0.1, 2)
            yDomain = (minValue - padding)...(maxValue + padding)

            let halfRange = max(abs(yDomain.lowerBound), abs(yDomain.upperBound))
            let step = max(ceil(halfRange / 5.0), 1.0)
            yAxisTickValues = (-5...5).map { Double($0) * step }

            if let first = yAxisTickValues.first, let last = yAxisTickValues.last {
                let gridlineInset = max(step * 0.01, 0.001)
                yAxisDisplayDomain = (first - gridlineInset)...(last + gridlineInset)
            } else {
                yAxisDisplayDomain = yDomain
            }

            viewport = .init(
                visibleStartLabel: data.indices.contains(startIndex)
                    ? data[startIndex].xLabel
                    : nil,
                pagerState: .init(
                    sortedGroups: sortedGroups,
                    dataCount: data.count,
                    monthsPerPage: config.monthsPerPage,
                    startIndex: startIndex,
                    contentOffsetX: contentOffsetX,
                    unitWidth: unitWidth))
        }
    }

    // MARK: - Rendering Models

    struct VisibleSelection: Equatable {
        let index: Int
        let pointID: ChartPointID
    }
}
