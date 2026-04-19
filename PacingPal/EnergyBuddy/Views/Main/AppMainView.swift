// PacingPal
// AppMainView.swift
// 主应用入口 - TabView 导航

import SwiftUI

enum AppTab: CaseIterable, Identifiable {
    case today, history, insights, settings

    var id: String { String(describing: self) }

    var title: String {
        switch self {
        case .today: return String(localized: "Today")
        case .history: return String(localized: "History")
        case .insights: return String(localized: "Insights")
        case .settings: return String(localized: "Settings")
        }
    }

    var iconName: String {
        switch self {
        case .today: return "drop.fill"
        case .history: return "calendar"
        case .insights: return "lightbulb"
        case .settings: return "gear"
        }
    }
}

@MainActor
struct AppMainView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    makeContentView(for: tab)
                        .navigationTitle(tab.title)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.iconName)
                }
                .tag(tab)
            }
        }
        .onAppear {
            // Load products when app starts
            Task {
                await SubscriptionManager.shared.loadProducts()
            }
        }
    }

    @ViewBuilder
    private func makeContentView(for tab: AppTab) -> some View {
        switch tab {
        case .today: TodayView()
        case .history: HistoryView()
        case .insights: InsightsView()
        case .settings: SettingsView()
        }
    }
}

#Preview {
    AppMainView()
        .withAppServices()
}
