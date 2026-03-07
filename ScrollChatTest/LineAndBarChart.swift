//
//  LineAndBarChart.swift
//  ScrollChatTest
//
//  Created by Bernard on 2026/2/13.
//

import Charts
import SwiftUI
import UIKit

// swiftlint:disable file_length
struct ChartConfig {
    let bar: ChartBarConfig
    let line: ChartLineConfig
    let axis: ChartAxisConfig

    static let `default` = ChartConfig(
        bar: ChartBarConfig(
            series: [
                ChartConfig.ChartBarConfig.ChartSeriesStyle(
                    id: "liabilities",
                    label: "Liabilities",
                    color: Color(red: 0.82, green: 0.35, blue: 0.42),
                    isNegative: true,
                    includeInLine: true),
                ChartConfig.ChartBarConfig.ChartSeriesStyle(
                    id: "saving",
                    label: "Saving",
                    color: Color(red: 0.20, green: 0.52, blue: 0.68),
                    isNegative: false,
                    includeInLine: true),
                ChartConfig.ChartBarConfig.ChartSeriesStyle(
                    id: "investment",
                    label: "Investment",
                    color: Color(red: 0.86, green: 0.43, blue: 0.16),
                    isNegative: false,
                    includeInLine: true),
                ChartConfig.ChartBarConfig.ChartSeriesStyle(
                    id: "otherLiquid",
                    label: "Other Liquid",
                    color: Color(red: 0.30, green: 0.67, blue: 0.14),
                    isNegative: false,
                    includeInLine: true),
                ChartConfig.ChartBarConfig.ChartSeriesStyle(
                    id: "otherNonLiquid",
                    label: "Other Non-Liquid",
                    color: Color(red: 0.08, green: 0.28, blue: 0.34),
                    isNegative: false,
                    includeInLine: true)
            ],
            totalTrendColor: Color.gray.opacity(0.45),
            useTotalTrendSingleColor: false,
            segmentGap: 4,
            segmentGapColor: Color(uiColor: .systemBackground)),
        line: ChartLineConfig(
            positiveLineColor: Color(red: 0.16, green: 0.30, blue: 0.38),
            negativeLineColor: Color(red: 0.74, green: 0.24, blue: 0.28),
            lineWidth: 2,
            selection: .init(
                pointSize: 60,
                lineColorStrategy: .fixedLine(Color.gray),
                fillColor: Color.gray.opacity(0.12))),
        axis: ChartAxisConfig(
            xAxisLabel: { $0 },
            yAxisLabel: { value in
                value == 0 ? "0" : "\(Int(value / 1000))K"
            },
            zeroLineColor: .black,
            zeroLineWidth: 1))
}

extension ChartConfig {
    struct ChartBarConfig {
        let series: [ChartSeriesStyle]
        let totalTrendColor: Color
        let useTotalTrendSingleColor: Bool
        let segmentGap: CGFloat
        let segmentGapColor: Color
    }

    struct ChartLineConfig {
        let positiveLineColor: Color
        let negativeLineColor: Color
        let lineWidth: CGFloat
        let selection: SelectionConfig
    }

    struct ChartAxisConfig {
        let xAxisLabel: (String) -> String
        let yAxisLabel: (Double) -> String
        let zeroLineColor: Color
        let zeroLineWidth: CGFloat
    }
}

extension ChartConfig.ChartBarConfig {
    struct ChartSeriesStyle: Identifiable {
        let id: String
        let label: String
        let color: Color
        let isNegative: Bool
        let includeInLine: Bool
    }
}

extension ChartConfig.ChartLineConfig {
    struct SelectionConfig {
        let pointSize: CGFloat
        let lineColorStrategy: LineColorStrategy
        let fillColor: Color
    }

    enum LineColorStrategy {
        case fixedLine(Color)
        case color(positive: Color, negative: Color)
    }
}

struct CombinedChartView<Payload>: View {
    private let config: ChartConfig
    private let onSelect: ((ChartPoint) -> Void)?
    private let groups: [ChartGroup]

    init(config: ChartConfig = .default, groups: [ChartGroup], onSelect: ((ChartPoint) -> Void)? = nil) {
        self.config = config
        self.groups = groups
        self.onSelect = onSelect
    }

