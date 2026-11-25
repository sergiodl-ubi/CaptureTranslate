import AppKit
import FinderSync

final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        // Finder Sync only receives menu callbacks inside observed directories.
        FIFinderSyncController.default().directoryURLs = [FileManager.default.homeDirectoryForCurrentUser]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems,
              let urls = FIFinderSyncController.default().selectedItemURLs(),
              !urls.isEmpty,
              urls.allSatisfy({ $0.pathExtension.lowercased() == "pdf" }) else {
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
        guard let urls = FIFinderSyncController.default().selectedItemURLs() else { return }
        for fileURL in urls where fileURL.pathExtension.lowercased() == "pdf" {
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
