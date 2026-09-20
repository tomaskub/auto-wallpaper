## Context

The repository contains OpenSpec configuration but no implementation. This change establishes the first executable, its Swift package structure, and its Homebrew formula. The utility must run inside a signed-in macOS graphical session because appearance detection and wallpaper updates depend on AppKit. It has two execution modes: short-lived CLI commands and a long-running watcher that Homebrew runs as a per-user service. The initial supported package target is Apple Silicon on macOS 15 or later, matching the platform portion of Homebrew's September 2026 Tier 1 matrix.

## Goals / Non-Goals

**Goals:**

- Provide a predictable CLI for configuring and applying a light and dark wallpaper pair.
- React to appearance and connected-display changes without a visible application.
- Use macOS-native APIs for appearance detection, wallpaper updates, and background service management.
- Install, update, and manage the background process through Homebrew.
- Keep configuration in `$HOME/.config/auto-wallpaper/config` and let the user reload it on demand.
- Keep platform-dependent behavior behind protocols so unit tests can use deterministic fakes.
- Preserve the last valid configuration when a command fails.
- Keep a running watcher synchronized with configuration changes without requiring a service restart.
- Build the Homebrew formula from a locked dependency graph without network access during the install phase.

**Non-Goals:**

- A menu bar item, settings window, Dock icon, or other graphical interface.
- Wallpaper scheduling based on time, sunrise, location, or custom themes.
- Downloading, resizing, converting, or copying image files.
- Managing wallpaper independently for each display or macOS Space.
- A system-wide daemon or configuration shared between user accounts.
- A macOS application bundle, Mac App Store release, or standalone installer.
- Automatic submission to `homebrew/core`. The first release will use a project-owned tap.
- Intel Macs and macOS releases older than 15 in the initial supported installation matrix.

## Decisions

### Build a native Swift command-line package

Use Swift Package Manager with an `AutoWallpaperCore` library target, an `AutoWallpaperCLI` executable target, an `auto-wallpaper` executable product, and corresponding test targets. Set macOS 15 as the minimum supported release. `AutoWallpaperCore` will own configuration, appearance mapping, wallpaper application, and watching. `AutoWallpaperCLI` will parse commands and render terminal output.

Use Apple's `swift-argument-parser` package for subcommands, help text, validation errors, and exit codes. A handwritten parser would remove one dependency, but it would add repetitive parsing and help-generation code to every command.

### Keep the CLI contract small

Expose these commands:

- `auto-wallpaper configure --light <path> --dark <path>` validates and saves both paths, then applies the wallpaper for the current appearance.
- `auto-wallpaper reload` re-reads the saved file, validates both paths, and immediately applies the wallpaper for the current appearance.
- `auto-wallpaper status` reports the configuration path, configured wallpaper paths, and current appearance without changing them.
- `auto-wallpaper watch` runs the foreground event loop used by the Homebrew service and is also useful for diagnostics.

Requiring both paths on `configure` prevents partial configurations. Separate `set-light` and `set-dark` commands would create an incomplete configuration that cannot switch wallpapers. The `reload` command uses the same one-shot read, validate, select, and apply path as watcher startup. It is intended for changes made directly to the configuration file. Because `reload` runs in a separate process, the watcher will also re-read the saved document before every appearance or display event. This keeps later event-driven updates on the latest saved paths without requiring a service restart.

### Store file references in one atomic JSON document

Store a JSON document at `$HOME/.config/auto-wallpaper/config`. Resolve the home directory with `FileManager.homeDirectoryForCurrentUser` instead of trusting a mutable `HOME` environment variable. The document contains a schema version and canonical absolute paths for the light and dark images. Resolve relative paths against the caller's current directory, verify that both files are readable regular files, and ask AppKit to decode them before committing the document. Write to a sibling temporary file and atomically replace the destination.

The utility will reference the user's image files rather than copy them. Moving or deleting an image will invalidate that path. Each configure, reload, watcher startup, and event-driven update will validate the selected file and return a path-specific error.

### Isolate macOS integration behind interfaces

Define interfaces for the configuration store, appearance source, wallpaper setter, and event source. Production adapters will use `UserDefaults` and `NSApplication.effectiveAppearance` to map Aqua and high-contrast Aqua variants to light or dark, `NSWorkspace.setDesktopImageURL` for each entry in `NSScreen.screens`, and AppKit notifications for appearance and screen-parameter changes.

