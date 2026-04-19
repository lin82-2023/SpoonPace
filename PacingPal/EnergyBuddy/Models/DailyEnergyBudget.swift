// PacingPal
// DailyEnergyBudget.swift
// 每日能量预算

import Foundation
import SwiftData

@Model
final class DailyEnergyBudget {
    @Attribute(.unique) var id: UUID
    var date: Date
    var totalBudget: Double
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        totalBudget: Double,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.totalBudget = totalBudget
        self.updatedAt = updatedAt
    }

    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }
}
