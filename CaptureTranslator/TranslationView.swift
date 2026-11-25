import SwiftUI

struct TranslationView: View {
    @ObservedObject var session: TranslationSession

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                ZoomableImageView(
                    image: session.image,
                    zoom: $session.zoom,
                    fitRequest: session.fitRequest
                )
                .frame(minWidth: 360, minHeight: 300)

                HStack {
                    Button(action: session.zoomOut) { Image(systemName: "minus.magnifyingglass") }
                    Text("\(Int(session.zoom * 100))%")
                        .monospacedDigit()
                        .frame(minWidth: 54)
                    Button(action: session.zoomIn) { Image(systemName: "plus.magnifyingglass") }
                    Button(action: session.fitImage) { Image(systemName: "house") }
                        .help("Fit image to the available space")
                    Spacer()
                    Text("⌘ + scroll to zoom")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .padding(10)
                .background(.bar)
            }

            VStack(spacing: 0) {
                HStack {
                    Picker("Translate to", selection: $session.targetLanguageCode) {
                        ForEach(Language.supported) { language in
                            Text(language.name).tag(language.code)
                        }
                    }
                    .onChange(of: session.targetLanguageCode) { _, _ in session.translate() }

                    Spacer()

                    if session.isTranslating {
                        ProgressView().controlSize(.small)
                        Text("Translating…").foregroundStyle(.secondary)
                    }
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(session.translation, forType: .string)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .disabled(session.translation.isEmpty)
                }
                .padding(10)
                .background(.bar)

                if let error = session.errorMessage {
                    ContentUnavailableView {
                        Label("Translation failed", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry", action: session.translate)
                    }
                } else {
                    TextEditor(text: $session.translation)
                        .font(.body)
                        .padding(8)
                        .overlay(alignment: .topLeading) {
                            if session.translation.isEmpty && session.isTranslating {
                                Text("The translation will appear here.")
                                    .foregroundStyle(.tertiary)
                                    .padding(14)
                            }
                        }
                }
            }
            .frame(minWidth: 360)
        }
        .onAppear { session.fitImage() }
    }
}
