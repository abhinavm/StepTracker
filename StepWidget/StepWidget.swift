import WidgetKit
import SwiftUI

struct StepWidget: Widget {
    let kind: String = "StepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StepWidgetProvider()) { entry in
            StepWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Step Counter")
        .description("Track your daily steps and goal progress.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Background modifier — gradient via containerBackground (iOS 17+) or .background (iOS 16)

struct GradientBackgroundModifier: ViewModifier {
    let colors: [Color]

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(for: .widget) {
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        } else {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        }
    }
}

// MARK: - Main Entry View

struct StepWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: StepEntry

    var gradientColors: [Color] {
        gradientColors(fromHue: UserDefaults.appGroup.widgetColorHue)
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .accessoryCircular:
                AccessoryCircularView(entry: entry)
            case .accessoryRectangular:
                AccessoryRectangularView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .modifier(GradientBackgroundModifier(colors: gradientColors))
    }
}

// MARK: - Small Home Screen Widget

struct SmallWidgetView: View {
    let entry: StepEntry
    var data: StepData { entry.stepData }

    var body: some View {
        VStack(spacing: 10) {
            // Ring with step count inside
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: data.goalProgress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text(data.stepsFormatted)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 100, height: 100)

            Text(data.distanceString)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Home Screen Widget

struct MediumWidgetView: View {
    let entry: StepEntry
    var data: StepData { entry.stepData }

    var body: some View {
        HStack(spacing: 0) {
            // Left: ring + stats
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 9)
                    Circle()
                        .trim(from: 0, to: data.goalProgress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text(data.stepsFormatted)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 64, height: 64)

                Text("/ \(data.stepGoal) goal")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.8))

                Label(data.distanceString, systemImage: "figure.walk")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(width: 130)

            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1)
                .padding(.vertical, 12)

            // Right: weekly chart
            VStack(alignment: .leading, spacing: 6) {
                Text("This Week")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))

                if data.weeklySteps.isEmpty {
                    Spacer()
                    Text("No data")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                } else {
                    MiniBarChart(days: data.weeklySteps, goal: data.stepGoal)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Mini Bar Chart (for medium widget)

struct MiniBarChart: View {
    let days: [DaySteps]
    let goal: Int

    private var maxSteps: Int {
        max(days.map(\.steps).max() ?? 1, goal)
    }

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(days) { day in
                    let barHeight = CGFloat(day.steps) / CGFloat(maxSteps) * (geo.size.height - 16)
                    let isToday = Calendar.current.isDateInToday(day.date)
                    let metGoal = day.steps >= goal

                    VStack(spacing: 2) {
                        Spacer()
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                metGoal ? Color.white :
                                isToday ? Color.white.opacity(0.9) :
                                Color.white.opacity(0.35)
                            )
                            .frame(height: max(barHeight, 3))
                        Text(day.shortDayName)
                            .font(.system(size: 7))
                            .foregroundStyle(.white.opacity(isToday ? 1.0 : 0.6))
                            .fontWeight(isToday ? .bold : .regular)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Lock Screen Circular Widget

struct AccessoryCircularView: View {
    let entry: StepEntry
    var data: StepData { entry.stepData }

    var body: some View {
        Gauge(value: data.goalProgress) {
            Image(systemName: "figure.walk")
        } currentValueLabel: {
            Text(shortSteps)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(data.goalReached ? .green : .blue)
    }

    private var shortSteps: String {
        if data.todaySteps >= 10000 {
            return String(format: "%.0fk", Double(data.todaySteps) / 1000)
        } else if data.todaySteps >= 1000 {
            return String(format: "%.1fk", Double(data.todaySteps) / 1000)
        }
        return "\(data.todaySteps)"
    }
}

// MARK: - Lock Screen Rectangular Widget

struct AccessoryRectangularView: View {
    let entry: StepEntry
    var data: StepData { entry.stepData }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.caption2)
                Text("STEPS TODAY")
                    .font(.system(size: 9, weight: .semibold))
                    .kerning(1)
            }
            .foregroundStyle(.secondary)

            Text(data.stepsFormatted)
                .font(.system(size: 22, weight: .bold, design: .rounded))

            ProgressView(value: data.goalProgress)
                .tint(data.goalReached ? .green : .blue)

            Text("\(Int(data.goalProgress * 100))% of \(data.stepGoal) goal · \(data.distanceString)")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

struct StepWidget_Previews: PreviewProvider {
    static let sampleData = StepData(
        todaySteps: 7342,
        todayDistanceMiles: 3.1,
        stepGoal: 10000,
        weeklySteps: [
            DaySteps(dateString: "2024-01-15", steps: 6500),
            DaySteps(dateString: "2024-01-16", steps: 9200),
            DaySteps(dateString: "2024-01-17", steps: 3100),
            DaySteps(dateString: "2024-01-18", steps: 11500),
            DaySteps(dateString: "2024-01-19", steps: 8700),
            DaySteps(dateString: "2024-01-20", steps: 5400),
            DaySteps(dateString: "2024-01-21", steps: 7342),
        ]
    )
    static let sampleEntry = StepEntry(date: .now, stepData: sampleData)

    static var previews: some View {
        SmallWidgetView(entry: sampleEntry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")

        MediumWidgetView(entry: sampleEntry)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")

        AccessoryCircularView(entry: sampleEntry)
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")

        AccessoryRectangularView(entry: sampleEntry)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Rectangular")
    }
}
