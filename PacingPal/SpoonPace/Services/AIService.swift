// SpoonPace
// AIService.swift
// AI 服务 - Natural Language Extraction + Weekly Insights
// 架构：云端 API（增强质量，支持多个提供者） + 本地规则提取（always available fallback）

import Foundation

protocol AIServiceProtocol {
    func extractFromNaturalText(_ text: String) async throws -> AIExtractResult
    func generateWeeklyInsight(entries: [DailySummary]) async throws -> String
}

struct AIExtractResult: Codable {
    let activityName: String?
    let energyCost: Double?
    let symptomType: String?
    let symptomSeverity: Int?
    let error: String?
}

struct SymptomData: Codable {
    let name: String
    let severity: Int
}

struct ActivityData: Codable {
    let name: String
    let cost: Double
}

struct DailySummary: Codable {
    let date: Date
    let totalEnergyUsed: Double
    let budget: Double
    let overBudget: Bool
    let averageSymptomSeverity: Double
    let symptoms: [SymptomData]
    let activities: [ActivityData]

    // HealthKit synchronized data (optional, only available if user enabled
    let stepCount: Double?
    let activeEnergyBurned: Double?
    let restingHeartRate: Double?
    let sleepDurationHours: Double?

    init(
        date: Date,
        totalEnergyUsed: Double,
        budget: Double,
        overBudget: Bool,
        averageSymptomSeverity: Double,
        symptoms: [SymptomData],
        activities: [ActivityData],
        stepCount: Double? = nil,
        activeEnergyBurned: Double? = nil,
        restingHeartRate: Double? = nil,
        sleepDurationHours: Double? = nil
    ) {
        self.date = date
        self.totalEnergyUsed = totalEnergyUsed
        self.budget = budget
        self.overBudget = overBudget
        self.averageSymptomSeverity = averageSymptomSeverity
        self.symptoms = symptoms
        self.activities = activities
        self.stepCount = stepCount
        self.activeEnergyBurned = activeEnergyBurned
        self.restingHeartRate = restingHeartRate
        self.sleepDurationHours = sleepDurationHours
    }
}

enum AIError: Error {
    case invalidResponse
    case parsingError
    case apiError(String)
    case apiKeyNotConfigured
    case modelNotAvailable
}

enum CloudAIProvider: String, CaseIterable {
    case anthropic = "Anthropic Claude"
    case openAI = "OpenAI GPT"
    case deepSeek = "DeepSeek"
    case moonshot = "Kimi (Moonshot)"
    case qwen = "Qwen (Alibaba)"
}

// MARK: - 本地规则基 AI 服务（轻量，无需模型，always available 兼容所有 iOS 版本）

@MainActor
final class LocalRuleBasedAIService: AIServiceProtocol {

    // 预定义活动和能量消耗范围
    private let activityPatterns: [(pattern: String, name: String, cost: Double)] = [
        // 洗澡
        ("shower|showering|bathe|bath", "Shower", 2.0),
        // 做饭
        ("cook|cooking|made dinner|made lunch", "Cooking", 2.5),
        // 散步
        ("walk.*10|walking.*10 minute|10 min walk", "Walking (10min)", 1.0),
        ("walk.*20|walking.*20|20 min walk", "Walking (20min)", 2.0),
        ("walk.*30|walking.*30|30 min walk", "Walking (30min)", 2.5),
        // 购物
        ("grocery|shopping", "Grocery Shopping", 3.0),
        // 工作
        ("work.*1 hour|working 1h", "Work (1h)", 3.5),
        ("work.*2 hour|working 2h", "Work (2h)", 7.0),
        // 社交
        ("social|gathering|party|meet up", "Social Gathering", 4.5),
        // 看电视
        ("tv|television|watch tv", "Watching TV", 1.0),
        // 看书
        ("read|reading|book", "Reading", 1.0),
        // 睡觉
        ("sleep|nap|napping", "Sleep", 0.5),
        // 锻炼
        ("exercise|workout|gym", "Exercise", 4.0),
        // 打扫
        ("clean|cleaning|tidy", "Cleaning", 3.0),
        // 洗衣服
        ("laundry|wash clothes", "Laundry", 2.0),
    ]

    // 预定义症状
    private let symptomPatterns: [(pattern: String, name: String)] = [
        ("fatigue|tired|exhausted", "Fatigue"),
        ("pain|ache|aching", "Pain"),
        ("headache|head ache", "Headache"),
        ("migraine", "Migraine"),
        ("brain fog|brainfog|fog", "Brain Fog"),
        ("short.*breath|breathless", "Shortness of breath"),
        ("sleep.*issue|insomnia|can't sleep", "Sleep issues"),
        ("nausea|sick to stomach", "Nausea"),
        ("heart.*palpitation|palpitations", "Heart palpitations"),
        ("dizzy|dizziness", "Dizziness"),
    ]

    init() {}

    func extractFromNaturalText(_ text: String) async throws -> AIExtractResult {
        let lowercased = text.lowercased()

        // 提取活动
        var extractedActivity: (name: String, cost: Double)?
        for (pattern, name, cost) in activityPatterns {
            if containsPattern(lowercased, pattern: pattern) {
                extractedActivity = (name, cost)
                break // 只取第一个匹配
            }
        }

        // 提取症状
        var extractedSymptom: (name: String, severity: Int)?
        for (pattern, name) in symptomPatterns {
            if containsPattern(lowercased, pattern: pattern) {
                // 尝试查找严重程度 0-10
                let severity = findSeverity(in: lowercased) ?? 5
                extractedSymptom = (name, severity)
                break
            }
        }

        // 如果都没找到，尝试从文本中猜测
        if extractedActivity == nil && extractedSymptom == nil {
            // 尝试找任意数字作为能量消耗
            if let number = findNumber(in: lowercased) {
                // 看看附近有没有活动关键词
                if lowercased.contains("spoon") || lowercased.contains("energy") {
                    extractedActivity = ("Activity", number)
                }
            }
        }

        return AIExtractResult(
            activityName: extractedActivity?.name,
            energyCost: extractedActivity?.cost,
            symptomType: extractedSymptom?.name,
            symptomSeverity: extractedSymptom?.severity,
            error: nil
        )
    }

