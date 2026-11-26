import AppKit
import FinderSync
import os

private func monitoredFoldersChanged(
    _ center: CFNotificationCenter?,
    _ observer: UnsafeMutableRawPointer?,
    _ name: CFNotificationName?,
    _ object: UnsafeRawPointer?,
    _ userInfo: CFDictionary?
) {
    guard let observer else { return }
    let finderSync = Unmanaged<FinderSync>.fromOpaque(observer).takeUnretainedValue()
    finderSync.scheduleDirectoryReload()
}

final class FinderSync: FIFinderSync {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "CaptureTranslator.FinderExtension",
        category: "FinderSync"
    )

    override init() {
        super.init()

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            monitoredFoldersChanged,
            MonitoredFolderConfiguration.notificationName.rawValue,
            nil,
            .deliverImmediately
        )

        reloadMonitoredDirectories()
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            MonitoredFolderConfiguration.notificationName,
            nil
        )
    }

    fileprivate func scheduleDirectoryReload() {
        DispatchQueue.main.async { [weak self] in
            self?.reloadMonitoredDirectories()
        }
    }

    private func reloadMonitoredDirectories() {
        let urls = MonitoredFolderConfiguration.enabledURLs()
        FIFinderSyncController.default().directoryURLs = Set(urls)
        logger.notice("Updated monitored folders; enabled count: \(urls.count)")
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems,
              let selectedURLs = FIFinderSyncController.default().selectedItemURLs(),
              !selectedURLs.isEmpty,
              selectedURLs.allSatisfy({
                  $0.pathExtension.caseInsensitiveCompare("pdf") == .orderedSame
              }) else {
            return nil
        }

        let menu = NSMenu(title: "CaptureTranslator")
        let item = NSMenuItem(
            title: "Translate this document",
            action: #selector(translateSelectedPDFs(_:)),
            keyEquivalent: ""
        )
        item.target = self
        menu.addItem(item)
        return menu
    }

    @objc private func translateSelectedPDFs(_ sender: Any?) {
        guard let selectedURLs = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        for fileURL in selectedURLs
        where fileURL.pathExtension.caseInsensitiveCompare("pdf") == .orderedSame {
            var components = URLComponents()
            components.scheme = "capturetranslator"
            components.host = "translate-pdf"
            components.queryItems = [URLQueryItem(name: "path", value: fileURL.path)]

            if let requestURL = components.url {
                NSWorkspace.shared.open(requestURL)
            }
        }
    }
}
