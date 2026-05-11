import Foundation
import os

public struct SharedState: Codable, Sendable {
    public var currentSoundID: String?
    public var pomodoroPhase: String?
    public var pomodoroEndDate: Date?
    public var workSoundID: String?
    public var breakSoundID: String?
    public var workDurationMinutes: Int?
    public var breakDurationMinutes: Int?
    public var pendingAction: String?
    public var pendingSoundID: String?

    public init(currentSoundID: String? = nil,
                pomodoroPhase: String? = nil,
                pomodoroEndDate: Date? = nil,
                workSoundID: String? = nil,
                breakSoundID: String? = nil,
                workDurationMinutes: Int? = nil,
                breakDurationMinutes: Int? = nil,
                pendingAction: String? = nil,
                pendingSoundID: String? = nil) {
        self.currentSoundID = currentSoundID
        self.pomodoroPhase = pomodoroPhase
        self.pomodoroEndDate = pomodoroEndDate
        self.workSoundID = workSoundID
        self.breakSoundID = breakSoundID
        self.workDurationMinutes = workDurationMinutes
        self.breakDurationMinutes = breakDurationMinutes
        self.pendingAction = pendingAction
        self.pendingSoundID = pendingSoundID
    }
}

private let log = Logger(subsystem: "design.reality.noisebar", category: "SharedStore")

public enum SharedStateStore {
    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedKeys.appGroupID)
    }

    public static var stateFileURL: URL? {
        containerURL?.appendingPathComponent("state.json")
    }

    public static func read() -> SharedState {
        guard let url = stateFileURL else {
            log.error("No container URL for app group")
            return SharedState()
        }
        guard let data = try? Data(contentsOf: url) else {
            return SharedState()
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return (try? decoder.decode(SharedState.self, from: data)) ?? SharedState()
    }

    public static func write(_ mutate: (inout SharedState) -> Void) {
        guard let url = stateFileURL else {
            log.error("No container URL for app group")
            return
        }
        var state = read()
        mutate(&state)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        do {
            let data = try encoder.encode(state)
            try data.write(to: url, options: .atomic)
            log.notice("wrote state: sound=\(state.currentSoundID ?? "nil", privacy: .public) phase=\(state.pomodoroPhase ?? "nil", privacy: .public)")
        } catch {
            log.error("write failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