    // UI state.
    @State private var selectedTab: ChartTab = .totalTrend
    @State private var selectedIndex: Int? = 0
    @State private var scrollPage: Int = 0
    @State private var showDebugOverlay: Bool = false
    @State private var showAllYearsInPager: Bool = true
    @State private var scrollOffsetX: CGFloat = 0
    @State private var unitWidth: CGFloat = 0
    @State private var viewportWidth: CGFloat = 0

    @State private var plotAreaInfo: PlotAreaInfo?
    @State private var yTickPositions: [Double: CGFloat] = [:]
}

extension CombinedChartView {
    /// Two display modes for the same dataset.
    enum ChartTab: String, CaseIterable, Identifiable {
        case totalTrend = "Total Trend"
        case breakdown = "Breakdown"

        var id: String {
            rawValue
        }
    }

    struct ChartPoint: Identifiable {
        let id = UUID()
        let xKey: String
        let xLabel: String
        let values: [String: Double]
        let payload: Payload
    }

    struct ChartGroup: Identifiable {
        let id: String
        let title: String
        let sortKey: Int
        let points: [ChartPoint]
    }

    struct YearPageRange: Identifiable {
        var id: String {
            title
        }

        let title: String
        let sortKey: Int
        let startMonthIndex: Int
        let endMonthIndex: Int
        let startPage: Int
        let endPage: Int

        func contains(page: Int) -> Bool {
            page >= startPage && page <= endPage
        }
    }

    struct PlotAreaInfo: Equatable {
        let minY: CGFloat
        let height: CGFloat
    }
}

extension CombinedChartView {
    private var sortedGroups: [ChartGroup] {
        groups.sorted { $0.sortKey < $1.sortKey }
    }

    /// Data array for all years, ordered by year ascending.
    private var data: [ChartPoint] {
        sortedGroups.flatMap(\.points)
    }

    private var yearPageRanges: [YearPageRange] {
        var ranges: [YearPageRange] = []
        var cumulativeMonths = 0
        for group in sortedGroups {
            let startMonthIndex = cumulativeMonths
            let endMonthIndex = cumulativeMonths + max(group.points.count - 1, 0)
            let startPage = startMonthIndex / 4
            let endPage = endMonthIndex / 4
            ranges.append(
                YearPageRange(
                    title: group.title,
                    sortKey: group.sortKey,
                    startMonthIndex: startMonthIndex,
                    endMonthIndex: endMonthIndex,
                    startPage: startPage,
                    endPage: endPage))
            cumulativeMonths += group.points.count
        }
        return ranges
    }

    private var currentYearRange: YearPageRange? {
        yearPageRanges.first { $0.contains(page: scrollPage) } ?? yearPageRanges.first
    }

    private var visibleMonthRange: ClosedRange<Int>? {
        guard unitWidth > 0, viewportWidth > 0, !data.isEmpty else { return nil }
        let offset = max(0, -scrollOffsetX)
        let start = max(0, Int(floor(offset / unitWidth)))
        let visibleCount = max(1, Int(round(viewportWidth / unitWidth)))
        let end = min(data.count - 1, start + visibleCount - 1)
        return start...end
    }

    private var fullyVisibleYearRange: YearPageRange? {
        guard let visibleRange = visibleMonthRange else { return nil }
        return yearPageRanges.first { range in
            range.startMonthIndex <= visibleRange.lowerBound &&
                range.endMonthIndex >= visibleRange.upperBound
        }
    }

    /// Number of 4-month pages for arrow navigation.
    private var maxScrollPage: Int {
        max(0, Int(ceil(Double(max(data.count - 4, 0)) / 4.0)))
    }

    private var hasData: Bool {
        !data.isEmpty
    }

    /// Dynamic Y range to fit all visible bars/line.
    private var yDomain: ClosedRange<Double> {
        let minValue = data
            .map { ChartMath.stackedExtents(for: $0, config: config).min }
            .min() ?? -20
        let maxValue = data
            .map { ChartMath.stackedExtents(for: $0, config: config).max }
            .max() ?? 20
        let padding = max((maxValue - minValue) * 0.1, 2)
        return (minValue - padding)...(maxValue + padding)
    }

