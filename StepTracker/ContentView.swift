import SwiftUI
import WidgetKit

struct ContentView: View {
    @EnvironmentObject var healthKit: HealthKitManager
    @State private var showGoalPicker = false
    @State private var goalInput: String = ""
    @State private var appPreset: ColorPreset = UserDefaults.appGroup.appColorPreset
    @State private var widgetPreset: ColorPreset = UserDefaults.appGroup.widgetColorPreset

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
                    colors: appPreset.gradientColors,
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
                .foregroundStyle(appPreset.accentColor)
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
                .foregroundStyle(appPreset.accentColor)

            ProgressView(value: healthKit.stepData.goalProgress)
                .tint(appPreset.accentColor)
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.headline)

            // App color
            VStack(alignment: .leading, spacing: 10) {
                Text("App")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ColorSwatchRow(selected: $appPreset) { preset in
                    appPreset = preset
                    UserDefaults.appGroup.appColorPreset = preset
                }
            }

            Divider()

            // Widget color
            VStack(alignment: .leading, spacing: 10) {
                Text("Widget")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ColorSwatchRow(selected: $widgetPreset) { preset in
                    widgetPreset = preset
                    UserDefaults.appGroup.widgetColorPreset = preset
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

// MARK: - Color Swatch Row

struct ColorSwatchRow: View {
    @Binding var selected: ColorPreset
    let onSelect: (ColorPreset) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ColorPreset.allCases) { preset in
                    Button {
                        onSelect(preset)
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: preset.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 44, height: 44)

                                if selected == preset {
                                    Circle()
                                        .strokeBorder(Color.primary, lineWidth: 2.5)
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            Text(preset.displayName)
                                .font(.caption2)
                                .foregroundStyle(selected == preset ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthKitManager.shared)
}
