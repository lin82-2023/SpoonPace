// PacingPal
// ActivityType.swift
// 预定义活动类型，用户可以自定义

import Foundation
import SwiftData

@Model
final class ActivityType {
    @Attribute(.unique) var id: UUID
    var name: String
    var defaultEnergyCost: Double
    var isCustom: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        defaultEnergyCost: Double,
        isCustom: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.defaultEnergyCost = defaultEnergyCost
        self.isCustom = isCustom
        self.createdAt = createdAt
    }
}

// MARK: - Default Activities
extension ActivityType {
    static func createDefaultActivities() -> [ActivityType] {
        return [
            ActivityType(name: String(localized: "Shower"), defaultEnergyCost: 1.5, isCustom: false),
            ActivityType(name: String(localized: "Cooking"), defaultEnergyCost: 2.5, isCustom: false),
            ActivityType(name: String(localized: "Walking (10min)"), defaultEnergyCost: 1, isCustom: false),
            ActivityType(name: String(localized: "Grocery Shopping"), defaultEnergyCost: 3, isCustom: false),
            ActivityType(name: String(localized: "Work (1hr)"), defaultEnergyCost: 4, isCustom: false),
            ActivityType(name: String(localized: "Social Meeting"), defaultEnergyCost: 4.5, isCustom: false),
            ActivityType(name: String(localized: "Driving (30min)"), defaultEnergyCost: 2, isCustom: false),
            ActivityType(name: String(localized: "House Cleaning"), defaultEnergyCost: 3.5, isCustom: false)
        ]
    }
}