    /// Fixed 11 ticks based on the current Y range.
    private var yAxisTickValues: [Double] {
        let halfRange = max(abs(yDomain.lowerBound), abs(yDomain.upperBound))
        let step = max(ceil(halfRange / 5.0), 1.0)
        return (-5...5).map { Double($0) * step }
    }

    /// Use tick extremes for the displayed Y domain so labels/grid align.
    private var yAxisDisplayDomain: ClosedRange<Double> {
        guard let first = yAxisTickValues.first, let last = yAxisTickValues.last else {
            return yDomain
        }
        return first...last
    }

    private func yAxisLabel(for amount: Double) -> String {
        config.axis.yAxisLabel(amount)
    }

    private enum ChartMath {
        static func signedValue(
            for point: ChartPoint,
            series: ChartConfig.ChartBarConfig.ChartSeriesStyle) -> Double {
            let raw = point.values[series.id] ?? 0
            return series.isNegative ? -abs(raw) : raw
        }

        static func lineValue(for point: ChartPoint, config: ChartConfig) -> Double {
            config.bar.series.reduce(0) { partial, series in
                guard series.includeInLine else { return partial }
                let value = signedValue(for: point, series: series)
                return partial + value
            }
        }

        static func stackedExtents(for point: ChartPoint, config: ChartConfig) -> (min: Double, max: Double) {
            var positiveTotal: Double = 0
            var negativeTotal: Double = 0
            for series in config.bar.series {
                let value = signedValue(for: point, series: series)
                if value >= 0 {
                    positiveTotal += value
                } else {
                    negativeTotal += value
                }
            }
            return (negativeTotal, positiveTotal)
        }
    }
}

