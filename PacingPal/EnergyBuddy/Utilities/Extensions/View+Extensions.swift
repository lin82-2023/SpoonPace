// PacingPal
// View+Extensions.swift
// 便捷扩展 - 环境注入

import SwiftUI
import SwiftData

extension View {
    func withAppServices() -> some View {
        self
            .environment(Theme.shared)
            .environment(AuthenticationManager.shared)
            .environment(SubscriptionManager.shared)
    }

    func withModelContainer() -> some View {
        self.modelContainer(
            for: [
                ActivityType.self,
                EnergyEntry.self,
                SymptomEntry.self,
                DailyEnergyBudget.self,
                UserSettings.self,
                WeeklyAIInsight.self
            ]
        )
    }

    func withPreviewModelContainer() -> some View {
        self
            .modelContainer(
                for: [
                    ActivityType.self,
                    EnergyEntry.self,
                    SymptomEntry.self,
                    DailyEnergyBudget.self,
                    UserSettings.self,
                    WeeklyAIInsight.self
                ],
                inMemory: true
            )
            .withAppServices()
    }
}
