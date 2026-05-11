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
    let workSoundID: String?
    let breakSoundID: String?
    let workDurationMinutes: Int?
    let breakDurationMinutes: Int?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NoiseBarEntry {
        NoiseBarEntry(
            date: Date(),
            currentSoundID: nil,
            pomodoroPhase: nil,
            pomodoroEndDate: nil,
            workSoundID: "brown-noise",
            breakSoundID: "birds",
            workDurationMinutes: 25,
            breakDurationMinutes: 5
        )
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
        let state = SharedStateStore.read()
        return NoiseBarEntry(
            date: Date(),
            currentSoundID: state.currentSoundID,
            pomodoroPhase: state.pomodoroPhase,
            pomodoroEndDate: state.pomodoroEndDate,
            workSoundID: state.workSoundID,
            breakSoundID: state.breakSoundID,
            workDurationMinutes: state.workDurationMinutes,
            breakDurationMinutes: state.breakDurationMinutes
        )
    }
}

struct NoiseBarWidgetView: View {
    var entry: NoiseBarEntry

    private var pomoRunning: Bool { entry.pomodoroPhase != nil }
    private var workSoundName: String {
        SoundLibrary.byID(entry.workSoundID ?? "")?.name ?? "—"
    }
    private var breakSoundName: String {
        SoundLibrary.byID(entry.breakSoundID ?? "")?.name ?? "—"
    }
    private var workMin: Int { entry.workDurationMinutes ?? 25 }
    private var breakMin: Int { entry.breakDurationMinutes ?? 5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            countdown
            settings
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
    private var countdown: some View {
        if let phase = entry.pomodoroPhase, let end = entry.pomodoroEndDate {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(phase.capitalized)
                    .font(.caption2)
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
            HStack(spacing: 4) {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(.secondary)
                Text(sound.name).font(.headline).lineLimit(1)
            }
        } else {
            Text("Idle")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 2) {
            settingRow(label: "Work", sound: workSoundName, minutes: workMin)
            settingRow(label: "Break", sound: breakSoundName, minutes: breakMin)
        }
    }

    private func settingRow(label: String, sound: String, minutes: Int) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(sound).font(.caption2).lineLimit(1)
            Spacer(minLength: 4)
            Text("\(minutes)m").font(.caption2).monospacedDigit().foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button(intent: TogglePomodoroIntent()) {
                Label(
                    pomoRunning ? "Stop Pomodoro" : "Start Pomodoro",
                    systemImage: pomoRunning ? "pause.fill" : "play.fill"
                )
                .labelStyle(.iconOnly)
                .font(.title3)
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderedProminent)

            Link(destination: URL(string: "noisebar://")!) {
                Label("Open", systemImage: "arrow.up.right.square.fill")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .background(.thinMaterial, in: Capsule())
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
