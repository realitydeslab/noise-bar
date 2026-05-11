import Foundation
import AVFoundation

@MainActor
public final class AudioPlayer: ObservableObject {
    @Published public private(set) var currentSound: Sound?

    private var player: AVAudioPlayer?

    public init() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    public func play(_ sound: Sound) {
        guard let url = Bundle.main.url(forResource: sound.filename, withExtension: "m4a") else {
            #if DEBUG
            print("Missing audio file: \(sound.filename).m4a")
            #endif
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.prepareToPlay()
            p.play()
            player = p
            currentSound = sound
            WidgetSync.updateCurrentSound(sound)
        } catch {
            #if DEBUG
            print("AVAudioPlayer error: \(error)")
            #endif
        }
    }

    public func stop() {
        player?.stop()
        player = nil
        currentSound = nil
        WidgetSync.updateCurrentSound(nil)
    }
}
