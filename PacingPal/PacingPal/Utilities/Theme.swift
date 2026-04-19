// PacingPal
// Theme.swift
// 色彩主题

import Foundation
import SwiftUI

@Observable
final class Theme: Sendable {
    nonisolated static let shared = Theme()

    // Primary: Soft Blue - calm, trusting
    let primary = Color(red: 91/255, green: 143/255, blue: 185/255)

    // Secondary: Gentle Green - health, healing
    let secondary = Color(red: 134/255, green: 184/255, blue: 146/255)

    // Energy gradient colors
    func energyColor(remainingPercentage: Double) -> Color {
        if remainingPercentage > 0.5 {
            return secondary
        } else if remainingPercentage > 0.25 {
            return Color(red: 255/255, green: 204/255, blue: 0/255) // yellow
        } else {
            return Color(red: 230/255, green: 74/255, blue: 25/255) // red
        }
    }

    func energyGradient(remainingPercentage: Double) -> LinearGradient {
        let start = primary
        let end = energyColor(remainingPercentage: remainingPercentage)
        return LinearGradient(gradient: Gradient(colors: [start, end]), startPoint: .leading, endPoint: .trailing)
    }

    func energyGradient(usedPercentage: Double) -> LinearGradient {
        // usedPercentage = 0 → 0% used → all green
        // usedPercentage = 1 → 100% used → all red
        let end = energyColor(remainingPercentage: 1 - usedPercentage)
        return LinearGradient(gradient: Gradient(colors: [primary, end]), startPoint: .leading, endPoint: .trailing)
    }
}

extension EnvironmentValues {
    @Entry var theme: Theme = .shared
}
