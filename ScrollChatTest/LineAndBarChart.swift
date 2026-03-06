//
//  LineAndBarChart.swift
//  ScrollChatTest
//
//  Created by Bernard on 2026/2/13.
//

import SwiftUI
import Charts

struct LineAndBarChart: View {
    // Chart + overlay for selection. Uses index-based X axis.
    var body: some View {
        CombinedChartView()
            .frame(maxWidth: .infinity)
    }
}

struct CombinedChartView: View {
    // Two display modes for the same dataset.
    enum ChartTab: String, CaseIterable, Identifiable {
        case totalTrend = "Total Trend"
        case breakdown = "Breakdown"

        var id: String { rawValue }
    }

    // Raw monthly data (values are in HKD).
    struct MonthData: Identifiable {
        let id = UUID()
        let month: String
        let saving: Double
        let invstment: Double
        let otherLiquidAsset: Double
        let otherNonLiquidAsset: Double
        let selfUsedProperty: Double
        let liabilities: Double

        // Always render liabilities as negative.
        var liabilitiesValue: Double {
            -abs(liabilities)
        }

        // Convert to "K" for axis readability.
        var savingK: Double { saving / 1_000 }
        var invstmentK: Double { invstment / 1_000 }
        var otherLiquidAssetK: Double { otherLiquidAsset / 1_000 }
        var otherNonLiquidAssetK: Double { otherNonLiquidAsset / 1_000 }
        var selfUsedPropertyK: Double { selfUsedProperty / 1_000 }
        var liabilitiesK: Double { liabilitiesValue / 1_000 }

        // Net total (includes liabilities).
        var totalK: Double {
            liabilitiesK + savingK + invstmentK + otherLiquidAssetK + otherNonLiquidAssetK + selfUsedPropertyK
        }

        // Positive-only total for bar height in Total Trend.
        var positiveTotalK: Double {
            savingK + invstmentK + otherLiquidAssetK + otherNonLiquidAssetK + selfUsedPropertyK
        }
    }

    // Group a full year of monthly data.
    struct YearData: Identifiable {
        var id: Int { year }
        let year: Int
        let data: [MonthData]
    }

    // Total Trend uses the same stacked bars but all gray.
    private let totalTrendPalette: [Color] = [
        Color.gray.opacity(0.45),
        Color.gray.opacity(0.45),
        Color.gray.opacity(0.45),
        Color.gray.opacity(0.45),
        Color.gray.opacity(0.45)
    ]

    // Breakdown uses colored stacked segments.
    private let breakdownPalette: [Color] = [
        Color(red: 0.82, green: 0.35, blue: 0.42),
        Color(red: 0.20, green: 0.52, blue: 0.68),
        Color(red: 0.86, green: 0.43, blue: 0.16),
        Color(red: 0.30, green: 0.67, blue: 0.14),
        Color(red: 0.08, green: 0.28, blue: 0.34)
    ]

    // UI state.
    @State private var selectedTab: ChartTab = .totalTrend
    @State private var selectedIndex: Int? = 0
    @State private var scrollPage: Int = 0
    @State private var showDebugOverlay: Bool = false

    @State private var selectedYearIndex: Int = 0
    @State private var plotAreaInfo: PlotAreaInfo? = nil
    @State private var yTickPositions: [Double: CGFloat] = [:]
    private let years: [YearData] = Self.makeYearsData()

    // Demo data (replace with API payload later).
    private static func makeYearsData() -> [YearData] {
        [
            YearData(year: 2020, data: makeYearData(
                savingBase: 5000,
                invstmentBase: 10000,
                otherLiquidBase: 2000,
                otherNonLiquidBase: 3000,
                selfUsedPropertyBase: 50000,
                liabilitiesBase: 15000
            )),
            YearData(year: 2021, data: makeYearData(
                savingBase: 5500,
                invstmentBase: 11000,
                otherLiquidBase: 2200,
                otherNonLiquidBase: 3200,
                selfUsedPropertyBase: 52000,
                liabilitiesBase: 15500
            ))
        ]
    }

