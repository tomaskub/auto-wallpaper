import XCTest
@testable import AutoWallpaperCore

final class WatcherTests: XCTestCase {
    func testStartupReloadAndDuplicateSuppression() {
        let setup = makeSetup()
        setup.watcher.start()
        XCTAssertEqual(setup.updater.attempts.count, 1)

        setup.events.send(.appearanceChanged)
        setup.watcher.waitForPendingEvents()
        XCTAssertEqual(setup.updater.attempts.count, 1)
    }

    func testAppearanceAndDisplayChangesCauseApplications() {
        let setup = makeSetup()
        setup.watcher.start()

        setup.appearance.value = .dark
        setup.events.send(.appearanceChanged)
        setup.watcher.waitForPendingEvents()
        XCTAssertEqual(setup.updater.imagePaths.last, "/dark")

        setup.appearance.value = .light
        setup.events.send(.appearanceChanged)
        setup.watcher.waitForPendingEvents()
        XCTAssertEqual(setup.updater.imagePaths.last, "/light")

        setup.updater.displays.append(Display(id: "2", name: "Two"))
        setup.events.send(.displaysChanged)
        setup.watcher.waitForPendingEvents()
        XCTAssertEqual(setup.updater.attempts.suffix(2).map(\.id), ["1", "2"])
    }

    func testChangedConfigurationIsReadOnNextEvent() {
        let setup = makeSetup()
        setup.watcher.start()
        setup.store.configuration = WallpaperConfiguration(light: "/new-light", dark: "/new-dark")

        setup.events.send(.appearanceChanged)
        setup.watcher.waitForPendingEvents()
        XCTAssertEqual(setup.updater.imagePaths.last, "/new-light")
    }

    func testFailureDoesNotAdvanceStateAndNextEventRetries() {
        let setup = makeSetup()
        setup.updater.failNext = true
        setup.watcher.start()
        XCTAssertNil(setup.watcher.lastSuccessfulState)
        XCTAssertEqual(setup.reporter.errors.count, 1)

        setup.events.send(.appearanceChanged)
        setup.watcher.waitForPendingEvents()
        XCTAssertNotNil(setup.watcher.lastSuccessfulState)
        XCTAssertEqual(setup.updater.attempts.count, 2)
    }

    func testStopRemovesSubscription() {
        let setup = makeSetup()
        setup.watcher.start()
        setup.watcher.stop()
        XCTAssertEqual(setup.events.stopCount, 1)
        setup.events.send(.appearanceChanged)
        setup.watcher.waitForPendingEvents()
        XCTAssertEqual(setup.updater.attempts.count, 1)
    }

    func testErrorReporterUsesTimestampAndMessage() {
        var output = ""
        let reporter = StandardErrorReporter(
            date: { Date(timeIntervalSince1970: 0) },
            stream: { output += $0 }
        )
        reporter.report(AutoWallpaperError.noDisplays)
        XCTAssertTrue(output.hasPrefix("[1970-01-01T00:00:00Z]"))
        XCTAssertTrue(output.contains("No connected displays"))
    }

    private func makeSetup() -> Setup {
        let store = Store(configuration: .init(light: "/light", dark: "/dark"))
        let appearance = Appearance(.light)
        let updater = MutableUpdater(displays: [Display(id: "1", name: "One")])
        let events = EventSource()
        let reporter = Reporter()
        let coordinator = ReloadCoordinator(
            configurationStore: store,
            imageValidator: Validator(),
            appearanceSource: appearance,
            wallpaperUpdater: updater
        )
        return Setup(
            store: store,
            appearance: appearance,
            updater: updater,
            events: events,
            reporter: reporter,
            watcher: WallpaperWatcher(
                coordinator: coordinator,
                eventSource: events,
                errorReporter: reporter
            )
        )
    }
}

private struct Setup {
    let store: Store
    let appearance: Appearance
    let updater: MutableUpdater
    let events: EventSource
    let reporter: Reporter
    let watcher: WallpaperWatcher
}

private final class MutableUpdater: WallpaperUpdating {
    var displays: [Display]
    var attempts: [Display] = []
    var imagePaths: [String] = []
    var failNext = false

    init(displays: [Display]) { self.displays = displays }
    func connectedDisplays() -> [Display] { displays }
    func setWallpaper(_ imageURL: URL, on display: Display) throws {
        attempts.append(display)
        imagePaths.append(imageURL.path)
        if failNext {
            failNext = false
            throw CocoaError(.fileWriteUnknown)
        }
    }
}

private final class EventSource: SystemEventSourcing {
    var handler: (@Sendable (SystemEvent) -> Void)?
    var stopCount = 0
    func start(handler: @escaping @Sendable (SystemEvent) -> Void) { self.handler = handler }
    func stop() { handler = nil; stopCount += 1 }
    func send(_ event: SystemEvent) { handler?(event) }
}

private final class Reporter: ErrorReporting {
    var errors: [Error] = []
    func report(_ error: Error) { errors.append(error) }
}
