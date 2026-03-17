# StepTracker

A clean, native iOS step counter app built with SwiftUI, HealthKit, and WidgetKit — inspired by the simplicity of [Steps - Simple Pedometer](https://apps.apple.com/us/app/steps-simple-pedometer/id1602546738).

> Built as a personal project to explore HealthKit background delivery, WidgetKit timelines, App Groups, and SwiftUI animation.

---

## Features

- **Live step count** — reads directly from Apple Health using `HKObserverQuery`, updates in the background without opening the app
- **Animated goal ring** — circular progress ring with step count displayed inside; configurable daily goal (5K–15K or custom)
- **Distance walked** — live conversion to miles from `HKQuantityTypeIdentifierDistanceWalkingRunning`
- **7-day weekly bar chart** — colour-coded history (green = goal met, blue = in progress)
- **Gradient colour themes** — independently configurable colour scheme for the app and widgets via a hue slider
- **Home screen widgets** — Small (ring + distance) and Medium (ring + 7-day chart)
- **Lock screen widgets** — Circular gauge and Rectangular bar (iOS 16+)
- **Background refresh** — HealthKit observer queries + `enableBackgroundDelivery(for:frequency:.immediate)` keep widgets current

---

## Screenshots

<div align="center">

### App

<table>
  <tr>
    <td align="center"><img src="screenshots/app_main.PNG" width="220"/><br/><sub><b>Step Counter & Goal Ring</b></sub></td>
    <td align="center"><img src="screenshots/app_goal.PNG" width="220"/><br/><sub><b>Colour Theme Picker</b></sub></td>
  </tr>
</table>

### Widgets

<table>
  <tr>
    <td align="center"><img src="screenshots/widget_small.PNG" width="160"/><br/><sub><b>Small Widget</b></sub></td>
    <td align="center"><img src="screenshots/widget_medium.PNG" width="320"/><br/><sub><b>Medium Widget</b></sub></td>
  </tr>
</table>

</div>

---

## Architecture

```
StepTracker/
├── Shared/
│   └── Models.swift              # StepData, DaySteps, App Group UserDefaults, gradient helpers
├── StepTracker/                  # Main app target
│   ├── StepTrackerApp.swift
│   ├── ContentView.swift         # Main screen — ring, stats, chart, goal editor, colour picker
│   ├── HealthKitManager.swift    # HealthKit queries with async/await + background observer
│   ├── GoalRingView.swift        # Animated circular progress ring (SwiftUI)
│   └── WeeklyBarChartView.swift  # 7-day bar chart
└── StepWidget/                   # Widget extension target
    ├── StepWidgetBundle.swift
    ├── StepWidgetProvider.swift  # WidgetKit TimelineProvider (15-min refresh)
    └── StepWidget.swift          # Views for small, medium, circular, rectangular widget families
```

### Data flow

```
Apple Health
    │
    ▼
HealthKitManager (HKObserverQuery + HKStatisticsQuery)
    │
    ├── @Published stepData ──► ContentView (SwiftUI)
    │
    └── App Group UserDefaults ──► WidgetKit TimelineProvider ──► Widget Views
```

The main app writes `StepData` to a shared App Group (`group.com.abhinav.steptracker`). The widget reads from the same store — no direct HealthKit access needed in the extension. HealthKit observer queries fire whenever new step data arrives, triggering `WidgetCenter.shared.reloadAllTimelines()`.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Health data | HealthKit (`HKObserverQuery`, `HKStatisticsCollectionQuery`) |
| Widgets | WidgetKit (`TimelineProvider`, `StaticConfiguration`) |
| App ↔ Widget data | App Groups + `UserDefaults` |
| Background delivery | `enableBackgroundDelivery(for:frequency:.immediate)` |
| Colour system | Hue-based gradient (stored as `Double` in App Group) |
| Min deployment | iOS 16.0 |

---

## Getting Started

### Requirements

- Xcode 15+
- iOS 16.0+ device or simulator
- Apple Developer account (free for personal device testing; $99/yr for App Store distribution)

### 1. Clone

```bash
git clone https://github.com/abhinavm/StepTracker.git
cd StepTracker
```

### 2. Open in Xcode

```bash
open StepTracker.xcodeproj
```

### 3. Configure signing

- Select the **StepTracker** target → **Signing & Capabilities** → set your **Team**
- Repeat for the **StepWidget** target
- Click the **refresh button** next to `group.com.abhinav.steptracker` on both targets to register the App Group with your Apple ID

### 4. Build and run

Select your iPhone as the destination and press **⌘R**. Approve HealthKit access on first launch.

### 5. Add a widget

Long press the home screen → **+** → search **StepTracker** → choose Small or Medium.

---

## Customisation

| File | What to change |
|------|----------------|
| `Models.swift` | App Group identifier, default daily goal |
| `HealthKitManager.swift` | Add calories, floors climbed, active energy |
| `GoalRingView.swift` | Ring thickness, animation curve |
| `StepWidget.swift` | Widget layout, add `.systemLarge` family |
| `ContentView.swift` | Additional stat cards, UI tweaks |

---

## Notable Implementation Details

**HealthKit background delivery** requires calling the `HKObserverQuery` completion handler on every invocation — even if no UI update occurs. Failing to do so causes HealthKit to throttle and eventually stop background notifications.

**WidgetKit full-bleed backgrounds** on iOS 17+ require using `.containerBackground(for: .widget)` rather than placing a gradient inside the view body. A `GradientBackgroundModifier` handles the `#available(iOS 17.0, *)` branch automatically.

**Hue-based colour system** — the app stores a single `Double` (0.0–1.0 hue) per colour theme in App Group UserDefaults, so the widget always reads the latest colour preference chosen in the app without any IPC.

---

## License

MIT — free to use, modify, and distribute.