    // Generates 12 months with seasonal variance so bars don't look identical.
    private static func makeYearData(
        savingBase: Double,
        invstmentBase: Double,
        otherLiquidBase: Double,
        otherNonLiquidBase: Double,
        selfUsedPropertyBase: Double,
        liabilitiesBase: Double
    ) -> [MonthData] {
        let months = [
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        ]
        var points: [MonthData] = []
        points.reserveCapacity(months.count)

        for (index, month) in months.enumerated() {
            let i = Double(index)
            let waveA = sin(i * 0.52)
            let waveB = cos(i * 0.41 + 0.7)
            let waveC = sin(i * 0.33 + 1.6)
            let waveD = cos(i * 0.27 + 2.2)
            let waveE = sin(i * 0.19 + 0.9)
            let waveF = cos(i * 0.23 + 1.3)

            points.append(
                MonthData(
                    month: month,
                    saving: savingBase * (1.0 + waveA * 0.18),
                    invstment: invstmentBase * (1.0 + waveB * 0.15),
                    otherLiquidAsset: otherLiquidBase * (1.0 + waveC * 0.22),
                    otherNonLiquidAsset: otherNonLiquidBase * (1.0 + waveD * 0.20),
                    selfUsedProperty: selfUsedPropertyBase * (1.0 + waveE * 0.08),
                    liabilities: liabilitiesBase * (1.0 + waveF * 0.16)
                )
            )
        }

        return points
    }

    // Current year selection.
    private var currentYearData: YearData {
        years[selectedYearIndex]
    }

    // Data array for the selected year.
    private var data: [MonthData] {
        currentYearData.data
    }

    // Number of 4-month pages for arrow navigation.
    private var maxScrollPage: Int {
        max(0, Int(ceil(Double(max(data.count - 4, 0)) / 4.0)))
    }

    private var visibleData: [MonthData] {
        data
    }

    // Dynamic Y range to fit all visible bars/line.
    private var yDomain: ClosedRange<Double> {
        let minValue = data.map(\.liabilitiesK).min() ?? -20
        let maxValue = data.map {
            $0.savingK + $0.invstmentK + $0.otherLiquidAssetK + $0.otherNonLiquidAssetK + $0.selfUsedPropertyK
        }.max() ?? 20
        let padding = max((maxValue - minValue) * 0.1, 2)
        return (minValue - padding)...(maxValue + padding)
    }

    // Fixed 11 ticks based on the current Y range.
    private var yAxisTickValues: [Double] {
        let halfRange = max(abs(yDomain.lowerBound), abs(yDomain.upperBound))
        let step = max(ceil(halfRange / 5.0), 1.0)
        return (-5...5).map { Double($0) * step }
    }

    // Use tick extremes for the displayed Y domain so labels/grid align.
    private var yAxisDisplayDomain: ClosedRange<Double> {
        guard let first = yAxisTickValues.first, let last = yAxisTickValues.last else {
            return yDomain
        }
        return first...last
    }

    private func yAxisLabel(for amount: Double) -> String {
        amount == 0 ? "0" : "\(Int(amount))K"
    }

    private struct PlotAreaInfo: Equatable {
        let minY: CGFloat
        let height: CGFloat
    }

    var body: some View {
        VStack(spacing: 12) {
            tabPicker
            currencyHeader
            debugToggle
            chartSection
            yearPager
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

    // Fixed Y-axis labels aligned to the chart's plot area.
    // Each label is centered on its corresponding grid line.
    private func yAxisLabels(plotArea: PlotAreaInfo?, tickPositions: [Double: CGFloat]) -> some View {
        let topPadding = plotArea?.minY ?? 12
        let plotHeight = plotArea?.height ?? 320

        return GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .topLeading) {
                ForEach(yAxisTickValues, id: \.self) { value in
                    if let yPos = tickPositions[value] {
                        Text(yAxisLabel(for: value))
                            .font(.caption2)
                            .foregroundStyle(.gray)
                            .border(.red, width: 1)
                            .position(x: width - 2, y: yPos)
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

    // Main chart area: fixed Y labels + horizontally scrollable chart.
    private var chartSection: some View {
        GeometryReader { geometry in
            let visibleCount: CGFloat = 4
            let yAxisWidth: CGFloat = 40
            let spacing: CGFloat = 8
            let viewportWidth = max(geometry.size.width - yAxisWidth - spacing, 1)
            let unitWidth = viewportWidth / visibleCount
            let chartWidth = max(viewportWidth, unitWidth * CGFloat(visibleData.count))

            HStack(alignment: .top, spacing: spacing) {
                yAxisLabels(plotArea: plotAreaInfo, tickPositions: yTickPositions)
                    .frame(width: yAxisWidth)

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            ChartContainer(
                                selectedTab: selectedTab,
                                visibleData: visibleData,
                                yAxisTickValues: yAxisTickValues,
                                yAxisDisplayDomain: yAxisDisplayDomain,
                                totalTrendPalette: totalTrendPalette,
                                breakdownPalette: breakdownPalette,
                                showDebugOverlay: showDebugOverlay,
                                onSelectIndex: { selectedIndex = $0 },
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
                                }
                            )
                            .frame(width: chartWidth, height: 420)

                            HStack(spacing: 0) {
                                ForEach(0...maxScrollPage, id: \.self) { page in
                                    Color.clear
                                        .frame(width: unitWidth * 4, height: 1)
                                        .id(page)
                                }
                            }
                        }
                    }
                    .frame(width: viewportWidth)
                    .onChange(of: scrollPage) { newValue in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(newValue, anchor: .leading)
                        }
                    }
                }
            }
        }
        .frame(height: 420)
    }

