// PacingPal
// InsightsView.swift
// AI 洞察页面 - 每周分析和建议

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.subscriptionManager) private var subscriptionManager
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyEnergyBudget.date, order: .reverse) private var budgets: [DailyEnergyBudget]
    @Query(sort: \EnergyEntry.date, order: .reverse) private var entries: [EnergyEntry]
    @Query(sort: \SymptomEntry.date, order: .reverse) private var symptoms: [SymptomEntry]
    @Query(sort: \WeeklyAIInsight.createdAt, order: .reverse) private var savedInsights: [WeeklyAIInsight]

    @State private var weeklyInsight: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var lastGeneratedAt: Date?
    @State private var cachedSummaries: [DailySummary]?

    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.UI.spacing) {
                // DEBUG: Allow access without subscription during development
                #if DEBUG
                insightsContent
                #else
                if !subscriptionManager.isSubscribed {
                    PaywallCard()
                } else {
                    insightsContent
                }
                #endif
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "Insights"))
        .alert(String(localized: "Error"), isPresented: $showError) {
            Button(String(localized: "OK"), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // DEBUG: Always load in development
            #if DEBUG
            loadSavedInsight()
            if weeklyInsight.isEmpty {
                generateInsight()
            }
            #else
            if subscriptionManager.isSubscribed {
                loadSavedInsight()
                if weeklyInsight.isEmpty {
                    generateInsight()
                }
            }
            #endif
        }
    }
    
    // MARK: - Insights Content
    private var insightsContent: some View {
        VStack(spacing: Constants.UI.spacing) {
            // Weekly Summary Card
            weeklySummaryCard
            
            // AI Insight Card
            aiInsightCard
            
            // Stats Cards
            statsSection
        }
    }
    
    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(theme.primary)
                    .font(.title2)
                Text(String(localized: "This Week"))
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                StatItem(
                    title: String(localized: "Days Tracked"),
                    value: "\(uniqueDaysThisWeek)",
                    icon: "calendar",
                    color: theme.primary
                )

                StatItem(
                    title: String(localized: "Activities"),
                    value: "\(entriesThisWeek.count)",
                    icon: "figure.walk",
                    color: theme.secondary
                )

                StatItem(
                    title: String(localized: "Symptoms"),
                    value: "\(symptomsThisWeek.count)",
                    icon: "heart.fill",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
    
    private var aiInsightCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(theme.primary)
                    .font(.title2)
                Text(String(localized: "AI Weekly Insight"))
                    .font(.headline)
                Spacer()

                // Show current AI mode indicator
                if !isLoading {
                    Text(currentAIModeName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }

                Button(action: generateInsight) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(theme.primary)
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .disabled(isLoading)
                .rotationEffect(.degrees(isLoading ? 360 : 0))
                .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
            }

            // Show generation time if available
            if let lastGenerated = lastGeneratedAt, !isLoading, !weeklyInsight.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(String(format: String(localized: "Generated %@"), formatGeneratedDate(lastGenerated)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.3)
                    Text(String(localized: "Generating insight..."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
            } else if !weeklyInsight.isEmpty {
                formattedInsightText(weeklyInsight)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(8)

                // Non-medical disclaimer
                VStack(spacing: 8) {
                    Divider()
                        .padding(.vertical, 4)
                    Text(String(localized: "Disclaimer: This is a personal health tracking tool for reference only. It does not provide medical diagnosis or treatment advice. Always consult your healthcare provider for medical concerns."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 12)

                // Export buttons
                if !isLoading {
                    VStack(spacing: 12) {
                        HStack {
                            Text(String(localized: "Export"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            // Export as Image
                            ShareLink(item: createExportImage(), preview: SharePreview(String(localized: "Weekly Insight"), image: createExportImage())) {
                                Text(String(localized: "Image"))
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(theme.primary.opacity(0.12))
                                    .cornerRadius(8)
                            }
                            // Export as PDF
                            if let pdfURL = exportPDF() {
                                ShareLink(item: pdfURL, preview: SharePreview(String(localized: "Weekly Insight (PDF)"))) {
                                    Text(String(localized: "PDF"))
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(theme.primary.opacity(0.12))
                                        .cornerRadius(8)
                                }
                            }
                            // Export as CSV
                            if let csvURL = exportCSV() {
                                ShareLink(item: csvURL, preview: SharePreview(String(localized: "Weekly Data (CSV)"))) {
                                    Text(String(localized: "CSV"))
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(theme.primary.opacity(0.12))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            } else {
                Text(String(localized: "Tap the refresh button to generate your personalized weekly insight."))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Energy Patterns"))
                .font(.headline)
                .padding(.horizontal, 4)

            // Over budget days
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    Text(String(localized: "Over Budget Days"))
                        .font(.subheadline)
                    Spacer()
                    Text("\(overBudgetDaysThisWeek)")
                        .font(.headline)
                        .foregroundColor(.orange)
                }

                if overBudgetDaysThisWeek > 0 {
                    Text(String(localized: "Try to pace yourself better on high-activity days."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )

            // Average energy use
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(theme.secondary)
                        .font(.title3)
                    Text(String(localized: "Avg Daily Energy Use"))
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f spoons", averageDailyEnergyUse))
                        .font(.headline)
                        .foregroundColor(theme.secondary)
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )

            // Most common symptom
            if let commonSymptom = mostCommonSymptom {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                        Text(String(localized: "Most Common Symptom"))
                            .font(.subheadline)
                        Spacer()
                        Text(commonSymptom.localizedName)
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                }
                .padding(16)
                .background(.regularMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var thisWeekRange: (start: Date, end: Date) {
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        return (startOfWeek, endOfWeek)
    }
    
    private var entriesThisWeek: [EnergyEntry] {
        let range = thisWeekRange
        return entries.filter { $0.date >= range.start && $0.date < range.end }
    }
    
    private var symptomsThisWeek: [SymptomEntry] {
        let range = thisWeekRange
        return symptoms.filter { $0.date >= range.start && $0.date < range.end }
    }
    
    private var uniqueDaysThisWeek: Int {
        let dates = entriesThisWeek.map { calendar.startOfDay(for: $0.date) }
        return Set(dates).count
    }
    
    private var overBudgetDaysThisWeek: Int {
        let range = thisWeekRange
        let weekBudgets = budgets.filter { $0.date >= range.start && $0.date < range.end }
        
        return weekBudgets.filter { budget in
            let dayEntries = entries.filter { 
                calendar.isDate($0.date, inSameDayAs: budget.date)
            }
            let totalUsed = dayEntries.reduce(0) { $0 + $1.energyCost }
            return totalUsed > budget.totalBudget
        }.count
    }
    
    private var averageDailyEnergyUse: Double {
        guard uniqueDaysThisWeek > 0 else { return 0 }
        let total = entriesThisWeek.reduce(0) { $0 + $1.energyCost }
        return total / Double(uniqueDaysThisWeek)
    }
    
    private var mostCommonSymptom: Symptom? {
        let symptomCounts = Dictionary(grouping: symptomsThisWeek) { $0.symptomType }
            .mapValues { $0.count }
        guard let mostCommon = symptomCounts.max(by: { $0.value < $1.value }) else { return nil }
        return Symptom(rawValue: mostCommon.key)
    }
    
    // MARK: - Actions
    private func generateInsight() {
        isLoading = true

        Task { @MainActor in
            do {
                let summaries = await generateDailySummaries()
                cachedSummaries = summaries
                let insight = try await HybridAIService.shared.generateWeeklyInsight(entries: summaries)
                weeklyInsight = insight
                lastGeneratedAt = Date()
                isLoading = false

                // Save to SwiftData
                let range = thisWeekRange
                // Delete any existing insight for this week
                if let existing = savedInsights.first(where: { $0.startDate <= range.end && $0.endDate >= range.start }) {
                    modelContext.delete(existing)
                }
                // Save new insight
                let newInsight = WeeklyAIInsight(
                    startDate: range.start,
                    endDate: range.end,
                    insightText: insight
                )
                modelContext.insert(newInsight)
                try? modelContext.save()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
    
    private func generateDailySummaries() async -> [DailySummary] {
        let range = thisWeekRange
        let calendar = Calendar.current

        var results: [DailySummary] = []

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: range.start) else { continue }

            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let daySymptoms = symptoms.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let budget = budgets.first { calendar.isDate($0.date, inSameDayAs: date) }

            // Skip days with no entries AND no symptoms - user didn't track anything that day
            if dayEntries.isEmpty && daySymptoms.isEmpty {
                continue
            }

            let totalUsed = dayEntries.reduce(0) { $0 + $1.energyCost }
            let budgetAmount = budget?.totalBudget ?? 5.0

            // Get HealthKit data if authorized
            var stepCount: Double?
            var activeEnergy: Double?
            var restingHR: Double?
            var sleepHours: Double?

            if HealthKitManager.shared.isAuthorized {
                let healthMetrics = await HealthKitManager.shared.getDailyHealthMetrics(for: date)
                if !healthMetrics.isEmpty {
                    stepCount = healthMetrics.stepCount
                    activeEnergy = healthMetrics.activeEnergyBurned
                    restingHR = healthMetrics.restingHeartRate
                    sleepHours = healthMetrics.sleepDurationHours
                }
            }

            let summary = DailySummary(
                date: date,
                totalEnergyUsed: totalUsed,
                budget: budgetAmount,
                overBudget: totalUsed > budgetAmount,
                averageSymptomSeverity: daySymptoms.isEmpty ? 0 : Double(daySymptoms.reduce(0) { $0 + $1.severity }) / Double(daySymptoms.count),
                symptoms: daySymptoms.map { SymptomData(name: $0.symptomType, severity: $0.severity) },
                activities: dayEntries.map { ActivityData(name: $0.activityName, cost: $0.energyCost) },
                stepCount: stepCount,
                activeEnergyBurned: activeEnergy,
                restingHeartRate: restingHR,
                sleepDurationHours: sleepHours
            )

            results.append(summary)
        }

        return results
    }

    /// Format markdown text with basic styling
    @ViewBuilder
    private func formattedInsightText(_ text: String) -> some View {
        let lines = text.components(separatedBy: .newlines)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(lines.indices, id: \.self) { index in
                let line = lines[index].trimmingCharacters(in: .whitespaces)
                if line.isEmpty {
                    Spacer().frame(height: 8)
                } else if line.hasPrefix("# ") {
                    // Main title (PacingPal Weekly Insight)
                    Text(line.dropFirst(2))
                        .font(.title2.bold())
                        .foregroundColor(theme.primary)
                        .padding(.top, 4)
                        .padding(.bottom, 2)
                } else if line.hasPrefix("## ") {
                    // Secondary heading
                    Text(line.dropFirst(3))
                        .font(.headline)
                        .foregroundColor(theme.primary)
                        .padding(.top, 6)
                } else if line.hasPrefix("**") && line.hasSuffix("**") {
                    // Heading/bold section
                    Text(line.dropFirst(2).dropLast(2))
                        .font(.headline)
                        .foregroundColor(theme.primary)
                        .padding(.top, 4)
                } else if line.hasPrefix("•") || line.hasPrefix("- ") || line.hasPrefix("* ") {
                    // Bullet point
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundColor(theme.primary)
                            .font(.body)
                        parseMarkdownText(line.replacingOccurrences(of: "^[•\\-\\*] ", with: "", options: .regularExpression))
                    }
                } else if line == "**Key Observations:**" || line == "**Suggestion:**" || line == "**Closing:**" {
                    Text(line.replacingOccurrences(of: "**", with: ""))
                        .font(.headline)
                        .foregroundColor(theme.primary)
                        .padding(.top, 4)
                } else {
                    // Regular paragraph with bold parsing
                    parseMarkdownText(line)
                }
            }
        }
    }

    /// Parse inline bold (**text**) in a line
    private func parseMarkdownText(_ line: String) -> Text {
        // Remove all markdown bold markers
        var processedString = line
        while let range = processedString.range(of: "**") {
            processedString.removeSubrange(range)
        }

        // For the simplified version, just remove bold markers and return plain text
        // Bold formatting handled by removing markdown markers
        return Text(processedString)
            .font(.body)
            .foregroundColor(.primary)
    }

    // MARK: - Helper computed properties

    private var currentAIModeName: String {
        if APIKeyManager.hasCloudAPIKey() {
            return APIKeyManager.getCloudAIProvider().rawValue
        }
        return String(localized: "Basic")
    }

    private func formatGeneratedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func loadSavedInsight() {
        // Load the most recent insight for this week
        let range = thisWeekRange
        if let saved = savedInsights.first(where: { $0.startDate <= range.end && $0.endDate >= range.start }) {
            weeklyInsight = saved.insightText
            lastGeneratedAt = saved.createdAt
        }
    }

    // MARK: - Export Functions

    /// Render the insight as UIImage for sharing
    fileprivate func createExportImage() -> Image {
        let renderer = ImageRenderer(content:
            VStack(spacing: 16) {
                Text(String(localized: "EnergyBuddy Weekly Insight"))
                    .font(.title)
                    .bold()
                    .foregroundColor(theme.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let generated = lastGeneratedAt {
                    Text(String(format: String(localized: "Generated: %@"), formatGeneratedDate(generated)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                formattedInsightText(weeklyInsight)
                    .foregroundColor(.primary)

                Divider()

                Text(String(localized: "Generated by EnergyBuddy • Energy management for Long COVID"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .frame(width: 600)
        )

        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }

        return Image(systemName: "doc")
    }

    /// Export insight and data as PDF
    fileprivate func exportPDF() -> URL? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // US Letter size

        let data = pdfRenderer.pdfData { context in
            context.beginPage()

            // Title
            let title = NSLocalizedString("EnergyBuddy Weekly Insight", comment: "") as NSString
            title.draw(at: CGPoint(x: 20, y: 20), withAttributes: [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24),
                NSAttributedString.Key.foregroundColor: UIColor(theme.primary)
            ])

            var currentY: CGFloat = 60

            // Date
            if let generated = lastGeneratedAt {
                let dateStr = String(format: NSLocalizedString("Generated: %@", comment: ""), formatGeneratedDate(generated)) as NSString
                dateStr.draw(at: CGPoint(x: 20, y: currentY), withAttributes: [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
                    NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel
                ])
                currentY += 30
            }

            // Content
            let rect = CGRect(x: 20, y: currentY, width: 572, height: 650)
            let text = weeklyInsight as NSString
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6
            text.draw(in: rect, withAttributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.foregroundColor: UIColor.label
            ])
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("EnergyBuddy-Weekly-Insight.pdf")
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Failed to write PDF: \(error)")
            return nil
        }
    }

    /// Export raw weekly data as CSV
    fileprivate func exportCSV() -> URL? {
        var csvText = "Date,TotalEnergyUsed,Budget,OverBudget,AverageSymptomSeverity,NumberOfActivities,NumberOfSymptoms,StepCount,SleepDurationHours\n"

        guard let summaries = cachedSummaries else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        for summary in summaries {
            let dateStr = dateFormatter.string(from: summary.date)
            let line = "\(dateStr),\(summary.totalEnergyUsed),\(summary.budget),\(summary.overBudget ? "YES" : "NO"),\(summary.averageSymptomSeverity),\(summary.activities.count),\(summary.symptoms.count),\(summary.stepCount ?? 0),\(summary.sleepDurationHours ?? 0)\n"
            csvText += line
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("EnergyBuddy-Weekly-Data.csv")
        do {
            try csvText.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        InsightsView()
    }
    .withAppServices()
    .withPreviewModelContainer()
}