Tests will inject fakes for each interface. This avoids changing the developer's real wallpaper during unit tests and makes failure cases repeatable.

### Use an event-driven watcher with duplicate suppression

`auto-wallpaper watch` will reload once at startup, subscribe to system appearance and display-configuration notifications, and keep the main run loop alive. Before handling each notification, it will re-read and validate the saved document, then calculate its configuration fingerprint. It will serialize events and remember the last successfully applied appearance, connected-display set, and configuration fingerprint. Repeated notifications with no change to those values will not rewrite wallpaper settings. A changed fingerprint forces an application even when appearance and displays are unchanged.

If an event cannot be applied, the watcher will write a timestamped error to standard error and continue listening. A later event can recover after the user restores an image or fixes the configuration.

### Publish a Homebrew formula with a service definition

Publish `auto-wallpaper` from a project-owned Homebrew tap. The formula will use a stable tagged source archive with a SHA-256 checksum, require Apple Silicon and macOS 15 or later, build the release executable with Swift Package Manager, and install it into the formula's `bin` directory. The package will commit `Package.resolved` so every release pins `swift-argument-parser` and its transitive dependencies.

Homebrew disables network access during the install phase. The formula will use Homebrew's network-enabled fetch phase to resolve and download the versions locked in `Package.resolved`. The install phase will build from those fetched checkouts with automatic dependency resolution and remote updates disabled. A clean-cache source-build test will verify that the formula does not rely on the developer's SwiftPM cache. The formula's test block will run commands that do not modify wallpaper, configuration, or service state.

The formula's `service do` block will run `opt_bin/"auto-wallpaper" watch` as a per-user service and keep it alive after a crash. Users will manage it with `brew services start auto-wallpaper`, `brew services stop auto-wallpaper`, and `brew services restart auto-wallpaper`. They can inspect it with `brew services list`. The utility will not create property lists or call `launchctl` itself.

The service definition will use Homebrew's stable `opt_bin` path so upgrades do not leave a versioned Cellar path in the generated LaunchAgent. Running the service without `sudo` keeps it in the signed-in user's graphical domain, which AppKit requires.

## Risks / Trade-offs

- [AppKit behavior can vary across macOS releases and Spaces] -> Support a stated minimum macOS version, use public APIs, test on supported releases, and promise updates only for currently connected displays.
- [The configured file can move or become unreadable] -> Validate on every reload or event-driven update, name the failing path, retain the saved configuration, and keep the watcher alive.
- [Appearance notifications may be duplicated or coalesced] -> Read current state after every event and suppress only updates whose appearance, display set, and configuration fingerprint match the last successful application.
- [A Homebrew service started with `sudo` would run outside the intended user session] -> Document and test only the per-user `brew services` workflow.
- [A formula release can point to mutable or unverifiable source] -> Require tagged archives, SHA-256 checksums, `brew audit`, and a source-build installation test before release.
- [SwiftPM tries to download dependencies during Homebrew's network-isolated install phase] -> Commit `Package.resolved`, fetch the locked dependencies in Homebrew's fetch phase, disable automatic resolution during install, and test from a clean cache.
- [Updating several displays can partially fail] -> Attempt every connected display, report each failure, and return failure unless all displays were updated.
- [The configuration path does not follow macOS Application Support conventions] -> Use the requested stable path and create its parent directory with user-only write access.
- [Homebrew changes its Tier 1 operating-system matrix over time] -> Verify the current matrix before each release and raise the formula's platform floor when a supported release would otherwise fall outside Tier 1.

## Migration Plan

This is a new package, so there is no data migration. Implementation will first ship the foreground commands, then add the Apple Silicon, macOS 15 or later Homebrew formula and service definition. Users can stop background operation with `brew services stop auto-wallpaper`. `brew uninstall auto-wallpaper` removes the installed package but leaves `$HOME/.config/auto-wallpaper/config` and the selected image files untouched. Removing `$HOME/.config/auto-wallpaper` completes a manual cleanup.

## Open Questions

The Homebrew tap owner and repository name must be chosen before the first formula release. This does not affect the formula name or CLI contract.
