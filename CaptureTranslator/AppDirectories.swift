import Foundation

enum AppDirectories {
    static var root: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".capturetranslator", isDirectory: true)
    }

    static var captures: URL { root.appendingPathComponent("captures", isDirectory: true) }
    static var jobs: URL { root.appendingPathComponent("jobs", isDirectory: true) }

    static func prepare() throws {
        try FileManager.default.createDirectory(at: captures, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: jobs, withIntermediateDirectories: true)
    }
}
