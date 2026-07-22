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
        // Apps offer wildly different flavours (JPEG, HEIC, PDF from vector apps),
        // so fall back to anything NSImage can decode once the two cheap bitmap
        // flavours are ruled out.
        let imageTypes = [NSPasteboard.PasteboardType.png, .tiff]
            + NSImage.imageTypes.map(NSPasteboard.PasteboardType.init(rawValue:))
        if let type = pasteboard.availableType(from: imageTypes),
           let data = pasteboard.data(forType: type) {
            return .image(data)
        }
        if let text = pasteboard.string(forType: .string) {
            return .text(text)
        }
        return nil
    }
}
