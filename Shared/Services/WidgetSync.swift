import Foundation
#if os(iOS)
import WidgetKit
#endif

@MainActor
public enum WidgetSync {
    public static func updateCurrentSound(_ sound: Sound?) {
        #if os(iOS)
        let d = SharedKeys.defaults
        d?.set(sound?.id, forKey: SharedKeys.currentSoundID)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    public static func updatePomodoro(phase: PomodoroPhase, endDate: Date?) {
        #if os(iOS)
        let d = SharedKeys.defaults
        if phase == .idle {
            d?.removeObject(forKey: SharedKeys.pomodoroPhase)
            d?.removeObject(forKey: SharedKeys.pomodoroEndDate)
        } else {
            d?.set(phase.rawValue, forKey: SharedKeys.pomodoroPhase)
            if let endDate = endDate {
                d?.set(endDate.timeIntervalSince1970, forKey: SharedKeys.pomodoroEndDate)
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
