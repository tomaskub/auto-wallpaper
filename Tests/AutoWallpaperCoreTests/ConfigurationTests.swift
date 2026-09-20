import AppKit
import XCTest
@testable import AutoWallpaperCore

final class ConfigurationTests: XCTestCase {
    func testDefaultConfigurationURLUsesFileManagerHomeDirectory() {
        let url = FileConfigurationStore.defaultConfigurationURL()
        XCTAssertEqual(url, FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/auto-wallpaper/config"))
    }

    func testResolvesRelativeAbsoluteAndTildePaths() throws {
        let root = try makeTemporaryDirectory()
        let home = root.appendingPathComponent("home", isDirectory: true)
        let cwd = root.appendingPathComponent("work", isDirectory: true)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: cwd, withIntermediateDirectories: true)
        let resolver = PathResolver(homeDirectory: home, currentDirectory: cwd)

        XCTAssertEqual(resolver.resolve("image.png"), cwd.appendingPathComponent("image.png"))
        XCTAssertEqual(resolver.resolve("~/image.png"), home.appendingPathComponent("image.png"))
        XCTAssertEqual(resolver.resolve("/tmp/image.png").path, "/tmp/image.png")
    }

    func testImageValidationReportsModeAndMissingCanonicalPath() throws {
        let root = try makeTemporaryDirectory()
        let validator = AppKitImageValidator(resolver: PathResolver(homeDirectory: root, currentDirectory: root))
        XCTAssertThrowsError(try validator.validate(path: "missing.png", mode: .dark)) { error in
            guard case .invalidPath(let mode, let path, let reason) = error as? AutoWallpaperError else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(mode, .dark)
            XCTAssertTrue(path.hasSuffix("missing.png"))
            XCTAssertEqual(reason, "file does not exist")
        }
    }

    func testImageValidationRejectsUndecodableFile() throws {
        let root = try makeTemporaryDirectory()
        let file = root.appendingPathComponent("text.txt")
        try Data("not an image".utf8).write(to: file)
        let validator = AppKitImageValidator(resolver: PathResolver(homeDirectory: root, currentDirectory: root))
        XCTAssertThrowsError(try validator.validate(path: file.path, mode: .light))
    }

    func testConfigurationRoundTripAndPermissions() throws {
        let root = try makeTemporaryDirectory()
        let url = root.appendingPathComponent("nested/config")
        let store = FileConfigurationStore(configurationURL: url)
        let configuration = WallpaperConfiguration(light: "/light.png", dark: "/dark.png")
        try store.save(configuration)
        XCTAssertEqual(try store.load(), configuration)
        let directoryPermissions = try FileManager.default.attributesOfItem(atPath: url.deletingLastPathComponent().path)[.posixPermissions] as? NSNumber
        let filePermissions = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? NSNumber
        XCTAssertEqual(directoryPermissions?.intValue, 0o700)
        XCTAssertEqual(filePermissions?.intValue, 0o600)
    }

    func testUnsupportedVersionDoesNotOverwriteDocument() throws {
        let root = try makeTemporaryDirectory()
        let url = root.appendingPathComponent("config")
        let data = Data(#"{"version":99,"light":"/light","dark":"/dark"}"#.utf8)
        try data.write(to: url)
        let store = FileConfigurationStore(configurationURL: url)
        XCTAssertThrowsError(try store.load()) { error in
            XCTAssertEqual(error as? AutoWallpaperError, .unsupportedConfigurationVersion(99))
        }
        XCTAssertEqual(try Data(contentsOf: url), data)
    }

    func testMissingConfigurationHasActionableError() throws {
        let url = try makeTemporaryDirectory().appendingPathComponent("config")
        XCTAssertThrowsError(try FileConfigurationStore(configurationURL: url).load()) { error in
            XCTAssertTrue(error.localizedDescription.contains("configure"))
        }
    }

    func testFailedReplacementPreservesExistingDocument() throws {
        let root = try makeTemporaryDirectory()
        let url = root.appendingPathComponent("config")
        let original = WallpaperConfiguration(light: "/old-light", dark: "/old-dark")
        try FileConfigurationStore(configurationURL: url).save(original)
        let failingStore = FileConfigurationStore(configurationURL: url) { _, _ in
            throw CocoaError(.fileWriteUnknown)
        }
        XCTAssertThrowsError(try failingStore.save(WallpaperConfiguration(light: "/new-light", dark: "/new-dark")))
        XCTAssertEqual(try FileConfigurationStore(configurationURL: url).load(), original)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
}
