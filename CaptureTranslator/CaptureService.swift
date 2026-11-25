import Foundation

enum CaptureError: LocalizedError {
    case cancelled
    case failed(Int32)

    var errorDescription: String? {
        switch self {
        case .cancelled: return "Screen capture was cancelled."
        case .failed(let status): return "screencapture exited with status \(status)."
        }
    }
}

enum CaptureService {
    static func captureSelection() async throws -> URL {
        try AppDirectories.prepare()
        let output = AppDirectories.captures
            .appendingPathComponent("capture-\(UUID().uuidString).png")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", output.path]

        let status: Int32 = try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do { try process.run() } catch { continuation.resume(throwing: error) }
        }

        let size = (try? output.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard status == 0,
              FileManager.default.fileExists(atPath: output.path),
              size > 0 else {
            try? FileManager.default.removeItem(at: output)
            if status == 0 || status == 1 { throw CaptureError.cancelled }
            throw CaptureError.failed(status)
        }
        return output
    }
}
