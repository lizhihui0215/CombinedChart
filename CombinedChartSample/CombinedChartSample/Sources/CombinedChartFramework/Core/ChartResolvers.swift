import Charts
import SwiftUI

extension CombinedChartView {
    // MARK: - Selection

    enum SelectionResolver {
        static func nearestIndex(
            to tapLocation: CGPoint,
            candidates: [(index: Int, xPosition: CGFloat)]) -> Int? {
            candidates
                .min { abs($0.xPosition - tapLocation.x) < abs($1.xPosition - tapLocation.x) }?
                .index
        }

        static func resolvedVisibleIndex(
            for selection: VisibleSelection,
            dataPointIDs: [ChartPointID]) -> Int? {
            if dataPointIDs.indices.contains(selection.index),
               dataPointIDs[selection.index] == selection.pointID {
                return selection.index
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
                index: resolvedVisibleIndex,
                pointID: dataPointIDs[resolvedVisibleIndex])
        }
    }

    // MARK: - Line

    enum LineSegmentResolver {
        static func makeSegments(
            points: [(position: CGPoint, value: Double)],
            style: ChartConfig.Line.LineType,
            color: (Double) -> Color) -> [LineSegmentPath] {
            guard points.count > 1 else { return [] }
            let contiguousSegments = makeContiguousSegments(points: points)

            return contiguousSegments.enumerated().map { index, segment in
                LineSegmentPath(
                    id: "\(index)-segment",
                    path: path(for: segment.points, style: style),
                    color: color(segment.value))
            }
        }

        private static func makeContiguousSegments(
            points: [(position: CGPoint, value: Double)]) -> [(points: [CGPoint], value: Double)] {
            var segments: [(points: [CGPoint], value: Double)] = []

            for index in 0..<(points.count - 1) {
                let start = points[index]
                let end = points[index + 1]

                if isSameSideOrZero(start.value, end.value) {
                    append(point: start.position, value: start.value, to: &segments)
                    append(point: end.position, value: start.value, to: &segments)
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

                append(point: start.position, value: start.value, to: &segments)
                append(point: intersection, value: start.value, to: &segments)
                append(point: intersection, value: end.value, to: &segments)
                append(point: end.position, value: end.value, to: &segments)
            }

            return segments.filter { $0.points.count > 1 }
        }

        private static func append(
            point: CGPoint,
            value: Double,
            to segments: inout [(points: [CGPoint], value: Double)]) {
            if let lastIndex = segments.indices.last,
               isSameSideOrZero(segments[lastIndex].value, value) {
                if segments[lastIndex].points.last != point {
                    segments[lastIndex].points.append(point)
                }
            } else {
                segments.append((points: [point], value: value))
            }
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

        private static func path(
            for points: [CGPoint],
            style: ChartConfig.Line.LineType) -> Path {
            switch style {
            case .linear:
                polylinePath(points: points)
            case .smoothed(let tension):
                smoothedPath(points: points, tension: tension)
            }
        }

        private static func polylinePath(points: [CGPoint]) -> Path {
            var path = Path()
            guard let first = points.first else { return path }

            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            return path
        }

        private static func smoothedPath(points: [CGPoint], tension: CGFloat) -> Path {
            guard points.count > 2 else {
                return polylinePath(points: points)
            }

            let clampedTension = max(0, min(tension, 1))
            let factor = clampedTension / 6.0

            var path = Path()
            path.move(to: points[0])

            for index in 0..<(points.count - 1) {
                let previous = index > 0 ? points[index - 1] : points[index]
                let current = points[index]
                let next = points[index + 1]
                let following = index + 2 < points.count ? points[index + 2] : next

                let controlPoint1 = CGPoint(
                    x: current.x + (next.x - previous.x) * factor,
                    y: current.y + (next.y - previous.y) * factor)
                let controlPoint2 = CGPoint(
                    x: next.x - (following.x - current.x) * factor,
                    y: next.y - (following.y - current.y) * factor)

                path.addCurve(to: next, control1: controlPoint1, control2: controlPoint2)
            }

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
            series: [ChartConfig.Bar.SeriesStyle],
            useTrendBarColor: Bool,
            trendBarColorStyle: ChartConfig.Bar.TrendBarColorStyle) -> [BarSegment] {
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
            trendBarColorStyle: ChartConfig.Bar.TrendBarColorStyle) -> Color {
            guard useTrendBarColor else { return seriesColor }

            switch trendBarColorStyle {
            case .seriesColor:
                return seriesColor
            case .unified(let color):
                return color
            }
        }
    }
}
