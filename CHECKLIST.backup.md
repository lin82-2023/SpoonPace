# PacingPal Development Checklist

---

## Phase 1: Project Setup ⏳ Week 1

- [ ] Create Xcode project (SwiftUI, iOS 17)
- [ ] Configure SwiftData model container
- [ ] Configure iCloud capabilities
- [ ] Add Sign in with Apple capability
- [ ] Configure StoreKit for in-app purchases
- [ ] Add API keys configuration (do NOT commit to git)
- [ ] Setup basic project structure (folders for Models/Views/ViewModels/Services)
- [ ] Create basic theme/color palette
- [ ] Configure localization (en, zh-Hant)

**Done? Check all above → Phase 1 complete ✓**

---

## Phase 2: Core Features ⏳ Week 2-3

### Data Models
- [ ] `EnergyEntry` model
- [ ] `SymptomEntry` model
- [ ] `ActivityType` model (with default activities)
- [ ] `DailyEnergyBudget` model

### Main Tabs
- [ ] `MainTabView` - 4 tabs: Today / Add / History / Insights

### Today View (Home)
- [ ] Daily energy budget display
- [ ] Energy bucket visual indicator (progress bar with color change)
- [ ] List of today's activities
- [ ] List of today's symptoms
- [ ] Quick add buttons

### Add Entry
- [ ] Add energy/activity entry form
- [ ] Add symptom entry form with 0-10 slider
- [ ] Natural language input view (AI powered)
- [ ] Save to SwiftData

### History / Calendar
- [ ] Calendar month view
- [ ] Select date to view details
- [ ] Summary per day

### Settings
- [ ] Default daily spoon/energy setting
- [ ] Customize activity types (edit defaults, add new)
- [ ] iCloud sync toggle
- [ ] Subscription management UI
- [ ] Privacy policy / terms links
- [ ] Export data (CSV)

**Done? Check all above → Phase 2 complete ✓**

---

## Phase 3: AI Features ⏳ Week 4

- [ ] `AIService` protocol + implementation for Claude/GPT
- [ ] Natural language extraction (parse user text into activity + symptom)
- [ ] Weekly AI analysis - generate insight from 7 days data
- [ ] Insights view - display weekly summary
- [ ] Error handling for API
- [ ] Rate limiting / quota management

**Done? Check all above → Phase 3 complete ✓**

---

## Phase 4: Subscription & Auth ⏳ Week 4

- [ ] `AuthenticationManager` - Sign in with Apple
- [ ] `SubscriptionManager` - StoreKit 2 integration
- [ ] Paywall screen - show subscription options
- [ ] Entitlement management - unlock features after subscription
- [ ] 7-day free trial configuration
- [ ] Handle subscription status changes

**Done? Check all above → Phase 4 complete ✓**

---

## Phase 5: UI/UX Polish & Testing ⏳ Week 5-6

- [ ] All visuals polished
- [ ] Dark mode support
- [ ] Accessibility: Dynamic Type support
- [ ] Accessibility: VoiceOver labels
- [ ] Crash handling
- [ ] Test iCloud sync with multiple devices
- [ ] Test subscription flow in sandbox
- [ ] Find beta testers from patient community
- [ ] Fix bugs reported by testers
- [ ] Performance optimization

**Done? Check all above → Phase 5 complete ✓**

---

## App Store Submission ⏳ Week 6

- [ ] App Store Connect create listing
- [ ] Prepare app description (English + Chinese)
- [ ] Prepare keywords (ASO optimized - see PRD)
- [ ] Create app icon
- [ ] Take screenshots for different device sizes
- [ ] Write privacy policy (host online)
- [ ] Fill out export compliance information
- [ ] Submit for Apple review
- [ ] Wait for approval 🤞

**Done? Check all above → Ready to launch! 🚀**

---

## Post MVP - Phase 2 Features (After Launch)

- [ ] Activity energy preset suggestions
- [ ] Trigger analysis - AI finds patterns between activities and symptoms
- [ ] Line charts for historical trends
- [ ] Read sleep data from Apple Health
- [ ] Correlate sleep with energy levels
- [ ] PDF report export for doctor visits
- [ ] Home screen widget - today's remaining energy

---

## Launch Checklist

- [ ] Join relevant Reddit/Facebook groups
- [ ] Share launch announcement
- [ ] Setup simple website with landing page
- [ ] Add link in bio to App Store
- [ ] Collect feedback for next iteration

---

# Revenue Milestones Tracker

- [ ] $1,000/month 🥉
- [ ] $2,500/month 🥈
- [ ] $5,000/month 🎖️
- [ ] **$10,000/month 🏆** - GOAL ACHIEVED!
