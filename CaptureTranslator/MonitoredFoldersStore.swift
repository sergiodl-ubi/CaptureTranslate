import AppKit
import Combine
import Foundation

@MainActor
final class MonitoredFoldersStore: ObservableObject {
    @Published private(set) var folders: [MonitoredFolder]
    @Published var errorMessage: String?

    init() {
        if let saved = MonitoredFolderConfiguration.load() {
            folders = saved
        } else {
            folders = MonitoredFolderConfiguration.defaultFolders()
            persist()
        }
    }

    func chooseAndAddFolders() {
        let panel = NSOpenPanel()
        panel.title = "Choose folders containing PDFs"
        panel.prompt = "Add Folders"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false
        panel.resolvesAliases = true

        panel.begin { [weak self] response in
            guard response == .OK else { return }
            Task { @MainActor in
                self?.addFolders(panel.urls)
            }
        }
    }

    func addFolders(_ urls: [URL]) {
        var updated = folders
        let existing = Set(updated.map { $0.url.standardizedFileURL.path })

        for url in urls {
            let path = url.standardizedFileURL.path
            guard !existing.contains(path),
                  !updated.contains(where: { $0.url.standardizedFileURL.path == path }) else {
                continue
            }
            updated.append(MonitoredFolder(path: path))
        }

        updated.sort { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
        folders = updated
        persist()
    }

    func setEnabled(_ enabled: Bool, for id: UUID) {
        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[index].isEnabled = enabled
        persist()
    }

    func removeFolders(ids: Set<UUID>) {
        folders.removeAll { ids.contains($0.id) }
        persist()
    }

    func folderExists(_ folder: MonitoredFolder) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory)
            && isDirectory.boolValue
    }

    private func persist() {
        do {
            try MonitoredFolderConfiguration.save(folders)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