    func generateWeeklyInsight(entries: [DailySummary]) async throws -> String {
        // 基于统计数据生成基本洞察
        let totalDays = entries.count
        guard totalDays > 0 else {
            let observation = String(localized: "**Weekly Observations**\n• Not enough data yet to generate analysis. Keep tracking for a few days to see your energy patterns!")
            let wins = String(localized: "**Weekly Wins**\n• You've started tracking - that's already a great first step!")
            let suggestion = String(localized: "**Gentle Suggestions**\n• Spend one minute a day logging activities and symptoms. After a few days you'll get personalized insights.")
            let encouragement1 = String(localized: "**Encouragement**")
            let encouragement2 = String(localized: "Worsening symptoms aren't your fault, it's just your body telling you its limits")
            let encouragement3 = String(localized: "You keep tracking and taking care of yourself, you're already doing amazingly well")
            let encouragement4 = String(localized: "No matter how this week went, you're learning about yourself, and that's enough")
            let closing = String(localized: "I'm here with you, accepting you exactly as you are.")

            return """
\(observation)

\(wins)

\(suggestion)

\(encouragement1)
\(encouragement2)
\(encouragement3)
\(encouragement4)

\(closing)
"""
        }

        // MARK: Step 1 - 计算核心指标
        // 1. 平均症状评分
        let totalSymptomDays = entries.filter { $0.averageSymptomSeverity > 0 }.count
        let totalSymptomScore = entries.reduce(0.0) { $0 + $1.averageSymptomSeverity }
        let avgSymptomScore = totalSymptomDays > 0 ? totalSymptomScore / Double(totalSymptomDays) : 0.0

        // 2. 能量消耗
        let overBudgetDays = entries.filter { $0.overBudget }.count

        // 3. 活动-症状关联分析
        var hasDelayedWorsening = false
        var hasRecoveryAfterRest = false

        for i in 0..<entries.count where i + 1 < entries.count {
            let day = entries[i]
            let nextDay = entries[i + 1]
            // 如果当天超标，次日症状上升 ≥ 2 分
            if day.overBudget && nextDay.averageSymptomSeverity > day.averageSymptomSeverity + 2 {
                hasDelayedWorsening = true
            }
            // 如果当天低消耗，次日症状下降
            if day.totalEnergyUsed < day.budget * 0.5 && nextDay.averageSymptomSeverity < day.averageSymptomSeverity {
                hasRecoveryAfterRest = true
            }
        }

        // MARK: Step 2 - 匹配场景
        // 轻度：0-1，中度：2-3，重度：4-5
        let weeklySymptomLevel: SymptomLevel
        switch avgSymptomScore {
        case 0...1: weeklySymptomLevel = .mild
        case 2...3: weeklySymptomLevel = .moderate
        default: weeklySymptomLevel = .severe
        }

        let energyLevel: EnergyLevel
        if overBudgetDays == 0 {
            energyLevel = .noOverbudget
        } else if overBudgetDays == 1 && avgSymptomScore <= 1 {
            energyLevel = .mildOverbudget
        } else {
            energyLevel = .severeOverbudget
        }

        // 获取场景模板
        let template = getTemplateFor(
            symptomLevel: weeklySymptomLevel,
            energyLevel: energyLevel,
            hasDelayedWorsening: hasDelayedWorsening,
            hasRecoveryAfterRest: hasRecoveryAfterRest,
            avgSymptomScore: avgSymptomScore
        )

        // Add date header (localized)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: Date())

        let title = String(localized: "SpoonPace Weekly Insight")
        let generated = String(localized: "Generated %@")

        // Return full insight with generation date
        return """
# \(title)

* \(String(format: generated, dateString)) *

\(template)
"""
    }

    // MARK: - 场景定义
    private enum SymptomLevel {
        case mild      // 0-1
        case moderate  // 2-3
        case severe    // 4-5
    }

    private enum EnergyLevel {
        case noOverbudget      // 无超标
        case mildOverbudget    // 1天轻微超标
        case severeOverbudget // ≥2天严重超标
    }

    // MARK: - 根据匹配结果获取对应模板
    private func getTemplateFor(
        symptomLevel: SymptomLevel,
        energyLevel: EnergyLevel,
        hasDelayedWorsening: Bool,
        hasRecoveryAfterRest: Bool,
        avgSymptomScore: Double
    ) -> String {
        switch (symptomLevel, energyLevel) {
        // 场景 1：轻度症状 + 能量未超标 + 恢复良好
        case (.mild, .noOverbudget):
            if avgSymptomScore <= 0.1 {
                return scene7() // 全程休息 + 无症状
            }
            return scene1()

        // 场景 2：轻度症状 + 能量轻微超标 + 恢复良好
        case (.mild, .mildOverbudget):
            return scene2()

        // 场景 3：中度症状 + 能量超标 + 延迟加重
        case (.moderate, _) where hasDelayedWorsening:
            return scene3()

        // 场景 4：中度症状 + 能量未超标 + 休息充足
        case (.moderate, .noOverbudget):
            return scene4()

        // 场景 6：重度症状 + 全程休息 + 症状回落
        case (.severe, .noOverbudget) where hasRecoveryAfterRest:
            return scene6()

        // 场景 5：重度症状 + 能量严重超标 + 恢复缓慢
        case (.severe, _):
            return scene5()

        // 默认 fallback 到场景 1
        default:
            return scene1()
        }
    }