    private var yearPager: some View {
        HStack {
            Button {
                scrollPage = max(0, scrollPage - 1)
                selectedIndex = 0
            } label: {
                Image(systemName: "chevron.left")
            }
            .foregroundStyle(scrollPage > 0 ? .primary : .secondary)
            .disabled(scrollPage == 0)

            Spacer()
            Text("\(currentYearData.year)")
                .font(.title3.weight(.medium))
            Spacer()

            Button {
                scrollPage = min(maxScrollPage, scrollPage + 1)
                selectedIndex = 0
            } label: {
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(scrollPage < maxScrollPage ? .primary : .secondary)
            .disabled(scrollPage >= maxScrollPage)
        }
        .padding(.horizontal, 8)
    }
}

// Encapsulates the Chart to keep SwiftUI type-checking fast.
private struct ChartContainer: View {
    let selectedTab: CombinedChartView.ChartTab
    let visibleData: [CombinedChartView.MonthData]
    let yAxisTickValues: [Double]
    let yAxisDisplayDomain: ClosedRange<Double>
    let totalTrendPalette: [Color]
    let breakdownPalette: [Color]
    let showDebugOverlay: Bool
    let onSelectIndex: (Int) -> Void
    let onPlotAreaChange: (CGRect) -> Void
    let onYAxisTickPositions: ([Double: CGFloat]) -> Void
    @State private var selectedIndex: Int? = nil

    private func yAxisLabel(for amount: Double) -> String {
        amount == 0 ? "0" : "\(Int(amount))K"
    }

    var body: some View {
        let monthValues = visibleData.map(\.month)

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
                AxisTick()
                AxisValueLabel(centered: true) {
                    if let month = value.as(String.self) {
                        Text(month)
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
                        }
                    )
                    Color.clear
                        .onAppear { onYAxisTickPositions(positions) }
                        .onChange(of: positions) { onYAxisTickPositions($0) }
                }
                ZStack(alignment: .topLeading) {
                    if let selectedIndex, visibleData.indices.contains(selectedIndex) {
                        let selectedMonth = visibleData[selectedIndex].month
                        if let xPos = proxy.position(forX: selectedMonth) {
                            Group {
                                if selectedTab == .totalTrend {
                                    Path { path in
                                        path.move(to: CGPoint(x: xPos, y: plotRect.minY))
                                        path.addLine(to: CGPoint(x: xPos, y: plotRect.maxY))
                                    }
                                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                    .foregroundStyle(.gray)
                                } else {
                                    let step: CGFloat = {
                                        if selectedIndex + 1 < visibleData.count,
                                           let nextX = proxy.position(forX: visibleData[selectedIndex + 1].month) {
                                            return nextX - xPos
                                        }
                                        if selectedIndex - 1 >= 0,
                                           let prevX = proxy.position(forX: visibleData[selectedIndex - 1].month) {
                                            return xPos - prevX
                                        }
                                        return 40
                                    }()
                                    let width = max(step * 0.9, 24)
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.12))
                                        .frame(width: width, height: plotRect.height)
                                        .position(x: xPos, y: plotRect.midY)
                                }
                            }
                            .mask(
                                Rectangle()
                                    .frame(width: plotRect.width, height: plotRect.height)
                                    .position(x: plotRect.midX, y: plotRect.midY)
                            )
                        }
                    }

