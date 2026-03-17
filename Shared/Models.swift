import Foundation
import SwiftUI

// MARK: - Color Presets (shared between app and widget)

enum ColorPreset: String, Codable, CaseIterable, Identifiable {
    case ocean, violet, forest, flame, sunset, midnight, rose, teal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ocean:    return "Ocean"
        case .violet:   return "Violet"
        case .forest:   return "Forest"
        case .flame:    return "Flame"
        case .sunset:   return "Sunset"
        case .midnight: return "Midnight"
        case .rose:     return "Rose"
        case .teal:     return "Teal"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .ocean:    return [Color(red: 0.10, green: 0.40, blue: 0.90), Color(red: 0.30, green: 0.00, blue: 0.70)]
        case .violet:   return [Color(red: 0.55, green: 0.10, blue: 0.90), Color(red: 0.85, green: 0.10, blue: 0.50)]
        case .forest:   return [Color(red: 0.10, green: 0.72, blue: 0.40), Color(red: 0.00, green: 0.42, blue: 0.22)]
        case .flame:    return [Color(red: 1.00, green: 0.50, blue: 0.10), Color(red: 0.88, green: 0.10, blue: 0.10)]
        case .sunset:   return [Color(red: 1.00, green: 0.42, blue: 0.28), Color(red: 0.78, green: 0.08, blue: 0.52)]
        case .midnight: return [Color(red: 0.06, green: 0.06, blue: 0.22), Color(red: 0.14, green: 0.00, blue: 0.34)]
        case .rose:     return [Color(red: 1.00, green: 0.30, blue: 0.52), Color(red: 0.78, green: 0.08, blue: 0.28)]
        case .teal:     return [Color(red: 0.00, green: 0.72, blue: 0.80), Color(red: 0.00, green: 0.38, blue: 0.60)]
        }
    }

    var accentColor: Color { gradientColors[0] }
}

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

    /// Hue value 0.0–1.0. Default 0.62 (blue).
    var appColorHue: Double {
        get { object(forKey: "appColorHue") as? Double ?? 0.62 }
        set { set(newValue, forKey: "appColorHue") }
    }

    /// Hue value 0.0–1.0. Default 0.62 (blue).
    var widgetColorHue: Double {
        get { object(forKey: "widgetColorHue") as? Double ?? 0.62 }
        set { set(newValue, forKey: "widgetColorHue") }
    }

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

// MARK: - Gradient color helper (used by both app and widget)

/// Derives a two-stop gradient from a hue value (0.0 – 1.0).
/// The start is bright/light; the end is darker and slightly shifted in hue.
func gradientColors(fromHue hue: Double) -> [Color] {
    let h = max(0.0, min(1.0, hue))
    let endHue = (h + 0.10).truncatingRemainder(dividingBy: 1.0)
    return [
        Color(hue: h,      saturation: 0.68, brightness: 0.96),
        Color(hue: endHue, saturation: 0.95, brightness: 0.62)
    ]
}
