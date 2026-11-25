import Foundation

struct Language: Identifiable, Hashable {
    let code: String
    let name: String
    var id: String { code }

    static let automatic = Language(code: "auto", name: "Detect automatically")
    static let supported: [Language] = [
        Language(code: "en", name: "English"),
        Language(code: "es", name: "Spanish"),
        Language(code: "ja", name: "Japanese"),
        Language(code: "fr", name: "French"),
        Language(code: "de", name: "German"),
        Language(code: "zh", name: "Chinese"),
        Language(code: "ko", name: "Korean"),
        Language(code: "pt", name: "Portuguese"),
        Language(code: "it", name: "Italian")
    ]

    static func named(_ code: String) -> Language {
        supported.first(where: { $0.code == code }) ?? Language(code: code, name: code.uppercased())
    }
}
