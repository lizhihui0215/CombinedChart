//
//  ContentView.swift
//  ScrollChatTest
//
//  Created by Bernard on 2026/2/13.
//

import CombinedChartFramework
import SwiftUI

struct ContentView: View {
    enum ArrowModeOption: String, CaseIterable, Identifiable {
        case byPage = "By Page"
        case byEntry = "By Entry"

        var id: Self {
            self
        }

        var value: CombinedChartView.Config.Pager.ArrowScrollMode {
            switch self {
            case .byPage:
                .byPage
            case .byEntry:
                .byEntry
            }
        }
    }

    enum DragModeOption: String, CaseIterable, Identifiable {
        case byPage = "By Page"
        case freeSnapping = "Free Snapping"
        case free = "Free"

        var id: Self {
            self
        }

        var value: CombinedChartView.Config.Pager.DragScrollMode {
            switch self {
            case .byPage:
                .byPage
            case .freeSnapping:
                .freeSnapping
            case .free:
                .free
            }
        }

        init?(launchArgumentValue: String) {
            switch launchArgumentValue {
            case "byPage":
                self = .byPage
            case "freeSnapping":
                self = .freeSnapping
            case "free":
                self = .free
            default:
                return nil
            }
        }
    }

    enum ScrollImplementationOption: String, CaseIterable, Identifiable {
        case automatic = "Automatic"
        case swiftUI = "SwiftUI Gesture"
        case uiKit = "UIKit ScrollView"

        var id: Self {
            self
        }

        var value: CombinedChartView.Config.Pager.ScrollImplementation {
            switch self {
            case .automatic:
                .automatic
            case .swiftUI:
                .swiftUIGesture
            case .uiKit:
                .uiKitScrollView
            }
        }

        init?(launchArgumentValue: String) {
            switch launchArgumentValue {
            case "automatic":
                self = .automatic
            case "swiftUI":
                self = .swiftUI
            case "uiKit":
                self = .uiKit
            default:
                return nil
            }
        }
    }

    enum TrendBarColorOption: String, CaseIterable, Identifiable {
        case unified = "Unified"
        case series = "Series"

        var id: Self {
            self
        }
    }

    enum SelectionLineColorOption: String, CaseIterable, Identifiable {
        case fixed = "Fixed"
        case polarity = "Polarity"

        var id: Self {
            self
        }
    }

    private struct UITestLaunchConfiguration {
        let dataset: ChartSampleData.DatasetOption
        let selectedTab: CombinedChartView.Tab
        let dragMode: DragModeOption
        let scrollImplementation: ScrollImplementationOption
        let showDebugOverlay: Bool
        let chartHeight: CGFloat
        let visibleStartThreshold: CGFloat
        let barWidth: CGFloat

        init(processInfo: ProcessInfo = .processInfo) {
            let arguments = processInfo.arguments
            let datasetValue = Self.argumentValue(after: "-snapshot-dataset", in: arguments)
            let selectedTabID = Self.argumentValue(after: "-snapshot-selected-tab", in: arguments)
            let dragModeValue = Self.argumentValue(after: "-snapshot-drag-mode", in: arguments)
            let scrollImplementationValue = Self.argumentValue(after: "-snapshot-scroll-implementation", in: arguments)
            let chartHeightValue = Self.argumentValue(after: "-snapshot-chart-height", in: arguments)
            let visibleStartThresholdValue = Self.argumentValue(
                after: "-snapshot-visible-start-threshold",
                in: arguments)
            let barWidthValue = Self.argumentValue(after: "-snapshot-bar-width", in: arguments)

            dataset = datasetValue
                .flatMap { rawValue in
                    ChartSampleData.DatasetOption.allCases.first(where: {
                        $0.rawValue
                            .caseInsensitiveCompare(rawValue.replacingOccurrences(of: "-", with: " ")) == .orderedSame
                    })
                } ?? .current
            selectedTab = CombinedChartView.Tab.defaults.first(where: { $0.id == selectedTabID }) ?? .totalTrend
            dragMode = dragModeValue.flatMap { DragModeOption(launchArgumentValue: $0) } ?? .freeSnapping
            scrollImplementation = scrollImplementationValue
                .flatMap { ScrollImplementationOption(launchArgumentValue: $0) } ?? .automatic
            showDebugOverlay = arguments.contains("-snapshot-show-debug-overlay")
            chartHeight = chartHeightValue.flatMap { Double($0) }.map { CGFloat($0) } ?? 420
            visibleStartThreshold = visibleStartThresholdValue
                .flatMap { Double($0) }
                .map { CGFloat($0) }
                .map { min(max($0, 0), 1) } ?? (2.0 / 3.0)
            barWidth = barWidthValue.flatMap { Double($0) }.map { CGFloat($0) } ?? 40
        }

