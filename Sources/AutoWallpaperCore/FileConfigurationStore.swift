import Foundation

public struct FileConfigurationStore: ConfigurationStoring {
    public let configurationURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let replace: ((URL, URL) throws -> Void)?

    public init(
        configurationURL: URL = FileConfigurationStore.defaultConfigurationURL(),
        fileManager: FileManager = .default,
        replace: ((URL, URL) throws -> Void)? = nil
    ) {
        self.configurationURL = configurationURL
        self.fileManager = fileManager
        self.replace = replace
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        self.decoder = JSONDecoder()
    }

    public static func defaultConfigurationURL(fileManager: FileManager = .default) -> URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("auto-wallpaper", isDirectory: true)
            .appendingPathComponent("config", isDirectory: false)
    }

    public func load() throws -> WallpaperConfiguration {
        guard fileManager.fileExists(atPath: configurationURL.path) else {
            throw AutoWallpaperError.configurationMissing(configurationURL)
        }
        do {
            let data = try Data(contentsOf: configurationURL)
            let version = try decoder.decode(VersionHeader.self, from: data).version
            guard version == WallpaperConfiguration.currentVersion else {
                throw AutoWallpaperError.unsupportedConfigurationVersion(version)
            }
            return try decoder.decode(WallpaperConfiguration.self, from: data)
        } catch let error as AutoWallpaperError {
            throw error
        } catch {
            throw AutoWallpaperError.configurationUnreadable(configurationURL, error.localizedDescription)
        }
    }

    public func save(_ configuration: WallpaperConfiguration) throws {
        let directory = configurationURL.deletingLastPathComponent()
        let temporaryURL = directory.appendingPathComponent(".config.\(UUID().uuidString).tmp")
        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
            let data = try encoder.encode(configuration)
            try data.write(to: temporaryURL, options: [.atomic])
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: temporaryURL.path)

            if fileManager.fileExists(atPath: configurationURL.path) {
                if let replace {
                    try replace(configurationURL, temporaryURL)
                } else {
                    _ = try fileManager.replaceItemAt(configurationURL, withItemAt: temporaryURL)
                }
            } else {
                try fileManager.moveItem(at: temporaryURL, to: configurationURL)
            }
        } catch {
            try? fileManager.removeItem(at: temporaryURL)
            throw AutoWallpaperError.configurationWriteFailed(configurationURL, error.localizedDescription)
        }
    }

    private struct VersionHeader: Decodable {
        let version: Int
    }
}
