// PacingPal
// SymptomEntry.swift
// 症状记录

import Foundation
import SwiftData

enum Symptom: String, Codable, CaseIterable {
    case fatigue = "Fatigue"
    case pain = "Pain"
    case headache = "Headache"
    case migraine = "Migraine"
    case brainFog = "Brain Fog"
    case shortnessOfBreath = "Shortness of Breath"
    case sleepIssues = "Sleep Issues"
    case nausea = "Nausea"
    case heartPalpitations = "Heart Palpitations"

    var localizedName: String {
        switch self {
        case .fatigue: return String(localized: "Fatigue")
        case .pain: return String(localized: "Pain")
        case .headache: return String(localized: "Headache")
        case .migraine: return String(localized: "Migraine")
        case .brainFog: return String(localized: "Brain Fog")
        case .shortnessOfBreath: return String(localized: "Shortness of Breath")
        case .sleepIssues: return String(localized: "Sleep Issues")
        case .nausea: return String(localized: "Nausea")
        case .heartPalpitations: return String(localized: "Heart Palpitations")
        }
    }
}

@Model
final class SymptomEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var symptomType: String
    var severity: Int  // 0-10
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        symptomType: String,
        severity: Int,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.symptomType = symptomType
        self.severity = severity
        self.notes = notes
        self.createdAt = createdAt
    }

    convenience init(
        id: UUID = UUID(),
        date: Date = Date(),
        symptom: Symptom,
        severity: Int,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.init(
            id: id,
            date: date,
            symptomType: symptom.rawValue,
            severity: severity,
            notes: notes,
            createdAt: createdAt
        )
    }

    var asSymptom: Symptom? {
        Symptom(rawValue: symptomType)
    }

    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }
}
