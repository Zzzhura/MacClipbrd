import AppKit

final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let onChange: (String) -> Void

    var ignoreNextChange = false

    init(onChange: @escaping (String) -> Void) {
        self.onChange = onChange
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Pulls in anything copied since the last tick, so the history is current
    /// the moment the panel opens rather than up to a poll interval stale.
    func pollNow() {
        poll()
    }

    private func poll() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        if ignoreNextChange {
            ignoreNextChange = false
            return
        }
        guard let text = pasteboard.string(forType: .string) else { return }
        onChange(text)
    }
}
