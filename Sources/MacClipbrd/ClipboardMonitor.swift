import AppKit

enum ClipboardPayload {
    case text(String)
    case image(Data)
    case files([URL])
}

final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let onChange: (ClipboardPayload) -> Void

    var ignoreNextChange = false

    init(onChange: @escaping (ClipboardPayload) -> Void) {
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
        guard let payload = readPayload() else { return }
        onChange(payload)
    }

    /// Copies carry several flavours at once — a Finder copy also puts the paths
    /// on as text — so the richest one wins.
    private func readPayload() -> ClipboardPayload? {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL],
           !urls.isEmpty {
            return .files(urls)
        }
        for type in [NSPasteboard.PasteboardType.png, .tiff] {
            if let data = pasteboard.data(forType: type) {
                return .image(data)
            }
        }
        if let text = pasteboard.string(forType: .string) {
            return .text(text)
        }
        return nil
    }
}
