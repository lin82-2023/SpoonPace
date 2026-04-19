# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PacingPal (Chinese: 缓行) is an iOS energy management app for Long COVID and ME/CFS patients. It helps patients track energy expenditure using the "spoon theory" (energy bucket model) and provides AI-powered insights.

**Business Goal:** $10,000/month revenue within 12 months with 2,000 subscribers.

## Tech Stack

- **UI:** SwiftUI (iOS 17+)
- **Data Persistence:** SwiftData (local-only, iCloud removed)
- **Subscriptions:** StoreKit 2
- **Authentication:** Sign in with Apple
- **AI Features:** Cloud AI API (supports Anthropic Claude, OpenAI, DeepSeek, Kimi, Tongyi Qwen)
- **Health Integration:** HealthKit - reads step count, active energy, sleep duration, resting heart rate
- **Architecture:** MVVM with Swift 6 concurrency (async/await)
- **Localization:** English, Simplified Chinese, Traditional Chinese (follows system language automatically)

## Commands

Common development commands:

- Open project in Xcode:
  ```bash
  open "PacingPal/PacingPal/PacingPal.xcodeproj"
  ```

- Clean build folder:
  ```bash
  xcodebuild clean -project "PacingPal/PacingPal/PacingPal.xcodeproj" -scheme PacingPal
  ```

- Build (from command line, iPhone 17 simulator):
  ```bash
  xcodebuild build -project "PacingPal/PacingPal/PacingPal.xcodeproj" -scheme PacingPal -destination 'platform=iOS Simulator,name=iPhone 17'
  ```

- Boot iPhone 17 simulator:
  ```bash
  xcrun simctl boot "iPhone 17"
  ```

- Install and launch on simulator:
  ```bash
  xcrun simctl terminate booted com.quan.nextech.PacingPal && xcrun simctl install booted "/Users/nexq/Library/Developer/Xcode/DerivedData/Build/Products/Debug-iphonesimulator/PacingPal.app" && xcrun simctl launch booted com.quan.nextech.PacingPal
  ```

- Capture resized screenshot for App Store:
  ```bash
  xcrun simctl io booted screenshot screenshot.png && sips --resampleHeightWidthMax 1800 screenshot.png
  ```

## Project Structure

```
PacingPal/PacingPal/
├── App/
│   ├── PacingPalApp.swift          # App entry point
│   └── PacingPal.entitlements       # Only HealthKit capability (iCloud removed)
├── Models/
│   ├── EnergyEntry.swift           # Energy consumption record
│   ├── SymptomEntry.swift          # Symptom record with 0-10 severity
│   ├── ActivityType.swift          # Activity type with default energy cost
│   ├── DailyEnergyBudget.swift     # Daily energy budget setting
│   ├── UserSettings.swift          # User preferences
│   └── WeeklyAIInsight.swift       # Generated AI weekly insight
├── Views/
│   ├── Main/AppMainView.swift      # Main app view (4 tabs)
│   ├── Today/                      # Today/ home screen with energy bucket
│   ├── History/                    # Calendar history view
│   ├── AddEntry/                   # Add energy/symptom entry + AI natural language input
│   ├── Insights/                   # AI weekly insights view
│   └── Settings/                   # Settings & paywall
├── ViewModels/                     # View models for each major view
├── Services/
│   ├── AIService.swift             # Hybrid AI: cloud API + local rule fallback
│   ├── HealthKitManager.swift      # HealthKit data reader (step/energy/sleep/hr)
│   ├── SubscriptionManager.swift   # StoreKit 2 subscription management
│   ├── AuthenticationManager.swift # Sign in with Apple
│   └── APIKey.swift                # API Key management (default DeepSeek key configured)
├── Utilities/
│   ├── Extensions/                 # SwiftUI extensions
│   ├── Constants.swift             # App constants
│   └── Theme.swift                 # Color theme and styling
└── Resources/
    ├── Assets.xcassets
    └── (Localizable.strings for en/zh-Hans/zh-Hant)
```

## Architecture

- **MVVM:** Standard SwiftUI MVVM architecture
- **Local-first:** All data stored locally on device (iCloud sync removed in v1.0)
- **Privacy-first:** No third-party collection of personal health data. Only AI analysis is sent encrypted to cloud API.
- **Swift Concurrency:** Uses async/await for all async operations, Swift 6 strict isolation
- **Hybrid AI Architecture:** Cloud API is tried first if API key configured; falls back to local rule-based generation if cloud fails
- **Liquid Glass Design:** Uses `.regularMaterial` with rounded corners, border stroke, and soft shadow for modern iOS look

## Key Design Decisions

1. **Local-first + Privacy:** User health data stays on device, only AI analysis goes to API (encrypted)
2. **iOS 17+ minimum:** Required for SwiftData, leverages latest iOS features
3. **Triple-language support:** English + Simplified Chinese + Traditional Chinese (all text localized, follows system language automatically)
4. **Subscription model:** $4.99/month or $49.99/year with 7-day free trial
5. **Multiple AI providers:** User can configure any supported provider, DeepSeek is default
6. **HealthKit Integration:** Read-only access to step count, active energy, sleep, resting heart rate for better AI insights

## Color Palette

- **Primary:** Soft Blue `#5B8FB9` - calming, trustworthy
- **Secondary:** Gentle Green `#86B892` - health, healing
- **Energy indicator:** Green → Yellow → Red gradient as energy depletes
- **Background:** Uses system materials (regular/ultraThin) for adaptivity

## Important Notes

- `APIKey.swift` contains default development API key - git keeps it but should be removed from repo for public open source
- The project uses SwiftData, which handles model migrations automatically
- AI costs are very low (~$0.01 per user per month) with Claude 3 Haiku/GPT-4-mini/DeepSeek
- HealthKit requires `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` in Info.plist (already configured)
- All AI prompts and templates are localized using `String(localized:)`, AI output language matches system language

## Reference Documentation

- [PRD - Product Requirements Document](./PRD.md)
- [Development Checklist updated](./CHECKLIST_UPDATED.md)
- [Original Checklist](./CHECKLIST.md)
- [README](./README.md)
- [App Store Connect ready content](./PacingPal/PacingPal/AppStoreContent.md)
- [App Store screenshots](./PacingPal/screenshots/)
