import Charts
import SwiftUI

extension CombinedChartView {
    // MARK: - Selection

    enum SelectionResolver {
        static func nearestIndex(
            to tapLocation: CGPoint,
            candidates: [SelectionCandidate]) -> Int? {
            candidates
                .min { abs($0.xPosition - tapLocation.x) < abs($1.xPosition - tapLocation.x) }?
                .index
        }

        static func resolvedVisibleIndex(
            for selection: VisibleSelection,
            dataPointIDs: [ChartPointID]) -> Int? {
            if dataPointIDs.indices.contains(selection.visibleIndex),
               dataPointIDs[selection.visibleIndex] == selection.pointID {
                return selection.visibleIndex
            }

            return dataPointIDs.firstIndex(of: selection.pointID)
        }

        static func reconciledSelection(
            _ selection: VisibleSelection?,
            dataPointIDs: [ChartPointID]) -> VisibleSelection? {
            guard let selection,
                  let resolvedVisibleIndex = resolvedVisibleIndex(
                      for: selection,
                      dataPointIDs: dataPointIDs)
            else {
                return nil
            }

            return .init(
                visibleIndex: resolvedVisibleIndex,
                pointID: dataPointIDs[resolvedVisibleIndex])
        }
    }

    // MARK: - Line

    enum LineSegmentResolver {
        static func makeSegments(
            points: [ResolvedLinePoint],
            color: (Double) -> Color) -> [LineSegmentPath] {
            guard points.count > 1 else { return [] }
            var segments: [LineSegmentPath] = []

            for index in 0..<(points.count - 1) {
                let start = points[index]
                let end = points[index + 1]

                if isSameSideOrZero(start.value, end.value) {
                    segments.append(
                        LineSegmentPath(
                            path: linePath(from: start.position, to: end.position),
                            color: color(start.value)))
                    continue
                }

                guard let intersection = zeroIntersection(
                    from: start.position,
                    to: end.position,
                    startValue: start.value,
                    endValue: end.value)
                else {
                    continue
                }

                segments.append(
                    LineSegmentPath(
                        path: linePath(from: start.position, to: intersection),
                        color: color(start.value)))
                segments.append(
                    LineSegmentPath(
                        path: linePath(from: intersection, to: end.position),
                        color: color(end.value)))
            }

            return segments
        }

        static func isSameSideOrZero(_ startValue: Double, _ endValue: Double) -> Bool {
            startValue == 0 || endValue == 0 || (startValue >= 0) == (endValue >= 0)
        }

        static func zeroIntersection(
            from start: CGPoint,
            to end: CGPoint,
            startValue: Double,
            endValue: Double) -> CGPoint? {
            let denominator = startValue - endValue
            guard abs(denominator) > 0.000001 else { return nil }
            let interpolationFactor = startValue / denominator
            return CGPoint(
                x: start.x + (end.x - start.x) * interpolationFactor,
                y: start.y + (end.y - start.y) * interpolationFactor)
        }

        static func linePath(from start: CGPoint, to end: CGPoint) -> Path {
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            return path
        }
    }

    // MARK: - Bar

    enum BarSegmentResolver {
        static func gapValue(
            plotAreaHeight: CGFloat,
            yAxisDisplayDomain: ClosedRange<Double>,
            segmentGap: CGFloat) -> Double {
            guard plotAreaHeight > 0 else { return 0 }
            let domainSpan = yAxisDisplayDomain.upperBound - yAxisDisplayDomain.lowerBound
            let points = Double(segmentGap)
            return max(0, (points / Double(plotAreaHeight)) * domainSpan)
        }

        static func adjustedSegmentBounds(start: Double, value: Double) -> (low: Double, high: Double) {
            let end = start + value
            return (min(start, end), max(start, end))
        }

        static func makeSegments(
            for point: ChartDataPoint,
            series: [ChartConfig.ChartBarConfig.ChartSeriesStyle],
            useTrendBarColor: Bool,
            trendBarColorStyle: ChartConfig.ChartBarConfig.TrendBarColorStyle) -> [BarSegment] {
            var positiveStart: Double = 0
            var negativeStart: Double = 0
            var result: [BarSegment] = []

            for seriesStyle in series {
                let value = point.signedValue(for: seriesStyle)
                let color = resolveColor(
                    seriesColor: seriesStyle.color,
                    useTrendBarColor: useTrendBarColor,
                    trendBarColorStyle: trendBarColorStyle)
                if value >= 0 {
                    result.append(BarSegment(start: positiveStart, value: value, color: color))
                    positiveStart += value
                } else {
                    result.append(BarSegment(start: negativeStart, value: value, color: color))
                    negativeStart += value
                }
            }

            return result
        }

        static func resolveColor(
            seriesColor: Color,
            useTrendBarColor: Bool,
            trendBarColorStyle: ChartConfig.ChartBarConfig.TrendBarColorStyle) -> Color {
            guard useTrendBarColor else { return seriesColor }

            switch trendBarColorStyle {
            case .seriesColor:
                return seriesColor
            case .unified(let color):
                return color
            }
        }
    }

    struct SelectionCandidate {
        let index: Int
        let xPosition: CGFloat
    }

    struct ResolvedLinePoint {
        let position: CGPoint
        let value: Double
    }
}
