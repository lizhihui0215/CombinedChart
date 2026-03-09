//
//  SampleApp.swift
//  ScrollChatTest
//
//  Created by Bernard on 2026/2/13.
//

import SwiftUI
import UIKit

@main
struct SampleApp: App {
    init() {
        if ProcessInfo.processInfo.arguments.contains("-snapshot-disable-animations") {
            UIView.setAnimationsEnabled(false)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
