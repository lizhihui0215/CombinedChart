//
//  ContentView.swift
//  ScrollChatTest
//
//  Created by Bernard on 2026/2/13.
//

import CombinedChartFramework
import SwiftUI
import UIKit

struct ContentView: View {
    enum DragModeOption: String, CaseIterable, Identifiable {
        case byPage = "By Page"
        case freeSnapping = "Free Snapping"
        case free = "Free"

        var id: Self {
            self
        }

        var dragScrollMode: CombinedChartView.Config.Pager.DragScrollMode {
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

    private struct UITestLaunchConfiguration {
        let selectedTab: CombinedChartView.Tab
        let dragMode: DragModeOption
        let showDebugOverlay: Bool
        let chartHeight: CGFloat
        let visibleStartThreshold: CGFloat
        let barWidth: CGFloat

        init(processInfo: ProcessInfo = .processInfo) {
            let arguments = processInfo.arguments
            let selectedTabID = Self.argumentValue(after: "-snapshot-selected-tab", in: arguments)
            let dragModeValue = Self.argumentValue(after: "-snapshot-drag-mode", in: arguments)
            let chartHeightValue = Self.argumentValue(after: "-snapshot-chart-height", in: arguments)
            let visibleStartThresholdValue = Self.argumentValue(
                after: "-snapshot-visible-start-threshold",
                in: arguments)
            let barWidthValue = Self.argumentValue(after: "-snapshot-bar-width", in: arguments)

            selectedTab = CombinedChartView.Tab.defaults.first(where: { $0.id == selectedTabID }) ?? .totalTrend
            dragMode = dragModeValue.flatMap { DragModeOption(launchArgumentValue: $0) } ?? .freeSnapping
            showDebugOverlay = arguments.contains("-snapshot-show-debug-overlay")
            chartHeight = chartHeightValue
                .flatMap { Double($0) }
                .map { CGFloat($0) } ?? 420
            visibleStartThreshold = visibleStartThresholdValue
                .flatMap { Double($0) }
                .map { CGFloat($0) }
                .map { min(max($0, 0), 1) } ?? (2.0 / 3.0)
            barWidth = barWidthValue
                .flatMap { Double($0) }
                .map { CGFloat($0) } ?? 40
        }

        private static func argumentValue(after flag: String, in arguments: [String]) -> String? {
            guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
                return nil
            }
            return arguments[index + 1]
        }
    }

    private let groups = ChartSampleData.makeGroups(variance: 0.6)
    private let tabs = CombinedChartView.Tab.defaults
    @State private var selectedTab: CombinedChartView.Tab
    @State private var showDebugOverlay: Bool
    @State private var dragMode: DragModeOption
    @State private var chartHeight: CGFloat
    @State private var visibleStartThreshold: CGFloat
    @State private var barWidth: CGFloat

    init() {
        let launchConfiguration = UITestLaunchConfiguration()
        _selectedTab = State(initialValue: launchConfiguration.selectedTab)
        _showDebugOverlay = State(initialValue: launchConfiguration.showDebugOverlay)
        _dragMode = State(initialValue: launchConfiguration.dragMode)
        _chartHeight = State(initialValue: launchConfiguration.chartHeight)
        _visibleStartThreshold = State(initialValue: launchConfiguration.visibleStartThreshold)
        _barWidth = State(initialValue: launchConfiguration.barWidth)
    }

    private var config: CombinedChartView.Config {
        ChartSampleData.makeConfig(
            dragScrollMode: dragMode.dragScrollMode,
            chartHeight: chartHeight,
            visibleStartThreshold: visibleStartThreshold,
            barWidth: barWidth)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("HKD")
                    .font(.headline)
                Spacer()
            }

            Picker("", selection: $selectedTab) {
                ForEach(tabs) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Debug axis alignment", isOn: $showDebugOverlay)
                .font(.caption)
                .toggleStyle(SwitchToggleStyle(tint: .gray))

            Picker("Drag Mode", selection: $dragMode) {
                ForEach(DragModeOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 6) {
                HStack {
                    Text("Chart Height")
                        .font(.caption)
                    Spacer()
                    Text("\(Int(chartHeight)) pt")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Slider(value: $chartHeight, in: 240...720, step: 10)
                    .accessibilityIdentifier("chart-height-slider")
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Visible Start Threshold")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.2f", visibleStartThreshold))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Slider(value: $visibleStartThreshold, in: 0...1, step: 0.01)
                    .accessibilityIdentifier("visible-start-threshold-slider")
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Bar Width")
                        .font(.caption)
                    Spacer()
                    Text("\(Int(barWidth)) pt")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Slider(value: $barWidth, in: 8...80, step: 1)
                    .accessibilityIdentifier("bar-width-slider")
            }

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
        }
        .padding()
        .accessibilityIdentifier("combined-chart-root")
    }
}

#Preview {
    ContentView()
}
