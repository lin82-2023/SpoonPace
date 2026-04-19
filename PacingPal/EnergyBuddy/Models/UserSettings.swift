// PacingPal
// UserSettings.swift
// 用户设置

import Foundation
import SwiftData

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var defaultDailyBudget: Double
    var hasSeenOnboarding: Bool
    var enableiCloudSync: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        defaultDailyBudget: Double = 5.0,
        hasSeenOnboarding: Bool = false,
        enableiCloudSync: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.defaultDailyBudget = defaultDailyBudget
        self.hasSeenOnboarding = hasSeenOnboarding
        self.enableiCloudSync = enableiCloudSync
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
