// PacingPal
// EnergyEntry.swift
// 能量消耗记录

import Foundation
import SwiftData

@Model
final class EnergyEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var activityName: String
    var energyCost: Double
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        activityName: String,
        energyCost: Double,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.activityName = activityName
        self.energyCost = energyCost
        self.notes = notes
        self.createdAt = createdAt
    }

    // 用于排序，按日期升序
    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }
}
