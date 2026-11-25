import Foundation

@MainActor
final class PDFProgressSession: ObservableObject {
    enum State { case working, finished(URL), failed(String) }

    let id = UUID()
    let sourceURL: URL
    @Published var completedPages = 0
    @Published var totalPages = 0
    @Published var status = "Preparing document…"
    @Published var state: State = .working

    init(sourceURL: URL) { self.sourceURL = sourceURL }

    func update(page: Int, total: Int) {
        completedPages = page
        totalPages = total
        status = "Translating page \(page) of \(total)…"
    }

    func finish(outputURL: URL) {
        status = "Translation finished"
        state = .finished(outputURL)
    }

    func fail(_ error: Error) {
        status = "Translation failed"
        state = .failed(error.localizedDescription)
    }
}
