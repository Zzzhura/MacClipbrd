import SwiftUI
import AppKit

final class HistoryViewModel: ObservableObject {
    @Published var query = ""
    @Published var selectedID: UUID?
    let store: HistoryStore
    var onSelect: ((ClipItem) -> Void)?

    init(store: HistoryStore) {
        self.store = store
    }

    func reset() {
        query = ""
        selectedID = store.items.first?.id
    }

    /// Returns true if the event was consumed.
    func handleKey(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 125: move(1)
        case 126: move(-1)
        case 36, 76:
            guard let item = selectedItem else { return true }
            onSelect?(item)
        default: return false
        }
        return true
    }

    var filtered: [ClipItem] {
        guard !query.isEmpty else { return store.items }
        return store.items.filter { $0.text.localizedCaseInsensitiveContains(query) }
    }

    var selectedItem: ClipItem? {
        filtered.first { $0.id == selectedID } ?? filtered.first
    }

    func ensureSelection() {
        if selectedID == nil || !filtered.contains(where: { $0.id == selectedID }) {
            selectedID = filtered.first?.id
        }
    }

    func move(_ delta: Int) {
        let items = filtered
        guard !items.isEmpty else { return }
        let idx = items.firstIndex { $0.id == selectedID } ?? 0
        let next = min(max(idx + delta, 0), items.count - 1)
        selectedID = items[next].id
    }
}

struct HistoryView: View {
    @ObservedObject var store: HistoryStore
    @ObservedObject var vm: HistoryViewModel

    @FocusState private var searchFocused: Bool

    init(vm: HistoryViewModel) {
        self.store = vm.store
        self.vm = vm
    }

    private func onSelect(_ item: ClipItem) {
        vm.onSelect?(item)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            if vm.filtered.isEmpty {
                emptyState
            } else {
                list
            }
            Divider()
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            vm.reset()
            searchFocused = true
        }
        .onChange(of: vm.query) { _ in vm.ensureSelection() }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Поиск…", text: $vm.query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
            if !vm.query.isEmpty {
                Button {
                    vm.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(vm.filtered) { item in
                        ClipRow(item: item,
                                selected: item.id == vm.selectedID,
                                onSelect: { onSelect(item) },
                                onDelete: { store.remove(item) })
                            .id(item.id)
                        Divider()
                    }
                }
            }
            .onChange(of: vm.selectedID) { id in
                guard let id else { return }
                proxy.scrollTo(id)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "doc.on.clipboard")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(store.items.isEmpty ? "История пуста" : "Ничего не найдено")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack {
            Text("\(store.items.count) элем.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Очистить") { store.clear() }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
                .disabled(store.items.isEmpty)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

}

private struct ClipRow: View {
    let item: ClipItem
    let selected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(item.text)
                .lineLimit(3)
                .font(.system(size: 13))
                .foregroundStyle(selected ? Color.white : Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if hovering {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(selected ? Color.white.opacity(0.8) : Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(background)
        .onHover { hovering = $0 }
        .onTapGesture { onSelect() }
    }

    private var background: Color {
        if selected { return Color.accentColor }
        if hovering { return Color.primary.opacity(0.06) }
        return Color.clear
    }
}
