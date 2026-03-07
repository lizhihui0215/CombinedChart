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

    var body: some View {
        CombinedChartView<String>(
            config: config,
            groups: groups)
    }
}

#Preview {
    ContentView()
}
