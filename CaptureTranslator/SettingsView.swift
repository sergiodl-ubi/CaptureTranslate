import SwiftUI

struct SettingsView: View {
    @AppStorage("ollamaURL") private var ollamaURL = "http://127.0.0.1:11434"
    @AppStorage("model") private var model = "translategemma:12b"
    @AppStorage("targetLanguage") private var targetLanguage = "en"
    @AppStorage("sourceLanguage") private var sourceLanguage = "auto"
    @AppStorage("pdfDensity") private var pdfDensity = 160

    var body: some View {
        Form {
            TextField("Ollama server", text: $ollamaURL)
            TextField("Model", text: $model)

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

            Stepper("PDF render density: \(pdfDensity) DPI", value: $pdfDensity, in: 100...300, step: 20)

            LabeledContent("Capture shortcut") {
                Text("⌘⌥⇧4").fontDesign(.monospaced)
            }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .padding()
    }
}
