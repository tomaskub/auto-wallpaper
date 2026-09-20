import ArgumentParser
import XCTest
import AutoWallpaperCore
@testable import AutoWallpaperCLI

final class CommandTests: XCTestCase {
    func testConfigureRequiresBothOptions() {
        XCTAssertThrowsError(try AutoWallpaper.parseAsRoot(["configure", "--light", "/light"]))
        XCTAssertThrowsError(try AutoWallpaper.parseAsRoot(["configure", "--dark", "/dark"]))
    }

    func testHelpListsEveryCommand() throws {
        let help = AutoWallpaper.helpMessage()
        for command in ["configure", "reload", "watch", "status"] {
            XCTAssertTrue(help.contains(command))
        }
    }

    func testConfigureSavesThenApplies() throws {
        let setup = makeSetup()
        try setup.service.configure(light: "/new-light", dark: "/new-dark")
        XCTAssertEqual(setup.store.configuration.light, "/new-light")
        XCTAssertEqual(setup.store.saveCount, 1)
        XCTAssertEqual(setup.updater.paths, ["/new-light"])
    }

    func testReloadUsesManualEditAndReappliesUnchangedConfiguration() throws {
        let setup = makeSetup()
        setup.store.configuration = .init(light: "/edited", dark: "/dark")
        try setup.service.reload()
        try setup.service.reload()
        XCTAssertEqual(setup.updater.paths, ["/edited", "/edited"])
    }

    func testInvalidReloadReturnsFailureWithoutUpdatingDisplays() {
        let setup = makeSetup(invalidPaths: ["/light"])
        XCTAssertThrowsError(try setup.service.reload())
        XCTAssertTrue(setup.updater.paths.isEmpty)
    }

    func testConfiguredStatusIsReadOnlyAndIncludesAppearance() throws {
        let setup = makeSetup()
        try setup.service.status()
        XCTAssertEqual(setup.store.saveCount, 0)
        XCTAssertTrue(setup.output.lines.contains("Appearance: light"))
        XCTAssertTrue(setup.output.lines.contains("Configured: yes"))
        XCTAssertTrue(setup.output.lines.contains("Light: /light"))
    }

    func testUnconfiguredStatusIsReadOnlyAndIncludesAppearance() throws {
        let setup = makeSetup(missing: true)
        try setup.service.status()
        XCTAssertEqual(setup.store.saveCount, 0)
        XCTAssertTrue(setup.output.lines.contains("Appearance: light"))
        XCTAssertTrue(setup.output.lines.contains("Configured: no"))
    }

    private func makeSetup(invalidPaths: Set<String> = [], missing: Bool = false) -> CLISetup {
        let store = CLIStore(configuration: .init(light: "/light", dark: "/dark"), missing: missing)
        let updater = CLIUpdater()
        let output = Output()
        let dependencies = Dependencies(
            configurationStore: store,
            imageValidator: CLIValidator(invalidPaths: invalidPaths),
            appearanceSource: CLIAppearance(),
            wallpaperUpdater: updater,
            eventSource: CLIEvents(),
            errorReporter: CLIReporter()
        )
        return CLISetup(store: store, updater: updater, output: output, service: CommandService(dependencies: dependencies, output: output.write))
    }
}

private struct CLISetup {
    let store: CLIStore
    let updater: CLIUpdater
    let output: Output
    let service: CommandService
}

private final class Output {
    var lines: [String] = []
    func write(_ line: String) { lines.append(line) }
}

private final class CLIStore: ConfigurationStoring {
    let configurationURL = URL(fileURLWithPath: "/config")
    var configuration: WallpaperConfiguration
    var missing: Bool
    var saveCount = 0
    init(configuration: WallpaperConfiguration, missing: Bool) { self.configuration = configuration; self.missing = missing }
    func load() throws -> WallpaperConfiguration {
        if missing { throw AutoWallpaperError.configurationMissing(configurationURL) }
        return configuration
    }
    func save(_ configuration: WallpaperConfiguration) throws { self.configuration = configuration; saveCount += 1; missing = false }
}

private struct CLIValidator: ImageValidating {
    let invalidPaths: Set<String>
    func validate(path: String, mode: WallpaperMode) throws -> URL {
        if invalidPaths.contains(path) { throw AutoWallpaperError.invalidPath(mode: mode, path: path, reason: "invalid") }
        return URL(fileURLWithPath: path)
    }
}

private struct CLIAppearance: AppearanceProviding {
    func currentAppearance() -> SystemAppearance { .light }
}

private final class CLIUpdater: WallpaperUpdating {
    var paths: [String] = []
    func connectedDisplays() -> [Display] { [Display(id: "1", name: "One")] }
    func setWallpaper(_ imageURL: URL, on display: Display) throws { paths.append(imageURL.path) }
}

private final class CLIEvents: SystemEventSourcing {
    func start(handler: @escaping @Sendable (SystemEvent) -> Void) {}
    func stop() {}
}

private final class CLIReporter: ErrorReporting {
    func report(_ error: Error) {}
}
