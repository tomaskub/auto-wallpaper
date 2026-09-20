import Darwin
import Foundation

public final class WallpaperWatcher: @unchecked Sendable {
    private let coordinator: ReloadCoordinator
    private let eventSource: any SystemEventSourcing
    private let errorReporter: any ErrorReporting
    private let queue: DispatchQueue
    private let lock = NSLock()
    private var _lastSuccessfulState: ApplicationState?
    private var started = false

    public var lastSuccessfulState: ApplicationState? {
        lock.withLock { _lastSuccessfulState }
    }

    public init(
        coordinator: ReloadCoordinator,
        eventSource: any SystemEventSourcing,
        errorReporter: any ErrorReporting,
        queue: DispatchQueue = DispatchQueue(label: "auto-wallpaper.events")
    ) {
        self.coordinator = coordinator
        self.eventSource = eventSource
        self.errorReporter = errorReporter
        self.queue = queue
    }

    public func start() {
        guard !started else { return }
        started = true
        processStartup()
        eventSource.start { [weak self] _ in
            self?.queue.async { self?.processEvent() }
        }
    }

    public func stop() {
        eventSource.stop()
        started = false
    }

    public func waitForPendingEvents() {
        queue.sync {}
    }

    private func processStartup() {
        do {
            let result = try coordinator.reload()
            setLastSuccessfulState(result.state)
        } catch {
            errorReporter.report(error)
        }
    }

    private func processEvent() {
        do {
            let result = try coordinator.currentState()
            guard result.state != lastSuccessfulState else { return }
            try coordinator.apply(result)
            setLastSuccessfulState(result.state)
        } catch {
            errorReporter.report(error)
        }
    }

    private func setLastSuccessfulState(_ state: ApplicationState) {
        lock.withLock { _lastSuccessfulState = state }
    }
}

public final class StandardErrorReporter: ErrorReporting {
    private let date: () -> Date
    private let stream: (String) -> Void

    public init(
        date: @escaping () -> Date = Date.init,
        stream: @escaping (String) -> Void = { message in
            FileHandle.standardError.write(Data(message.utf8))
        }
    ) {
        self.date = date
        self.stream = stream
    }

    public func report(_ error: Error) {
        stream("[\(ISO8601DateFormatter().string(from: date()))] \(error.localizedDescription)\n")
    }
}

public final class SignalController {
    private var sources: [DispatchSourceSignal] = []

    public init() {}

    public func install(handler: @escaping () -> Void) {
        for signalNumber in [SIGINT, SIGTERM] {
            Darwin.signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler(handler: handler)
            source.resume()
            sources.append(source)
        }
    }

    public func cancel() {
        sources.forEach { $0.cancel() }
        sources.removeAll()
    }

    deinit {
        cancel()
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