    // MARK: - Scene Template 1: Mild symptoms + within energy budget + good recovery
    private func scene1() -> String {
        return String(localized: """
**Weekly Observations**
Your body has been very stable this week. Daily energy usage has stayed within your budget, symptoms have remained mild with no worsening. Adequate rest has helped your body maintain stable condition.

**Weekly Wins**
• You've stayed accurately within your energy limits, no over-consumption this week
• You've kept consistent daily tracking and paid close attention to your body - this persistence is precious
• You've maintained a gentle life rhythm, giving your body plenty of rest time

**Gentle Suggestions**
If you're comfortable with your current state, keep doing what you're doing - no need to force changes. If you'd like to try a little more activity, you can add very small low-energy movements if your body allows, always stopping before you feel tired.

**Encouragement**
Worsening symptoms aren't your fault, it's just your body telling you its limits
You keep tracking and taking care of yourself, you're already doing amazingly well
No matter how this week went, you're learning about yourself, and that's enough

Your steady pace is caring for your body, every bit of patience with yourself matters. You don't need to chase "getting better" - staying comfortable is the best progress on your recovery journey. You're doing great. I'm here with you, accepting you exactly as you are.
""")
    }

    // MARK: - Scene Template 2: Mild symptoms + mild energy overbudget + good recovery
    private func scene2() -> String {
        return String(localized: """
**Weekly Observations**
Most of this week your energy usage stayed within a reasonable range, only one day had mild overbudgeting. Your body recovered well, and after prompt rest there was no noticeable symptom change. Overall condition remains stable.

**Weekly Wins**
• You adjusted and rested promptly after going over budget, quickly returning your body to stable condition
• You can clearly feel changes in your body and adjust with rest - you know how to take good care of yourself
• Symptoms stayed mild all week, not putting too much extra strain on your body

**Gentle Suggestions**
If you're feeling up to it, you might consider reflecting on the day you went over budget. In the future you could try shortening those activities slightly - no need to give them up completely. Just a small reduction in energy expenditure helps fit better with your budget, without adding extra stress to your body.

**Encouragement**
Worsening symptoms aren't your fault, it's just your body telling you its limits
You keep tracking and taking care of yourself, you're already doing amazingly well
No matter how this week went, you're learning about yourself, and that's enough

Occasional energy overbudget is never your fault - occasional fluctuations are normal in recovery. The fact that you notice and adjust already means you're doing the right thing. Just keep being gentle with yourself. I'm here with you, accepting you exactly as you are.
""")
    }

    // MARK: - Scene Template 3: Moderate symptoms + energy overbudget + delayed worsening
    private func scene3() -> String {
        return String(localized: """
**Weekly Observations**
This week there were days with energy overbudget. After activity, your body experienced noticeable delayed symptom worsening. Even after subsequent rest, symptoms have only partially improved and remain at a moderate level. It's clear your body needs more time to recover.

**Weekly Wins**
• When symptoms worsened, you didn't push yourself - you consistently chose rest first, honoring your body's signals
• You've kept recording every change in your body, helping you understand your condition clearly
• You haven't blamed yourself for the fluctuations - you've maintained a peaceful mindset

**Gentle Suggestions**
If your state allows, you might consider splitting high-energy activities into smaller segments, resting after each one to avoid building up too much fatigue at once. If you're feeling tired, it's also fine to pause all activities and focus on deep rest.

**Encouragement**
Worsening symptoms aren't your fault, it's just your body telling you its limits
You keep tracking and taking care of yourself, you're already doing amazingly well
No matter how this week went, you're learning about yourself, and that's enough

Symptom fluctuations are just your body reminding you of its current limits - this doesn't mean you're doing something wrong. The fact that you listen to and care for your body already makes you amazing. Recovery is inherently slow, there's no rush. I'm here with you, accepting you exactly as you are.
""")
    }

    // MARK: - Scene Template 4: Moderate symptoms + within energy budget + adequate rest
    private func scene4() -> String {
        return String(localized: """
**Weekly Observations**
This week you've carefully managed your energy consumption, stayed within budget the entire week, and maintained plenty of rest. Symptoms haven't worsened further and remain moderately stable. Your body has been nurtured with adequate rest.

**Weekly Wins**
• You've consistently respected your body's energy limits, not overextending yourself
• You've kept a regular rest routine, giving your body all the time it needs to heal
• You haven't felt anxious about your stable condition - you've maintained patience

**Gentle Suggestions**
Just keep your current rest and energy pattern - no need to force more activity. Recovery takes time, maintaining stability is the most important step. Always prioritize your own comfort.

**Encouragement**
Worsening symptoms aren't your fault, it's just your body telling you its limits
You keep tracking and taking care of yourself, you're already doing amazingly well
No matter how this week went, you're learning about yourself, and that's enough

Your careful nurturing of your body shows in your stable condition. Moving slowly and step-by-step is the perfect approach for recovery. You're really doing well and you deserve to acknowledge that. I'm here with you, accepting you exactly as you are.
""")
    }

    // MARK: - Scene Template 5: Severe symptoms + severe energy overbudget + slow recovery
    private func scene5() -> String {
        return String(localized: """
**Weekly Observations**
This week you had severe energy overbudget which directly triggered severe symptoms. Your body has been slow to recover, and even with rest, symptom improvement hasn't been significant. It's clear your body needs deep rest right now.

**Weekly Wins**
• Even when you felt extremely unwell, you didn't push through - you prioritized resting quietly. This was the correct choice
• You've kept tracking your body data, helping you understand your body's limits clearly
• You haven't given up on caring for yourself - this persistence takes real courage

**Gentle Suggestions**
At this stage you don't need to think about any activity - focus on deep rest and let your body fully relax. There's no need to feel guilty about it. Stopping completely and resting peacefully is the best thing you can do for your body right now.

**Encouragement**
Worsening symptoms aren't your fault, it's just your body telling you its limits
You keep tracking and taking care of yourself, you're already doing amazingly well
No matter how this week went, you're learning about yourself, and that's enough

Worsening symptoms aren't your mistake - it's just your body sending a signal that it needs complete rest. Please don't blame yourself. Recovery naturally has ups and downs. You've done the best you can taking care of yourself. I'm here with you.
""")
    }

