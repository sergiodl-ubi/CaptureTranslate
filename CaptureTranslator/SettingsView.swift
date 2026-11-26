import FinderSync
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }

            FinderFoldersSettingsView()
                .tabItem { Label("Finder", systemImage: "folder") }
        }
        .frame(width: 650, height: 500)
        .padding()
    }
}

private struct GeneralSettingsView: View {
    @AppStorage("ollamaURL") private var ollamaURL = "http://127.0.0.1:11434"
    @AppStorage("model") private var model = "translategemma:12b"
    @AppStorage("targetLanguage") private var targetLanguage = "en"
    @AppStorage("sourceLanguage") private var sourceLanguage = "auto"
    @AppStorage("pdfDensity") private var pdfDensity = 160

    var body: some View {
        Form {
            Section("Ollama") {
                TextField("Server", text: $ollamaURL)
                TextField("Model", text: $model)
            }

            Section("Translation") {
                Picker("Default target language", selection: $targetLanguage) {
                    ForEach(Language.supported) { language in
                        Text(language.name).tag(language.code)
                    }
                }

                Picker("Default source language", selection: $sourceLanguage) {
                    Text(Language.automatic.name).tag(Language.automatic.code)
                    ForEach(Language.supported) { language in
                        Text(language.name).tag(language.code)
                    }
                }

                Stepper(
                    "PDF render density: \(pdfDensity) DPI",
                    value: $pdfDensity,
                    in: 100...300,
                    step: 20
                )
            }

            Section("Keyboard") {
                LabeledContent("Capture and translate") {
                    Text("⌘⌥⇧4").fontDesign(.monospaced)
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct FinderFoldersSettingsView: View {
    @StateObject private var store = MonitoredFoldersStore()
    @State private var selection = Set<UUID>()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PDF translation folders")
                .font(.headline)

            Text("CaptureTranslator adds “Translate this document” to PDFs inside enabled folders and their subfolders.")
                .font(.callout)
                .foregroundStyle(.secondary)

            List(selection: $selection) {
                ForEach(store.folders) { folder in
                    HStack(spacing: 10) {
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { folder.isEnabled },
                                set: { store.setEnabled($0, for: folder.id) }
                            )
                        )
                        .labelsHidden()

                        Image(systemName: "folder")
                            .foregroundStyle(store.folderExists(folder) ? .secondary : .red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(folder.displayName)
                            Text(folder.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        Spacer()

                        if !store.folderExists(folder) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .help("This folder cannot currently be found.")
                        }
                    }
                    .tag(folder.id)
                }
            }
            .frame(minHeight: 245)

            HStack(spacing: 4) {
                Button(action: store.chooseAndAddFolders) {
                    Image(systemName: "plus")
                }
                .help("Add folders")

                Button {
                    store.removeFolders(ids: selection)
                    selection.removeAll()
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(selection.isEmpty)
                .help("Remove selected folders")

                Spacer()

                Button("Manage Finder Extension…") {
                    FIFinderSyncController.showExtensionManagementInterface()
                }
            }
            .buttonStyle(.bordered)

            if let error = store.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            } else {
                let enabled = FIFinderSyncController.extensionEnabled
                Label(
                    enabled ? "Finder extension enabled" : "Finder extension disabled",
                    systemImage: enabled ? "checkmark.circle.fill" : "exclamationmark.circle"
                )
                .font(.caption)
                .foregroundStyle(enabled ? Color.green : Color.secondary)
            }
        }
    }
}
