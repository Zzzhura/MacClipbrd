import AppKit
import Carbon.HIToolbox

final class HotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let handler: () -> Void

    // Default: Cmd+Opt+V
    init(keyCode: UInt32 = UInt32(kVK_ANSI_V),
         modifiers: UInt32 = UInt32(cmdKey | optionKey),
         handler: @escaping () -> Void) {
        self.handler = handler
        register(keyCode: keyCode, modifiers: modifiers)
    }

    private func register(keyCode: UInt32, modifiers: UInt32) {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4d425546), id: 1) // "MBUF"

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData -> OSStatus in
            guard let userData = userData else { return noErr }
            let me = Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue()
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            if hkID.id == 1 {
                DispatchQueue.main.async { me.handler() }
            }
            return noErr
        }, 1, &eventType, selfPtr, &eventHandler)

        RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    deinit {
        if let hotKeyRef = hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandler = eventHandler { RemoveEventHandler(eventHandler) }
    }
}