    // MARK: - Scene Template 6: Severe symptoms + full rest + symptom improvement
    private func scene6() -> String {
        return String(localized: """
**Weekly Observations**
This week you chose to take complete deep rest, doing no energy-consuming activities. Your previously severe symptoms have gradually improved, and your body has responded very positively to adequate rest. The benefits of your rest are clear.

**Weekly Wins**
• You made the brave choice to prioritize rest, making the decision that was best for your body
• Your body has improved with thorough rest - this proves your self-care is working
• You've stayed calm through discomfort, giving your body the patience it needs

**Gentle Suggestions**
Continue with your current rest rhythm. There's no rush to try new activities. Wait until symptoms are more stable and you feel completely comfortable before considering even very light activity. Let everything happen naturally.

**Encouragement**
Worsening symptoms aren't your fault, it's just your body telling you its limits
You keep tracking and taking care of yourself, you're already doing amazingly well
No matter how this week went, you're learning about yourself, and that's enough

Choosing to listen to your body and rest fully was the right and brave decision. Seeing symptoms gradually ease is the best feedback your body can give. Just keep being gentle with yourself and take it slowly. I'm here with you, accepting you exactly as you are.
""")
    }

    // MARK: - Scene Template 7: Full rest + no symptoms
    private func scene7() -> String {
        return String(localized: """
**Weekly Observations**
This week you focused entirely on rest, with no energy-consuming activities. Your body has stayed comfortably symptom-free the entire week with no discomfort. Adequate rest has left your body in an ideally relaxed state.

**Weekly Wins**
• You've let your body fully relax, achieving a week of comfortable symptom-free living
• You've been able to let go of anxiety, rest peacefully, and be kind to your body
• You've maintained regular tracking, giving you clear awareness of your condition

**Gentle Suggestions**
You can continue with this comfortable rhythm. If you'd like to try a little activity, start with very short, zero-energy movements. Always stop before you feel any discomfort and don't disrupt your stable condition.

**Encouragement**
Worsening symptoms aren't your fault, it's just your body telling you its limits
You keep tracking and taking care of yourself, you're already doing amazingly well
No matter how this week went, you're learning about yourself, and that's enough

Being able to keep your body in a comfortable, symptom-free state is the best recovery outcome. You don't need to chase "progress" - enjoying your current comfort and caring for this stability is the perfect state. I'm happy for you. I'm here with you, accepting you exactly as you are.
""")
    }

    // MARK: - Helpers

    private func containsPattern(_ text: String, pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "\\b\(pattern)\\b", options: .caseInsensitive)
            return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
        } catch {
            return text.contains(pattern)
        }
    }

    private func findNumber(in text: String) -> Double? {
        do {
            let regex = try NSRegularExpression(pattern: "\\d+(\\.\\d+)?", options: [])
            if let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                let range = Range(match.range, in: text)!
                let numberString = String(text[range])
                return Double(numberString)
            }
            return nil
        } catch {
            return nil
        }
    }

    private func findSeverity(in text: String) -> Int? {
        // 查找 X/10 或 X out of 10 或 X 程度
        do {
            let regex = try NSRegularExpression(pattern: "(\\d)\\s*\\/\\s*10|(\\d)\\s*(out of|out of|of)\\s*10|severity\\s*(\\d)", options: [])
            if let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                for i in 1..<match.numberOfRanges {
                    if let range = Range(match.range(at: i), in: text) {
                        let numStr = text[range]
                        if let num = Int(numStr), num >= 0 && num <= 10 {
                            return num
                        }
                    }
                }
            }
            // 直接找 1-10 的数字
            if let num = findNumber(in: text) {
                let intNum = Int(num)
                if intNum >= 0 && intNum <= 10 {
                    return intNum
                }
            }
            return nil
        } catch {
            return nil
        }
    }
}

// MARK: - 混合 AI 服务（云端优先，本地规则 fallback）

@MainActor
final class HybridAIService: AIServiceProtocol {

    // 本地规则提取服务（always available）
    private let localRuleService = LocalRuleBasedAIService()

    // 云端服务（可选，用户配置 API Key 后启用）
    private let cloudService: CloudAIService?

    // 使用云端优先还是本地优先
    private let preferCloud: Bool

    // 并发安全单例 - 使用 static var 支持重新加载
    static private(set) var shared: HybridAIService = HybridAIService()

    init() {
        self.preferCloud = APIKeyManager.hasCloudAPIKey()

        // 根据配置初始化云端服务
        if let key = APIKeyManager.getCloudAPIKey(), !key.isEmpty {
            let provider = APIKeyManager.getCloudAIProvider()
            self.cloudService = CloudAIService(provider: provider, apiKey: key)
        } else {
            self.cloudService = nil
        }
    }

    func extractFromNaturalText(_ text: String) async throws -> AIExtractResult {
        // 如果配置了云端，先尝试云端
        if preferCloud, let cloud = cloudService {
            do {
                return try await cloud.extractFromNaturalText(text)
            } catch {
                print("Cloud AI failed, falling back to local: \(error)")
            }
        }

        // 默认使用本地规则提取（always available）
        return try await localRuleService.extractFromNaturalText(text)
    }

    func generateWeeklyInsight(entries: [DailySummary]) async throws -> String {
        // 如果有云端，使用云端生成更优质的洞察
        if let cloud = cloudService {
            do {
                return try await cloud.generateWeeklyInsight(entries: entries)
            } catch {
                print("Cloud AI failed for weekly insight, falling back to local: \(error)")
            }
        }

        // 本地生成基于统计的基本洞察（always available）
        return try await localRuleService.generateWeeklyInsight(entries: entries)
    }

    /// API Key 更新后重新加载共享实例
    func reload() {
        Self.shared = HybridAIService()
    }
}

// MARK: - 云端 AI 服务（支持多个提供者）

@MainActor
final class CloudAIService: AIServiceProtocol {
    private let provider: CloudAIProvider
    private let apiKey: String

    init(provider: CloudAIProvider, apiKey: String) {
        self.provider = provider
        self.apiKey = apiKey
    }

