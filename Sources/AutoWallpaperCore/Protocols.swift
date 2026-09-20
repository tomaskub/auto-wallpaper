import Foundation

public protocol ConfigurationStoring {
    var configurationURL: URL { get }
    func load() throws -> WallpaperConfiguration
    func save(_ configuration: WallpaperConfiguration) throws
}

public protocol ImageValidating {
    func validate(path: String, mode: WallpaperMode) throws -> URL
}

public protocol AppearanceProviding {
    func currentAppearance() -> SystemAppearance
}

public protocol WallpaperUpdating {
    func connectedDisplays() -> [Display]
    func setWallpaper(_ imageURL: URL, on display: Display) throws
}

public enum SystemEvent: Sendable {
    case appearanceChanged
    case displaysChanged
}

public protocol SystemEventSourcing: AnyObject {
    func start(handler: @escaping @Sendable (SystemEvent) -> Void)
    func stop()
}

public protocol ErrorReporting {
    func report(_ error: Error)
}
