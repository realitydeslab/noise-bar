import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

public extension Image {
    static func bundleIcon(_ name: String) -> Image {
        #if os(iOS)
        if let ui = UIImage(named: name) {
            return Image(uiImage: ui)
        }
        #else
        if let ns = NSImage(named: name) {
            return Image(nsImage: ns)
        }
        #endif
        return Image(systemName: "speaker.wave.2.fill")
    }
}