    func extractFromNaturalText(_ text: String) async throws -> AIExtractResult {
        switch provider {
        case .anthropic:
            return try await sendAnthropicRequest(prompt: buildExtractPrompt(text), responseFormat: AIExtractResult.self, maxTokens: 200)
        case .openAI:
            return try await sendOpenAIRequest(prompt: buildExtractPrompt(text), responseFormat: AIExtractResult.self, maxTokens: 200)
        case .deepSeek:
            return try await sendDeepSeekRequest(prompt: buildExtractPrompt(text), responseFormat: AIExtractResult.self, maxTokens: 200)
        case .moonshot:
            return try await sendKimiRequest(prompt: buildExtractPrompt(text), responseFormat: AIExtractResult.self, maxTokens: 200)
        case .qwen:
            return try await sendQwenRequest(prompt: buildExtractPrompt(text), responseFormat: AIExtractResult.self, maxTokens: 200)
        }
    }

    // MARK: - ReAct Structured Workflow
    // Step 0: Local statistics (done in Swift, no AI needed - fully controllable)
    private struct WeeklyStatistics {
        let totalDaysTracked: Int
        let totalActivities: Int
        let totalSymptomsLogged: Int
        let overBudgetDays: Int
        let averageDailyEnergyUse: Double
        let hasDelayedSymptomPattern: Bool
        let hasRestImprovementPattern: Bool
        let mostCommonSymptom: String?
        let highestActivityDay: (date: Date, activities: Int, energyUsed: Double)?
    }

    private func analyzeDataLocally(entries: [DailySummary]) -> WeeklyStatistics {
        let totalDays = entries.count
        let totalActivities = entries.reduce(0) { $0 + $1.activities.count }
        let totalSymptoms = entries.reduce(0) { $0 + $1.symptoms.count }
        let overBudgetDays = entries.filter { $0.overBudget }.count
        let averageEnergy = entries.reduce(0.0) { $0 + $1.totalEnergyUsed } / Double(totalDays)

        // Check for delayed symptom pattern: activity day -> next day more severe symptoms
        var hasDelayedPattern = false
        var hasRestImprovement = false

        for i in 0..<entries.count where i + 1 < entries.count {
            let day = entries[i]
            let nextDay = entries[i + 1]
            // If day has high activity/over budget and next day has higher average symptom severity
            if day.overBudget && nextDay.averageSymptomSeverity > day.averageSymptomSeverity + 1 {
                hasDelayedPattern = true
            }
        }

        // Check for rest improvement: day with low activity -> next day lower symptoms
        for i in 0..<entries.count where i + 1 < entries.count {
            let day = entries[i]
            let nextDay = entries[i + 1]
            if day.totalEnergyUsed < day.budget * 0.5 && nextDay.averageSymptomSeverity < day.averageSymptomSeverity {
                hasRestImprovement = true
            }
        }

        // Find most common symptom
        var symptomCounts: [String: Int] = [:]
        for entry in entries {
            for symptom in entry.symptoms {
                symptomCounts[symptom.name, default: 0] += 1
            }
        }
        let mostCommon = symptomCounts.max { $0.value < $1.value }
        let mostCommonSymptom = mostCommon?.key

        // Find highest activity day (by energy used)
        let highestDay = entries.max { $0.totalEnergyUsed < $1.totalEnergyUsed }
        let highestActivityDay = highestDay.flatMap {
            (date: $0.date, activities: $0.activities.count, energyUsed: $0.totalEnergyUsed)
        }

        return WeeklyStatistics(
            totalDaysTracked: totalDays,
            totalActivities: totalActivities,
            totalSymptomsLogged: totalSymptoms,
            overBudgetDays: overBudgetDays,
            averageDailyEnergyUse: averageEnergy,
            hasDelayedSymptomPattern: hasDelayedPattern,
            hasRestImprovementPattern: hasRestImprovement,
            mostCommonSymptom: mostCommonSymptom,
            highestActivityDay: highestActivityDay
        )
    }

    func generateWeeklyInsight(entries: [DailySummary]) async throws -> String {
        // ReAct Workflow: Step 0 - Local analysis in Swift (fully controllable)
        let stats = analyzeDataLocally(entries: entries)
        let jsonData = try JSONEncoder().encode(entries)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Step 1 - Get observations from AI
        let observationPrompt = buildObservationPrompt(jsonString: jsonString, stats: stats)
        let observation: String

        switch provider {
        case .anthropic:
            observation = try await sendAnthropicTextRequest(prompt: observationPrompt, maxTokens: 150)
        case .openAI:
            observation = try await sendOpenAITextRequest(prompt: observationPrompt, maxTokens: 150)
        case .deepSeek:
            observation = try await sendDeepSeekTextRequest(prompt: observationPrompt, maxTokens: 150)
        case .moonshot:
            observation = try await sendKimiTextRequest(prompt: observationPrompt, maxTokens: 150)
        case .qwen:
            observation = try await sendQwenTextRequest(prompt: observationPrompt, maxTokens: 150)
        }

        // Step 2 - Get bright spots (small wins)
        let brightSpotPrompt = buildBrightSpotPrompt(jsonString: jsonString, stats: stats)
        let brightSpots: String

        switch provider {
        case .anthropic:
            brightSpots = try await sendAnthropicTextRequest(prompt: brightSpotPrompt, maxTokens: 120)
        case .openAI:
            brightSpots = try await sendOpenAITextRequest(prompt: brightSpotPrompt, maxTokens: 120)
        case .deepSeek:
            brightSpots = try await sendDeepSeekTextRequest(prompt: brightSpotPrompt, maxTokens: 120)
        case .moonshot:
            brightSpots = try await sendKimiTextRequest(prompt: brightSpotPrompt, maxTokens: 120)
        case .qwen:
            brightSpots = try await sendQwenTextRequest(prompt: brightSpotPrompt, maxTokens: 120)
        }

        // Step 3 - Get gentle suggestion
        let suggestionPrompt = buildSuggestionPrompt(jsonString: jsonString, stats: stats)
        let suggestion: String

        switch provider {
        case .anthropic:
            suggestion = try await sendAnthropicTextRequest(prompt: suggestionPrompt, maxTokens: 100)
        case .openAI:
            suggestion = try await sendOpenAITextRequest(prompt: suggestionPrompt, maxTokens: 100)
        case .deepSeek:
            suggestion = try await sendDeepSeekTextRequest(prompt: suggestionPrompt, maxTokens: 100)
        case .moonshot:
            suggestion = try await sendKimiTextRequest(prompt: suggestionPrompt, maxTokens: 100)
        case .qwen:
            suggestion = try await sendQwenTextRequest(prompt: suggestionPrompt, maxTokens: 100)
        }

        // Step 4 - Get encouragement
        let encouragementPrompt = buildEncouragementPrompt(stats: stats)
        let encouragement: String

        switch provider {
        case .anthropic:
            encouragement = try await sendAnthropicTextRequest(prompt: encouragementPrompt, maxTokens: 120)
        case .openAI:
            encouragement = try await sendOpenAITextRequest(prompt: encouragementPrompt, maxTokens: 120)
        case .deepSeek:
            encouragement = try await sendDeepSeekTextRequest(prompt: encouragementPrompt, maxTokens: 120)
        case .moonshot:
            encouragement = try await sendKimiTextRequest(prompt: encouragementPrompt, maxTokens: 120)
        case .qwen:
            encouragement = try await sendQwenTextRequest(prompt: encouragementPrompt, maxTokens: 120)
        }

        // Step 5 - Combine into final report
        // Add date header (localized)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: Date())

        let title = String(localized: "SpoonPace Weekly Insight")
        let generated = String(localized: "Generated %@")

        return """
# \(title)

* \(String(format: generated, dateString)) *

**\(String(localized: "Weekly Observations"))**
\(observation.trimmingCharacters(in: .whitespacesAndNewlines))

**\(String(localized: "Weekly Wins"))**
\(brightSpots.trimmingCharacters(in: .whitespacesAndNewlines))

**\(String(localized: "Gentle Suggestions"))**
\(suggestion.trimmingCharacters(in: .whitespacesAndNewlines))

**\(String(localized: "Encouragement"))**
\(encouragement.trimmingCharacters(in: .whitespacesAndNewlines))
"""
    }

