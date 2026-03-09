import WidgetKit
import Foundation

struct StepEntry: TimelineEntry {
    let date: Date
    let stepData: StepData
}

struct StepWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> StepEntry {
        StepEntry(
            date: Date(),
            stepData: StepData(todaySteps: 7342, todayDistanceMiles: 3.1, stepGoal: 10000)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StepEntry) -> Void) {
        let data = UserDefaults.appGroup.stepData
        completion(StepEntry(date: Date(), stepData: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepEntry>) -> Void) {
        let data = UserDefaults.appGroup.stepData
        let entry = StepEntry(date: Date(), stepData: data)

        // Refresh every 15 minutes (WidgetKit minimum)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))

        completion(timeline)
    }
}
