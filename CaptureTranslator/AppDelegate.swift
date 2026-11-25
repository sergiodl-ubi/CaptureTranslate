import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKey: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        installGlobalHotKey()
        AppController.shared.prepareConfigurationDirectory()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let hotKeyHandler { RemoveEventHandler(hotKeyHandler) }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            AppController.shared.handleIncomingURL(url)
        }
    }

    private func installGlobalHotKey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                var identifier = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &identifier
                )
                guard status == noErr, identifier.id == 1 else { return status }
                let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in delegate.performCapture() }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &hotKeyHandler
        )

        var identifier = EventHotKeyID(signature: fourCharCode("CTRN"), id: 1)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_4),
            UInt32(cmdKey | optionKey | shiftKey),
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
    }

    @MainActor
    private func performCapture() {
        AppController.shared.captureAndTranslate()
    }
}

private func fourCharCode(_ value: String) -> OSType {
    value.utf8.reduce(0) { ($0 << 8) + OSType($1) }
}
