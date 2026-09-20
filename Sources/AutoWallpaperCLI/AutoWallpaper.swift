import ArgumentParser
import AutoWallpaperCore

@main
public struct AutoWallpaper: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "auto-wallpaper",
        abstract: "Keep macOS wallpaper in sync with light and dark appearance.",
        subcommands: [Configure.self, Reload.self, Watch.self, Status.self]
    )

    public init() {}
}

public struct Configure: ParsableCommand {
    public static let configuration = CommandConfiguration(abstract: "Save a light and dark wallpaper pair, then apply the current one.")

    @Option(help: "Path to the light appearance wallpaper.")
    public var light: String

    @Option(help: "Path to the dark appearance wallpaper.")
    public var dark: String

    public init() {}

    public mutating func run() throws {
        try runCommand { try CommandService(dependencies: .production()).configure(light: light, dark: dark) }
    }
}

public struct Reload: ParsableCommand {
    public static let configuration = CommandConfiguration(abstract: "Read the saved configuration and apply the current wallpaper.")
    public init() {}

    public mutating func run() throws {
        try runCommand { try CommandService(dependencies: .production()).reload() }
    }
}

public struct Watch: ParsableCommand {
    public static let configuration = CommandConfiguration(abstract: "Watch appearance and display changes in the foreground.")
    public init() {}

    public mutating func run() throws {
        try runCommand { try CommandService(dependencies: .production()).watch() }
    }
}

public struct Status: ParsableCommand {
    public static let configuration = CommandConfiguration(abstract: "Show saved paths and the current appearance without changing anything.")
    public init() {}

    public mutating func run() throws {
        try runCommand { try CommandService(dependencies: .production()).status() }
    }
}

private func runCommand(_ body: () throws -> Void) throws {
    do {
        try body()
    } catch {
        throw ValidationError(error.localizedDescription)
    }
}

private func runCommand<T>(_ body: () throws -> T) throws {
    do {
        _ = try body()
    } catch {
        throw ValidationError(error.localizedDescription)
    }
}
