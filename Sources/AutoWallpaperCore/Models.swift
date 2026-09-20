import Foundation

public enum WallpaperMode: String, Codable, CaseIterable, Sendable {
    case light
    case dark
}

public struct WallpaperConfiguration: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public let version: Int
    public let light: String
    public let dark: String

    public init(version: Int = currentVersion, light: String, dark: String) {
        self.version = version
        self.light = light
        self.dark = dark
    }

    public func path(for appearance: SystemAppearance) -> String {
        appearance == .dark ? dark : light
    }

    public var fingerprint: ConfigurationFingerprint {
        ConfigurationFingerprint(version: version, light: light, dark: dark)
    }
}

public enum SystemAppearance: String, Codable, Sendable {
    case light
    case dark
}

public struct Display: Hashable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct ConfigurationFingerprint: Hashable, Sendable {
    public let version: Int
    public let light: String
    public let dark: String

    public init(version: Int, light: String, dark: String) {
        self.version = version
        self.light = light
        self.dark = dark
    }
}

public struct ApplicationState: Hashable, Sendable {
    public let appearance: SystemAppearance
    public let displays: Set<String>
    public let configuration: ConfigurationFingerprint

    public init(appearance: SystemAppearance, displays: Set<String>, configuration: ConfigurationFingerprint) {
        self.appearance = appearance
        self.displays = displays
        self.configuration = configuration
    }
}