extension CombinedChartView {
    var body: some View {
        VStack(spacing: 12) {
            tabPicker
            currencyHeader
            debugToggle
            if hasData {
                chartSection
                yearPager
            } else {
                Text("No data")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 420)
            }
        }
        .padding()
    }

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(ChartTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    private var currencyHeader: some View {
        HStack {
            Text("HKD")
                .font(.headline)
            Spacer()
        }
    }

    /// Fixed Y-axis labels aligned to the chart's plot area.
    /// Each label is centered on its corresponding grid line.
    private func yAxisLabels(plotArea: PlotAreaInfo?, tickPositions: [Double: CGFloat]) -> some View {
        let topPadding = plotArea?.minY ?? 12
        let plotHeight = plotArea?.height ?? 320

        return GeometryReader { _ in
            let maxLabelWidth: CGFloat = 44
            ZStack(alignment: .topLeading) {
                ForEach(yAxisTickValues, id: \.self) { value in
                    if let yPos = tickPositions[value] {
                        Text(yAxisLabel(for: value))
                            .font(.caption2)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.trailing)
                            .frame(width: maxLabelWidth, alignment: .trailing)
                            .fixedSize(horizontal: false, vertical: true)
                            .position(x: 0, y: yPos)
                    }
                }
            }
        }
        .frame(height: plotHeight)
        .padding(.top, topPadding)
    }

    private var debugToggle: some View {
        Toggle("Debug axis alignment", isOn: $showDebugOverlay)
            .font(.caption)
            .toggleStyle(SwitchToggleStyle(tint: .gray))
    }

    /// Main chart area: fixed Y labels + horizontally scrollable chart.
    private var chartSection: some View {
        GeometryReader { geometry in
            let visibleCount: CGFloat = 4
            let yAxisWidth: CGFloat = 40
            let computedViewportWidth = max(geometry.size.width - yAxisWidth, 1)
            let computedUnitWidth = computedViewportWidth / visibleCount
            let chartWidth = max(computedViewportWidth, computedUnitWidth * CGFloat(data.count))

            HStack(alignment: .top, spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    yAxisLabels(plotArea: plotAreaInfo, tickPositions: yTickPositions)

                    if let plotAreaInfo {
                        Rectangle()
                            .fill(.black)
                            .frame(width: 1, height: plotAreaInfo.height)
                            .offset(y: plotAreaInfo.minY)
                    }
                }

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(
                                        key: ScrollOffsetKey.self,
                                        value: proxy.frame(in: .named("ChartScroll")).minX)
                            }
                            .frame(width: chartWidth, height: 1, alignment: .topLeading)

                            ChartContainer(
                                selectedTab: selectedTab,
                                visibleData: data,
                                yAxisTickValues: yAxisTickValues,
                                yAxisDisplayDomain: yAxisDisplayDomain,
                                plotAreaHeight: plotAreaInfo?.height ?? 0,
                                config: config,
                                showDebugOverlay: showDebugOverlay,
                                onSelectIndex: { index in
                                    selectedIndex = index
                                    if data.indices.contains(index) {
                                        onSelect?(data[index])
                                    }
                                },
                                onPlotAreaChange: { plotRect in
                                    let info = PlotAreaInfo(minY: plotRect.minY, height: plotRect.height)
                                    if plotAreaInfo != info {
                                        plotAreaInfo = info
                                    }
                                },
                                onYAxisTickPositions: { positions in
                                    if yTickPositions != positions {
                                        yTickPositions = positions
                                    }
                                })
                                .frame(width: chartWidth, height: 420)

                            HStack(spacing: 0) {
                                ForEach(0...maxScrollPage, id: \.self) { page in
                                    Color.clear
                                        .frame(width: computedUnitWidth * 4, height: 1)
                                        .id(page)
                                }
                            }
                        }
                    }
                    .frame(width: computedViewportWidth)
                    .coordinateSpace(name: "ChartScroll")
                    .onPreferenceChange(ScrollOffsetKey.self) { scrollOffsetX = $0 }
                    .onChange(of: scrollPage) { newValue in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(newValue, anchor: .leading)
                        }
                    }
                }
            }
            .onAppear {
                unitWidth = computedUnitWidth
                viewportWidth = computedViewportWidth
            }
            .onChange(of: geometry.size) { _ in
                unitWidth = computedUnitWidth
                viewportWidth = computedViewportWidth
            }
        }
        .frame(height: 420)
    }

    private var yearPager: some View {
        let ranges = yearPageRanges
        let current = fullyVisibleYearRange ?? currentYearRange
        let highlightedTitle = current?.title

        return HStack(spacing: 12) {
            Button {
                let newPage = max(0, scrollPage - 1)
                scrollPage = newPage
                selectedIndex = max(0, newPage * 4)
            } label: {
                Image(systemName: "chevron.left")
            }
            .foregroundStyle(scrollPage > 0 ? .primary : .secondary)
            .disabled(scrollPage == 0)

            Spacer()

            if showAllYearsInPager {
                HStack(spacing: 16) {
                    ForEach(ranges) { range in
                        Text(range.title)
                            .font(.callout.weight(range.title == highlightedTitle ? .semibold : .regular))
                            .foregroundStyle(range.title == highlightedTitle ? .primary : .secondary)
                            .onTapGesture {
                                scrollPage = range.startPage
                                selectedIndex = range.startMonthIndex
                            }
                    }
                }
            } else {
                Text(highlightedTitle ?? "")
                    .font(.callout.weight(.semibold))
            }

            Spacer()

            Button {
                scrollPage = min(maxScrollPage, scrollPage + 1)
                selectedIndex = min(data.count - 1, (scrollPage + 1) * 4)
            } label: {
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(scrollPage < maxScrollPage ? .primary : .secondary)
            .disabled(scrollPage >= maxScrollPage)
        }
        .padding(.horizontal, 8)
    }
}

extension CombinedChartView {
    private struct ChartContainerSegment: Identifiable {
        let id = UUID()
        let start: Double
        let value: Double
        let color: Color
    }

    private struct ChartContainerSegmentBarStyle {
        let gap: Double
        let gapColor: Color
        let drawGapMark: Bool
    }

    private struct ChartContainerLineSegmentPath: Identifiable {
        let id = UUID()
        let path: Path
        let color: Color
    }

    private struct ScrollOffsetKey: PreferenceKey {
        static var defaultValue: CGFloat {
            0
        }

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    /// Encapsulates the Chart to keep SwiftUI type-checking fast.
    private struct ChartContainer: View {
        let selectedTab: ChartTab
        let visibleData: [ChartPoint]
        let yAxisTickValues: [Double]
        let yAxisDisplayDomain: ClosedRange<Double>
        let plotAreaHeight: CGFloat
        let config: ChartConfig
        let showDebugOverlay: Bool
        let onSelectIndex: (Int) -> Void
        let onPlotAreaChange: (CGRect) -> Void
        let onYAxisTickPositions: ([Double: CGFloat]) -> Void
        @State private var selectedIndex: Int?

