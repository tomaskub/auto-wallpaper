import AppKit
import XCTest
@testable import AutoWallpaperCore

final class CoordinatorTests: XCTestCase {
    func testAppearanceMapping() {
        XCTAssertEqual(AppKitAppearanceSource.map(NSAppearance(named: .aqua)!), .light)
        XCTAssertEqual(AppKitAppearanceSource.map(NSAppearance(named: .accessibilityHighContrastAqua)!), .light)
        XCTAssertEqual(AppKitAppearanceSource.map(NSAppearance(named: .darkAqua)!), .dark)
        XCTAssertEqual(AppKitAppearanceSource.map(NSAppearance(named: .accessibilityHighContrastDarkAqua)!), .dark)
    }

    func testReloadSelectsDarkWallpaperAndUpdatesEveryDisplay() throws {
        let store = Store(configuration: .init(light: "/light", dark: "/dark"))
        let validator = Validator()
        let updater = Updater(displays: [Display(id: "1", name: "One"), Display(id: "2", name: "Two")])
        let coordinator = ReloadCoordinator(
            configurationStore: store,
            imageValidator: validator,
            appearanceSource: Appearance(.dark),
            wallpaperUpdater: updater
        )
        let result = try coordinator.reload()
        XCTAssertEqual(result.imageURL.path, "/dark")
        XCTAssertEqual(updater.attempts.map(\.id), ["1", "2"])
    }

    func testPartialFailureStillAttemptsEveryDisplayAndAggregatesFailures() throws {
        let displays = [Display(id: "1", name: "One"), Display(id: "2", name: "Two")]
        let updater = Updater(displays: displays, failingIDs: ["1"])
        let coordinator = ReloadCoordinator(
            configurationStore: Store(configuration: .init(light: "/light", dark: "/dark")),
            imageValidator: Validator(),
            appearanceSource: Appearance(.light),
            wallpaperUpdater: updater
        )
        XCTAssertThrowsError(try coordinator.reload()) { error in
            guard case .displayUpdatesFailed(let failures) = error as? AutoWallpaperError else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(failures.map(\.display.id), ["1"])
        }
        XCTAssertEqual(updater.attempts.map(\.id), ["1", "2"])
    }

    func testMissingSelectedImagePreventsAllDisplayUpdates() {
        let updater = Updater(displays: [Display(id: "1", name: "One")])
        let coordinator = ReloadCoordinator(
            configurationStore: Store(configuration: .init(light: "/missing", dark: "/dark")),
            imageValidator: Validator(invalidPaths: ["/missing"]),
            appearanceSource: Appearance(.light),
            wallpaperUpdater: updater
        )
        XCTAssertThrowsError(try coordinator.reload())
        XCTAssertTrue(updater.attempts.isEmpty)
    }
}

final class Store: ConfigurationStoring {
    let configurationURL = URL(fileURLWithPath: "/config")
    var configuration: WallpaperConfiguration
    var saveCount = 0

    init(configuration: WallpaperConfiguration) { self.configuration = configuration }
    func load() throws -> WallpaperConfiguration { configuration }
    func save(_ configuration: WallpaperConfiguration) throws { self.configuration = configuration; saveCount += 1 }
}

struct Validator: ImageValidating {
    var invalidPaths: Set<String> = []
    func validate(path: String, mode: WallpaperMode) throws -> URL {
        guard !invalidPaths.contains(path) else {
            throw AutoWallpaperError.invalidPath(mode: mode, path: path, reason: "missing")
        }
        return URL(fileURLWithPath: path)
    }
}

final class Appearance: AppearanceProviding {
    var value: SystemAppearance
    init(_ value: SystemAppearance) { self.value = value }
    func currentAppearance() -> SystemAppearance { value }
}

final class Updater: WallpaperUpdating {
    var displays: [Display]
    var failingIDs: Set<String>
    var attempts: [Display] = []

    init(displays: [Display], failingIDs: Set<String> = []) {
        self.displays = displays
        self.failingIDs = failingIDs
    }
    func connectedDisplays() -> [Display] { displays }
    func setWallpaper(_ imageURL: URL, on display: Display) throws {
        attempts.append(display)
        if failingIDs.contains(display.id) { throw CocoaError(.fileWriteUnknown) }
    }
}
