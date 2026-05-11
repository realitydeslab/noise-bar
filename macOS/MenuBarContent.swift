import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject var state: AppState
    @StateObject private var loginItem = LoginItemManager()

    var body: some View {
        Menu(currentSoundsLabel) {
            ForEach(SoundLibrary.all) { sound in
                Button(sound.name) { state.playSound(sound) }
            }
        }

        Menu(pomodoroLabel) {
            Menu("Work sound: \(state.pomodoro.workSound.name)") {
                ForEach(SoundLibrary.all) { sound in
                    Button {
                        state.pomodoro.workSound = sound
                    } label: {
                        if sound.id == state.pomodoro.workSound.id {
                            Label(sound.name, systemImage: "checkmark")
                        } else {
                            Text(sound.name)
                        }
                    }
                }
            }
            Menu("Break sound: \(state.pomodoro.breakSound.name)") {
                ForEach(SoundLibrary.all) { sound in
                    Button {
                        state.pomodoro.breakSound = sound
                    } label: {
                        if sound.id == state.pomodoro.breakSound.id {
                            Label(sound.name, systemImage: "checkmark")
                        } else {
                            Text(sound.name)
                        }
                    }
                }
            }
            Menu("Work duration: \(state.pomodoro.workDuration.label)") {
                ForEach(PomodoroDurations.options) { opt in
                    Button {
                        state.pomodoro.workDuration = opt
                    } label: {
                        if opt.minutes == state.pomodoro.workDuration.minutes {
                            Label(opt.label, systemImage: "checkmark")
                        } else {
                            Text(opt.label)
                        }
                    }
                }
            }
            Menu("Break duration: \(state.pomodoro.breakDuration.label)") {
                ForEach(PomodoroDurations.options) { opt in
                    Button {
                        state.pomodoro.breakDuration = opt
                    } label: {
                        if opt.minutes == state.pomodoro.breakDuration.minutes {
                            Label(opt.label, systemImage: "checkmark")
                        } else {
                            Text(opt.label)
                        }
                    }
                }
            }
            Button {
                state.pomodoro.loop.toggle()
            } label: {
                if state.pomodoro.loop {
                    Label("Loop", systemImage: "checkmark")
                } else {
                    Text("Loop")
                }
            }
            Divider()
            Button(state.pomodoro.isRunning ? "Stop Pomodoro" : "Start Pomodoro") {
                if state.pomodoro.isRunning {
                    state.pomodoro.cancelAll()
                } else {
                    state.pomodoro.start()
                }
            }
        }

        Divider()

        Button("Stop") { state.stopAll() }

        Button {
            loginItem.toggle()
        } label: {
            if loginItem.isEnabled {
                Label("Launch at login", systemImage: "checkmark")
            } else {
                Text("Launch at login")
            }
        }

        Divider()

        Button("Quit") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }

    private var currentSoundsLabel: String {
        if let s = state.audio.currentSound { return "Sounds: \(s.name)" }
        return "Sounds"
    }

    private var pomodoroLabel: String {
        let w = state.pomodoro.workDuration.minutes
        let b = state.pomodoro.breakDuration.minutes
        return "Pomodoro (\(w)/\(b))"
    }
}