        private static func argumentValue(after flag: String, in arguments: [String]) -> String? {
            guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
                return nil
            }
            return arguments[index + 1]
        }
    }

    private let tabs = CombinedChartView.Tab.defaults

    private struct SampleControls {
        var dataset: ChartSampleData.DatasetOption
        var selectedTab: CombinedChartView.Tab
        var showDebugOverlay: Bool
        var arrowMode: ArrowModeOption
        var dragMode: DragModeOption
        var scrollImplementation: ScrollImplementationOption
        var chartHeight: CGFloat
        var visibleStartThreshold: CGFloat
        var barWidth: CGFloat
        var monthsPerPage: CGFloat
        var segmentGap: CGFloat
        var lineWidth: CGFloat
        var selectionPointSize: CGFloat
        var minimumSelectionWidth: CGFloat
        var yAxisWidth: CGFloat
        var zeroLineWidth: CGFloat
        var gridLineWidth: CGFloat
        var pagerVisible: Bool
        var trendBarColorOption: TrendBarColorOption
        var selectionLineColorOption: SelectionLineColorOption
        var showDebugLog: Bool
        var showDataControls: Bool
        var showInteractionControls: Bool
        var showLayoutControls: Bool
        var showVisualControls: Bool

        init(launchConfiguration: UITestLaunchConfiguration) {
            dataset = launchConfiguration.dataset
            selectedTab = launchConfiguration.selectedTab
            showDebugOverlay = launchConfiguration.showDebugOverlay
            arrowMode = .byPage
            dragMode = launchConfiguration.dragMode
            scrollImplementation = launchConfiguration.scrollImplementation
            chartHeight = launchConfiguration.chartHeight
            visibleStartThreshold = launchConfiguration.visibleStartThreshold
            barWidth = launchConfiguration.barWidth
            monthsPerPage = 4
            segmentGap = 2
            lineWidth = 1
            selectionPointSize = 20
            minimumSelectionWidth = 24
            yAxisWidth = 40
            zeroLineWidth = 1
            gridLineWidth = 0.5
            pagerVisible = true
            trendBarColorOption = .unified
            selectionLineColorOption = .fixed
            showDebugLog = false
            showDataControls = true
            showInteractionControls = true
            showLayoutControls = false
            showVisualControls = false
        }
    }

    @State private var controls: SampleControls
    @State private var latestDebugState: CombinedChartView.DebugState?

    init() {
        let launchConfiguration = UITestLaunchConfiguration()
        _controls = State(initialValue: SampleControls(launchConfiguration: launchConfiguration))
    }

    private var groups: [CombinedChartView.DataGroup] {
        ChartSampleData.makeGroups(dataset: controls.dataset, variance: 0.6)
    }

    private var trendBarColorStyle: CombinedChartView.Config.Bar.TrendBarColorStyle {
        switch controls.trendBarColorOption {
        case .unified:
            .unified(ChartSampleData.Palette.trendBar)
        case .series:
            .seriesColor
        }
    }

    private var selectionLineColorStyle: CombinedChartView.Config.Line.LineColorStrategy {
        switch controls.selectionLineColorOption {
        case .fixed:
            .fixedLine(ChartSampleData.Palette.selectionLine)
        case .polarity:
            .color(positive: ChartSampleData.Palette.positiveLine, negative: ChartSampleData.Palette.negativeLine)
        }
    }

    private var config: CombinedChartView.Config {
        ChartSampleData.makeConfig(
            monthsPerPage: Int(controls.monthsPerPage.rounded()),
            arrowScrollMode: controls.arrowMode.value,
            dragScrollMode: controls.dragMode.value,
            scrollImplementation: controls.scrollImplementation.value,
            chartHeight: controls.chartHeight,
            visibleStartThreshold: controls.visibleStartThreshold,
            barWidth: controls.barWidth,
            segmentGap: controls.segmentGap,
            lineWidth: controls.lineWidth,
            selectionPointSize: controls.selectionPointSize,
            minimumSelectionWidth: controls.minimumSelectionWidth,
            yAxisWidth: controls.yAxisWidth,
            zeroLineWidth: controls.zeroLineWidth,
            gridLineWidth: controls.gridLineWidth,
            isPagerVisible: controls.pagerVisible,
            trendBarColorStyle: trendBarColorStyle,
            selectionLineColorStyle: selectionLineColorStyle,
            debugLoggingEnabled: controls.showDebugLog)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 12) {
                headerCard
                configPanel
                statCards
                chartCard
                debugNotes
            }
            .padding()
        }
        .accessibilityIdentifier("combined-chart-root")
    }
}

