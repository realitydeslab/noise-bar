import SwiftUI

@main
struct NoiseBarApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(state)
        } label: {
            MenuBarLabel()
                .environmentObject(state)
        }
        .menuBarExtraStyle(.menu)
    }
}

struct MenuBarLabel: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform")
            if state.pomodoro.isRunning {
                Text(formatMMSS(state.pomodoro.remaining))
            }
        }
    }
}
