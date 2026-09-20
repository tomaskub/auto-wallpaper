import AppKit
import Foundation

public struct AppKitImageValidator: ImageValidating {
    private let fileManager: FileManager
    private let resolver: PathResolver

    public init(fileManager: FileManager = .default, resolver: PathResolver = PathResolver()) {
        self.fileManager = fileManager
        self.resolver = resolver
    }

    public func validate(path: String, mode: WallpaperMode) throws -> URL {
        let url = resolver.resolve(path)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw AutoWallpaperError.invalidPath(mode: mode, path: url.path, reason: "file does not exist")
        }
        guard !isDirectory.boolValue else {
            throw AutoWallpaperError.invalidPath(mode: mode, path: url.path, reason: "path is not a regular file")
        }
        guard fileManager.isReadableFile(atPath: url.path) else {
            throw AutoWallpaperError.invalidPath(mode: mode, path: url.path, reason: "file is not readable")
        }
        guard NSImage(contentsOf: url) != nil else {
            throw AutoWallpaperError.invalidPath(mode: mode, path: url.path, reason: "AppKit cannot decode the file as an image")
        }
        return url
    }
}
