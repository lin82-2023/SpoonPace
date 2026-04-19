// PacingPal
// TodayView.swift
// 今日首页 - 能量桶显示

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Query(sort: \DailyEnergyBudget.date, order: .reverse) private var budgets: [DailyEnergyBudget]
    @Query(sort: \EnergyEntry.date, order: .reverse) private var entries: [EnergyEntry]
    @Query(sort: \SymptomEntry.date, order: .reverse) private var symptoms: [SymptomEntry]
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]

    @State private var showAddEntry = false
    @State private var showEditBudget = false
    @State private var editedBudget: Double = 0.0

    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var currentBudget: Double {
        if let budget = budgets.first(where: { $0.normalizedDate == today }) {
            return budget.totalBudget
        }
        return userSettings.defaultDailyBudget
    }

    private var totalUsed: Double {
        entries.filter { $0.normalizedDate == today }.reduce(0) { $0 + $1.energyCost }
    }

    private var usedPercentage: Double {
        guard currentBudget > 0 else { return 0 }
        return min(totalUsed, currentBudget) / currentBudget
    }

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    private var todaysSymptoms: [SymptomEntry] {
        symptoms.filter { $0.normalizedDate == today }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.UI.spacing) {
                // Energy Bucket Card
                VStack(spacing: 16) {
                    HStack {
                        SVGLogoView()
                            .frame(width: 40, height: 40)
                            .foregroundColor(theme.primary)

                        Text(String(localized: "Today's Energy"))
                            .font(.title)
                            .fontWeight(.semibold)

                        Spacer()
                    }

                    EnergyBucketView(
                        total: currentBudget,
                        used: totalUsed,
                        percentage: usedPercentage
                    )

                    HStack {
                        VStack(alignment: .leading) {
                            Text(String(format: String(localized: "%.1f / %.1f spoons"), totalUsed, currentBudget))
                                .font(.headline)
                            Text(String(localized: "Used Energy"))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        Spacer()
                        Button(action: { editBudget() }) {
                            Text(String(localized: "Edit"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(Constants.UI.cornerRadius)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // Today's Activities
                if !entries.filter({ $0.normalizedDate == today }).isEmpty {
                    VStack(spacing: 12) {
                        Text(String(localized: "Today's Activities"))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(entries.filter { $0.normalizedDate == today }) { entry in
                            ActivityRow(entry: entry) {
                                deleteEntry(entry)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }

                // Today's Symptoms
                if !todaysSymptoms.isEmpty {
                    VStack(spacing: 12) {
                        Text(String(localized: "Today's Symptoms"))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(todaysSymptoms) { symptom in
                            SymptomRow(entry: symptom) {
                                deleteSymptom(symptom)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }

                if entries.filter({ $0.normalizedDate == today }).isEmpty && todaysSymptoms.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "No Entries Yet"), systemImage: "drop")
                    } description: {
                        Text(String(localized: "Tap the + tab to add your first activity or symptom"))
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                }
            }
            .padding(Constants.UI.padding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showAddEntry = true }) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showAddEntry) {
            NavigationStack {
                AddEntryView()
            }
        }
        .sheet(isPresented: $showEditBudget) {
            NavigationStack {
                EditTodayBudgetView(
                    budget: $editedBudget,
                    onSave: {
                        saveBudget()
                        showEditBudget = false
                    }
                )
            }
        }
    }

    private func editBudget() {
        editedBudget = currentBudget
        showEditBudget = true
    }

    private func saveBudget() {
        // Find existing budget for today or create new
        if let existing = budgets.first(where: { $0.normalizedDate == today }) {
            existing.totalBudget = editedBudget
        } else {
            let newBudget = DailyEnergyBudget(date: today, totalBudget: editedBudget)
            modelContext.insert(newBudget)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save budget: \(error)")
        }
    }

    private func deleteEntry(_ entry: EnergyEntry) {
        modelContext.delete(entry)
        save()
    }

    private func deleteSymptom(_ entry: SymptomEntry) {
        modelContext.delete(entry)
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}

// MARK: - Energy Bucket Visual
struct EnergyBucketView: View {
    let total: Double
    let used: Double
    let percentage: Double
    @Environment(\.theme) private var theme

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background (empty bucket - gray)
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 40)

                // Filled portion (used energy - green → yellow → red)
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.energyGradient(usedPercentage: percentage))
                    .frame(width: max(0, geometry.size.width * CGFloat(percentage)), height: 40)
                    .animation(.easeInOut(duration: 0.3), value: percentage)
            }
            .frame(height: 40)
        }
        .frame(height: 40)
    }
}

// MARK: - Edit Today Budget View
struct EditTodayBudgetView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @Binding var budget: Double
    let onSave: () -> Void

    var body: some View {
        Form {
            Section {
                VStack(spacing: 20) {
                    Text(String(format: "%.1f spoons", budget))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(theme.primary)

                    Slider(value: $budget, in: 1...20, step: 0.5)

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
                Text(String(localized: "Today's Energy Budget"))
            } footer: {
                Text(String(localized: "Adjust your energy budget for today."))
            }

            Section {
                Button(action: {
                    onSave()
                }) {
                    HStack {
                        Spacer()
                        Text(String(localized: "Save"))
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Edit Budget"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "Cancel")) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    TodayView()
        .withAppServices()
}
