import Foundation

public enum PomodoroPhase: String, Codable, Sendable {
    case idle
    case work
    case `break`
}

public struct DurationOption: Identifiable, Hashable, Sendable {
    public let minutes: Int
    public var id: Int { minutes }
    public var seconds: Int { minutes * 60 }
    public var label: String { minutes == 1 ? "1 minute" : "\(minutes) minutes" }

    public init(minutes: Int) { self.minutes = minutes }
}

public enum PomodoroDurations {
    public static let options: [DurationOption] = [
        DurationOption(minutes: 1),
        DurationOption(minutes: 2),
        DurationOption(minutes: 5),
        DurationOption(minutes: 10),
        DurationOption(minutes: 15),
        DurationOption(minutes: 25),
    ]

    public static let defaultWork = options.last!
    public static let defaultBreak = options[2]
}

public func formatMMSS(_ seconds: Int) -> String {
    let m = max(0, seconds) / 60
    let s = max(0, seconds) % 60
    return String(format: "%d:%02d", m, s)
}
