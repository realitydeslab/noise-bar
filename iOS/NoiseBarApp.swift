import SwiftUI

@main
struct NoiseBarApp: App {
    @StateObject private var state = AppState()
    @Environment(\.scenePhase) private var scenePhase
    @State private var darwinToken: AnyObject?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .onAppear {
                    processPendingAction()
                    if darwinToken == nil {
                        darwinToken = DarwinBus.observe(AppIntentBus.darwinNotificationName) {
                            Task { @MainActor in processPendingAction() }
                        }
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { processPendingAction() }
                }
        }
    }

    @MainActor
    private func processPendingAction() {
        var current = SharedStateStore.read()
        guard let raw = current.pendingAction,
              let action = PendingAction(rawValue: raw)
        else { return }
        let soundID = current.pendingSoundID
        SharedStateStore.write { s in
            s.pendingAction = nil
            s.pendingSoundID = nil
        }
        _ = current

        switch action {
        case .stop:
            state.stopAll()
        case .togglePomodoro:
            if state.pomodoro.isRunning {
                state.pomodoro.cancelAll()
            } else {
                state.pomodoro.start()
            }
        case .play:
            if let id = soundID, let s = SoundLibrary.byID(id) {
                state.playSound(s)
            }
        }
    }
}
