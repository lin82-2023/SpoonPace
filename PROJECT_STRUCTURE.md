# PacingPal - Project Structure

```
PacingPal/
├── PacingPal/
│   ├── App/
│   │   ├── PacingPalApp.swift          # App entry point
│   │   ├── PacingPalApp.entitlements   # iCloud, Sign in with Apple
│   │   └── Info.plist
│   ├── Models/
│   │   ├── EnergyEntry.swift           # 能量记录条目
│   │   ├── SymptomEntry.swift          # 症状记录
│   │   ├── ActivityType.swift          # 活动类型
│   │   ├── DailyEnergyBudget.swift     # 每日能量预算
│   │   └── UserSettings.swift          # 用户设置
│   ├── Views/
│   │   ├── MainTabView.swift           # 主 Tab 栏
│   │   ├── Today/
│   │   │   ├── TodayView.swift         # 今日能量桶首页
│   │   │   └── EnergyBucketView.swift  # 能量可视化组件
│   │   ├── History/
│   │   │   └── CalendarHistoryView.swift  # 日历历史
│   │   ├── AddEntry/
│   │   │   ├── AddEnergyView.swift     # 添加能量记录
│   │   │   ├── AddSymptomView.swift    # 添加症状
│   │   │   └── NaturalLanguageInputView.swift  # AI 自然语言输入
│   │   ├── Insights/
│   │   │   └── WeeklyAIInsightView.swift  # AI 周总结
│   │   └── Settings/
│   │       └── SettingsView.swift
│   ├── ViewModels/
│   │   ├── TodayViewModel.swift
│   │   ├── EnergyViewModel.swift
│   │   ├── HistoryViewModel.swift
│   │   └── AIInsightViewModel.swift
│   ├── Services/
│   │   ├── DataManager.swift           # SwiftData 管理
│   │   ├── iCloudSyncManager.swift
│   │   ├── AIService.swift             # AI API 封装
│   │   ├── SubscriptionManager.swift   # StoreKit 2 订阅管理
│   │   └── AuthenticationManager.swift # Apple 登录
│   ├── Utilities/
│   │   ├── Extensions/
│   │   ├── Constants.swift
│   │   └── Theme.swift                  # 色彩主题
│   └── Resources/
│       ├── Assets.xcassets
│       └── Localization/
│           ├── en.lproj/Localizable.strings
│           └── zh-Hant.lproj/Localizable.strings
├── PacingPalTests/
└── PacingPalUITests/
```

# Architecture

- **MVVM Architecture** - 标准 SwiftUI MVVM
- **SwiftData** - 本地数据持久化 + 原生 iCloud 同步
- **StoreKit 2** - 订阅管理
- **Dependency Injection** - 服务协议便于测试
- **Swift 6 Concurrency** - async/await

# Key Design Decisions

1. **Local-first:** 数据默认存在本地，用户可选 iCloud 同步
2. **Privacy-first:** 不收集个人健康数据到第三方服务器
3. **AI API calls:** AI 分析通过 API 调用，数据传输加密
4. **iOS-first:** 充分利用 iOS 原生特性

# Color Palette

因为用户通常需要安静，不刺激的界面：

- **Primary:** Soft Blue `#5B8FB9` - 平静，信任
- **Secondary:** Gentle Green `#86B892` - 健康，疗愈
- **Background:** Off-White / Light Gray - 减少眼睛疲劳
- **Text:** 高对比度易于阅读
- **Energy Bucket:** 绿色 → 黄色 → 红色 渐变表示剩余能量

# Localization

Support two languages at launch:
1. English (US) - 主要市场
2. Traditional Chinese (Hong Kong/Taiwan) - 华语市场

# Minimum iOS Version

iOS 17.0 - 因为需要 SwiftData，而且大多数用户会更新系统
