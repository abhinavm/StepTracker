import SwiftUI

struct GoalRingView: View {
    let progress: Double   // 0.0 to 1.0
    let steps: Int
    let goal: Int

    private let lineWidth: CGFloat = 16

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        colors: progress >= 1.0
                            ? [.yellow, .orange, .yellow]
                            : [.white, .white.opacity(0.7)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)

            // Overflow ring (when goal is exceeded)
            if progress > 1.0 {
                Circle()
                    .trim(from: 0, to: progress - 1.0)
                    .stroke(Color.yellow, style: StrokeStyle(lineWidth: lineWidth * 0.6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(0.85)
            }

            // Center text
            VStack(spacing: 2) {
                Text(stepsFormatted)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("steps")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .textCase(.uppercase)
                    .kerning(1.5)
            }
        }
    }

    private var stepsFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        GoalRingView(progress: 0.72, steps: 7200, goal: 10000)
            .frame(width: 200, height: 200)
    }
}
