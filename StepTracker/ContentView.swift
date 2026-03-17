import SwiftUI
import WidgetKit

struct ContentView: View {
    @EnvironmentObject var healthKit: HealthKitManager
    @State private var showGoalPicker = false
    @State private var goalInput: String = ""
    @State private var appHue: Double = UserDefaults.appGroup.appColorHue
    @State private var widgetHue: Double = UserDefaults.appGroup.widgetColorHue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Main Step Count Card
                    mainStepCard

                    // MARK: - Stats Row
                    statsRow

                    // MARK: - Weekly Chart
                    weeklyChartCard

                    // MARK: - Goal Setting
                    goalCard

                    // MARK: - Appearance
                    appearanceCard
                }
                .padding()
            }
            .navigationTitle("Steps")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await healthKit.fetchAllData() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                await healthKit.fetchAllData()
            }
        }
        .alert("HealthKit Error", isPresented: Binding(
            get: { healthKit.authError != nil },
            set: { if !$0 { healthKit.authError = nil } }
        )) {
            Button("OK") { healthKit.authError = nil }
        } message: {
            Text(healthKit.authError ?? "")
        }
    }

    // MARK: - Main Step Count Card

    private var mainStepCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: gradientColors(fromHue: appHue),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(radius: 8)

            VStack(spacing: 20) {
                GoalRingView(
                    progress: healthKit.stepData.goalProgress,
                    steps: healthKit.stepData.todaySteps,
                    goal: healthKit.stepData.stepGoal
                )
                .frame(width: 200, height: 200)

                if healthKit.stepData.goalReached {
                    Label("Goal reached!", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .padding(.vertical, 32)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 16) {
            statCard(
                icon: "figure.walk",
                value: healthKit.stepData.distanceString,
                label: "Distance"
            )
            statCard(
                icon: "target",
                value: "\(Int(healthKit.stepData.goalProgress * 100))%",
                label: "of Goal"
            )
            statCard(
                icon: "clock",
                value: lastUpdatedString,
                label: "Updated"
            )
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color(hue: appHue, saturation: 0.75, brightness: 0.85))
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Weekly Chart

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .padding(.horizontal)

            if healthKit.stepData.weeklySteps.isEmpty {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                WeeklyBarChartView(
                    days: healthKit.stepData.weeklySteps,
                    goal: healthKit.stepData.stepGoal
                )
                .frame(height: 160)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Goal Card

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Goal")
                    .font(.headline)
                Spacer()
                Button("Edit") {
                    goalInput = "\(healthKit.stepData.stepGoal)"
                    showGoalPicker = true
                }
                .font(.subheadline)
            }

            Text("\(healthKit.stepData.stepGoal) steps")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color(hue: appHue, saturation: 0.75, brightness: 0.85))

            ProgressView(value: healthKit.stepData.goalProgress)
                .tint(Color(hue: appHue, saturation: 0.75, brightness: 0.85))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .sheet(isPresented: $showGoalPicker) {
            GoalPickerSheet(goalInput: $goalInput) { newGoal in
                healthKit.updateGoal(newGoal)
            }
            .presentationDetents([.height(240)])
        }
    }

    // MARK: - Appearance Card

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Appearance")
                .font(.headline)

            // App gradient slider
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("App")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: gradientColors(fromHue: appHue),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: 44, height: 22)
                }
                GradientSlider(hue: $appHue)
                    .onChange(of: appHue) { newVal in
                        UserDefaults.appGroup.appColorHue = newVal
                    }
            }

            Divider()

            // Widget gradient slider
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Widget")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: gradientColors(fromHue: widgetHue),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: 44, height: 22)
                }
                GradientSlider(hue: $widgetHue)
                    .onChange(of: widgetHue) { newVal in
                        UserDefaults.appGroup.widgetColorHue = newVal
                        WidgetCenter.shared.reloadAllTimelines()
                    }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
    }

    private var lastUpdatedString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: healthKit.stepData.lastUpdated)
    }
}

// MARK: - Goal Picker Sheet

struct GoalPickerSheet: View {
    @Binding var goalInput: String
    let onSave: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    let presets = [5000, 7500, 10000, 12500, 15000]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Set your daily step goal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                goalInput = "\(preset)"
                            } label: {
                                Text("\(preset)")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(goalInput == "\(preset)" ? Color.blue : Color.secondary.opacity(0.15))
                                    )
                                    .foregroundStyle(goalInput == "\(preset)" ? .white : .primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                TextField("Custom goal", text: $goalInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }
            .navigationTitle("Daily Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let value = Int(goalInput), value > 0 {
                            onSave(value)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Gradient Slider

struct GradientSlider: View {
    @Binding var hue: Double

    private let trackHeight: CGFloat = 36
    private let thumbSize: CGFloat = 32

    private var rainbowGradient: LinearGradient {
        LinearGradient(
            colors: (0...20).map { i in
                Color(hue: Double(i) / 20.0, saturation: 0.80, brightness: 0.92)
            },
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        GeometryReader { geo in
            let usableWidth = geo.size.width - thumbSize
            let thumbX = hue * usableWidth

            ZStack(alignment: .leading) {
                // Rainbow track
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(rainbowGradient)
                    .frame(height: trackHeight)

                // Thumb — purely visual, gesture is on the whole ZStack
                Circle()
                    .fill(Color(hue: hue, saturation: 0.75, brightness: 0.95))
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                    .offset(x: thumbX)
                    .allowsHitTesting(false) // gesture handled by parent ZStack
            }
            // Gesture on the full track so tapping anywhere works correctly
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard usableWidth > 0 else { return }
                        // Offset by half thumb so thumb centre tracks the finger
                        let raw = (value.location.x - thumbSize / 2) / usableWidth
                        hue = max(0.0, min(1.0, raw))
                    }
            )
        }
        .frame(height: thumbSize)
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthKitManager.shared)
}
