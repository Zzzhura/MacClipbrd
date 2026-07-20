import AppKit
import CryptoKit

struct ImageRef: Codable, Equatable {
    let fileName: String
    let thumbnailName: String
    let hash: String
    let width: Int
    let height: Int

    var url: URL { ImageStore.directory.appendingPathComponent(fileName) }
    var thumbnailURL: URL { ImageStore.directory.appendingPathComponent(thumbnailName) }
}

enum ImageStore {
    static let directory: URL = {
        let dir = HistoryStore.supportDirectory.appendingPathComponent("Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// Everything is normalised to PNG so the pasteboard flavour the image came
    /// in with (TIFF, PDF-backed, …) does not leak into the stored file name.
    static func pngData(from data: Data) -> Data? {
        if let rep = NSBitmapImageRep(data: data) {
            return rep.representation(using: .png, properties: [:])
        }
        // Vector flavours (PDF, EPS) have no bitmap rep until NSImage rasterises them.
        guard let image = NSImage(data: data), let tiff = image.tiffRepresentation else { return nil }
        return NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
    }

    static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func store(png: Data, hash: String) -> ImageRef? {
        guard let rep = NSBitmapImageRep(data: png),
              let image = NSImage(data: png),
              let thumb = thumbnail(of: image) else { return nil }
        let base = UUID().uuidString
        let fileName = base + ".png"
        let thumbnailName = base + "-thumb.png"
        try? png.write(to: directory.appendingPathComponent(fileName), options: .atomic)
        try? thumb.write(to: directory.appendingPathComponent(thumbnailName), options: .atomic)
        return ImageRef(fileName: fileName,
                        thumbnailName: thumbnailName,
                        hash: hash,
                        width: rep.pixelsWide,
                        height: rep.pixelsHigh)
    }

    static func delete(_ ref: ImageRef) {
        try? FileManager.default.removeItem(at: ref.url)
        try? FileManager.default.removeItem(at: ref.thumbnailURL)
    }

    private static func thumbnail(of image: NSImage) -> Data? {
        let side: CGFloat = 96
        let scale = min(1, side / max(image.size.width, image.size.height))
        let size = NSSize(width: max(1, (image.size.width * scale).rounded()),
                          height: max(1, (image.size.height * scale).rounded()))
        let thumb = NSImage(size: size)
        thumb.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        thumb.unlockFocus()
        guard let tiff = thumb.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
