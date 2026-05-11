import WidgetKit
import SwiftUI

struct NoiseBarEntry: TimelineEntry {
    let date: Date
    let currentSoundID: String?
    let pomodoroRemaining: Int?
    let pomodoroPhase: String?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NoiseBarEntry {
        NoiseBarEntry(date: Date(), currentSoundID: "brown-noise", pomodoroRemaining: nil, pomodoroPhase: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NoiseBarEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NoiseBarEntry>) -> Void) {
        let entry = readEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date().addingTimeInterval(60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readEntry() -> NoiseBarEntry {
        let defaults = UserDefaults(suiteName: "group.design.reality.noisebar")
        return NoiseBarEntry(
            date: Date(),
            currentSoundID: defaults?.string(forKey: "currentSoundID"),
            pomodoroRemaining: defaults?.object(forKey: "pomodoroRemaining") as? Int,
            pomodoroPhase: defaults?.string(forKey: "pomodoroPhase")
        )
    }
}

struct NoiseBarWidgetView: View {
    var entry: NoiseBarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform")
                Text("NoiseBar").font(.caption).bold()
                Spacer()
            }
            if let phase = entry.pomodoroPhase, let remaining = entry.pomodoroRemaining {
                Text(phase.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(formatMMSS(remaining))
                    .font(.system(.title, design: .monospaced))
                    .bold()
            } else if let id = entry.currentSoundID, let sound = SoundLibrary.byID(id) {
                Text("Playing")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(sound.name)
                    .font(.headline)
                    .lineLimit(2)
            } else {
                Text("Idle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Tap to open")
                    .font(.headline)
            }
            Spacer(minLength: 0)
        }
        .containerBackground(.background, for: .widget)
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
        .description("Shows the currently playing sound or Pomodoro countdown.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
