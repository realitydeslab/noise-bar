import AppIntents
import Foundation
import WidgetKit

struct StopNoiseBarIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop"
    static var description: IntentDescription = IntentDescription("Stop the current sound and any running Pomodoro.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        SharedStateStore.write { state in
            state.pomodoroPhase = nil
            state.pomodoroEndDate = nil
            state.currentSoundID = nil
            state.pendingAction = PendingAction.stop.rawValue
        }
        postBus()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct TogglePomodoroIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Pomodoro"
    static var description: IntentDescription = IntentDescription("Start or stop the Pomodoro cycle.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        SharedStateStore.write { state in
            if state.pomodoroPhase != nil {
                state.pomodoroPhase = nil
                state.pomodoroEndDate = nil
            } else {
                state.pomodoroPhase = PomodoroPhase.work.rawValue
                state.pomodoroEndDate = Date().addingTimeInterval(
                    TimeInterval(PomodoroDurations.defaultWork.seconds))
            }
            state.pendingAction = PendingAction.togglePomodoro.rawValue
        }
        postBus()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

private func postBus() {
    let name = AppIntentBus.darwinNotificationName as CFString
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName(name),
        nil, nil, true
    )
}
