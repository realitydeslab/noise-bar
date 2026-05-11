import Foundation
import os
#if os(iOS)
import WidgetKit
#endif

private let log = Logger(subsystem: "design.reality.noisebar", category: "WidgetSync")

@MainActor
public enum WidgetSync {
    public static func updateCurrentSound(_ sound: Sound?) {
        #if os(iOS)
        SharedStateStore.write { state in
            state.currentSoundID = sound?.id
        }
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    public static func updatePomodoro(phase: PomodoroPhase, endDate: Date?) {
        #if os(iOS)
        SharedStateStore.write { state in
            if phase == .idle {
                state.pomodoroPhase = nil
                state.pomodoroEndDate = nil
            } else {
                state.pomodoroPhase = phase.rawValue
                state.pomodoroEndDate = endDate
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
