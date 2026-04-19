# PacingPal Development Checklist - UPDATED ✓

---

## Phase 1: Project Setup ⏳ Week 1

- [x] Create Xcode project (SwiftUI, iOS 17)
- [x] Configure SwiftData model container
- [x] **iCloud capabilities REMOVED** (per request - local-only first release)
- [x] Add Sign in with Apple capability
- [x] Configure StoreKit for in-app purchases
- [x] Add API keys configuration (do NOT commit to git)
- [x] Setup basic project structure (folders for Models/Views/ViewModels/Services)
- [x] Create basic theme/color palette (primary: #5B8FB9, secondary: #86B892)
- [x] Configure localization (en, zh-Hans, zh-Hant)

**Done? Check all above → Phase 1 complete ✓**

---

## Phase 2: Core Features ⏳ Week 2-3

### Data Models
- [x] `EnergyEntry` model
- [x] `SymptomEntry` model
- [x] `ActivityType` model (with default activities)
- [x] `DailyEnergyBudget` model

### Main Tabs
- [x] `AppMainView` - 4 tabs: Today / Add / History / Insights

### Today View (Home)
- [x] Daily energy budget display
- [x] Energy bucket visual indicator (progress bar with color change green → yellow → red)
- [x] List of today's activities
- [x] List of today's symptoms
- [x] Quick add buttons

### Add Entry
- [x] Add energy/activity entry form
- [x] Add symptom entry form with 0-10 slider
- [x] Natural language input view (AI powered)
- [x] Save to SwiftData

### History / Calendar
- [x] Calendar month view
- [x] Select date to view details
- [x] Summary per day

### Settings
- [x] Default daily spoon/energy setting
- [x] Customize activity types (edit defaults, add new)
- [x] **iCloud sync REMOVED** (per request)
- [x] Subscription management UI
- [x] Privacy policy / terms links
- [x] **Export data (JSON) FIXED** - button now working ✓

**Done? Check all above → Phase 2 complete ✓**

---

## Phase 3: AI Features ⏳ Week 4

- [x] `AIService` protocol + implementation for Claude/GPT/DeepSeek
- [x] Natural language extraction (parse user text into activity + symptom)
- [x] Weekly AI analysis - generate insight from 7 days data
- [x] Insights view - display weekly summary with Liquid Glass styling
- [x] Error handling for API
- [x] Multiple AI provider support (user can configure API key)
- [x] **Full localization complete** - all text/prompts/templates follow system language (English/简体中文/繁體中文) ✓

**Done? Check all above → Phase 3 complete ✓**

---

## Phase 4: Subscription & Auth ⏳ Week 4

- [x] `AuthenticationManager` - Sign in with Apple
- [x] `SubscriptionManager` - StoreKit 2 integration
- [x] Paywall screen - show subscription options
- [x] Entitlement management - unlock features after subscription
- [x] 7-day free trial configuration
- [x] Handle subscription status changes

**Done? Check all above → Phase 4 complete ✓**

---

## Phase 5: UI/UX Polish & Testing ⏳ Week 5-6

- [x] All visuals polished with Liquid Glass design
- [x] Dark mode support (adapts automatically)
- [x] Accessibility: Dynamic Type support
- [x] Accessibility: VoiceOver labels, 44pt minimum hit targets
- [x] Crash handling
- [x] **iCloud sync removed** - no testing needed for this release
- [x] Test subscription flow
- [x] All known bugs fixed (last fixed: Export Data button not responding to taps)
- [x] Performance optimization
- [x] Strict code audit complete - all comments in English, no deprecated APIs, build succeeds with zero errors

**Done? Check all above → Phase 5 complete ✓**

---

## App Store Submission ⏳ Week 6

- [x] App Store Connect create listing (all content prepared in `AppStoreContent.md`)
- [x] Prepare app description (English + Traditional Chinese) ✓
- [x] Prepare keywords (ASO optimized) ✓
- [x] App icon already created ✓
- [x] **Take 5 required screenshots for 6.5-inch iPhone** - all done in `../PacingPal/screenshots/` ✓
- [ ] Write privacy policy (host online) - **⚠️ you need to host this yourself and add URL to App Store Connect**
- [x] Fill out export compliance information (ready in Xcode)
- [ ] Submit for Apple review - **⚠️ your step after uploading build**
- [ ] Wait for approval 🤞

**Done (except privacy policy and final submit) → Ready for submission! 🚀**

---

## Post MVP - Phase 2 Features (After Launch)

- [ ] Activity energy preset suggestions
- [ ] Trigger analysis - AI finds patterns between activities and symptoms
- [ ] Line charts for historical trends
- [x] Read sleep/step/heart rate data from Apple Health **DONE**
- [x] Correlate sleep/activity with energy levels **DONE** (used in AI analysis)
- [ ] PDF report export for doctor visits
- [ ] Home screen widget - today's remaining energy

---

## Launch Checklist

- [ ] Join relevant Reddit/Facebook groups
- [ ] Share launch announcement
- [ ] Setup simple website with landing page
- [ ] Add link in bio to App Store
- [ ] Collect feedback for next iteration

