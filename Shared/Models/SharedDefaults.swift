import Foundation

public enum SharedKeys {
    public static let appGroupID = "group.design.reality.noisebar"

    public static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    public static let currentSoundID = "currentSoundID"
    public static let pomodoroPhase = "pomodoroPhase"
    public static let pomodoroEndDate = "pomodoroEndDate"

    public static let pendingAction = "pendingAction"
    public static let pendingSoundID = "pendingSoundID"
}

public enum PendingAction: String, Sendable {
    case stop
    case togglePomodoro
    case play
}

public enum AppIntentBus {
    public static let darwinNotificationName = "design.reality.noisebar.intent"
}
