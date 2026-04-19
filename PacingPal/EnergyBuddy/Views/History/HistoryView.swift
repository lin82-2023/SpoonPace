// PacingPal
// HistoryView.swift
// 历史日历视图

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.theme) private var theme
    @Query(sort: \DailyEnergyBudget.date, order: .reverse) private var budgets: [DailyEnergyBudget]
    @Query(sort: \EnergyEntry.date, order: .reverse) private var allEntries: [EnergyEntry]
    @Query(sort: \SymptomEntry.date, order: .reverse) private var allSymptoms: [SymptomEntry]

    @State private var selectedDate: Date? = Calendar.current.startOfDay(for: Date())

    var body: some View {
        VStack(spacing: Constants.UI.spacing) {
            // Month Calendar
            MonthCalendarView(
                selectedDate: $selectedDate,
                budgets: budgets,
                entries: allEntries,
                symptoms: allSymptoms
            )
            .padding(.horizontal)

            // Selected Date Detail
            if let selectedDate = selectedDate {
                DateDetailView(date: selectedDate)
            } else {
                ContentUnavailableView {
                    Label(String(localized: "Select a date"), systemImage: "calendar")
                } description: {
                    Text(String(localized: "Select a date from the calendar to view details"))
                }
            }
        }
        .padding(.vertical, Constants.UI.padding)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Month Calendar
struct MonthCalendarView: View {
    @Binding var selectedDate: Date?
    let budgets: [DailyEnergyBudget]
    let entries: [EnergyEntry]
    let symptoms: [SymptomEntry]

    private let calendar = Calendar.current
    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var currentMonth: Date {
        selectedDate ?? Date()
    }

    var monthRange: (start: Date, end: Date) {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let end = calendar.date(byAdding: .day, value: range.count - 1, to: start)!
        return (start, end)
    }

    var allDaysInMonth: [Date] {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        return (0..<range.count).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Month header
            HStack {
                Text(currentMonth, format: Date.FormatStyle(date: .long, time: .omitted))
                    .font(.headline)
                Spacer()
            }

            // Day headers
            HStack {
                ForEach(days, id: \.self) { day in
                    Text(day.prefix(3))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Grid of days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(allDaysInMonth, id: \.self) { day in
                    DayCell(
                        date: day,
                        selected: calendar.isDate(day, equalTo: selectedDate ?? Date(), toGranularity: .day),
                        hasData: hasData(for: day),
                        overBudget: isOverBudget(for: day),
                        onTap: { selectedDate = day }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func hasData(for date: Date) -> Bool {
        let normalized = calendar.startOfDay(for: date)
        return entries.contains { $0.normalizedDate == normalized } ||
               symptoms.contains { $0.normalizedDate == normalized } ||
               budgets.contains { $0.normalizedDate == normalized }
    }

    private func isOverBudget(for date: Date) -> Bool {
        let normalized = calendar.startOfDay(for: date)
        guard let budget = budgets.first(where: { $0.normalizedDate == normalized }) else {
            return false
        }
        let totalUsed = entries.filter { $0.normalizedDate == normalized }.reduce(0) { $0 + $1.energyCost }
        return totalUsed > budget.totalBudget
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let selected: Bool
    let hasData: Bool
    let overBudget: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            Text("\(calendar.component(.day, from: date))")
                .font(.body)
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background {
                    if selected {
                        Circle()
                            .fill(Color.accentColor)
                    } else if !hasData {
                        Circle()
                            .fill(Color.clear)
                    } else if overBudget {
                        Circle()
                            .fill(Color.red.opacity(0.3))
                    } else {
                        Circle()
                            .fill(Color.green.opacity(0.3))
                    }
                }
                .foregroundColor(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Detail
struct DateDetailView: View {
    let date: Date
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [EnergyEntry]
    @Query private var symptoms: [SymptomEntry]
    @Query private var budgets: [DailyEnergyBudget]

    private let calendar = Calendar.current

    init(date: Date) {
        self.date = calendar.startOfDay(for: date)
        let startOfDay = self.date
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        _entries = Query(filter: #Predicate<EnergyEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        }, sort: \EnergyEntry.date, order: .reverse)
        _symptoms = Query(filter: #Predicate<SymptomEntry> { symptom in
            symptom.date >= startOfDay && symptom.date < endOfDay
        }, sort: \SymptomEntry.date, order: .reverse)
        _budgets = Query(filter: #Predicate<DailyEnergyBudget> { budget in
            budget.date >= startOfDay && budget.date < endOfDay
        })
    }

    var currentBudget: Double {
        budgets.first?.totalBudget ?? 5.0
    }

    var totalUsed: Double {
        entries.reduce(0) { $0 + $1.energyCost }
    }

    var remaining: Double {
        max(0, currentBudget - totalUsed)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.UI.spacing) {
                // Summary card
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(date, style: .date)
                                .font(.headline)
                            Text(String(format: String(localized: "%.1f / %.1f spoons used"), totalUsed, currentBudget))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if totalUsed > currentBudget {
                            Text(String(localized: "Over Budget"))
                                .font(.caption)
                                .padding(6)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(6)
                        } else {
                            Text(String(localized: "Within Budget"))
                                .font(.caption)
                                .padding(6)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }

                    // Progress bar
                    ProgressView(value: min(1.0, totalUsed / max(1, currentBudget)))
                        .tint(totalUsed > currentBudget ? .red : .green)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(Constants.UI.cornerRadius)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // Activities
                if !entries.isEmpty {
                    VStack(spacing: 12) {
                        Text(String(localized: "Activities"))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(entries) { entry in
                            ActivityRow(entry: entry) {
                                modelContext.delete(entry)
                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Failed to delete: \(error)")
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }

                // Symptoms
                if !symptoms.isEmpty {
                    VStack(spacing: 12) {
                        Text(String(localized: "Symptoms"))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(symptoms) { symptom in
                            SymptomRow(entry: symptom) {
                                modelContext.delete(symptom)
                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Failed to delete: \(error)")
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
            .padding(Constants.UI.padding)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let entry: EnergyEntry
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.activityName)
                    .font(.body)
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(String(format: "%.1f", entry.energyCost))
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
        }
    }
}

// MARK: - Symptom Row
struct SymptomRow: View {
    let entry: SymptomEntry
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(Symptom(rawValue: entry.symptomType)?.localizedName ?? entry.symptomType)
                    .font(.body)
            }
            Spacer()
            Text(String(format: "%d/10", entry.severity))
                .font(.headline)
                .foregroundColor(entry.severity > 5 ? .orange : .secondary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
        }
    }
}

#Preview {
    HistoryView()
        .withPreviewModelContainer()
}
