import Foundation
import Combine

@MainActor
public final class PomodoroTimer: ObservableObject {
    @Published public var workSound: Sound = SoundLibrary.byID("brown-noise")!
    @Published public var breakSound: Sound = SoundLibrary.byID("birds")!
    @Published public var workDuration: DurationOption = PomodoroDurations.defaultWork
    @Published public var breakDuration: DurationOption = PomodoroDurations.defaultBreak
    @Published public var loop: Bool = true

    @Published public private(set) var phase: PomodoroPhase = .idle
    @Published public private(set) var remaining: Int = 0
    @Published public private(set) var phaseEndDate: Date?

    private var ticker: Timer?
    private weak var audio: AudioPlayer?

    public init(audio: AudioPlayer) {
        self.audio = audio
    }

    public var isRunning: Bool { phase != .idle }

    public func start() {
        guard !isRunning else { return }
        beginWork()
    }

    public func stop() {
        ticker?.invalidate()
        ticker = nil
        phase = .idle
        remaining = 0
        phaseEndDate = nil
        WidgetSync.updatePomodoro(phase: .idle, endDate: nil)
    }

    public func cancelAll() {
        stop()
        audio?.stop()
    }

    private func beginWork() {
        phase = .work
        remaining = workDuration.seconds
        phaseEndDate = Date().addingTimeInterval(TimeInterval(remaining))
        audio?.play(workSound)
        WidgetSync.updatePomodoro(phase: .work, endDate: phaseEndDate)
        scheduleTicker()
    }

    private func beginBreak() {
        phase = .break
        remaining = breakDuration.seconds
        phaseEndDate = Date().addingTimeInterval(TimeInterval(remaining))
        audio?.play(breakSound)
        WidgetSync.updatePomodoro(phase: .break, endDate: phaseEndDate)
        scheduleTicker()
    }

    private func scheduleTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        guard remaining > 0 else { advancePhase(); return }
        remaining -= 1
        if remaining == 0 { advancePhase() }
    }

    private func advancePhase() {
        switch phase {
        case .work:
            beginBreak()
        case .break:
            if loop {
                beginWork()
            } else {
                cancelAll()
            }
        case .idle:
            break
        }
    }
}