        private func lineColor(for value: Double) -> Color {
            value >= 0 ? config.line.positiveLineColor : config.line.negativeLineColor
        }

        private func selectionLineColor(for value: Double) -> Color {
            switch config.line.selection.lineColorStrategy {
            case .fixedLine(let color):
                color
            case .color(let positive, let negative):
                value >= 0 ? positive : negative
            }
        }

        private func gapValue() -> Double {
            guard plotAreaHeight > 0 else { return 0 }
            let domainSpan = yAxisDisplayDomain.upperBound - yAxisDisplayDomain.lowerBound
            let points = Double(config.bar.segmentGap)
            return max(0, (points / Double(plotAreaHeight)) * domainSpan)
        }

        /// Build line segments for the overlay so we can color positive and negative parts separately.
        private func lineSegmentPaths(proxy: ChartProxy) -> [ChartContainerLineSegmentPath] {
            guard visibleData.count > 1 else { return [] }
            var segments: [ChartContainerLineSegmentPath] = []

            for index in 0..<(visibleData.count - 1) {
                let start = visibleData[index]
                let end = visibleData[index + 1]
                let startValue = ChartMath.lineValue(for: start, config: config)
                let endValue = ChartMath.lineValue(for: end, config: config)

                // Convert data points into chart-space points. If any position is missing, skip this pair.
                guard let startPoint = linePoint(for: start.xKey, value: startValue, proxy: proxy),
                      let endPoint = linePoint(for: end.xKey, value: endValue, proxy: proxy) else { continue }

                // If both points are on the same side of zero, the segment is single-colored.
                if isSameSideOrZero(startValue, endValue) {
                    segments.append(
                        ChartContainerLineSegmentPath(
                            path: linePath(from: startPoint, to: endPoint),
                            color: lineColor(for: startValue)))
                    continue
                }

                // Crossing zero: split the segment at the exact intersection point.
                if let intersection = zeroIntersection(
                    from: startPoint,
                    to: endPoint,
                    startValue: startValue,
                    endValue: endValue) {
                    segments.append(
                        ChartContainerLineSegmentPath(
                            path: linePath(from: startPoint, to: intersection),
                            color: lineColor(for: startValue)))
                    segments.append(
                        ChartContainerLineSegmentPath(
                            path: linePath(from: intersection, to: endPoint),
                            color: lineColor(for: endValue)))
                }
            }

            return segments
        }

        /// Map a data point into the chart's coordinate space.
        private func linePoint(for xKey: String, value: Double, proxy: ChartProxy) -> CGPoint? {
            guard let xPos = proxy.position(forX: xKey),
                  let yPos = proxy.position(forY: value) else { return nil }
            return CGPoint(x: xPos, y: yPos)
        }

        /// Determine whether two values are on the same side of zero or touch zero.
        private func isSameSideOrZero(_ startValue: Double, _ endValue: Double) -> Bool {
            startValue == 0 || endValue == 0 || (startValue >= 0) == (endValue >= 0)
        }

