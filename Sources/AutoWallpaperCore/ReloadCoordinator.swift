import Foundation

public struct ReloadResult: Equatable, Sendable {
    public let configuration: WallpaperConfiguration
    public let appearance: SystemAppearance
    public let displays: [Display]
    public let imageURL: URL

    public var state: ApplicationState {
        ApplicationState(
            appearance: appearance,
            displays: Set(displays.map(\.id)),
            configuration: configuration.fingerprint
        )
    }
}

public struct ReloadCoordinator {
    private let configurationStore: any ConfigurationStoring
    private let imageValidator: any ImageValidating
    private let appearanceSource: any AppearanceProviding
    private let wallpaperUpdater: any WallpaperUpdating

    public init(
        configurationStore: any ConfigurationStoring,
        imageValidator: any ImageValidating,
        appearanceSource: any AppearanceProviding,
        wallpaperUpdater: any WallpaperUpdating
    ) {
        self.configurationStore = configurationStore
        self.imageValidator = imageValidator
        self.appearanceSource = appearanceSource
        self.wallpaperUpdater = wallpaperUpdater
    }

    @discardableResult
    public func reload() throws -> ReloadResult {
        try apply(configurationStore.load())
    }

    @discardableResult
    public func configure(lightPath: String, darkPath: String) throws -> ReloadResult {
        let light = try imageValidator.validate(path: lightPath, mode: .light)
        let dark = try imageValidator.validate(path: darkPath, mode: .dark)
        let configuration = WallpaperConfiguration(light: light.path, dark: dark.path)
        try configurationStore.save(configuration)
        return try apply(configuration, prevalidated: [.light: light, .dark: dark])
    }

    public func currentState() throws -> ReloadResult {
        let configuration = try configurationStore.load()
        let appearance = appearanceSource.currentAppearance()
        let imageURL = try imageValidator.validate(path: configuration.path(for: appearance), mode: appearance.mode)
        let displays = wallpaperUpdater.connectedDisplays()
        return ReloadResult(configuration: configuration, appearance: appearance, displays: displays, imageURL: imageURL)
    }

    public func apply(_ result: ReloadResult) throws {
        try applyWallpaper(result.imageURL, displays: result.displays)
    }

    private func apply(
        _ configuration: WallpaperConfiguration,
        prevalidated: [WallpaperMode: URL] = [:]
    ) throws -> ReloadResult {
        let appearance = appearanceSource.currentAppearance()
        let mode = appearance.mode
        let path = configuration.path(for: appearance)
        let imageURL = try prevalidated[mode] ?? imageValidator.validate(path: path, mode: mode)
        let displays = wallpaperUpdater.connectedDisplays()
        let result = ReloadResult(configuration: configuration, appearance: appearance, displays: displays, imageURL: imageURL)
        try apply(result)
        return result
    }

    private func applyWallpaper(_ imageURL: URL, displays: [Display]) throws {
        guard !displays.isEmpty else { throw AutoWallpaperError.noDisplays }
        var failures: [DisplayFailure] = []
        for display in displays {
            do {
                try wallpaperUpdater.setWallpaper(imageURL, on: display)
            } catch {
                failures.append(DisplayFailure(display: display, reason: error.localizedDescription))
            }
        }
        if !failures.isEmpty {
            throw AutoWallpaperError.displayUpdatesFailed(failures)
        }
    }
}

private extension SystemAppearance {
    var mode: WallpaperMode {
        self == .dark ? .dark : .light
    }
}
