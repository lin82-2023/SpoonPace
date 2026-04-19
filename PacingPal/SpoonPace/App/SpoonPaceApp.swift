// SpoonPace
// SpoonPaceApp.swift
// App 入口

import SwiftUI
import SwiftData

@MainActor
@main
struct SpoonPaceApp: App {
    var body: some Scene {
        WindowGroup {
            AppMainView()
                .withAppServices()
                .withModelContainer()
        }
    }
}
