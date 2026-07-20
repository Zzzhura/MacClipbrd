import AppKit
import SwiftUI

final class CursorPanel: NSPanel {
    static let preferredSize = NSSize(width: 340, height: 440)

    override var canBecomeKey: Bool { true }

    private var onClose: (() -> Void)?
    private var isClosing = false

    init(rootView: some View, onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init(contentRect: NSRect(origin: .zero, size: Self.preferredSize),
                   styleMask: [.fullSizeContentView, .borderless],
                   backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .popUpMenu
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        backgroundColor = .clear
        hasShadow = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let host = NSHostingView(rootView: rootView)
        host.wantsLayer = true
        host.layer?.cornerRadius = 10
        host.layer?.masksToBounds = true
        contentView = host
    }

    func showAtCursor() {
        let mouse = NSEvent.mouseLocation
        show(preferredTopLeft: NSPoint(x: mouse.x, y: mouse.y), near: mouse)
    }

    func show(below view: NSView) {
        guard let window = view.window else { return }
        let rect = window.convertToScreen(view.convert(view.bounds, to: nil))
        show(preferredTopLeft: NSPoint(x: rect.midX - frame.width / 2, y: rect.minY),
             near: NSPoint(x: rect.midX, y: rect.midY))
    }

    private func show(preferredTopLeft topLeft: NSPoint, near point: NSPoint) {
        let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
        let vis = screen?.visibleFrame ?? frame
        let size = NSSize(width: min(Self.preferredSize.width, vis.width - 16),
                          height: min(Self.preferredSize.height, vis.height - 16))
        setContentSize(size)

        var origin = NSPoint(x: topLeft.x, y: topLeft.y - size.height)
        origin.x = min(max(origin.x, vis.minX + 8), vis.maxX - size.width - 8)
        origin.y = min(max(origin.y, vis.minY + 8), vis.maxY - size.height - 8)
        setFrameOrigin(origin)
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }

    override func resignKey() {
        super.resignKey()
        close()
    }

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    override func close() {
        guard !isClosing else { return }
        isClosing = true
        super.close()
        onClose?()
    }
}
