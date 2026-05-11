import Foundation
import Combine

@MainActor
public final class AppState: ObservableObject {
    public let audio: AudioPlayer
    public let pomodoro: PomodoroTimer

    private var cancellables = Set<AnyCancellable>()

    public init() {
        let audio = AudioPlayer()
        self.audio = audio
        self.pomodoro = PomodoroTimer(audio: audio)

        audio.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        pomodoro.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    public func playSound(_ sound: Sound) {
        pomodoro.stop()
        audio.play(sound)
    }

    public func stopAll() {
        pomodoro.cancelAll()
    }
}