        /// Compute intersection point with the zero line by linear interpolation.
        private func zeroIntersection(
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

        /// Construct a straight line path between two points.
        private func linePath(from start: CGPoint, to end: CGPoint) -> Path {
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            return path
        }

        private func segments(for point: ChartPoint, useTotalTrendColor: Bool) -> [ChartContainerSegment] {
            var positiveStart: Double = 0
            var negativeStart: Double = 0
            var result: [ChartContainerSegment] = []

            for series in config.bar.series {
                let value = ChartMath.signedValue(for: point, series: series)
                let color = useTotalTrendColor ? config.bar.totalTrendColor : series.color
                if value >= 0 {
                    result.append(ChartContainerSegment(start: positiveStart, value: value, color: color))
                    positiveStart += value
                } else {
                    result.append(ChartContainerSegment(start: negativeStart, value: value, color: color))
                    negativeStart += value
                }
            }

            return result
        }

        var body: some View {
            let monthValues = visibleData.map(\.xKey)
            let monthLabels = Dictionary(uniqueKeysWithValues: visibleData.map { ($0.xKey, $0.xLabel) })

            Chart {
                if selectedTab == .totalTrend {
                    totalTrendMarks
                } else {
                    breakdownMarks
                }
                sharedMarks
            }
            .chartXScale(domain: monthValues)
            .chartXAxis {
                AxisMarks(values: monthValues) { value in
                    AxisValueLabel(centered: true) {
                        if let key = value.as(String.self) {
                            Text(config.axis.xAxisLabel(monthLabels[key] ?? ""))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: yAxisTickValues) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray)
                }
            }
            .chartYScale(domain: yAxisDisplayDomain)
            // Removed top padding to align plot area with fixed Y labels and overlays.
            .chartPlotStyle { plot in
                plot
            }
            // Tap in plot area to select the nearest month index.
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    let plotRect = geometry[proxy.plotAreaFrame]
                    if plotRect.width > 0, plotRect.height > 0 {
                        let currentRect = plotRect
                        Color.clear
                            .onAppear { onPlotAreaChange(currentRect) }
                            .onChange(of: currentRect) { onPlotAreaChange($0) }
                    }
                    if plotRect.width > 0, plotRect.height > 0 {
                        let positions: [Double: CGFloat] = Dictionary(
                            uniqueKeysWithValues: yAxisTickValues.compactMap { value in
                                if let yPos = proxy.position(forY: value) {
                                    return (value, yPos - plotRect.minY)
                                }
                                return nil
                            })
                        Color.clear
                            .onAppear { onYAxisTickPositions(positions) }
                            .onChange(of: positions) { onYAxisTickPositions($0) }
                    }
                    ZStack(alignment: .topLeading) {
                        if selectedTab == .totalTrend {
                            let segments = lineSegmentPaths(proxy: proxy)
                            ForEach(segments) { segment in
                                segment.path
                                    .stroke(
                                        segment.color,
                                        style: StrokeStyle(lineWidth: config.line.lineWidth))
                            }
                            .mask(
                                Rectangle()
                                    .frame(width: plotRect.width, height: plotRect.height)
                                    .position(x: plotRect.midX, y: plotRect.midY))
                        }

                        if let selectedIndex, visibleData.indices.contains(selectedIndex) {
                            let selectedKey = visibleData[selectedIndex].xKey
                            if let xPos = proxy.position(forX: selectedKey) {
                                Group {
                                    if selectedTab == .totalTrend {
                                        let selectedValue = ChartMath.lineValue(
                                            for: visibleData[selectedIndex],
                                            config: config)
                                        Path { path in
                                            path.move(to: CGPoint(x: xPos, y: plotRect.minY))
                                            path.addLine(to: CGPoint(x: xPos, y: plotRect.maxY))
                                        }
                                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                        .foregroundStyle(selectionLineColor(for: selectedValue))
                                    } else {
                                        let step: CGFloat = {
                                            if selectedIndex + 1 < visibleData.count,
                                               let nextX = proxy.position(forX: visibleData[selectedIndex + 1].xKey) {
                                                return nextX - xPos
                                            }
                                            if selectedIndex - 1 >= 0,
                                               let prevX = proxy.position(forX: visibleData[selectedIndex - 1].xKey) {
                                                return xPos - prevX
                                            }
                                            return 40
                                        }()
                                        let width = max(step * 0.9, 24)
                                        Rectangle()
                                            .fill(config.line.selection.fillColor)
                                            .frame(width: width, height: plotRect.height)
                                            .position(x: xPos, y: plotRect.midY)
                                    }
                                }
                                .mask(
                                    Rectangle()
                                        .frame(width: plotRect.width, height: plotRect.height)
                                        .position(x: plotRect.midX, y: plotRect.midY))
                            }
                        }

                        if !visibleData.isEmpty {
                            Color.clear
                                .contentShape(Rectangle())
                                .simultaneousGesture(
                                    SpatialTapGesture()
                                        .onEnded { value in
                                            let localX = value.location.x - plotRect.minX
                                            let clampedX = min(max(localX, 0), plotRect.width)
                                            if let key = proxy.value(atX: clampedX, as: String.self) {
                                                if let index = visibleData.firstIndex(where: { $0.xKey == key }) {
                                                    selectedIndex = index
                                                    onSelectIndex(index)
                                                }
                                            }
                                        })
                        }
                    }
                }
            }
        }

