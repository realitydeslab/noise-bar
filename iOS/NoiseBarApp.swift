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
        guard let raw = SharedKeys.defaults?.string(forKey: SharedKeys.pendingAction),
              let action = PendingAction(rawValue: raw)
        else { return }
        SharedKeys.defaults?.removeObject(forKey: SharedKeys.pendingAction)

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
            if let id = SharedKeys.defaults?.string(forKey: SharedKeys.pendingSoundID),
               let s = SoundLibrary.byID(id) {
                state.playSound(s)
            }
            SharedKeys.defaults?.removeObject(forKey: SharedKeys.pendingSoundID)
        }
    }
}
