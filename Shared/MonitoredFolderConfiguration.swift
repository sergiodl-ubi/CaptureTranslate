import Darwin
import Foundation

struct MonitoredFolder: Codable, Hashable, Identifiable {
    let id: UUID
    var path: String
    var isEnabled: Bool

    init(id: UUID = UUID(), path: String, isEnabled: Bool = true) {
        self.id = id
        self.path = URL(fileURLWithPath: path, isDirectory: true)
            .standardizedFileURL.path
        self.isEnabled = isEnabled
    }

    var url: URL {
        URL(fileURLWithPath: path, isDirectory: true)
    }

    var displayName: String {
        let name = url.lastPathComponent
        return name.isEmpty ? path : name
    }
}

enum MonitoredFolderConfiguration {
    static let storageKey = "monitoredFolders.v1"

    enum ConfigurationError: LocalizedError {
        case appGroupUnavailable(String)
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .appGroupUnavailable(let identifier):
                return "The shared App Group ‘\(identifier)’ is unavailable. Check Signing & Capabilities for both targets."
            case .encodingFailed:
                return "The monitored-folder configuration could not be encoded."
            }
        }
    }

    static var appGroupIdentifier: String {
        Bundle.main.object(forInfoDictionaryKey: "CaptureTranslatorAppGroupIdentifier") as? String
            ?? "group.com.ubi-lab.CaptureTranslator"
    }

    static var notificationName: CFNotificationName {
        CFNotificationName(
            rawValue: "\(appGroupIdentifier).monitoredFoldersChanged" as CFString
        )
    }

    static func load() -> [MonitoredFolder]? {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: storageKey) else {
            return nil
        }
        return try? JSONDecoder().decode([MonitoredFolder].self, from: data)
    }

    static func save(_ folders: [MonitoredFolder]) throws {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            throw ConfigurationError.appGroupUnavailable(appGroupIdentifier)
        }
        guard let data = try? JSONEncoder().encode(folders) else {
            throw ConfigurationError.encodingFailed
        }
        defaults.set(data, forKey: storageKey)
        defaults.synchronize()
        postChangeNotification()
    }

    static func enabledURLs() -> [URL] {
        (load() ?? defaultFolders())
            .filter(\.isEnabled)
            .map(\.url)
    }

    static func defaultFolders() -> [MonitoredFolder] {
        [MonitoredFolder(path: realUserHomeDirectory()
            .appendingPathComponent("Downloads", isDirectory: true).path)]
    }

    static func realUserHomeDirectory() -> URL {
        if let passwordEntry = getpwuid(getuid()) {
            return URL(
                fileURLWithPath: String(cString: passwordEntry.pointee.pw_dir),
                isDirectory: true
            )
        }
        return URL(fileURLWithPath: "/Users/\(NSUserName())", isDirectory: true)
    }

    static func postChangeNotification() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            notificationName,
            nil,
            nil,
            true
        )
    }
}
