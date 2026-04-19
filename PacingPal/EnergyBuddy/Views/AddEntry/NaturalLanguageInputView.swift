// EenergyBuddy
// NaturalLanguageInputView.swift
// AI 自然语言输入 - 用户用自然语言描述，AI 自动提取活动和症状

import SwiftUI

struct NaturalLanguageInputView: View {
    @Environment(\.subscriptionManager) private var subscriptionManager
    @Environment(\.theme) private var theme
    @State private var inputText = ""
    @State private var isProcessing = false
    @State private var extractedResult: AIExtractResult?
    @State private var showError = false
    @State private var errorMessage = ""

    let onExtracted: (AIExtractResult) -> Void
    let onSave: () -> Void

    init(
        onExtracted: @escaping (AIExtractResult) -> Void,
        onSave: @escaping () -> Void
    ) {
        self.onExtracted = onExtracted
        self.onSave = onSave
    }

    var body: some View {
        Section(String(localized: "Natural Language Input")) {
            TextEditor(text: $inputText)
                .frame(minHeight: 100)
                .overlay(
                    Group {
                        if inputText.isEmpty {
                            Text(String(localized: "Try: \"Walked 20 minutes this morning, now I have a headache at 6/10\""))
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )

            // 显示当前 AI 模式
            HStack {
                Image(systemName: APIKeyManager.hasCloudAPIKey() ? "cloud.fill" : "gear")
                    .foregroundColor(APIKeyManager.hasCloudAPIKey() ? theme.primary : .secondary)
                Text(APIKeyManager.hasCloudAPIKey() ?
                    String(localized: "Using Cloud AI (Enhanced)") :
                    String(localized: "Using Local AI (Offline)"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            Button(action: processInput) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(String(localized: "Extract Information"))
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(inputText.isEmpty || isProcessing)
        }

        if let result = extractedResult, hasAnyExtracted(result) {
            Section(String(localized: "Extracted Result")) {
                if let activity = result.activityName, let cost = result.energyCost {
                    HStack {
                        Text(String(localized: "Activity"))
                        Spacer()
                        Text("\(activity) - \(String(format: "%.1f", cost)) spoons")
                            .foregroundColor(.secondary)
                    }
                }
                if let symptom = result.symptomType, let severity = result.symptomSeverity {
                    HStack {
                        Text(String(localized: "Symptom"))
                        Spacer()
                        Text("\(symptom) - \(severity)/10")
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: {
                    if let result = extractedResult {
                        onExtracted(result)
                        onSave()
                    }
                }) {
                    Text(String(localized: "Save Entries"))
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(.green)
            }
        }

        Section {
            Text(String(localized: "Use natural language to describe your day, AI will automatically extract activities and symptoms. Works best for English."))
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .alert(String(localized: "Error"), isPresented: $showError) {
            Button(String(localized: "OK"), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func hasAnyExtracted(_ result: AIExtractResult) -> Bool {
        result.activityName != nil || result.symptomType != nil
    }

    private func processInput() {
        isProcessing = true

        Task {
            do {
                let result = try await HybridAIService.shared.extractFromNaturalText(inputText)
                extractedResult = result
                isProcessing = false
            } catch {
                isProcessing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            NaturalLanguageInputView(onExtracted: { _ in }, onSave: {})
        }
    }
    .withAppServices()
}
