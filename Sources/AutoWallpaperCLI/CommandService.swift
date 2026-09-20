import AutoWallpaperCore
import CoreFoundation
import Foundation

public final class CommandService {
    private let dependencies: Dependencies
    private let output: (String) -> Void

    public init(dependencies: Dependencies, output: @escaping (String) -> Void = { print($0) }) {
        self.dependencies = dependencies
        self.output = output
    }

    @discardableResult
    public func configure(light: String, dark: String) throws -> ReloadResult {
        let result = try coordinator.configure(lightPath: light, darkPath: dark)
        output("Saved configuration to \(dependencies.configurationStore.configurationURL.path)")
        output("Applied \(result.appearance.rawValue) wallpaper to \(result.displays.count) display(s).")
        return result
    }

    @discardableResult
    public func reload() throws -> ReloadResult {
        let result = try coordinator.reload()
        output("Applied \(result.appearance.rawValue) wallpaper to \(result.displays.count) display(s).")
        return result
    }

    public func status() throws {
        output("Configuration: \(dependencies.configurationStore.configurationURL.path)")
        output("Appearance: \(dependencies.appearanceSource.currentAppearance().rawValue)")
        do {
            let configuration = try dependencies.configurationStore.load()
            output("Configured: yes")
            output("Light: \(configuration.light)")
            output("Dark: \(configuration.dark)")
        } catch AutoWallpaperError.configurationMissing {
            output("Configured: no")
        }
    }

    public func watch() throws {
        let watcher = WallpaperWatcher(
            coordinator: coordinator,
            eventSource: dependencies.eventSource,
            errorReporter: dependencies.errorReporter
        )
        let signals = SignalController()
        signals.install {
            watcher.stop()
            CFRunLoopStop(CFRunLoopGetMain())
        }
        watcher.start()
        RunLoop.main.run()
        signals.cancel()
    }

    private var coordinator: ReloadCoordinator {
        ReloadCoordinator(
            configurationStore: dependencies.configurationStore,
            imageValidator: dependencies.imageValidator,
            appearanceSource: dependencies.appearanceSource,
            wallpaperUpdater: dependencies.wallpaperUpdater
        )
    }
}
