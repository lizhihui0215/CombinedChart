import SwiftUI

extension CombinedChartView {
    // MARK: - Selection

    struct XPositionRequest {
        let dataCount: Int
        let xPosition: (Int) -> CGFloat?
    }

    struct XPositionDescriptor: Equatable {
        let index: Int
        let xPosition: CGFloat
    }

    struct SelectionHitRequest {
        let dataCount: Int
        let minimumHitWidth: CGFloat
        let fallbackWidth: CGFloat
        let xPositions: [XPositionDescriptor]
    }

    struct SelectionHitDescriptor: Equatable {
        let index: Int
        let xPosition: CGFloat
        let hitWidth: CGFloat

        var hitRange: ClosedRange<CGFloat> {
            (xPosition - (hitWidth / 2))...(xPosition + (hitWidth / 2))
        }
    }

    struct SelectionOverlayRequest {
        let visibleSelection: VisibleSelection?
        let data: [ChartDataPoint]
        let config: ChartConfig
        let indicatorStyle: ChartPresentationMode.SelectionIndicatorStyle
        let plotRect: CGRect
        let minimumSelectionWidth: CGFloat
        let fallbackWidth: CGFloat
        let xPositions: [XPositionDescriptor]
        let yPosition: (Double) -> CGFloat?
    }

    enum XPositionResolver {
        static func descriptors(_ request: XPositionRequest) -> [XPositionDescriptor] {
            (0..<request.dataCount).compactMap { index in
                guard let xPosition = request.xPosition(index) else { return nil }
                return .init(index: index, xPosition: xPosition)
            }
        }

        static func xPosition(for index: Int, in descriptors: [XPositionDescriptor]) -> CGFloat? {
            descriptors.first(where: { $0.index == index })?.xPosition
        }
    }

    enum SelectionHitResolver {
        static func descriptors(_ request: SelectionHitRequest) -> [SelectionHitDescriptor] {
            request.xPositions.compactMap { descriptor in
                let hitWidth = SelectionLayoutResolver.highlightWidth(
                    at: descriptor.index,
                    dataCount: request.dataCount,
                    xCoordinate: descriptor.xPosition,
                    minimumSelectionWidth: request.minimumHitWidth,
                    fallbackWidth: request.fallbackWidth,
                    xPositions: request.xPositions)

                return .init(
                    index: descriptor.index,
                    xPosition: descriptor.xPosition,
                    hitWidth: hitWidth)
            }
        }

        static func resolveIndex(
            at tapLocation: CGPoint,
            request: SelectionHitRequest) -> Int? {
            let descriptors = descriptors(request)
            let containedDescriptors = descriptors.filter { $0.hitRange.contains(tapLocation.x) }
            let activeDescriptors = containedDescriptors.isEmpty ? descriptors : containedDescriptors

            return activeDescriptors.min {
                abs($0.xPosition - tapLocation.x) < abs($1.xPosition - tapLocation.x)
            }?.index
        }
    }

    enum SelectionResolver {
        static func resolvedIndex(
            forDomainXValue domainXValue: Double,
            dataCount: Int) -> Int? {
            guard dataCount > 0, domainXValue.isFinite else { return nil }

            let roundedIndex = Int(domainXValue.rounded())
            return min(max(roundedIndex, 0), dataCount - 1)
        }

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

    enum SelectionLayoutResolver {
        static func candidates(
            dataCount: Int,
            xPosition: (Int) -> CGFloat?) -> [(index: Int, xPosition: CGFloat)] {
            (0..<dataCount).compactMap { index in
                guard let xPosition = xPosition(index) else { return nil }
                return (index: index, xPosition: xPosition)
            }
        }

        static func selectionState(
            for visibleSelection: VisibleSelection?,
            data: [ChartDataPoint],
            config: ChartConfig,
            xPositions: [XPositionDescriptor]) -> SelectionState? {
            guard let visibleSelection,
                  let resolvedIndex = SelectionResolver.resolvedVisibleIndex(
                      for: visibleSelection,
                      dataPointIDs: data.map(\.id)),
                  let resolvedXPosition = XPositionResolver.xPosition(for: resolvedIndex, in: xPositions)
            else {
                return nil
            }

            let point = data[resolvedIndex]
            let value = point.trendLineValue(using: config)
            return .init(
                point: point,
                index: resolvedIndex,
                value: value,
                xPosition: resolvedXPosition)
        }