                    Color.clear
                        .contentShape(Rectangle())
                        .simultaneousGesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    let localX = value.location.x - plotRect.minX
                                    let clampedX = min(max(localX, 0), plotRect.width)
                                    if let month = proxy.value(atX: clampedX, as: String.self) {
                                        if let index = visibleData.firstIndex(where: { $0.month == month }) {
                                            selectedIndex = index
                                            onSelectIndex(index)
                                        }
                                    }
                                }
                        )
                }
            }
        }
    }

    // Total Trend: stacked gray bars plus a line on top.
    @ChartContentBuilder
    private var totalTrendMarks: some ChartContent {
        ForEach(Array(visibleData.enumerated()), id: \.element.id) { index, item in
            let gap = 0.4
            segmentBar(index: index, start: 0.0, value: item.liabilitiesK, gap: gap, color: totalTrendPalette[0])
            segmentBar(index: index, start: 0.0, value: item.savingK, gap: gap, color: totalTrendPalette[1])
            segmentBar(index: index, start: item.savingK, value: item.invstmentK, gap: gap, color: totalTrendPalette[2])
            segmentBar(index: index, start: item.savingK + item.invstmentK, value: item.otherLiquidAssetK, gap: gap, color: totalTrendPalette[3])
            segmentBar(index: index, start: item.savingK + item.invstmentK + item.otherLiquidAssetK, value: item.otherNonLiquidAssetK + item.selfUsedPropertyK, gap: gap, color: totalTrendPalette[4])

            LineMark(
                x: .value("Month", item.month),
                y: .value("Total", item.positiveTotalK)
            )
            .foregroundStyle(Color(red: 0.16, green: 0.30, blue: 0.38))
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
    }

    // Breakdown: colored stacked bars by category.
    @ChartContentBuilder
    private var breakdownMarks: some ChartContent {
        ForEach(Array(visibleData.enumerated()), id: \.element.id) { index, item in
            let gap = 0.4
            segmentBar(index: index, start: 0.0, value: item.liabilitiesK, gap: gap, color: breakdownPalette[0])
            segmentBar(index: index, start: 0.0, value: item.savingK, gap: gap, color: breakdownPalette[1])
            segmentBar(index: index, start: item.savingK, value: item.invstmentK, gap: gap, color: breakdownPalette[2])
            segmentBar(index: index, start: item.savingK + item.invstmentK, value: item.otherLiquidAssetK, gap: gap, color: breakdownPalette[3])
            segmentBar(index: index, start: item.savingK + item.invstmentK + item.otherLiquidAssetK, value: item.otherNonLiquidAssetK + item.selfUsedPropertyK, gap: gap, color: breakdownPalette[4])
        }
    }

    // Marks shared by both modes (zero line + selection dot).
    @ChartContentBuilder
    private var sharedMarks: some ChartContent {
        RuleMark(y: .value("Zero", 0))
            .foregroundStyle(.black)

        if selectedTab == .totalTrend, let selectedIndex, visibleData.indices.contains(selectedIndex) {
            PointMark(
                x: .value("Selected Month", visibleData[selectedIndex].month),
                y: .value("Selected Value", visibleData[selectedIndex].positiveTotalK)
            )
            .foregroundStyle(Color(red: 0.10, green: 0.50, blue: 0.66))
            .symbolSize(60)
        }

        if showDebugOverlay {
            ForEach(visibleData, id: \.id) { item in
                RuleMark(x: .value("Debug X", item.month))
                    .foregroundStyle(Color.red.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.0, dash: [2, 3]))
            }
        }
    }

    // Draw one stacked segment and apply a small gap so segments are visually separated.
    private func segmentBar(index: Int, start: Double, value: Double, gap: Double, color: Color) -> some ChartContent {
        let bounds = adjustedSegmentBounds(start: start, value: value, gap: gap)
        return BarMark(
            x: .value("Month", visibleData[index].month),
            yStart: .value("Value", bounds.low),
            yEnd: .value("Value", bounds.high),
            width: 40
        )
        .cornerRadius(0)
        .foregroundStyle(color)
    }

    // Convert a signed segment into a visual bar range with a small gap.
    private func adjustedSegmentBounds(start: Double, value: Double, gap: Double) -> (low: Double, high: Double) {
        let end = start + value
        let rawLow = min(start, end)
        let rawHigh = max(start, end)
        var displayLow = rawLow + gap / 2.0
        var displayHigh = rawHigh - gap / 2.0
        if displayLow > displayHigh {
            displayLow = rawLow
            displayHigh = rawHigh
        }
        return (displayLow, displayHigh)
    }
}

#Preview {
    LineAndBarChart()
}
