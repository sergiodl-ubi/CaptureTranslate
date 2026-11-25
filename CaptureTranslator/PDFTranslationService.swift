import Foundation

enum PDFTranslationError: LocalizedError {
    case magickNotFound
    case conversionFailed(String)
    case noPages

    var errorDescription: String? {
        switch self {
        case .magickNotFound:
            return "ImageMagick was not found. Install it with ‘brew install imagemagick ghostscript’."
        case .conversionFailed(let output):
            return "ImageMagick could not render the PDF: \(output)"
        case .noPages:
            return "No pages were produced from the selected PDF."
        }
    }
}

enum PDFTranslationService {
    @MainActor
    static func translate(url: URL, progress: PDFProgressSession) async throws -> URL {
        try AppDirectories.prepare()
        let job = AppDirectories.jobs.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: job, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: job) }

        progress.status = "Rendering PDF pages…"
        let pages = try await renderPDF(url, into: job)
        guard !pages.isEmpty else { throw PDFTranslationError.noPages }
        progress.totalPages = pages.count

        let client = OllamaClient()
        let firstData = try Data(contentsOf: pages[0])
        let configuredSource = AppSettings.sourceLanguageCode
        let detectedCode = configuredSource == "auto"
            ? (try await client.detectLanguage(imageData: firstData))
            : configuredSource
        let source = detectedCode == "und" ? Language.automatic : Language.named(detectedCode)
        let target = Language.named(AppSettings.targetLanguageCode)

        var translatedPages: [String] = []
        for (index, page) in pages.enumerated() {
            try Task.checkCancellation()
            progress.update(page: index + 1, total: pages.count)
            let data = try Data(contentsOf: page)
            translatedPages.append(try await client.translate(imageData: data, source: source, target: target))
        }

        progress.status = "Creating translated PDF…"
        let base = url.deletingPathExtension().lastPathComponent
        let filename = "\(base).translated_\(detectedCode)_\(target.code).pdf"
        let output = url.deletingLastPathComponent().appendingPathComponent(filename)
        try TextPDFBuilder.write(pages: translatedPages, sourceName: url.lastPathComponent, to: output)
        return output
    }

    private static func renderPDF(_ source: URL, into directory: URL) async throws -> [URL] {
        guard let magick = magickExecutable() else { throw PDFTranslationError.magickNotFound }
        let outputPattern = directory.appendingPathComponent("page-%04d.png").path
        let process = Process()
        process.executableURL = magick
        process.arguments = [
            "-density", String(AppSettings.pdfDensity),
            source.path,
            "-background", "white", "-alpha", "remove", "-alpha", "off",
            outputPattern
        ]
        let diagnosticURL = directory.appendingPathComponent("magick.log")
        FileManager.default.createFile(atPath: diagnosticURL.path, contents: nil)
        let diagnosticHandle = try FileHandle(forWritingTo: diagnosticURL)
        process.standardError = diagnosticHandle
        process.standardOutput = diagnosticHandle

        let status: Int32 = try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do { try process.run() } catch { continuation.resume(throwing: error) }
        }
        try diagnosticHandle.close()
        let diagnostic = (try? String(contentsOf: diagnosticURL, encoding: .utf8)) ?? ""
        guard status == 0 else { throw PDFTranslationError.conversionFailed(diagnostic) }

        return try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "png" }
        .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    private static func magickExecutable() -> URL? {
        ["/opt/homebrew/bin/magick", "/usr/local/bin/magick", "/opt/local/bin/magick"]
            .first(where: { FileManager.default.isExecutableFile(atPath: $0) })
            .map { URL(fileURLWithPath: $0) }
    }
}
