import Foundation
import Combine

enum ClipContent: Codable {
    case text(String)
    case image(ImageRef)
    case files([FileRef])
}

extension ClipContent: Equatable {
    static func == (lhs: ClipContent, rhs: ClipContent) -> Bool {
        switch (lhs, rhs) {
        case let (.text(l), .text(r)): return l == r
        case let (.image(l), .image(r)): return l.hash == r.hash
        case let (.files(l), .files(r)): return l == r
        default: return false
        }
    }
}

struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: ClipContent
    let date: Date

    init(content: ClipContent, date: Date = Date()) {
        self.id = UUID()
        self.content = content
        self.date = date
    }

    var searchText: String {
        switch content {
        case .text(let text): return text
        case .image: return ""
        case .files(let refs): return refs.map(\.name).joined(separator: " ")
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, content, date
    }

    // Histories written before media support have a bare `text` field instead.
    private enum LegacyKeys: String, CodingKey {
        case text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        if let content = try container.decodeIfPresent(ClipContent.self, forKey: .content) {
            self.content = content
        } else {
            let legacy = try decoder.container(keyedBy: LegacyKeys.self)
            self.content = .text(try legacy.decode(String.self, forKey: .text))
        }
    }
}

final class HistoryStore: ObservableObject {
    @Published private(set) var items: [ClipItem] = []

    static let supportDirectory: URL = {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MacClipbrd", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private let maxItems = 200
    private let fileURL: URL

    init() {
        fileURL = Self.supportDirectory.appendingPathComponent("history.json")
        load()
    }

    func add(_ payload: ClipboardPayload) {
        switch payload {
        case .text(let text):
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            insert(.text(text))
        case .image(let data):
            guard let png = ImageStore.pngData(from: data) else { return }
            let hash = ImageStore.hash(png)
            // Hash first: writing the file before the dedup check would orphan it.
            if case .image(let ref) = items.first?.content, ref.hash == hash { return }
            guard let ref = ImageStore.store(png: png, hash: hash) else { return }
            insert(.image(ref))
        case .files(let urls):
            let refs = urls.compactMap(FileStore.describe)
            guard !refs.isEmpty else { return }
            // Describe first: copying before the dedup check would orphan the copies.
            if case .files(let stored) = items.first?.content, stored == refs { return }
            insert(.files(refs.map(FileStore.store)))
        }
    }

    func remove(_ item: ClipItem) {
        items.removeAll { $0.id == item.id }
        discardAssets(of: [item])
        save()
    }

    func clear() {
        let dropped = items
        items.removeAll()
        discardAssets(of: dropped)
        save()
    }

    private func insert(_ content: ClipContent) {
        if items.first?.content == content { return }
        let duplicates = items.filter { $0.content == content }
        items.removeAll { $0.content == content }
        discardAssets(of: duplicates)
        items.insert(ClipItem(content: content), at: 0)
        if items.count > maxItems {
            let overflow = items.count - maxItems
            discardAssets(of: Array(items.suffix(overflow)))
            items.removeLast(overflow)
        }
        save()
    }

    private func discardAssets(of items: [ClipItem]) {
        for item in items {
            switch item.content {
            case .image(let ref): ImageStore.delete(ref)
            case .files(let refs): refs.forEach(FileStore.delete)
            case .text: break
            }
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ClipItem].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
