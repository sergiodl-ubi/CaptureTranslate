import Foundation

enum AppSettings {
    private static let defaults = UserDefaults.standard

    static var ollamaURL: URL {
        URL(string: defaults.string(forKey: "ollamaURL") ?? "http://127.0.0.1:11434")!
    }

    static var model: String {
        defaults.string(forKey: "model") ?? "translategemma:12b"
    }

    static var targetLanguageCode: String {
        defaults.string(forKey: "targetLanguage") ?? "en"
    }

    static var sourceLanguageCode: String {
        defaults.string(forKey: "sourceLanguage") ?? "auto"
    }

    static var pdfDensity: Int {
        let value = defaults.integer(forKey: "pdfDensity")
        return value == 0 ? 160 : value
    }
}
