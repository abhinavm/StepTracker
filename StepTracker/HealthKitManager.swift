import HealthKit
import Foundation
import WidgetKit

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published var stepData = StepData()
    @Published var isAuthorized = false
    @Published var authError: String?

    private let stepsType = HKQuantityType(.stepCount)
    private let distanceType = HKQuantityType(.distanceWalkingRunning)

    // MARK: - Authorization

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authError = "HealthKit is not available on this device."
            return
        }

        let typesToRead: Set<HKQuantityType> = [stepsType, distanceType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            authError = nil
            await fetchAllData()
            startObserving()
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Fetch all data

    func fetchAllData() async {
        async let steps = fetchTodaySteps()
        async let distance = fetchTodayDistance()
        async let weekly = fetchWeeklySteps()

        let (stepCount, dist, weekData) = await (steps, distance, weekly)

        var data = stepData
        data.todaySteps = stepCount
        data.todayDistanceMiles = dist
        data.weeklySteps = weekData
        data.lastUpdated = Date()
        stepData = data

        // Save to App Group so the widget can read it
        UserDefaults.appGroup.stepData = data

        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Today's Steps

    private func fetchTodaySteps() async -> Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Today's Distance

    private func fetchTodayDistance() async -> Double {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let meters = result?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                let miles = meters / 1609.344
                continuation.resume(returning: miles)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Weekly Steps (last 7 days)

    private func fetchWeeklySteps() async -> [DaySteps] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        var interval = DateComponents()
        interval.day = 1

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: calendar.startOfDay(for: startDate),
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, _ in
                guard let results = results else {
                    continuation.resume(returning: [])
                    return
                }

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"

                var dayStepsArray: [DaySteps] = []
                results.enumerateStatistics(from: startDate, to: endDate) { stats, _ in
                    let steps = Int(stats.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                    let dateStr = formatter.string(from: stats.startDate)
                    dayStepsArray.append(DaySteps(dateString: dateStr, steps: steps))
                }
                continuation.resume(returning: dayStepsArray)
            }

            self.healthStore.execute(query)
        }
    }

    // MARK: - Goal Update

    func updateGoal(_ goal: Int) {
        stepData.stepGoal = goal
        UserDefaults.appGroup.stepData = stepData
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Background observer

    func startObserving() {
        let query = HKObserverQuery(sampleType: stepsType, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
            Task { await self?.fetchAllData() }
        }
        healthStore.execute(query)

        // Enable background delivery (requires Background Modes capability)
        healthStore.enableBackgroundDelivery(for: stepsType, frequency: .immediate) { _, _ in }
    }
}
