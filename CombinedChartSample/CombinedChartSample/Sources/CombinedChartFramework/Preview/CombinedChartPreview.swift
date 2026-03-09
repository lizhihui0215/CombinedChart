import SwiftUI

private struct CombinedChartPreviewHost: View {
    private let groups = CombinedChartPreviewData.groups
    private let config = CombinedChartPreviewData.config
    private let tabs = CombinedChartView.Tab.defaults
    @State private var selectedTab: CombinedChartView.Tab = .totalTrend
    @State private var showDebugOverlay = false

    var body: some View {
        CombinedChartView(
            config: config,
            groups: groups,
            tabs: tabs,
            selectedTab: $selectedTab,
            showDebugOverlay: $showDebugOverlay,
            onPointTap: { context in
                print(
                    "Tapped point:",
                    "groupID=\(context.point.id.groupID)",
                    "xKey=\(context.point.xKey)",
                    "index=\(context.index)")
            })
            .padding()
    }
}

#Preview {
    CombinedChartPreviewHost()
}

private enum CombinedChartPreviewData {
    static let groups: [CombinedChartView.DataGroup] = [
        .init(
            id: "2020",
            displayTitle: "2020",
            groupOrder: 2020,
            points: [
                makePoint(
                    groupID: "2020",
                    xKey: "2020-01",
                    saving: 5000,
                    investment: 10000,
                    otherLiquid: 2000,
                    otherNonLiquid: 3000,
                    liabilities: 15000),
                makePoint(
                    groupID: "2020",
                    xKey: "2020-02",
                    saving: 5200,
                    investment: 10400,
                    otherLiquid: 2200,
                    otherNonLiquid: 3200,
                    liabilities: 14700),
                makePoint(
                    groupID: "2020",
                    xKey: "2020-03",
                    saving: 5100,
                    investment: 10100,
                    otherLiquid: 2100,
                    otherNonLiquid: 3300,
                    liabilities: 14900),
                makePoint(
                    groupID: "2020",
                    xKey: "2020-04",
                    saving: 5400,
                    investment: 10800,
                    otherLiquid: 2300,
                    otherNonLiquid: 3500,
                    liabilities: 15100)
            ]),
        .init(
            id: "2021",
            displayTitle: "2021",
            groupOrder: 2021,
            points: [
                makePoint(
                    groupID: "2021",
                    xKey: "2021-01",
                    saving: 6000,
                    investment: 11400,
                    otherLiquid: 2600,
                    otherNonLiquid: 3700,
                    liabilities: 16000),
                makePoint(
                    groupID: "2021",
                    xKey: "2021-02",
                    saving: 6200,
                    investment: 11900,
                    otherLiquid: 2700,
                    otherNonLiquid: 3900,
                    liabilities: 16200),
                makePoint(
                    groupID: "2021",
                    xKey: "2021-03",
                    saving: 6400,
                    investment: 12300,
                    otherLiquid: 2900,
                    otherNonLiquid: 4100,
                    liabilities: 16500),
                makePoint(
                    groupID: "2021",
                    xKey: "2021-04",
                    saving: 6500,
                    investment: 12700,
                    otherLiquid: 3000,
                    otherNonLiquid: 4300,
                    liabilities: 16700)
            ])
    ]

    static let config = CombinedChartView.Config(
        monthsPerPage: 4,
        chartHeight: 420,
        bar: .init(
            series: [
                .init(
                    id: .liabilities,
                    label: "Liabilities",
                    color: Color(red: 0.82, green: 0.35, blue: 0.42),
                    valuePolarity: .forcedSign(.negative),
                    trendLineInclusion: .included),
                .init(
                    id: .saving,
                    label: "Saving",
                    color: Color(red: 0.20, green: 0.52, blue: 0.68),
                    valuePolarity: .preserveSign,
                    trendLineInclusion: .included),
                .init(
                    id: .investment,
                    label: "Investment",
                    color: Color(red: 0.86, green: 0.43, blue: 0.16),
                    valuePolarity: .preserveSign,
                    trendLineInclusion: .included),
                .init(
                    id: .otherLiquid,
                    label: "Other Liquid",
                    color: Color(red: 0.30, green: 0.67, blue: 0.14),
                    valuePolarity: .preserveSign,
                    trendLineInclusion: .included),
                .init(
                    id: .otherNonLiquid,
                    label: "Other Non-Liquid",
                    color: Color(red: 0.08, green: 0.28, blue: 0.34),
                    valuePolarity: .preserveSign,
                    trendLineInclusion: .included)
            ],
            trendBarColorStyle: .unified(Color.gray.opacity(0.45)),
            segmentGap: 2,
            segmentGapColor: Color(uiColor: .systemBackground),
            barWidth: 40),
        line: .init(
            positiveLineColor: .red,
            negativeLineColor: .yellow,
            lineWidth: 1,
            selection: .init(
                pointSize: 20,
                selectionLineColorStrategy: .fixedLine(.gray),
                fillColor: Color.gray.opacity(0.12),
                minimumSelectionWidth: 24)),
        axis: .init(
            xAxisLabel: { $0.point.xLabel },
            yAxisLabel: { context in
                let value = context.value
                return value == 0 ? "0" : "\(Int(value / 1000))K"
            },
            zeroLineColor: .black,
            zeroLineWidth: 1,
            yAxisWidth: 40),
        pager: .init(isVisible: true, dragScrollMode: .freeSnapping))

    private static func makePoint(
        groupID: String,
        xKey: String,
        saving: Double,
        investment: Double,
        otherLiquid: Double,
        otherNonLiquid: Double,
        liabilities: Double) -> CombinedChartView.Point {
        .init(
            id: .init(groupID: groupID, xKey: xKey),
            xKey: xKey,
            xLabel: xKey,
            values: [
                .saving: saving,
                .investment: investment,
                .otherLiquid: otherLiquid,
                .otherNonLiquid: otherNonLiquid,
                .liabilities: liabilities
            ])
    }
}
