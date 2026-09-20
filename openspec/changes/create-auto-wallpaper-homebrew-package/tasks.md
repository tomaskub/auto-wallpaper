## 1. Package foundation

- [x] 1.1 Create the SwiftPM package with macOS 15 support, an `AutoWallpaperCore` library target, an `AutoWallpaperCLI` executable target, an `auto-wallpaper` executable product, test targets, and the `swift-argument-parser` dependency
- [x] 1.2 Define configuration, appearance, display, and error models with user-facing error descriptions
- [x] 1.3 Define interfaces for configuration storage, image validation, appearance lookup, wallpaper updates, and system events
- [x] 1.4 Add a production dependency container and resolve `$HOME/.config/auto-wallpaper/config` from `FileManager.homeDirectoryForCurrentUser`
- [x] 1.5 Commit `Package.resolved` and verify it pins `swift-argument-parser` and every transitive dependency used by a release build

## 2. Wallpaper configuration

- [x] 2.1 Implement path expansion and canonicalization for absolute, relative, and tilde-prefixed wallpaper paths
- [x] 2.2 Implement AppKit image validation for readable regular files and mode-specific validation errors
- [x] 2.3 Implement versioned JSON encoding, decoding, and unsupported-version errors for `$HOME/.config/auto-wallpaper/config`
- [x] 2.4 Implement atomic configuration writes that create `$HOME/.config/auto-wallpaper` with user-only write access and preserve the last valid document after failure
- [x] 2.5 Add unit tests for home-directory resolution, path resolution, image validation failures, configuration round trips, unsupported versions, missing configuration, and failed atomic replacement

## 3. Appearance and wallpaper application

- [x] 3.1 Implement the AppKit appearance source and map Aqua variants to light or dark mode
- [x] 3.2 Implement wallpaper selection from the saved configuration and revalidate the selected image before each application
- [x] 3.3 Implement the `NSWorkspace` wallpaper adapter for every connected display with aggregated per-display failures
- [x] 3.4 Implement a one-shot reload coordinator used by configure, reload, and watcher startup
- [x] 3.5 Add unit tests for appearance mapping, wallpaper selection, multi-display success, partial failure, missing images, and attempt-all-displays behavior

## 4. Event-driven watcher

- [x] 4.1 Implement AppKit subscriptions for effective-appearance and screen-parameter changes with serialized event delivery
- [x] 4.2 Implement watcher startup reload, saved-document reload before every appearance or display event, duplicate suppression based on the last successful appearance, display set, and configuration fingerprint, and retry after failure
- [x] 4.3 Implement timestamped standard-error reporting that keeps the watcher active after recoverable errors
- [x] 4.4 Add SIGINT and SIGTERM handling that removes subscriptions and stops the run loop cleanly
- [x] 4.5 Add unit tests for startup reload, light-to-dark and dark-to-light changes, display changes, configuration changes made while watching, unchanged fingerprints, duplicate events, retry after failure, and clean shutdown

## 5. Homebrew formula and service

- [ ] 5.1 Add an `auto-wallpaper` formula for a stable tagged source archive with a SHA-256 checksum, Apple Silicon architecture requirement, macOS 15 minimum, Swift release build, and executable installation
- [ ] 5.2 Add a formula fetch phase that downloads the exact SwiftPM versions in `Package.resolved`, then build during install with automatic dependency resolution and remote updates disabled
- [ ] 5.3 Add a formula service block that runs `opt_bin/"auto-wallpaper" watch` without root privileges and keeps the watcher alive after a crash
- [ ] 5.4 Add a formula test block that checks installed command behavior without changing wallpaper, configuration, or service state
- [ ] 5.5 Run `brew style`, `brew audit --new --formula`, a clean-cache `brew fetch --build-from-source`, a network-isolated `brew install --build-from-source`, and `brew test` against the formula and fix every failure
- [ ] 5.6 Smoke-test per-user `brew services` start, list, restart, and stop behavior, including the stable executable path after an upgrade
- [ ] 5.7 Verify that stopping or uninstalling the formula does not remove `$HOME/.config/auto-wallpaper/config` or configured image files

## 6. CLI commands

- [x] 6.1 Implement the root command, shared dependency creation, help text, and consistent mapping from domain errors to terminal messages and non-zero exit codes
- [x] 6.2 Implement `configure --light <path> --dark <path>` so it validates and atomically saves the pair before applying the current wallpaper
- [x] 6.3 Implement `reload` so it re-reads and validates the saved document before applying the current wallpaper to every display
- [x] 6.4 Implement `watch` for the foreground event loop and `status` for read-only configuration paths and effective appearance
- [x] 6.5 Add command-level tests for required options, help output, configure, reload after a manual edit, unchanged reload, invalid reload, configured and unconfigured status appearance output, read-only status behavior, and failure exit codes

## 7. Documentation and verification

- [ ] 7.1 Write a README with the Apple Silicon and macOS 15 or later requirements, the current Homebrew Tier 1 support assumption, installation and upgrade steps, the configuration file format, command examples, `brew services` setup, troubleshooting, and full uninstall instructions
- [x] 7.2 Run the full Swift test suite and fix all failures
- [ ] 7.3 Build the release executable and smoke-test help, unconfigured status, invalid path handling, and formula metadata without changing the developer's wallpaper or service state
- [ ] 7.4 Review every OpenSpec scenario against automated tests or a documented manual check and record any platform-only verification steps in the README
- [ ] 7.5 Document the tagged-release and project-tap publication workflow, including formula URL and checksum updates and a check that the declared platform floor still matches Homebrew's current Tier 1 matrix
