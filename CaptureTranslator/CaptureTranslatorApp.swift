import SwiftUI

@main
struct CaptureTranslatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = AppController.shared

    var body: some Scene {
        MenuBarExtra("CaptureTranslator", systemImage: "character.bubble") {
            Button("Capture and Translate") {
                controller.captureAndTranslate()
            }
            .keyboardShortcut("4", modifiers: [.command, .option, .shift])

            Divider()

            SettingsLink {
                Label("Settings…", systemImage: "gear")
            }

            Button("Quit CaptureTranslator") {
                NSApplication.shared.terminate(nil)
            }
        }

        Settings {
            SettingsView()
        }
    }
}
