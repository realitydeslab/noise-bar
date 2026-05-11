import WidgetKit
import SwiftUI
import AppIntents
import os

private let log = Logger(subsystem: "design.reality.noisebar", category: "Widget")

struct NoiseBarEntry: TimelineEntry {
    let date: Date
    let currentSoundID: String?
    let pomodoroPhase: String?
    let pomodoroEndDate: Date?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NoiseBarEntry {
        NoiseBarEntry(date: Date(), currentSoundID: "brown-noise", pomodoroPhase: nil, pomodoroEndDate: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NoiseBarEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NoiseBarEntry>) -> Void) {
        let entry = readEntry()
        let refreshAt: Date = {
            if let end = entry.pomodoroEndDate { return end }
            return Date().addingTimeInterval(15 * 60)
        }()
        completion(Timeline(entries: [entry], policy: .after(refreshAt)))
    }

    private func readEntry() -> NoiseBarEntry {
        let url = SharedStateStore.stateFileURL?.path ?? "<no container>"
        let exists = FileManager.default.fileExists(atPath: SharedStateStore.stateFileURL?.path ?? "")
        let state = SharedStateStore.read()
        log.notice("readEntry: file=\(url, privacy: .public) exists=\(exists, privacy: .public) soundID=\(state.currentSoundID ?? "<nil>", privacy: .public), phase=\(state.pomodoroPhase ?? "<nil>", privacy: .public)")
        return NoiseBarEntry(
            date: Date(),
            currentSoundID: state.currentSoundID,
            pomodoroPhase: state.pomodoroPhase,
            pomodoroEndDate: state.pomodoroEndDate
        )
    }
}

struct NoiseBarWidgetView: View {
    var entry: NoiseBarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            content
            Spacer(minLength: 0)
            actions
        }
        .containerBackground(.background, for: .widget)
    }

    private var header: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform")
            Text("NoiseBar").font(.caption2).bold()
            Spacer()
        }
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var content: some View {
        if let phase = entry.pomodoroPhase, let end = entry.pomodoroEndDate {
            VStack(alignment: .leading, spacing: 2) {
                Text(phase.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if end > Date() {
                    Text(timerInterval: Date()...end, countsDown: true)
                        .font(.system(.title2, design: .monospaced).bold())
                        .monospacedDigit()
                } else {
                    Text("0:00")
                        .font(.system(.title2, design: .monospaced).bold())
                }
            }
        } else if let id = entry.currentSoundID, let sound = SoundLibrary.byID(id) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Playing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(sound.name)
                    .font(.headline)
                    .lineLimit(2)
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("Idle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Tap to open")
                    .font(.headline)
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        let isActive = entry.pomodoroPhase != nil || entry.currentSoundID != nil
        HStack(spacing: 8) {
            Button(intent: TogglePomodoroIntent()) {
                Label(entry.pomodoroPhase != nil ? "Stop" : "Pomodoro",
                      systemImage: entry.pomodoroPhase != nil ? "stop.fill" : "timer")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderedProminent)

            if isActive {
                Button(intent: StopNoiseBarIntent()) {
                    Label("Stop", systemImage: "stop.fill")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

@main
struct NoiseBarWidget: Widget {
    let kind: String = "NoiseBarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NoiseBarWidgetView(entry: entry)
        }
        .configurationDisplayName("NoiseBar")
        .description("Currently playing sound or Pomodoro countdown.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
