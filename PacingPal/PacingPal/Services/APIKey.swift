// PacingPal
// APIKey.swift
// API Key 管理 - 从 UserDefaults 读取，用户可在 Settings 中设置
// 支持多个云端 AI 提供者：Anthropic Claude, OpenAI, DeepSeek, Kimi, Qwen

import Foundation

// CloudAIProvider is defined in AIService.swift
enum APIKeyManager {
    private static let cloudAPIKeyKey = "pacingpal_cloud_api_key"
    private static let cloudAIProviderKey = "pacingpal_cloud_ai_provider"

    /// 获取当前选中的云端 AI 提供者
    static func getCloudAIProvider() -> CloudAIProvider {
        let rawValue = UserDefaults.standard.string(forKey: cloudAIProviderKey) ?? CloudAIProvider.deepSeek.rawValue
        return CloudAIProvider(rawValue: rawValue) ?? .deepSeek
    }

    /// 保存选中的云端 AI 提供者
    static func saveCloudAIProvider(_ provider: CloudAIProvider) {
        UserDefaults.standard.set(provider.rawValue, forKey: cloudAIProviderKey)
    }

    /// 获取云端 API Key
    static func getCloudAPIKey() -> String? {
        // If already saved in UserDefaults, use that
        if let key = UserDefaults.standard.string(forKey: cloudAPIKeyKey), !key.isEmpty {
            return key
        }
        // Default for development - DeepSeek API key provided by user
        return "sk-77c1c6eafd0e4923889764cbd116c27b"
    }

    /// 保存云端 API Key
    static func saveCloudAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: cloudAPIKeyKey)
    }

    /// 清除 API Key
    static func clearCloudAPIKey() {
        UserDefaults.standard.removeObject(forKey: cloudAPIKeyKey)
    }

    /// 检查是否有云端 API Key
    static func hasCloudAPIKey() -> Bool {
        return getCloudAPIKey() != nil
    }

    /// 兼容旧版：迁移旧的 Claude API Key
    static func migrateIfNeeded() {
        if getCloudAPIKey() == nil {
            // 检查旧存储
            if let oldKey = UserDefaults.standard.string(forKey: "pacingpal_claude_api_key"),
               !oldKey.isEmpty {
                saveCloudAPIKey(oldKey)
                saveCloudAIProvider(.anthropic)
                UserDefaults.standard.removeObject(forKey: "pacingpal_claude_api_key")
            }
        }
    }
}
