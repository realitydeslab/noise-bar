import Foundation

#if os(iOS)
@MainActor
public enum DarwinBus {
    public static func post(_ name: String) {
        let cfName = name as CFString
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(cfName),
            nil, nil, true
        )
    }

    @discardableResult
    public static func observe(_ name: String, handler: @escaping @Sendable () -> Void) -> AnyObject {
        let observer = DarwinObserver(handler: handler)
        let cfName = name as CFString
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(observer).toOpaque(),
            { _, observerPtr, _, _, _ in
                guard let observerPtr = observerPtr else { return }
                let o = Unmanaged<DarwinObserver>.fromOpaque(observerPtr).takeUnretainedValue()
                DispatchQueue.main.async { o.handler() }
            },
            cfName, nil, .deliverImmediately
        )
        return observer
    }
}

final class DarwinObserver {
    let handler: @Sendable () -> Void
    init(handler: @escaping @Sendable () -> Void) { self.handler = handler }
}
#endif
