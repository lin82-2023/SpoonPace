// PacingPal
// APIKeySettingsView.swift
// AI API Key 设置页面
// 支持多个云端 AI 提供者：Anthropic Claude, OpenAI

import SwiftUI

struct APIKeySettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var isKeyVisible: Bool = false
    @State private var selectedProvider: CloudAIProvider = .anthropic
    @State private var showSaveConfirmation: Bool = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "AI Provider"))
                        .font(.headline)
                }
                .padding(.vertical, 4)

                Picker(String(localized: "AI Provider"), selection: $selectedProvider) {
                    ForEach(CloudAIProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "API Key"))
                        .font(.headline)

                    Text(descriptionForProvider(selectedProvider))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)

                HStack {
                    if isKeyVisible {
                        TextField(placeholderForProvider(selectedProvider), text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField(placeholderForProvider(selectedProvider), text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    Button(action: { isKeyVisible.toggle() }) {
                        Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                Button(action: saveAPIKey) {
                    HStack {
                        Spacer()
                        Text(String(localized: "Save API Key"))
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(apiKey.isEmpty)

                if APIKeyManager.hasCloudAPIKey() {
                    Button(action: clearAPIKey) {
                        HStack {
                            Spacer()
                            Text(String(localized: "Remove API Key"))
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "How to get an API Key"))
                        .font(.headline)

                    instructionsForProvider(selectedProvider)

                    Text(String(localized: "Your API key is stored locally on your device and is never sent to our servers."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding(.vertical, 8)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "Features"))
                        .font(.headline)

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(String(localized: "Natural language input (offline)"))
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(String(localized: "Weekly insights (basic offline)"))
                        Spacer()
                    }

                    HStack {
                        Image(systemName: APIKeyManager.hasCloudAPIKey() ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(APIKeyManager.hasCloudAPIKey() ? .green : .secondary)
                        Text(String(localized: "Weekly insights (AI-enhanced)"))
                        Spacer()
                    }

                    HStack {
                        Image(systemName: APIKeyManager.hasCloudAPIKey() ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(APIKeyManager.hasCloudAPIKey() ? .green : .secondary)
                        Text(String(localized: "Better natural language understanding"))
                        Spacer()
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(String(localized: "AI Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            APIKeyManager.migrateIfNeeded()
            apiKey = APIKeyManager.getCloudAPIKey() ?? ""
            selectedProvider = APIKeyManager.getCloudAIProvider()
        }
        .alert(String(localized: "API Key Saved"), isPresented: $showSaveConfirmation) {
            Button(String(localized: "OK")) {
                dismiss()
            }
        } message: {
            Text(String(localized: "Your API key has been saved. Cloud AI features are now enabled."))
        }
    }

    private func descriptionForProvider(_ provider: CloudAIProvider) -> String {
        switch provider {
        case .anthropic:
            return String(localized: "Enter your Anthropic API key to enable enhanced AI features.")
        case .openAI:
            return String(localized: "Enter your OpenAI API key to enable enhanced AI features.")
        case .deepSeek:
            return String(localized: "Enter your DeepSeek API key to enable enhanced AI features.")
        case .moonshot:
            return String(localized: "Enter your Kimi (Moonshot) API key to enable enhanced AI features.")
        case .qwen:
            return String(localized: "Enter your Qwen (Alibaba Dashscope) API key to enable enhanced AI features.")
        }
    }

    private func placeholderForProvider(_ provider: CloudAIProvider) -> String {
        switch provider {
        case .anthropic:
            return String(localized: "sk-ant-api...")
        case .openAI:
            return String(localized: "sk-...")
        case .deepSeek:
            return String(localized: "sk-...")
        case .moonshot:
            return String(localized: "sk-...")
        case .qwen:
            return String(localized: "sk-...")
        }
    }

    @ViewBuilder
    private func instructionsForProvider(_ provider: CloudAIProvider) -> some View {
        switch provider {
        case .anthropic:
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "1. Visit console.anthropic.com"))
                Text(String(localized: "2. Create an account"))
                Text(String(localized: "3. Go to API Keys section"))
                Text(String(localized: "4. Create a new key and copy it here"))
            }
        case .openAI:
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "1. Visit platform.openai.com"))
                Text(String(localized: "2. Create an account"))
                Text(String(localized: "3. Go to API Keys section"))
                Text(String(localized: "4. Create a new secret key and copy it here"))
            }
        case .deepSeek:
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "1. Visit platform.deepseek.com"))
                Text(String(localized: "2. Create an account"))
                Text(String(localized: "3. Go to API Keys section"))
                Text(String(localized: "4. Create a new key and copy it here"))
            }
        case .moonshot:
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "1. Visit platform.moonshot.cn"))
                Text(String(localized: "2. Create an account"))
                Text(String(localized: "3. Go to API Keys section"))
                Text(String(localized: "4. Create a new key and copy it here"))
            }
        case .qwen:
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "1. Visit dashscope.aliyun.com"))
                Text(String(localized: "2. Create an account"))
                Text(String(localized: "3. Go to API Keys section"))
                Text(String(localized: "4. Create a new key and copy it here"))
            }
        }
    }

    private func saveAPIKey() {
        APIKeyManager.saveCloudAPIKey(apiKey)
        APIKeyManager.saveCloudAIProvider(selectedProvider)
        // 重置共享实例，重新加载
        HybridAIService.shared.reload()
        showSaveConfirmation = true
    }

    private func clearAPIKey() {
        APIKeyManager.clearCloudAPIKey()
        apiKey = ""
        // 重置共享实例
        HybridAIService.shared.reload()
    }
}

#Preview {
    NavigationStack {
        APIKeySettingsView()
    }
    .withAppServices()
}
