 import SwiftUI

@main
struct StepTrackerApp: App {
    @StateObject private var healthKit = HealthKitManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKit)
                .task {
                    await healthKit.requestAuthorization()
                }
        }
    }
}
