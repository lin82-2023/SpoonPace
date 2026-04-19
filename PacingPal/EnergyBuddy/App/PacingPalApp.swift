// PacingPal
// PacingPalApp.swift
// App 入口

import SwiftUI
import SwiftData

@MainActor
@main
struct PacingPalApp: App {
    var body: some Scene {
        WindowGroup {
            AppMainView()
                .withAppServices()
                .withModelContainer()
        }
    }
}
