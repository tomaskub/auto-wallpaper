import Foundation

public struct Dependencies {
    public var configurationStore: any ConfigurationStoring
    public var imageValidator: any ImageValidating
    public var appearanceSource: any AppearanceProviding
    public var wallpaperUpdater: any WallpaperUpdating
    public var eventSource: any SystemEventSourcing
    public var errorReporter: any ErrorReporting

    public init(
        configurationStore: any ConfigurationStoring,
        imageValidator: any ImageValidating,
        appearanceSource: any AppearanceProviding,
        wallpaperUpdater: any WallpaperUpdating,
        eventSource: any SystemEventSourcing,
        errorReporter: any ErrorReporting
    ) {
        self.configurationStore = configurationStore
        self.imageValidator = imageValidator
        self.appearanceSource = appearanceSource
        self.wallpaperUpdater = wallpaperUpdater
        self.eventSource = eventSource
        self.errorReporter = errorReporter
    }

    public static func production() -> Dependencies {
        Dependencies(
            configurationStore: FileConfigurationStore(),
            imageValidator: AppKitImageValidator(),
            appearanceSource: AppKitAppearanceSource(),
            wallpaperUpdater: AppKitWallpaperUpdater(),
            eventSource: AppKitSystemEventSource(),
            errorReporter: StandardErrorReporter()
        )
    }
}
