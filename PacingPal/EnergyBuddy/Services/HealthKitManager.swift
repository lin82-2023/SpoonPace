// PacingPal
// HealthKitManager.swift
// HealthKit health data sync - reads step count, active energy, sleep, resting heart rate
// Read-only access, no writing. Enabled only after explicit user authorization

import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published private(set) var isAuthorized = false
    @Published private(set) var isAvailable = HKHealthStore.isHealthDataAvailable()

    // Types we read
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    ]

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    private func checkAuthorizationStatus() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            isAvailable = false
            isAuthorized = false
            return
        }

        let status = readTypes.allSatisfy { type in
            healthStore.authorizationStatus(for: type) == .sharingAuthorized
        }
        isAuthorized = status
    }

    /// Request authorization from user
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = readTypes.allSatisfy { healthStore.authorizationStatus(for: $0) == .sharingAuthorized }
            return isAuthorized
        } catch {
            print("HealthKit authorization failed: \(error)")
            isAuthorized = false
            return false
        }
    }

    /// Get step count for a specific day
    func getStepCount(for date: Date) async -> Double {
        guard isAuthorized, let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                guard let result = result, let sumQuantity = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let stepCount = sumQuantity.doubleValue(for: HKUnit.count())
                continuation.resume(returning: stepCount)
            }
            healthStore.execute(query)
        }
    }

    /// Get active energy burned for a specific day (in kilocalories)
    func getActiveEnergyBurned(for date: Date) async -> Double {
        guard isAuthorized, let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                guard let result = result, let sumQuantity = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let energy = sumQuantity.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: energy)
            }
            healthStore.execute(query)
        }
    }

    /// Get average resting heart rate for a specific day (bpm)
    func getAverageRestingHeartRate(for date: Date) async -> Double {
        guard isAuthorized, let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return 0
        }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: hrType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, error in
                guard let result = result, let avgQuantity = result.averageQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let hr = avgQuantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                continuation.resume(returning: hr)
            }
            healthStore.execute(query)
        }
    }

    /// Get sleep analysis duration for a specific day (in hours)
    func getSleepDuration(for date: Date) async -> Double {
        guard isAuthorized, let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return 0
        }

        let calendar = Calendar.current
        // Sleep from previous day evening to this day morning
        let dayStart = calendar.startOfDay(for: date)
        guard let startDate = calendar.date(byAdding: .day, value: -1, to: dayStart) else {
            return 0
        }
        let endDate = dayStart

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }

                var totalSleep: Double = 0
                for sample in samples where sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                           sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                           sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                           sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600
                    totalSleep += duration
                }

                continuation.resume(returning: totalSleep)
            }
            healthStore.execute(query)
        }
    }

    /// Get all health metrics for a day
    func getDailyHealthMetrics(for date: Date) async -> DailyHealthMetrics {
        async let steps = getStepCount(for: date)
        async let activeEnergy = getActiveEnergyBurned(for: date)
        async let restingHR = getAverageRestingHeartRate(for: date)
        async let sleepHours = getSleepDuration(for: date)

        return await DailyHealthMetrics(
            date: date,
            stepCount: steps,
            activeEnergyBurned: activeEnergy,
            restingHeartRate: restingHR,
            sleepDurationHours: sleepHours,
            hasData: isAuthorized
        )
    }
}

/// Health metrics for a single day
struct DailyHealthMetrics {
    let date: Date
    let stepCount: Double
    let activeEnergyBurned: Double
    let restingHeartRate: Double
    let sleepDurationHours: Double
    let hasData: Bool

    var isEmpty: Bool {
        return stepCount == 0 && activeEnergyBurned == 0 && restingHeartRate == 0 && sleepDurationHours == 0
    }
}
