// PacingPal
// SettingsView.swift
// 设置页面

import SwiftUI
import SwiftData
import HealthKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Environment(\.subscriptionManager) private var subscriptionManager
    @Query private var settings: [UserSettings]
    
    @State private var showPaywall = false
    @State private var showResetConfirmation = false

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    // Generate export JSON and return file URL
    private func generateExportJSON() -> URL? {
        do {
            // Fetch all data
            let energyEntries = try modelContext.fetch(FetchDescriptor<EnergyEntry>())
            let symptomEntries = try modelContext.fetch(FetchDescriptor<SymptomEntry>())
            let dailyBudgets = try modelContext.fetch(FetchDescriptor<DailyEnergyBudget>())

            // If no data at all, return nil
            if energyEntries.isEmpty && symptomEntries.isEmpty && dailyBudgets.isEmpty {
                return nil
            }

            // Create export dictionary
            var exportDict: [String: Any] = [:]
            exportDict["exportDate"] = ISO8601DateFormatter().string(from: Date())
            exportDict["appVersion"] = "1.0.0"

            // Convert entries to dictionaries
            let energyArray = energyEntries.map { entry -> [String: Any] in
                return [
                    "id": entry.id.uuidString,
                    "date": ISO8601DateFormatter().string(from: entry.date),
                    "activityName": entry.activityName,
                    "energyCost": entry.energyCost,
                    "notes": entry.notes ?? "",
                    "createdAt": ISO8601DateFormatter().string(from: entry.createdAt)
                ]
            }

            let symptomArray = symptomEntries.map { entry -> [String: Any] in
                return [
                    "id": entry.id.uuidString,
                    "date": ISO8601DateFormatter().string(from: entry.date),
                    "symptomType": entry.symptomType,
                    "severity": entry.severity,
                    "notes": entry.notes ?? "",
                    "createdAt": ISO8601DateFormatter().string(from: entry.createdAt)
                ]
            }

            let budgetArray = dailyBudgets.map { budget -> [String: Any] in
                return [
                    "id": budget.id.uuidString,
                    "date": ISO8601DateFormatter().string(from: budget.date),
                    "totalBudget": budget.totalBudget
                ]
            }

            exportDict["energyEntries"] = energyArray
            exportDict["symptomEntries"] = symptomArray
            exportDict["dailyBudgets"] = budgetArray

            // Convert to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)

            // Write to temporary file
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let fileName = "PacingPal-Export-\(dateFormatter.string(from: Date())).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try jsonData.write(to: tempURL)

            return tempURL
        } catch {
            print("Export error: \(error)")
            return nil
        }
    }
    
    var body: some View {
        List {
            // Subscription Section
            Section {
                if subscriptionManager.isSubscribed {
                    HStack {
                        SVGLogoView()
                            .frame(width: 32, height: 32)
                            .foregroundColor(theme.primary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "PacingPal Pro"))
                                .font(.headline)
                            Text(String(localized: "Active"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } else {
                    Button(action: { showPaywall = true }) {
                        HStack {
                            SVGLogoView()
                                .frame(width: 32, height: 32)
                                .foregroundColor(theme.primary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "Upgrade to Pro"))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(String(localized: "Unlock AI insights and more"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text(String(localized: "Subscription"))
            }
            
            // Daily Budget Section
            Section {
                NavigationLink(destination: BudgetSettingsView()) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(theme.primary)
                            .frame(width: 30)
                        Text(String(localized: "Default Daily Budget"))
                        Spacer()
                        Text(String(format: "%.1f spoons", userSettings.defaultDailyBudget))
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(String(localized: "Energy Settings"))
            }
            
            // Data Management Section
            Section {
                // Generate export data and share directly
                if let exportURL = generateExportJSON() {
                    ShareLink(
                        item: exportURL,
                        preview: SharePreview(
                            String(localized: "PacingPal Data Export"),
                            image: Image(systemName: "square.and.arrow.up")
                        )
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(theme.secondary)
                                .frame(width: 30)
                            Text(String(localized: "Export Data"))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .frame(minHeight: 44)
                } else {
                    // No data to export
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                        Text(String(localized: "Export Data"))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(localized: "No Data"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: { showResetConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 30)
                        Text(String(localized: "Clear All Data"))
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
                .frame(minHeight: 44)
            } header: {
                Text(String(localized: "Data Management"))
            } footer: {
                Text(String(localized: "Export your data as JSON or clear all app data. This action cannot be undone."))
            }
            
            // AI Settings Section
            Section {
                NavigationLink(destination: APIKeySettingsView()) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(theme.primary)
                            .frame(width: 30)
                        Text(String(localized: "AI API Key"))
                        Spacer()
                        if APIKeyManager.hasCloudAPIKey() {
                            Text(String(localized: "Configured"))
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text(String(localized: "Not Set"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text(String(localized: "AI Settings"))
            } footer: {
                Text(String(localized: "Natural language extraction works offline with local rules by default. Add an API key for enhanced AI and weekly insights. Supports Anthropic, OpenAI, DeepSeek, Kimi and Qwen."))
            }

            // HealthKit Sync Section
            Section {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Health Data Sync"))
                        Text(String(localized: "Import steps, activity, sleep and heart rate"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if HealthKitManager.shared.isAuthorized {
                        Text(String(localized: "Enabled"))
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                if !HealthKitManager.shared.isAuthorized && HealthKitManager.shared.isAvailable {
                    Button(action: {
                        Task {
                            _ = await HealthKitManager.shared.requestAuthorization()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text(String(localized: "Enable Health Sync"))
                            Spacer()
                        }
                    }
                }
            } header: {
                Text(String(localized: "Health Integration"))
            } footer: {
                Text(String(localized: "Your health data is only read locally on your device for AI analysis. It is never uploaded or shared. Denying access doesn't affect manual recording."))
            }

            // About Section
            Section {
                HStack {
                    Text(String(localized: "Version"))
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                NavigationLink(destination: LegalDocumentView(title: String(localized: "Privacy Policy"), filename: "PrivacyPolicy")) {
                    HStack {
                        Text(String(localized: "Privacy Policy"))
                        Spacer()
                    }
                }
                
                NavigationLink(destination: LegalDocumentView(title: String(localized: "Terms of Service"), filename: "TermsOfService")) {
                    HStack {
                        Text(String(localized: "Terms of Service"))
                        Spacer()
                    }
                }
            } header: {
                Text(String(localized: "About"))
            }
        }
        .navigationTitle(String(localized: "Settings"))
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert(String(localized: "Clear All Data?"), isPresented: $showResetConfirmation) {
            Button(String(localized: "Cancel"), role: .cancel) { }
            Button(String(localized: "Clear"), role: .destructive) {
                clearAllData()
            }
        } message: {
            Text(String(localized: "This will permanently delete all your entries, budgets, and settings. This action cannot be undone."))
        }
    }
    
    // MARK: - Actions
    private func clearAllData() {
        do {
            // Delete all entries
            let allEntries = try modelContext.fetch(FetchDescriptor<EnergyEntry>())
            for entry in allEntries {
                modelContext.delete(entry)
            }
            
            // Delete all symptoms
            let allSymptoms = try modelContext.fetch(FetchDescriptor<SymptomEntry>())
            for symptom in allSymptoms {
                modelContext.delete(symptom)
            }
            
            // Delete all budgets
            let allBudgets = try modelContext.fetch(FetchDescriptor<DailyEnergyBudget>())
            for budget in allBudgets {
                modelContext.delete(budget)
            }
            
            // Delete settings
            let allSettings = try modelContext.fetch(FetchDescriptor<UserSettings>())
            for setting in allSettings {
                modelContext.delete(setting)
            }
            
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}

// MARK: - Budget Settings View
struct BudgetSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Query private var settings: [UserSettings]
    
    @State private var defaultBudget: Double = 5.0
    @State private var hasChanged = false
    
    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }
    
    var body: some View {
        Form {
            Section {
                VStack(spacing: 20) {
                    Text(String(format: "%.1f spoons", defaultBudget))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(theme.primary)
                    
                    Slider(value: $defaultBudget, in: 1...20, step: 0.5)
                        .onChange(of: defaultBudget) { _, _ in
                            hasChanged = true
                        }
                    
                    HStack {
                        Text("1")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("20")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
                .padding(.vertical)
            } header: {
                Text(String(localized: "Default Daily Budget"))
            } footer: {
                Text(String(localized: "This will be used as the default budget for new days. You can adjust individual days in the app."))
            }
            
            Section {
                Button(action: saveSettings) {
                    HStack {
                        Spacer()
                        Text(String(localized: "Save"))
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!hasChanged)
            }
        }
        .navigationTitle(String(localized: "Daily Budget"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            defaultBudget = userSettings.defaultDailyBudget
        }
    }
    
    private func saveSettings() {
        if let existing = settings.first {
            existing.defaultDailyBudget = defaultBudget
        } else {
            let newSettings = UserSettings(defaultDailyBudget: defaultBudget)
            modelContext.insert(newSettings)
        }
        
        do {
            try modelContext.save()
            hasChanged = false
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .withAppServices()
    .withPreviewModelContainer()
}
