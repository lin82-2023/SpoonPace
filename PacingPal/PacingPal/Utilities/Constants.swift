// PacingPal
// Constants.swift
// 全局常量

import Foundation
import SwiftUI

enum Constants {
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let spacing: CGFloat = 12
    }

    enum AI {
        static let weeklyInsightMaxTokens = 500
        static let naturalLanguageExtractionMaxTokens = 200
    }

    enum Subscription {
        static let monthlyProductID = "com.pacingpal.subscription.monthly"
        static let yearlyProductID = "com.pacingpal.subscription.yearly"
    }
}