private extension ContentView {
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HKD")
                    .font(ChartSampleData.SampleAppearance.Typography.screenTitle)
                Spacer()
            }

            Text("Chart Config Playground")
                .font(ChartSampleData.SampleAppearance.Typography.cardTitle)
            Text("Compact sample page for tuning the public chart configuration surface and comparing scroll engines.")
                .font(ChartSampleData.SampleAppearance.Typography.bodyCaption)
                .foregroundStyle(ChartSampleData.SampleAppearance.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ChartSampleData.SampleAppearance.Colors.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    var configPanel: some View {
        VStack(spacing: 10) {
            DisclosureGroup("Data & Debug", isExpanded: $controls.showDataControls) {
                VStack(spacing: 10) {
                    Picker("Dataset", selection: $controls.dataset) {
                        ForEach(ChartSampleData.DatasetOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Debug axis alignment", isOn: $controls.showDebugOverlay)
                        .font(ChartSampleData.SampleAppearance.Typography.bodyCaption)
                        .toggleStyle(SwitchToggleStyle(tint: .gray))
                    Toggle("Debug logger", isOn: $controls.showDebugLog)
                        .font(ChartSampleData.SampleAppearance.Typography.bodyCaption)
                        .toggleStyle(SwitchToggleStyle(tint: .gray))
                }
                .padding(.top, 8)
            }

            DisclosureGroup("Interaction", isExpanded: $controls.showInteractionControls) {
                VStack(spacing: 10) {
                    compactPicker("Arrow Mode", selection: $controls.arrowMode)
                    compactPicker("Drag Mode", selection: $controls.dragMode)
                    compactPicker("Scroll Engine", selection: $controls.scrollImplementation)
                    Toggle("Pager Visible", isOn: $controls.pagerVisible)
                        .font(ChartSampleData.SampleAppearance.Typography.bodyCaption)
                }
                .padding(.top, 8)
            }

            DisclosureGroup("Layout", isExpanded: $controls.showLayoutControls) {
                VStack(spacing: 10) {
                    sliderRow("Months / Page", value: $controls.monthsPerPage, range: 1...12, step: 1)
                    sliderRow(
                        "Chart Height",
                        value: $controls.chartHeight,
                        range: 240...720,
                        step: 10,
                        suffix: " pt",
                        identifier: "chart-height-slider")
                    sliderRow(
                        "Bar Width",
                        value: $controls.barWidth,
                        range: 8...80,
                        step: 1,
                        suffix: " pt",
                        identifier: "bar-width-slider")
                    sliderRow("Segment Gap", value: $controls.segmentGap, range: 0...12, step: 1, suffix: " pt")
                    sliderRow("Y Axis Width", value: $controls.yAxisWidth, range: 24...72, step: 1, suffix: " pt")
                    sliderRow(
                        "Visible Start Threshold",
                        value: $controls.visibleStartThreshold,
                        range: 0...1,
                        step: 0.01,
                        format: "%.2f",
                        identifier: "visible-start-threshold-slider")
                }
                .padding(.top, 8)
            }

            DisclosureGroup("Visual", isExpanded: $controls.showVisualControls) {
                VStack(spacing: 10) {
                    sliderRow(
                        "Line Width",
                        value: $controls.lineWidth,
                        range: 1...6,
                        step: 0.5,
                        suffix: " pt",
                        format: "%.1f")
                    sliderRow(
                        "Selection Point",
                        value: $controls.selectionPointSize,
                        range: 8...60,
                        step: 1,
                        suffix: " pt")
                    sliderRow(
                        "Selection Width",
                        value: $controls.minimumSelectionWidth,
                        range: 8...48,
                        step: 1,
                        suffix: " pt")
                    sliderRow(
                        "Zero Line Width",
                        value: $controls.zeroLineWidth,
                        range: 0.5...4,
                        step: 0.5,
                        suffix: " pt",
                        format: "%.1f")
                    sliderRow(
                        "Grid Line Width",
                        value: $controls.gridLineWidth,
                        range: 0.5...3,
                        step: 0.5,
                        suffix: " pt",
                        format: "%.1f")
                    compactPicker("Trend Bar Color", selection: $controls.trendBarColorOption)
                    compactPicker("Selection Line", selection: $controls.selectionLineColorOption)
                }
                .padding(.top, 8)
            }
        }
        .font(ChartSampleData.SampleAppearance.Typography.bodyCaption)
        .padding(16)
        .background(ChartSampleData.SampleAppearance.Colors.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    var statCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            statCard(title: "Dataset", value: controls.dataset.rawValue)
            statCard(title: "Viewport", value: controls.selectedTab.title)
            statCard(title: "Drag", value: controls.dragMode.rawValue)
            statCard(title: "Scroll", value: controls.scrollImplementation.rawValue)
        }
    }

    var chartCard: some View {
        VStack(spacing: 12) {
            Picker("", selection: $controls.selectedTab) {
                ForEach(tabs) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            CombinedChartView(
                config: config,
                groups: groups,
                tabs: tabs,
                selectedTab: $controls.selectedTab,
                showDebugOverlay: $controls.showDebugOverlay,
                onPointTap: { context in
                    print(
                        "Tapped point:",
                        "groupID=\(context.point.id.groupID)",
                        "xKey=\(context.point.xKey)",
                        "index=\(context.index)")
                },
                onDebugStateChange: { latestDebugState = $0 })
        }
        .padding(16)
        .background(ChartSampleData.SampleAppearance.Colors.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    var debugNotes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Debug Notes")
                .font(ChartSampleData.SampleAppearance.Typography.sectionTitle)
            debugRow("Tab", value: latestDebugState?.selectedTabTitle ?? "-")
            debugRow("Engine", value: latestDebugState?.scrollImplementationTitle ?? "-")
            debugRow("Drag Mode", value: latestDebugState?.dragScrollModeTitle ?? "-")
            debugRow("Dragging", value: latestDebugState?.isDragging == true ? "Yes" : "No")
            debugRow("Decelerating", value: latestDebugState?.isDecelerating == true ? "Yes" : "No")
            debugRow("Start Index", value: "\(latestDebugState?.startIndex ?? 0)")
            debugRow("Visible Start", value: latestDebugState?.visibleStartIndex.map(String.init) ?? "-")
            debugRow("Visible Label", value: latestDebugState?.visibleStartLabel ?? "-")
            debugRow(
                "Threshold",
                value: latestDebugState.map { String(format: "%.2f", $0.visibleStartThreshold) } ?? "-")
            debugRow("Offset X", value: latestDebugState.map { String(format: "%.1f", $0.contentOffsetX) } ?? "-")
            debugRow("Drag X", value: latestDebugState.map { String(format: "%.1f", $0.dragTranslationX) } ?? "-")
            debugRow(
                "Target Offset",
                value: latestDebugState.map { String(format: "%.1f", $0.targetContentOffsetX) } ?? "-")
            debugRow("Target Index", value: "\(latestDebugState?.targetMonthIndex ?? 0)")
            debugRow("Selected Index", value: latestDebugState?.selectedPointIndex.map(String.init) ?? "-")
            debugRow("Selected Group", value: latestDebugState?.selectedPointGroupID ?? "-")
            debugRow("Selected XKey", value: latestDebugState?.selectedPointXKey ?? "-")
            debugRow("Selected Label", value: latestDebugState?.selectedPointXLabel ?? "-")
            debugRow("Selected Value", value: latestDebugState.map {
                guard let value = $0.selectedPointValue else { return "-" }
                return String(format: "%.2f", value)
            } ?? "-")
            debugRow("Viewport Width", value: latestDebugState.map { String(format: "%.1f", $0.viewportWidth) } ?? "-")
            debugRow("Unit Width", value: latestDebugState.map { String(format: "%.1f", $0.unitWidth) } ?? "-")
            debugRow("Chart Width", value: latestDebugState.map { String(format: "%.1f", $0.chartWidth) } ?? "-")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ChartSampleData.SampleAppearance.Colors.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    func debugRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(ChartSampleData.SampleAppearance.Colors.secondaryText)
            Spacer()
            Text(value)
                .font(ChartSampleData.SampleAppearance.Typography.valueCaption)
        }
    }

    func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(ChartSampleData.SampleAppearance.Typography.bodyCaption)
                .foregroundStyle(ChartSampleData.SampleAppearance.Colors.secondaryText)
            Text(value)
                .font(ChartSampleData.SampleAppearance.Typography.statValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(ChartSampleData.SampleAppearance.Colors.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    func compactPicker<Option: CaseIterable & Identifiable & RawRepresentable & Hashable>(
        _ title: String,
        selection: Binding<Option>) -> some View where Option.RawValue == String {
        HStack {
            Text(title)
            Spacer()
            Picker(title, selection: selection) {
                ForEach(Array(Option.allCases)) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }

    func sliderRow(
        _ title: String,
        value: Binding<CGFloat>,
        range: ClosedRange<CGFloat>,
        step: CGFloat,
        suffix: String = "",
        format: String = "%.0f",
        identifier: String? = nil) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue) + suffix)
                    .font(ChartSampleData.SampleAppearance.Typography.valueCaption)
                    .foregroundStyle(ChartSampleData.SampleAppearance.Colors.secondaryText)
            }

            if let identifier {
                Slider(value: value, in: range, step: step)
                    .accessibilityIdentifier(identifier)
            } else {
                Slider(value: value, in: range, step: step)
            }
        }
    }
}

#Preview {
    ContentView()
}
