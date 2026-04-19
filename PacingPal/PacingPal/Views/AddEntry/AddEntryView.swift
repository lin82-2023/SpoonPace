// PacingPal
// AddEntryView.swift
// 添加记录页面 - 活动和症状录入

import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Environment(\.subscriptionManager) private var subscriptionManager
    
    @State private var selectedTab: EntryTab = .activity
    @State private var showNaturalLanguageInput = false
    
    // Activity form states
    @State private var activityName = ""
    @State private var energyCost: Double = 1.0
    @State private var activityNotes = ""
    
    // Symptom form states
    @State private var selectedSymptom: Symptom = .fatigue
    @State private var severity: Double = 5.0
    @State private var symptomNotes = ""
    
    @State private var showSuccess = false
    @State private var extractedResult: AIExtractResult?
    
    enum EntryTab: CaseIterable {
        case activity, symptom
        
        var title: String {
            switch self {
            case .activity: return String(localized: "Activity")
            case .symptom: return String(localized: "Symptom")
            }
        }
        
        var icon: String {
            switch self {
            case .activity: return "figure.walk"
            case .symptom: return "heart.fill"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.UI.spacing) {
                // AI Input Section (if subscribed)
                if subscriptionManager.isSubscribed {
                    NaturalLanguageInputView(
                        onExtracted: { result in
                            extractedResult = result
                            applyExtractedResult(result)
                        },
                        onSave: {
                            saveExtractedEntries()
                        }
                    )
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(Constants.UI.cornerRadius)
                }
                
                // Manual Entry Tabs
                Picker(String(localized: "Entry Type"), selection: $selectedTab) {
                    ForEach(EntryTab.allCases, id: \.self) { tab in
                        Label(tab.title, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Form content
                Group {
                    switch selectedTab {
                    case .activity:
                        activityForm
                    case .symptom:
                        symptomForm
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(Constants.UI.cornerRadius)
                
                // Save button
                Button(action: saveEntry) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(String(localized: "Save Entry"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadius)
                }
                .padding(.horizontal)
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1.0 : 0.6)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .alert(String(localized: "Saved"), isPresented: $showSuccess) {
            Button(String(localized: "OK"), role: .cancel) { }
        } message: {
            Text(String(localized: "Entry saved successfully"))
        }
    }
    
    // MARK: - Activity Form
    private var activityForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Log Activity"))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Activity Name"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField(String(localized: "e.g., Walking, Cooking"), text: $activityName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: "Energy Cost"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f spoons", energyCost))
                        .font(.subheadline)
                        .foregroundColor(theme.primary)
                }
                Slider(value: $energyCost, in: 0.5...10, step: 0.5)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Notes (Optional)"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $activityNotes)
                    .frame(minHeight: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Symptom Form
    private var symptomForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Log Symptom"))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Symptom Type"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker(String(localized: "Symptom"), selection: $selectedSymptom) {
                    ForEach(Symptom.allCases, id: \.self) { symptom in
                        Text(symptom.localizedName).tag(symptom)
                    }
                }
                .pickerStyle(.menu)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: "Severity"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(severity))/10")
                        .font(.subheadline)
                        .foregroundColor(severityColor)
                }
                Slider(value: $severity, in: 0...10, step: 1)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Notes (Optional)"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $symptomNotes)
                    .frame(minHeight: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
    
    private var severityColor: Color {
        switch Int(severity) {
        case 0...3: return .green
        case 4...6: return .orange
        default: return .red
        }
    }
    
    private var isFormValid: Bool {
        switch selectedTab {
        case .activity:
            return !activityName.isEmpty
        case .symptom:
            return true
        }
    }
    
    // MARK: - Actions
    private func applyExtractedResult(_ result: AIExtractResult) {
        if let activity = result.activityName {
            activityName = activity
            selectedTab = .activity
        }
        if let cost = result.energyCost {
            energyCost = cost
        }
        if let symptom = result.symptomType {
            if let matchedSymptom = Symptom.allCases.first(where: { 
                $0.rawValue.lowercased() == symptom.lowercased() ||
                $0.localizedName.lowercased() == symptom.lowercased()
            }) {
                selectedSymptom = matchedSymptom
                selectedTab = .symptom
            }
        }
        if let sev = result.symptomSeverity {
            severity = Double(sev)
        }
    }
    
    private func saveExtractedEntries() {
        if extractedResult?.activityName != nil {
            saveActivityEntry()
        }
        if extractedResult?.symptomType != nil {
            saveSymptomEntry()
        }
        resetForm()
        showSuccess = true
    }
    
    private func saveEntry() {
        switch selectedTab {
        case .activity:
            saveActivityEntry()
        case .symptom:
            saveSymptomEntry()
        }
        resetForm()
        showSuccess = true
    }
    
    private func saveActivityEntry() {
        let entry = EnergyEntry(
            activityName: activityName,
            energyCost: energyCost,
            notes: activityNotes.isEmpty ? nil : activityNotes
        )
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save activity: \(error)")
        }
    }
    
    private func saveSymptomEntry() {
        let entry = SymptomEntry(
            symptom: selectedSymptom,
            severity: Int(severity),
            notes: symptomNotes.isEmpty ? nil : symptomNotes
        )
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save symptom: \(error)")
        }
    }
    
    private func resetForm() {
        activityName = ""
        energyCost = 1.0
        activityNotes = ""
        selectedSymptom = .fatigue
        severity = 5.0
        symptomNotes = ""
        extractedResult = nil
    }
}

#Preview {
    NavigationStack {
        AddEntryView()
    }
    .withAppServices()
    .withPreviewModelContainer()
}
