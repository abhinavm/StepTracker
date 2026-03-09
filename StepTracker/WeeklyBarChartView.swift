import SwiftUI

struct WeeklyBarChartView: View {
    let days: [DaySteps]
    let goal: Int

    private var maxSteps: Int {
        max(days.map(\.steps).max() ?? 0, goal)
    }

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days) { day in
                    barColumn(day: day, totalWidth: geo.size.width, totalHeight: geo.size.height)
                }
            }
        }
    }

    private func barColumn(day: DaySteps, totalWidth: CGFloat, totalHeight: CGFloat) -> some View {
        let barHeight = maxSteps > 0 ? CGFloat(day.steps) / CGFloat(maxSteps) * (totalHeight - 30) : 0
        let isToday = Calendar.current.isDateInToday(day.date)
        let metGoal = day.steps >= goal

        return VStack(spacing: 4) {
            // Step count label (only show for today or if space allows)
            if isToday || day.steps > 0 {
                Text(shortStepCount(day.steps))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isToday ? .blue : .secondary)
                    .lineLimit(1)
            } else {
                Spacer().frame(height: 14)
            }

            // Bar
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    metGoal
                        ? LinearGradient(colors: [.green, .mint], startPoint: .bottom, endPoint: .top)
                        : isToday
                            ? LinearGradient(colors: [.blue, .indigo], startPoint: .bottom, endPoint: .top)
                            : LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.6)], startPoint: .bottom, endPoint: .top)
                )
                .frame(height: max(barHeight, 4))
                .animation(.spring(duration: 0.5, bounce: 0.3), value: day.steps)

            // Day label
            Text(day.shortDayName)
                .font(.caption2)
                .foregroundStyle(isToday ? .blue : .secondary)
                .fontWeight(isToday ? .bold : .regular)
        }
        .frame(maxWidth: .infinity)
    }

    private func shortStepCount(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000)
        }
        return "\(steps)"
    }
}

#Preview {
    let sampleDays = [
        DaySteps(dateString: "2024-01-15", steps: 6500),
        DaySteps(dateString: "2024-01-16", steps: 9200),
        DaySteps(dateString: "2024-01-17", steps: 3100),
        DaySteps(dateString: "2024-01-18", steps: 11500),
        DaySteps(dateString: "2024-01-19", steps: 8700),
        DaySteps(dateString: "2024-01-20", steps: 5400),
        DaySteps(dateString: "2024-01-21", steps: 2300),
    ]
    WeeklyBarChartView(days: sampleDays, goal: 10000)
        .frame(height: 160)
        .padding()
}
