import Foundation

public struct PathResolver: Sendable {
    private let homeDirectory: URL
    private let currentDirectory: URL

    public init(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    ) {
        self.homeDirectory = homeDirectory.standardizedFileURL
        self.currentDirectory = currentDirectory.standardizedFileURL
    }

    public func resolve(_ path: String) -> URL {
        let expanded: URL
        if path == "~" {
            expanded = homeDirectory
        } else if path.hasPrefix("~/") {
            expanded = homeDirectory.appendingPathComponent(String(path.dropFirst(2)))
        } else if path.hasPrefix("/") {
            expanded = URL(fileURLWithPath: path)
        } else {
            expanded = currentDirectory.appendingPathComponent(path)
        }
        return expanded.standardizedFileURL.resolvingSymlinksInPath()
    }
}