    // MARK: - Build prompts for each step

    private func buildObservationPrompt(jsonString: String, stats: WeeklyStatistics) -> String {
let role = String(localized: "You are a warm, empathetic companion for people living with Long COVID / ME/CFS.")
let userDataHeader = String(localized: "Complete user data (including optional HealthKit synced data: steps, active energy, sleep duration, resting heart rate):")
let statsHeader = String(localized: "Statistics:")
let daysTracked = String(localized: "Days tracked this week")
let totalActivities = String(localized: "Total activities")
let overBudgetDays = String(localized: "Days over energy budget")
let avgDailyEnergy = String(localized: "Average daily energy usage")
let delayedWorsening = String(localized: "Detected post-activity delayed symptom worsening")
let restImprovement = String(localized: "Detected symptom improvement after rest")
let mostCommonSymptom = String(localized: "Most common symptom")
let combineHealthData = String(localized: "If you have health sync data, analyze connections between steps, sleep, heart rate and symptoms.")
let instructions = String(localized: "Output only **1-2 objective observations**, each starting with bullet •")
let rules = """
\(String(localized: "Rules:"))
- \(String(localized: "State only facts, no judgment"))
- \(String(localized: "Focus on connection patterns between energy/activity/sleep/symptoms"))
- \(String(localized: "Do NOT use 'you should / you must'"))
- \(String(localized: "Keep it brief, one or two sentences each"))
- \(String(localized: "Total under 100 words"))
"""

return """
\(role)

\(userDataHeader)
\(jsonString)

\(statsHeader)
- \(daysTracked): \(stats.totalDaysTracked)
- \(totalActivities): \(stats.totalActivities)
- \(overBudgetDays): \(stats.overBudgetDays)
- \(avgDailyEnergy): \(String(format: "%.1f", stats.averageDailyEnergyUse)) \(String(localized: "spoons"))
- \(delayedWorsening): \(stats.hasDelayedSymptomPattern ? String(localized: "Yes") : String(localized: "No"))
- \(restImprovement): \(stats.hasRestImprovementPattern ? String(localized: "Yes") : String(localized: "No"))
- \(mostCommonSymptom): \(stats.mostCommonSymptom ?? String(localized: "None"))

\(combineHealthData)

\(instructions)
\(rules)
"""
    }

    private func buildBrightSpotPrompt(jsonString: String, stats: WeeklyStatistics) -> String {
let role = String(localized: "You are a warm, empathetic companion for people living with Long COVID / ME/CFS.")
let userDataHeader = String(localized: "User data this week:")
let statsSummary = String(localized: "Stats: %lld days tracked, %lld activities.")
let instructions = String(localized: "Find **1-2 specific small wins / good things** the user did this week.")
let directions = """
\(String(localized: "Directions:"))
- \(String(localized: "Consistent tracking is already a win"))
- \(String(localized: "Choosing rest when tired"))
- \(String(localized: "Noticing body signals"))
- \(String(localized: "Not being hard on yourself"))
- \(String(localized: "Any positive attempt counts"))
"""
let closing = String(localized: "Start each with bullet •, keep it warm and sincere. Total under 80 words.")

return """
\(role)

\(userDataHeader)
\(jsonString)

\(String(format: statsSummary, stats.totalDaysTracked, stats.totalActivities))

\(instructions)
\(directions)

\(closing)
"""
    }

    private func buildSuggestionPrompt(jsonString: String, stats: WeeklyStatistics) -> String {
let role = String(localized: "You are a warm, empathetic companion for people living with Long COVID / ME/CFS.")
let userDataHeader = String(localized: "User data this week:")
let detectedPatterns = String(localized: "Detected patterns:")
let delayedWorsening = String(localized: "Post-activity delayed symptom worsening")
let restImprovement = String(localized: "Symptom improvement after rest")
let instructions = String(localized: "Give **one** gentle, zero-pressure suggestion.")
let rules = """
\(String(localized: "Rules:"))
- \(String(localized: "Must start with 'If your state allows, you might consider...'"))
- \(String(localized: "Only one suggestion, 1-2 sentences"))
- \(String(localized: "Completely optional, let the user feel they don't have to do it"))
- \(String(localized: "Base it on their actual data patterns"))
- \(String(localized: "Total under 60 words"))
"""

return """
\(role)

\(userDataHeader)
\(jsonString)

\(detectedPatterns)
- \(delayedWorsening): \(stats.hasDelayedSymptomPattern ? String(localized: "Yes") : String(localized: "No"))
- \(restImprovement): \(stats.hasRestImprovementPattern ? String(localized: "Yes") : String(localized: "No"))

\(instructions)
\(rules)
"""
    }

