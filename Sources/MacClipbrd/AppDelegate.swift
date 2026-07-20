import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let store = HistoryStore()
    private lazy var vm = HistoryViewModel(store: store)
    private var monitor: ClipboardMonitor!
    private var hotKey: HotKey?
    private var keyMonitor: Any?
    private var cursorPanel: CursorPanel?
    private var previousApp: NSRunningApplication?
    private var didWarnAccessibility = false

    private static let didPromptKey = "didPromptAccessibility"

    private var isShowingHistory: Bool {
        cursorPanel?.isVisible == true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        vm.onSelect = { [weak self] item in self?.paste(item) }
        setupStatusItem()
        setupKeyMonitor()

        monitor = ClipboardMonitor { [weak self] text in
            self?.store.add(text)
        }
        monitor.start()

        hotKey = HotKey { [weak self] in
            self?.toggleCursorPanel()
        }

        checkAccessibilityAtLaunch()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard",
                                   accessibilityDescription: "MacClipbrd")
            button.action = #selector(toggleFromStatusItem)
            button.target = self
        }
    }

    private func setupKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isShowingHistory else { return event }
            return self.vm.handleKey(event) ? nil : event
        }
    }

    @objc private func toggleFromStatusItem() {
        guard let button = statusItem.button else { return }
        togglePanel { $0.show(below: button) }
    }

    private func toggleCursorPanel() {
        togglePanel { $0.showAtCursor() }
    }

    private func togglePanel(_ present: (CursorPanel) -> Void) {
        if let panel = cursorPanel, panel.isVisible {
            panel.close()
            return
        }
        previousApp = NSWorkspace.shared.frontmostApplication
        monitor.pollNow()
        let panel = CursorPanel(
            rootView: HistoryView(vm: vm),
            onClose: { [weak self] in self?.cursorPanel = nil }
        )
        cursorPanel = panel
        present(panel)
    }

    private func paste(_ item: ClipItem) {
        let pb = NSPasteboard.general
        monitor.ignoreNextChange = true
        pb.clearContents()
        pb.setString(item.text, forType: .string)

        cursorPanel?.close()
        cursorPanel = nil

        // Return focus to the app that was frontmost, then paste into it.
        previousApp?.activate()

        // Without Accessibility the text is still on the pasteboard, so the user
        // can press ⌘V themselves — degrade quietly instead of blocking.
        guard AXIsProcessTrusted() else {
            warnAccessibilityOnce()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.simulatePaste()
        }
    }

    private func simulatePaste() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let vKey: CGKeyCode = 0x09 // 'v'
        let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    private func warnAccessibilityOnce() {
        guard !didWarnAccessibility else { return }
        didWarnAccessibility = true
        // Deferred so the alert does not fight the app we just activated.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.promptAccessibility(pasteFallbackHint: true)
        }
    }

    /// After an app update macOS may keep a stale Accessibility record: the
    /// checkbox still looks enabled while the grant no longer applies. Tell the
    /// user how to fix that rather than letting auto-paste silently do nothing.
    private func checkAccessibilityAtLaunch() {
        guard !AXIsProcessTrusted() else {
            UserDefaults.standard.set(false, forKey: Self.didPromptKey)
            return
        }
        guard !UserDefaults.standard.bool(forKey: Self.didPromptKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.didPromptKey)
        promptAccessibility(pasteFallbackHint: false)
    }

    private func promptAccessibility(pasteFallbackHint: Bool) {
        let loc = Localization.shared
        let alert = NSAlert()
        alert.messageText = loc.accessibilityAlertTitle
        var text = loc.accessibilityAlertBody
        if pasteFallbackHint {
            text = loc.pasteFallbackHint + text
        }
        alert.informativeText = text
        alert.addButton(withTitle: loc.openSettings)
        alert.addButton(withTitle: loc.later)
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
}
