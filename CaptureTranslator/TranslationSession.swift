import AppKit
import Foundation

@MainActor
final class TranslationSession: ObservableObject {
    let id = UUID()
    let imageURL: URL
    let image: NSImage

    @Published var translation = ""
    @Published var targetLanguageCode: String
    @Published var isTranslating = false
    @Published var errorMessage: String?
    @Published var zoom = 1.0
    @Published var fitRequest = 0

    private var task: Task<Void, Never>?
    private var requestID = UUID()

    init(imageURL: URL) throws {
        guard let image = NSImage(contentsOf: imageURL) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.imageURL = imageURL
        self.image = image
        self.targetLanguageCode = AppSettings.targetLanguageCode
    }

    func translate() {
        task?.cancel()
        let currentID = UUID()
        requestID = currentID
        isTranslating = true
        errorMessage = nil

        task = Task {
            do {
                let data = try Data(contentsOf: imageURL)
                let source = AppSettings.sourceLanguageCode == "auto"
                    ? Language.automatic : Language.named(AppSettings.sourceLanguageCode)
                let result = try await OllamaClient().translate(
                    imageData: data,
                    source: source,
                    target: Language.named(targetLanguageCode)
                )
                guard !Task.isCancelled, requestID == currentID else { return }
                translation = result
                isTranslating = false
            } catch is CancellationError {
                return
            } catch {
                guard requestID == currentID else { return }
                errorMessage = error.localizedDescription
                isTranslating = false
            }
        }
    }

    func fitImage() { fitRequest += 1 }
    func zoomIn() { zoom = min(zoom * 1.25, 8) }
    func zoomOut() { zoom = max(zoom / 1.25, 0.05) }

    func removeTemporaryCapture() {
        task?.cancel()
        try? FileManager.default.removeItem(at: imageURL)
    }
}