    private func buildEncouragementPrompt(stats: WeeklyStatistics) -> String {
let role = String(localized: "You are a warm, empathetic companion for people living with Long COVID / ME/CFS.")
let intro = String(localized: "The user has tracked for %lld days this week, it's not easy to keep going.")
let requirements = """
\(String(localized: "Write an encouraging message, **must include these three sentences**:"))
1. \(String(localized: "Worsening symptoms aren't your fault, it's just your body telling you its limits."))
2. \(String(localized: "You keep tracking and taking care of yourself, you're already doing amazingly well."))
3. \(String(localized: "No matter how this week went, you're learning about yourself, and that's enough."))
"""
let closing = String(localized: "Add one gentle closing sentence at the end. Keep it sincere and warm, under 80 words total.")

return """
\(role)

\(String(format: intro, stats.totalDaysTracked))

\(requirements)

\(closing)
"""
    }

    // MARK: - Natural Language Extraction Prompt

    private func buildExtractPrompt(_ text: String) -> String {
let role = String(localized: "You are a helper for an energy tracking app for Long COVID/ME-CFS patients.")
let instruction = String(localized: "Extract activity and/or symptom information from the user's input.")
let userInput = String(localized: "User input")
let format = String(localized: "Respond ONLY with valid JSON in this format:")
let commonActivities = String(localized: "Common activities and typical energy cost (in spoons):")
let shower = String(localized: "- shower: 1-2")
let cooking = String(localized: "- cooking: 2-3")
let walking10 = String(localized: "- walking 10min: 1")
let walking30 = String(localized: "- walking 30min: 2-3")
let shopping = String(localized: "- grocery shopping: 3")
let work = String(localized: "- work 1 hour: 3-4")
let social = String(localized: "- social gathering: 4-5")
let commonSymptoms = String(localized: "Common symptoms: fatigue, pain, headache, migraine, brain fog, shortness of breath, sleep issues, nausea, heart palpitations.")

return """
\(role)
\(instruction)

\(userInput): \(text)

\(format)
{
  "activityName": "name of activity if mentioned, null otherwise",
  "energyCost": estimated energy cost in spoons (0-10), null if unknown,
  "symptomType": "name of symptom if mentioned, null otherwise",
  "symptomSeverity": severity 0-10, null if unknown
}

\(commonActivities)
\(shower)
\(cooking)
\(walking10)
\(walking30)
\(shopping)
\(work)
\(social)

\(commonSymptoms)
"""
    }

    private func buildWeeklyPrompt(_ json: String) -> String {
let role = String(localized: "You are a warm, empathetic, non-judgmental companion for people with Long COVID / ME/CFS, generating a weekly AI health insight report for the user.")
let tone = String(localized: "Your tone should be like a friend who understands - gentle, soft, supportive. Never lecture, blame, or pressure.")
let header = String(localized: "This week's user tracking data (activities, energy usage, symptom logs):")
let instructions = String(localized: "Your report MUST include the following sections, each with specific guidance:")
let weeklyObs = String(localized: "**Weekly Observations**")
let obsGuidelines = """
• \(String(localized: "State only facts, no judgment"))
• \(String(localized: "Focus on:"))
  - \(String(localized: "Connections between activities and energy usage (which days went over budget, what activities caused it)"))
  - \(String(localized: "Delayed symptom responses to activity (how long after activity worsening happened, how long recovery took)"))
  - \(String(localized: "Positive effects of rest (symptom improvement after rest, stable condition)"))
• \(String(localized: "Do NOT use commanding language like 'you should not / you must / you should'"))
"""
let weeklyWins = String(localized: "**Weekly Wins**")
let winsGuidelines = """
• \(String(localized: "Specifically look for what the user did well, even if it's not about symptom improvement"))
• \(String(localized: "Be specific so the user can see their effort"))
• \(String(localized: "Examples: tracking for a full week, resting when tired, trying a new rest approach, not blaming yourself"))
"""
let gentleSuggestions = String(localized: "**Gentle Suggestions**")
let suggestionsGuidelines = """
• \(String(localized: "Only give optional, zero-pressure directions - leave the choice to the user"))
• \(String(localized: "Must start with 'If your state allows, you might consider...' - no forcing"))
• \(String(localized: "Do NOT say 'you need to / you must' - avoid creating anxiety"))
"""
let encouragement = String(localized: "**Encouragement**")
let encouragementGuidelines = """
• \(String(localized: "Core goal: help the user fight self-blame, guilt, and frustration"))
• \(String(localized: "Must include these three sentences:"))
  1. \(String(localized: "Worsening symptoms aren't your fault, it's just your body telling you its limits."))
  2. \(String(localized: "You keep tracking and taking care of yourself, you're already doing amazingly well."))
  3. \(String(localized: "No matter how this week went, you're learning about yourself, and that's enough."))
• \(String(localized: "Add one gentle closing sentence at the end with a feeling of companionship"))
"""
let styleRules = """
\(String(localized: "⚠️ Important Style Rules:"))
- \(String(localized: "Avoid lecturing, judging, blaming throughout - never let the user feel they did something wrong"))
- \(String(localized: "Focus on the user's effort and persistence, not whether symptoms improved"))
- \(String(localized: "All suggestions are optional - the user doesn't have to do anything, make them feel safe and accepted"))
- \(String(localized: "Tone should be like a friend who understands, not a teacher or doctor"))
- \(String(localized: "Keep total response under 300 words"))
"""
let closing = String(localized: "Please generate a personalized weekly report based on the user's specific data this week.")

return """
\(role)
\(tone)

\(header)
\(json)

\(instructions)

\(weeklyObs)
\(obsGuidelines)

\(weeklyWins)
\(winsGuidelines)

\(gentleSuggestions)
\(suggestionsGuidelines)

\(encouragement)
\(encouragementGuidelines)

---
\(styleRules)

\(closing)
"""
    }

