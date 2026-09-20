import AppKit
import Foundation

public struct AppKitAppearanceSource: AppearanceProviding {
    public init() {}

    public func currentAppearance() -> SystemAppearance {
        Self.map(NSApplication.shared.effectiveAppearance)
    }

    public static func map(_ appearance: NSAppearance) -> SystemAppearance {
        let match = appearance.bestMatch(from: [
            .aqua,
            .darkAqua,
            .accessibilityHighContrastAqua,
            .accessibilityHighContrastDarkAqua,
        ])
        switch match {
        case .darkAqua, .accessibilityHighContrastDarkAqua:
            return .dark
        default:
            return .light
        }
    }
}

public final class AppKitWallpaperUpdater: WallpaperUpdating {
    public init() {}

    public func connectedDisplays() -> [Display] {
        NSScreen.screens.map(Self.display)
    }

    public func setWallpaper(_ imageURL: URL, on display: Display) throws {
        guard let screen = NSScreen.screens.first(where: { Self.display($0).id == display.id }) else {
            throw NSError(
                domain: "AutoWallpaper",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "display disconnected before the wallpaper update"]
            )
        }
        try NSWorkspace.shared.setDesktopImageURL(imageURL, for: screen, options: [:])
    }

    private static func display(_ screen: NSScreen) -> Display {
        let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        return Display(id: number?.stringValue ?? screen.localizedName, name: screen.localizedName)
    }
}

public final class AppKitSystemEventSource: NSObject, SystemEventSourcing, @unchecked Sendable {
    private var appearanceObservation: NSKeyValueObservation?
    private var screenObserver: NSObjectProtocol?
    private var handler: (@Sendable (SystemEvent) -> Void)?

    public override init() {
        super.init()
    }

    public func start(handler: @escaping @Sendable (SystemEvent) -> Void) {
        stop()
        self.handler = handler
        appearanceObservation = NSApplication.shared.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            self?.handler?(.appearanceChanged)
        }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared,
            queue: .main
        ) { [weak self] _ in
            self?.handler?(.displaysChanged)
        }
    }

    public func stop() {
        appearanceObservation?.invalidate()
        appearanceObservation = nil
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
        screenObserver = nil
        handler = nil
    }

    deinit {
        stop()
    }
}
