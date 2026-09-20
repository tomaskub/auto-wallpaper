// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "auto-wallpaper",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "AutoWallpaperCore", targets: ["AutoWallpaperCore"]),
        .executable(name: "auto-wallpaper", targets: ["AutoWallpaperCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(name: "AutoWallpaperCore"),
        .executableTarget(
            name: "AutoWallpaperCLI",
            dependencies: [
                "AutoWallpaperCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "AutoWallpaperCoreTests", dependencies: ["AutoWallpaperCore"]),
        .testTarget(
            name: "AutoWallpaperCLITests",
            dependencies: [
                "AutoWallpaperCLI",
                "AutoWallpaperCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
