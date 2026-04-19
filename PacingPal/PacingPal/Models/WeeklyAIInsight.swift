// PacingPal
// WeeklyAIInsight.swift
// AI 每周分析结果

import Foundation
import SwiftData

@Model
final class WeeklyAIInsight {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date
    var insightText: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        insightText: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.insightText = insightText
        self.createdAt = createdAt
    }
}
