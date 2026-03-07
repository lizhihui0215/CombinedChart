//
//  ContentView.swift
//  ScrollChatTest
//
//  Created by Bernard on 2026/2/13.
//

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

        var dragScrollMode: ChartConfig.ChartPagerConfig.DragScrollMode {
            switch self {
            case .byPage:
                .byPage
            case .freeSnapping:
                .freeSnapping
            case .free:
                .free
            }
        }
    }

    private let groups = ChartSampleData.makeGroups(variance: 0.6)
    private let tabs = CombinedChartView.ChartTab.defaults
    @State private var selectedTab: CombinedChartView.ChartTab = .totalTrend
    @State private var showDebugOverlay = false
    @State private var dragMode: DragModeOption = .freeSnapping

    private var config: ChartConfig {
        ChartSampleData.makeConfig(dragScrollMode: dragMode.dragScrollMode)
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
    }
}

#Preview {
    ContentView()
}
