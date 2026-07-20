import AppKit

struct FileRef: Codable {
    let name: String
    let originalPath: String
    let size: Int64
    let isDirectory: Bool
    let storage: String?

    var isStored: Bool { storage != nil }

    var url: URL {
        guard let storage else { return URL(fileURLWithPath: originalPath) }
        return FileStore.directory
            .appendingPathComponent(storage, isDirectory: true)
            .appendingPathComponent(name)
    }

    /// The copy keeps the original extension, so the stored file resolves to the
    /// same icon as the original — and to the right one once the original is gone.
    var iconPath: String { isStored ? url.path : originalPath }
}

extension FileRef: Equatable {
    // Identity is the file that was copied, not where it landed: dedup has to
    // recognise a re-copy, and it runs before this entry's copy exists.
    static func == (lhs: FileRef, rhs: FileRef) -> Bool {
        lhs.originalPath == rhs.originalPath && lhs.size == rhs.size
    }
}

extension FileRef {
    // Histories written before file assets stored a bare file URL per entry.
    init(from decoder: Decoder) throws {
        if let string = try? decoder.singleValueContainer().decode(String.self),
           let url = URL(string: string) {
            self = FileStore.describe(url) ?? FileRef(name: url.lastPathComponent,
                                                     originalPath: url.path,
                                                     size: 0,
                                                     isDirectory: url.hasDirectoryPath,
                                                     storage: nil)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        originalPath = try container.decode(String.self, forKey: .originalPath)
        size = try container.decode(Int64.self, forKey: .size)
        isDirectory = try container.decode(Bool.self, forKey: .isDirectory)
        storage = try container.decodeIfPresent(String.self, forKey: .storage)
    }
}

enum FileStore {
    static let directory: URL = {
        let dir = HistoryStore.supportDirectory.appendingPathComponent("Files", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// Past this a copy costs more than it is worth: the history holds 200 entries,
    /// and targets people paste files into cap uploads well below it anyway.
    static let maxCopyBytes: Int64 = 64 * 1024 * 1024

    static func describe(_ url: URL) -> FileRef? {
        guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
        else { return nil }
        return FileRef(name: url.lastPathComponent,
                       originalPath: url.path,
                       size: Int64(values.fileSize ?? 0),
                       isDirectory: values.isDirectory ?? false,
                       storage: nil)
    }

    /// Directories and oversized files stay plain references to the original.
    static func store(_ ref: FileRef) -> FileRef {
        guard !ref.isDirectory, ref.size <= maxCopyBytes else { return ref }
        let storage = UUID().uuidString
        let folder = directory.appendingPathComponent(storage, isDirectory: true)
        // A directory per entry: the copy has to keep the original name, which is
        // what a paste target attaches, so names of unrelated entries would clash.
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: URL(fileURLWithPath: ref.originalPath),
                                             to: folder.appendingPathComponent(ref.name))
        } catch {
            try? FileManager.default.removeItem(at: folder)
            return ref
        }
        return FileRef(name: ref.name,
                       originalPath: ref.originalPath,
                       size: ref.size,
                       isDirectory: false,
                       storage: storage)
    }

    static func removeAll(except keep: Set<String>) {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        for name in names where !keep.contains(name) {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        }
    }
}
