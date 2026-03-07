//
//  ContentView.swift
//  ScrollChatTest
//
//  Created by Bernard on 2026/2/13.
//

import SwiftUI
import UIKit

struct ContentView: View {
    private let groups = ChartSampleData.makeGroups(variance: 0.6)
    private let config = ChartSampleData.makeConfig()
    private let tabs = CombinedChartView.ChartTab.defaults
    @State private var selectedTab: CombinedChartView.ChartTab = .totalTrend
    @State private var showDebugOverlay = false

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

            CombinedChartView(
                config: config,
                groups: groups,
                tabs: tabs,
                selectedTab: $selectedTab,
                showDebugOverlay: $showDebugOverlay)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