        /// Total Trend: stacked gray bars plus a line on top.
        @ChartContentBuilder
        private var totalTrendMarks: some ChartContent {
            ForEach(Array(visibleData.enumerated()), id: \.element.id) { index, item in
                let gap = gapValue()
                let style = ChartContainerSegmentBarStyle(
                    gap: gap,
                    gapColor: config.bar.segmentGapColor,
                    drawGapMark: true)
                ForEach(segments(for: item, useTotalTrendColor: config.bar.useTotalTrendSingleColor)) { segment in
                    segmentBar(
                        index: index,
                        segment: segment,
                        style: style)
                }
            }
        }

        // Breakdown: colored stacked bars by category.
        @ChartContentBuilder
        private var breakdownMarks: some ChartContent {
            ForEach(Array(visibleData.enumerated()), id: \.element.id) { index, item in
                let gap = gapValue()
                let style = ChartContainerSegmentBarStyle(
                    gap: gap,
                    gapColor: config.bar.segmentGapColor,
                    drawGapMark: true)
                ForEach(segments(for: item, useTotalTrendColor: false)) { segment in
                    segmentBar(
                        index: index,
                        segment: segment,
                        style: style)
                }
            }
        }

        /// Marks shared by both modes (zero line + selection dot).
        @ChartContentBuilder
        private var sharedMarks: some ChartContent {
            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(config.axis.zeroLineColor)
                .lineStyle(StrokeStyle(lineWidth: config.axis.zeroLineWidth))

            if selectedTab == .totalTrend, let selectedIndex, visibleData.indices.contains(selectedIndex) {
                let value = ChartMath.lineValue(for: visibleData[selectedIndex], config: config)
                PointMark(
                    x: .value("Selected Month", visibleData[selectedIndex].xKey),
                    y: .value("Selected Value", value))
                    .foregroundStyle(lineColor(for: value))
                    .symbolSize(config.line.selection.pointSize)
            }

            if showDebugOverlay {
                ForEach(visibleData, id: \.id) { item in
                    RuleMark(x: .value("Debug X", item.xKey))
                        .foregroundStyle(Color.red.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.0, dash: [2, 3]))
                }
            }
        }

        /// Draw one stacked segment and apply a small gap so segments are visually separated.
        @ChartContentBuilder
        private func segmentBar(
            index: Int,
            segment: ChartContainerSegment,
            style: ChartContainerSegmentBarStyle) -> some ChartContent {
            let bounds = adjustedSegmentBounds(start: segment.start, value: segment.value)
            BarMark(
                x: .value("Month", visibleData[index].xKey),
                yStart: .value("Value", bounds.low),
                yEnd: .value("Value", bounds.high),
                width: 40)
                .cornerRadius(0)
                .foregroundStyle(segment.color)
            if style.drawGapMark, style.gap > 0.0001, abs(segment.start) > 0.0001 {
                BarMark(
                    x: .value("Month", visibleData[index].xKey),
                    yStart: .value("Gap", segment.start - style.gap / 2.0),
                    yEnd: .value("Gap", segment.start + style.gap / 2.0),
                    width: 40)
                    .foregroundStyle(style.gapColor)
            }
        }

        /// Convert a signed segment into a visual bar range with a small gap.
        private func adjustedSegmentBounds(start: Double, value: Double) -> (low: Double, high: Double) {
            let end = start + value
            let rawLow = min(start, end)
            let rawHigh = max(start, end)
            return (rawLow, rawHigh)
        }
    }
}

private struct LineAndBarChartPreviewHost: View {
    private let groups = ChartSampleData.makeGroups(variance: 0.6)
    private let config = ChartSampleData.makeConfig()

    var body: some View {
        CombinedChartView<String>(
            config: config,
            groups: groups)
    }
}

#Preview {
    LineAndBarChartPreviewHost()
}
