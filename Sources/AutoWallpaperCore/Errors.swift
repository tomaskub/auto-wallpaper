import Foundation

public struct DisplayFailure: Equatable, Sendable {
    public let display: Display
    public let reason: String

    public init(display: Display, reason: String) {
        self.display = display
        self.reason = reason
    }
}

public enum AutoWallpaperError: Error, Equatable, LocalizedError, Sendable {
    case configurationMissing(URL)
    case configurationUnreadable(URL, String)
    case unsupportedConfigurationVersion(Int)
    case invalidPath(mode: WallpaperMode, path: String, reason: String)
    case configurationWriteFailed(URL, String)
    case noDisplays
    case displayUpdatesFailed([DisplayFailure])

    public var errorDescription: String? {
        switch self {
        case .configurationMissing(let url):
            return "No configuration found at \(url.path). Run 'auto-wallpaper configure --light <path> --dark <path>'."
        case .configurationUnreadable(let url, let reason):
            return "Could not read configuration at \(url.path): \(reason)"
        case .unsupportedConfigurationVersion(let version):
            return "Configuration version \(version) is not supported. This version supports \(WallpaperConfiguration.currentVersion)."
        case .invalidPath(let mode, let path, let reason):
            return "Invalid \(mode.rawValue) wallpaper at \(path): \(reason)"
        case .configurationWriteFailed(let url, let reason):
            return "Could not save configuration at \(url.path): \(reason)"
        case .noDisplays:
            return "No connected displays are available in the current graphical session."
        case .displayUpdatesFailed(let failures):
            let details = failures.map { "\($0.display.name) [\($0.display.id)]: \($0.reason)" }.joined(separator: "; ")
            return "Could not update \(failures.count) display(s): \(details)"
        }
    }
}
