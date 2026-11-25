import AppKit
import SwiftUI

@MainActor
final class AppController: ObservableObject {
    static let shared = AppController()

    private var translationWindows: [UUID: NSWindowController] = [:]
    private var progressWindows: [UUID: NSWindowController] = [:]

    private init() {}

    func prepareConfigurationDirectory() {
        do {
            try AppDirectories.prepare()
        } catch {
            presentError(error)
        }
    }

    func captureAndTranslate() {
        Task {
            do {
                let url = try await CaptureService.captureSelection()
                let session = try TranslationSession(imageURL: url)
                showTranslationWindow(session: session)
                session.translate()
            } catch CaptureError.cancelled {
                return
            } catch {
                presentError(error)
            }
        }
    }

    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "capturetranslator", url.host == "translate-pdf",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let path = components.queryItems?.first(where: { $0.name == "path" })?.value else {
            return
        }
        translatePDF(at: URL(fileURLWithPath: path))
    }

    func translatePDF(at url: URL) {
        let session = PDFProgressSession(sourceURL: url)
        showProgressWindow(session: session)
        Task {
            do {
                let output = try await PDFTranslationService.translate(url: url, progress: session)
                session.finish(outputURL: output)
                NSWorkspace.shared.activateFileViewerSelecting([output])
            } catch {
                session.fail(error)
            }
        }
    }

    private func showTranslationWindow(session: TranslationSession) {
        let id = session.id
        let root = TranslationView(session: session)
        let window = NSWindow(contentViewController: NSHostingController(rootView: root))
        window.title = "CaptureTranslator"
        let screen = screenUnderPointer()
        window.setContentSize(defaultWindowSize(for: screen))
        window.minSize = NSSize(width: 760, height: 480)
        window.styleMask = [.resizable, .miniaturizable, .closable, .titled]
        center(window, on: screen)
        window.isReleasedWhenClosed = false
        let controller = ClosingWindowController(window: window) { [weak self] in
            self?.translationWindows.removeValue(forKey: id)
            session.removeTemporaryCapture()
        }
        translationWindows[id] = controller
        NSApplication.shared.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
    }

    private func showProgressWindow(session: PDFProgressSession) {
        let id = session.id
        let root = PDFProgressView(session: session)
        let window = NSWindow(contentViewController: NSHostingController(rootView: root))
        window.title = "Translating PDF"
        window.setContentSize(NSSize(width: 480, height: 230))
        window.styleMask = [.titled, .closable]
        center(window, on: screenUnderPointer())
        window.isReleasedWhenClosed = false
        let controller = ClosingWindowController(window: window) { [weak self] in
            self?.progressWindows.removeValue(forKey: id)
        }
        progressWindows[id] = controller
        NSApplication.shared.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
    }

    private func defaultWindowSize(for screen: NSScreen?) -> NSSize {
        let visible = screen?.visibleFrame.size ?? NSSize(width: 1200, height: 800)
        return NSSize(width: min(visible.width * 0.84, 1500),
                      height: min(visible.height * 0.80, 980))
    }

    private func screenUnderPointer() -> NSScreen? {
        let point = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main
    }

    private func center(_ window: NSWindow, on screen: NSScreen?) {
        guard let frame = screen?.visibleFrame else {
            window.center()
            return
        }
        window.setFrameOrigin(NSPoint(
            x: frame.midX - window.frame.width / 2,
            y: frame.midY - window.frame.height / 2
        ))
    }

    private func presentError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}

private final class ClosingWindowController: NSWindowController, NSWindowDelegate {
    private let onClose: () -> Void

    init(window: NSWindow, onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) { nil }
    func windowWillClose(_ notification: Notification) { onClose() }
}
