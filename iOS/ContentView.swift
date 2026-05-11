import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var showPomodoroSheet = false

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    pomodoroCard
                    soundGrid
                }
                .padding()
            }
            .navigationTitle("NoiseBar")
            .toolbar {
                if state.audio.currentSound != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Stop", role: .destructive) { state.stopAll() }
                    }
                }
            }
            .sheet(isPresented: $showPomodoroSheet) {
                PomodoroSettingsView(pomodoro: state.pomodoro)
            }
        }
    }

    private var pomodoroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pomodoro (\(state.pomodoro.workDuration.minutes)/\(state.pomodoro.breakDuration.minutes))")
                    .font(.headline)
                Spacer()
                Button { showPomodoroSheet = true } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
            if state.pomodoro.isRunning {
                HStack {
                    Image(systemName: state.pomodoro.phase == .work ? "brain.head.profile" : "cup.and.saucer")
                    Text(state.pomodoro.phase == .work ? "Work" : "Break")
                    Spacer()
                    Text(formatMMSS(state.pomodoro.remaining))
                        .font(.system(.title2, design: .monospaced))
                        .bold()
                }
            }
            Button {
                if state.pomodoro.isRunning {
                    state.pomodoro.cancelAll()
                } else {
                    state.pomodoro.start()
                }
            } label: {
                Text(state.pomodoro.isRunning ? "Stop Pomodoro" : "Start Pomodoro")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private var soundGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sounds")
                .font(.headline)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(SoundLibrary.all) { sound in
                    SoundButton(
                        sound: sound,
                        isActive: state.audio.currentSound?.id == sound.id
                    ) {
                        state.playSound(sound)
                    }
                }
            }
        }
    }
}

struct SoundButton: View {
    let sound: Sound
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image.bundleIcon(sound.iconName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(isActive ? .white : .primary)
                Text(sound.name)
                    .font(.caption)
                    .foregroundStyle(isActive ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.accentColor : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

struct PomodoroSettingsView: View {
    @ObservedObject var pomodoro: PomodoroTimer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Work") {
                    Picker("Sound", selection: $pomodoro.workSound) {
                        ForEach(SoundLibrary.all) { Text($0.name).tag($0) }
                    }
                    Picker("Duration", selection: $pomodoro.workDuration) {
                        ForEach(PomodoroDurations.options) { Text($0.label).tag($0) }
                    }
                }
                Section("Break") {
                    Picker("Sound", selection: $pomodoro.breakSound) {
                        ForEach(SoundLibrary.all) { Text($0.name).tag($0) }
                    }
                    Picker("Duration", selection: $pomodoro.breakDuration) {
                        ForEach(PomodoroDurations.options) { Text($0.label).tag($0) }
                    }
                }
                Section {
                    Toggle("Loop", isOn: $pomodoro.loop)
                }
            }
            .navigationTitle("Pomodoro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