        static func layout(
            for selectionState: SelectionState,
            dataCount: Int,
            indicatorStyle: ChartPresentationMode.SelectionIndicatorStyle,
            plotRect: CGRect,
            minimumSelectionWidth: CGFloat,
            fallbackWidth: CGFloat,
            xPositions: [XPositionDescriptor]) -> SelectionLayout {
            let highlightWidth = highlightWidth(
                at: selectionState.index,
                dataCount: dataCount,
                xCoordinate: selectionState.xPosition,
                minimumSelectionWidth: minimumSelectionWidth,
                fallbackWidth: fallbackWidth,
                xPositions: xPositions)
            let indicatorFrame = switch indicatorStyle {
            case .line:
                CGRect(
                    x: selectionState.xPosition,
                    y: plotRect.minY,
                    width: 0,
                    height: plotRect.height)
            case .band:
                CGRect(
                    x: selectionState.xPosition - (highlightWidth / 2),
                    y: plotRect.minY,
                    width: highlightWidth,
                    height: plotRect.height)
            }

            return .init(
                highlightWidth: highlightWidth,
                indicatorFrame: indicatorFrame)
        }

        static func highlightWidth(
            at index: Int,
            dataCount: Int,
            xCoordinate: CGFloat,
            minimumSelectionWidth: CGFloat,
            fallbackWidth: CGFloat,
            xPositions: [XPositionDescriptor]) -> CGFloat {
            let step: CGFloat = {
                if index + 1 < dataCount,
                   let nextXPosition = XPositionResolver.xPosition(for: index + 1, in: xPositions) {
                    return abs(nextXPosition - xCoordinate)
                }
                if index - 1 >= 0,
                   let previousXPosition = XPositionResolver.xPosition(for: index - 1, in: xPositions) {
                    return abs(xCoordinate - previousXPosition)
                }
                return fallbackWidth
            }()

            return max(step * 0.9, minimumSelectionWidth)
        }
    }

    enum SelectionOverlayResolver {
        static func resolve(_ request: SelectionOverlayRequest) -> SelectionOverlayState? {
            guard let selectionState = SelectionLayoutResolver.selectionState(
                for: request.visibleSelection,
                data: request.data,
                config: request.config,
                xPositions: request.xPositions)
            else {
                return nil
            }

            let layout = SelectionLayoutResolver.layout(
                for: selectionState,
                dataCount: request.data.count,
                indicatorStyle: request.indicatorStyle,
                plotRect: request.plotRect,
                minimumSelectionWidth: request.minimumSelectionWidth,
                fallbackWidth: request.fallbackWidth,
                xPositions: request.xPositions)
            let context = SelectionOverlayContext(
                point: selectionState.point.source,
                value: selectionState.value,
                plotFrame: request.plotRect,
                indicatorFrame: layout.indicatorFrame,
                indicatorStyle: request.indicatorStyle)
            let pointCenter = request.yPosition(selectionState.value).map {
                CGPoint(x: selectionState.xPosition, y: $0)
            }

            return .init(
                selectionState: selectionState,
                layout: layout,
                context: context,
                pointCenter: pointCenter)
        }
    }

    enum DebugGuideResolver {
        static func pointGuideXPositions(xPositions: [XPositionDescriptor]) -> [CGFloat] {
            xPositions.map(\.xPosition)
        }

        static func thresholdGuideXPositions(
            unitWidth: CGFloat,
            visibleStartThreshold: CGFloat,
            xPositions: [XPositionDescriptor]) -> [CGFloat] {
            pointGuideXPositions(xPositions: xPositions)
                .map { $0 + (unitWidth * (visibleStartThreshold - 0.5)) }
        }
    }

    // MARK: - Line

    struct TrendLineRequest {
        let data: [ChartDataPoint]
        let config: ChartConfig
        let xPositions: [XPositionDescriptor]
        let yPosition: (Double) -> CGFloat?
    }

    struct TrendLinePointDescriptor {
        let point: ChartDataPoint
        let index: Int
        let value: Double
        let position: CGPoint
    }

    enum TrendLineResolver {
        static func pointDescriptors(_ request: TrendLineRequest) -> [TrendLinePointDescriptor] {
            request.data.enumerated().compactMap { index, point in
                let value = point.trendLineValue(using: request.config)
                guard let xPosition = XPositionResolver.xPosition(for: index, in: request.xPositions),
                      let yPosition = request.yPosition(value)
                else {
                    return nil
                }

                return .init(
                    point: point,
                    index: index,
                    value: value,
                    position: CGPoint(x: xPosition, y: yPosition))
            }
        }

        static func segments(
            _ request: TrendLineRequest,
            color: (Double) -> Color) -> [LineSegmentPath] {
            let points = pointDescriptors(request).map { descriptor in
                (position: descriptor.position, value: descriptor.value)
            }

            return LineSegmentResolver.makeSegments(
                points: points,
                style: request.config.line.lineType,
                color: color)
        }
    }

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