    // MARK: - Anthropic Claude Implementation

    private func sendAnthropicRequest<T: Decodable>(prompt: String, responseFormat: T.Type, maxTokens: Int) async throws -> T {
        let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "x-api-key")

        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": maxTokens,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            }
            throw AIError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = json?["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw AIError.invalidResponse
        }

        let cleanText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        guard let jsonData = cleanText.data(using: String.Encoding.utf8) else {
            throw AIError.parsingError
        }

        return try JSONDecoder().decode(T.self, from: jsonData)
    }

    private func sendAnthropicTextRequest(prompt: String, maxTokens: Int) async throws -> String {
        let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "x-api-key")

        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": maxTokens,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            }
            throw AIError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = json?["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw AIError.invalidResponse
        }

        return text
    }

    // MARK: - OpenAI Implementation

    private func sendOpenAIRequest<T: Decodable>(prompt: String, responseFormat: T.Type, maxTokens: Int) async throws -> T {
        let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let messages: [[String: String]] = [
            ["role": "user", "content": prompt]
        ]

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": maxTokens
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            }
            throw AIError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw AIError.invalidResponse
        }

        let cleanText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        guard let jsonData = cleanText.data(using: String.Encoding.utf8) else {
            throw AIError.parsingError
        }

        return try JSONDecoder().decode(T.self, from: jsonData)
    }

    private func sendOpenAITextRequest(prompt: String, maxTokens: Int) async throws -> String {
        let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let messages: [[String: String]] = [
            ["role": "user", "content": prompt]
        ]

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": maxTokens
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            }
            throw AIError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw AIError.invalidResponse
        }

        return text
    }

    // MARK: - DeepSeek Implementation (OpenAI compatible)

    private func sendDeepSeekRequest<T: Decodable>(prompt: String, responseFormat: T.Type, maxTokens: Int) async throws -> T {
        let baseURL = URL(string: "https://api.deepseek.com/chat/completions")!
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let messages: [[String: String]] = [
            ["role": "user", "content": prompt]
        ]

        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": messages,
            "max_tokens": maxTokens
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            }
            throw AIError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw AIError.invalidResponse
        }

        let cleanText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        guard let jsonData = cleanText.data(using: String.Encoding.utf8) else {
            throw AIError.parsingError
        }

        return try JSONDecoder().decode(T.self, from: jsonData)
    }

    private func sendDeepSeekTextRequest(prompt: String, maxTokens: Int) async throws -> String {
        let baseURL = URL(string: "https://api.deepseek.com/chat/completions")!
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let messages: [[String: String]] = [
            ["role": "user", "content": prompt]
        ]

        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": messages,
            "max_tokens": maxTokens
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            }
            throw AIError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw AIError.invalidResponse
        }

        return text
    }

    // MARK: - Kimi (Moonshot) Implementation (OpenAI compatible)

    private func sendKimiRequest<T: Decodable>(prompt: String, responseFormat: T.Type, maxTokens: Int) async throws -> T {
        let baseURL = URL(string: "https://api.moonshot.cn/v1/chat/completions")!
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let messages: [[String: String]] = [
            ["role": "user", "content": prompt]
        ]

        let body: [String: Any] = [
            "model": "moonshot-v1-8k",
            "messages": messages,
            "max_tokens": maxTokens
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            }
            throw AIError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw AIError.invalidResponse
        }

        let cleanText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        guard let jsonData = cleanText.data(using: String.Encoding.utf8) else {
            throw AIError.parsingError
        }

        return try JSONDecoder().decode(T.self, from: jsonData)
    }

    private func sendKimiTextRequest(prompt: String, maxTokens: Int) async throws -> String {
        let baseURL = URL(string: "https://api.moonshot.cn/v1/chat/completions")!
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let messages: [[String: String]] = [
            ["role": "user", "content": prompt]
        ]

        let body: [String: Any] = [
            "model": "moonshot-v1-8k",
            "messages": messages,
            "max_tokens": maxTokens
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            }
            throw AIError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw AIError.invalidResponse
        }

        return text
    }

    // MARK: - Qwen (Alibaba Tongyi) Implementation

    private func sendQwenRequest<T: Decodable>(prompt: String, responseFormat: T.Type, maxTokens: Int) async throws -> T {
        let baseURL = URL(string: "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation")!
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": "qwen2-7b-instruct",
            "input": [
                "messages": [
                    ["role": "user", "content": prompt]
                ]
            ],
            "parameters": [
                "max_tokens": maxTokens,
                "result_format": "message"
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["message"] as? String {
                throw AIError.apiError(error)
            }
            throw AIError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let output = json?["output"] as? [String: Any],
              let choices = output["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? String else {
            throw AIError.invalidResponse
        }

        let cleanText = message
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        guard let jsonData = cleanText.data(using: String.Encoding.utf8) else {
            throw AIError.parsingError
        }

        return try JSONDecoder().decode(T.self, from: jsonData)
    }

    private func sendQwenTextRequest(prompt: String, maxTokens: Int) async throws -> String {
        let baseURL = URL(string: "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation")!
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": "qwen2-7b-instruct",
            "input": [
                "messages": [
                    ["role": "user", "content": prompt]
                ]
            ],
            "parameters": [
                "max_tokens": maxTokens,
                "result_format": "message"
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["message"] as? String {
                throw AIError.apiError(error)
            }
            throw AIError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let output = json?["output"] as? [String: Any],
              let choices = output["choices"] as? [[String: Any]],
              let first = choices.first,
              let text = first["message"] as? String else {
            throw AIError.invalidResponse
        }

        return text
    }
}
