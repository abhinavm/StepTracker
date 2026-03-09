import Foundation

// MARK: - Shared data model used by both app and widget

struct DaySteps: Codable, Identifiable, Equatable {
    var id: String { dateString }
    let dateString: String // "yyyy-MM-dd" format
    let steps: Int

    var date: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString) ?? Date()
    }

    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct StepData: Codable, Equatable {
    var todaySteps: Int = 0
    var todayDistanceMiles: Double = 0.0
    var stepGoal: Int = 10000
    var weeklySteps: [DaySteps] = []
    var lastUpdated: Date = Date()

    var goalProgress: Double {
        guard stepGoal > 0 else { return 0 }
        return min(Double(todaySteps) / Double(stepGoal), 1.0)
    }

    var goalReached: Bool {
        todaySteps >= stepGoal
    }

    var distanceString: String {
        String(format: "%.2f mi", todayDistanceMiles)
    }

    var stepsFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: todaySteps)) ?? "\(todaySteps)"
    }
}

// MARK: - App Group shared UserDefaults

extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: "group.com.abhinav.steptracker")!

    var stepData: StepData {
        get {
            guard let data = data(forKey: "stepData"),
                  let decoded = try? JSONDecoder().decode(StepData.self, from: data) else {
                return StepData()
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                set(encoded, forKey: "stepData")
            }
        }
    }
}
