import AppIntents
import Foundation

struct StopNoiseBarIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop"
    static var description: IntentDescription = IntentDescription("Stop the current sound and any running Pomodoro.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        SharedStateStore.write { state in
            state.pendingAction = PendingAction.stop.rawValue
            state.pendingSoundID = nil
        }
        postBus()
        return .result()
    }
}

struct TogglePomodoroIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Pomodoro"
    static var description: IntentDescription = IntentDescription("Start or stop the Pomodoro cycle.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        SharedStateStore.write { state in
            state.pendingAction = PendingAction.togglePomodoro.rawValue
            state.pendingSoundID = nil
        }
        postBus()
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
