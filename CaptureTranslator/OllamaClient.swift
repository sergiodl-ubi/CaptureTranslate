import Foundation

struct OllamaClient {
    struct Message: Codable {
        let role: String
        let content: String
        let images: [String]?
    }

    struct ChatRequest: Codable {
        let model: String
        let messages: [Message]
        let stream: Bool
        let keep_alive: String
    }

    struct ChatResponse: Codable {
        struct ResponseMessage: Codable { let content: String }
        let message: ResponseMessage
    }

    enum ClientError: LocalizedError {
        case invalidResponse
        case server(Int, String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "Ollama returned an invalid response."
            case .server(let status, let body): return "Ollama returned HTTP \(status): \(body)"
            }
        }
    }

    func translate(imageData: Data, source: Language, target: Language) async throws -> String {
        let sourceDescription = source.code == "auto"
            ? "the automatically detected source language"
            : "\(source.name) (\(source.code))"
        let prompt = """
        You are a professional translator from \(sourceDescription) to \(target.name) (\(target.code)).
        Extract and translate all readable text in the attached image. Preserve reading order, paragraphs, headings, lists, names, numbers, and the intended tone. Do not describe the image and do not add commentary. Produce only the \(target.name) translation.
        """
        return try await chat(prompt: prompt, imageData: imageData)
    }

    func detectLanguage(imageData: Data) async throws -> String {
        let result = try await chat(
            prompt: "Identify the dominant written language in this image. Reply with only its lowercase two-letter ISO 639-1 language code, such as ja, en, es, zh, or ko.",
            imageData: imageData
        )
        let candidate = result.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = try NSRegularExpression(pattern: "(?:^|[^a-z])([a-z]{2})(?:[^a-z]|$)")
        let range = NSRange(candidate.startIndex..., in: candidate)
        guard let match = pattern.firstMatch(in: candidate, range: range),
              let swiftRange = Range(match.range(at: 1), in: candidate) else { return "und" }
        return String(candidate[swiftRange])
    }

    private func chat(prompt: String, imageData: Data) async throws -> String {
        let endpoint = AppSettings.ollamaURL.appendingPathComponent("api/chat")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 600
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ChatRequest(
            model: AppSettings.model,
            messages: [Message(role: "user", content: prompt, images: [imageData.base64EncodedString()])],
            stream: false,
            keep_alive: "10m"
        ))

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 600
        configuration.timeoutIntervalForResource = 900
        let (data, response) = try await URLSession(configuration: configuration).data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.server(http.statusCode, String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        return try JSONDecoder().decode(ChatResponse.self, from: data).message.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
