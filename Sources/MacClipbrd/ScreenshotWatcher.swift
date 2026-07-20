import AppKit
import CoreServices

/// ⇧⌘3 and ⇧⌘4 write a file instead of touching the pasteboard, so the clipboard
/// monitor never sees them. Watch the directory `screencapture` saves into.
final class ScreenshotWatcher {
    private let onCapture: (Data) -> Void
    private let directory: URL
    private var descriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private var seen: Set<String> = []

    init(onCapture: @escaping (Data) -> Void) {
        self.onCapture = onCapture
        directory = Self.screenshotDirectory()
    }

    func start() {
        seen = Self.imageNames(in: directory)
        descriptor = open(directory.path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor,
                                                              eventMask: .write,
                                                              queue: .main)
        source.setEventHandler { [weak self] in self?.scan() }
        source.setCancelHandler { [descriptor] in close(descriptor) }
        source.resume()
        self.source = source
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    private func scan() {
        let names = Self.imageNames(in: directory)
        let added = names.subtracting(seen)
        seen = names
        for name in added {
            ingest(directory.appendingPathComponent(name), attempt: 0)
        }
    }

    /// The event fires while the file is still being written, and Spotlight stamps
    /// the screenshot flag only once it indexes the file — both lag the event.
    private func ingest(_ url: URL, attempt: Int) {
        guard attempt < 4 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            guard Self.isScreenCapture(url) else {
                self.ingest(url, attempt: attempt + 1)
                return
            }
            guard let data = try? Data(contentsOf: url) else { return }
            self.onCapture(data)
        }
    }

    private static func imageNames(in directory: URL) -> Set<String> {
        let extensions: Set<String> = ["png", "jpg", "jpeg", "tiff", "heic"]
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return Set(names.filter { extensions.contains(($0 as NSString).pathExtension.lowercased()) })
    }

    /// Distinguishes a screenshot from any other image the user drops into the
    /// same folder; `screencapture` is what sets this attribute.
    private static func isScreenCapture(_ url: URL) -> Bool {
        guard let item = MDItemCreate(nil, url.path as CFString),
              let flag = MDItemCopyAttribute(item, "kMDItemIsScreenCapture" as CFString) as? Bool
        else { return false }
        return flag
    }

    private static func screenshotDirectory() -> URL {
        if let path = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location"),
           !path.isEmpty {
            return URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        }
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
    }
}
