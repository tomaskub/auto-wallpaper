## Why

macOS can switch between light and dark appearances, but it does not provide a terminal workflow for assigning a different wallpaper to each one. `auto-wallpaper` will keep the desktop wallpaper aligned with the current appearance and ship as a Homebrew formula, without installing a graphical application.

## What Changes

- Add a macOS command-line utility named `auto-wallpaper` for configuring separate light-mode and dark-mode wallpaper files.
- Detect the current macOS appearance and apply the matching wallpaper to every connected display.
- Watch for system appearance changes, re-read the saved configuration before each event-driven update, and switch wallpapers while running in the background.
- Store the wallpaper configuration at `$HOME/.config/auto-wallpaper/config`.
- Add a `reload` command that re-reads the saved configuration and immediately applies the wallpaper for the current appearance.
- Add commands to configure wallpapers, inspect saved paths and the current effective appearance, and run the watcher in the foreground.
- Package the utility as a Homebrew formula for Apple Silicon Macs running macOS 15 or later, with locked dependencies that build without network access during Homebrew's install phase.
- Add a service definition so Homebrew can install, update, start, stop, and restart the watcher on a current Tier 1 host configuration.
- Validate image paths and report actionable terminal errors without changing a working configuration when input is invalid.

## Capabilities

### New Capabilities

- `wallpaper-configuration`: Store, inspect, reload, and validate the light-mode and dark-mode wallpaper assignments through the CLI.
- `appearance-aware-wallpaper`: Detect the active system appearance and set the corresponding wallpaper on connected macOS displays.
- `background-service`: Run the appearance watcher as a per-user service managed by Homebrew.

### Modified Capabilities

None.

## Impact

- Introduces a macOS command-line executable, an Apple Silicon Homebrew formula with a macOS 15 minimum, and their automated tests.
- Reads the system appearance, changes desktop wallpaper settings, and reacts to display and appearance changes.
- Stores per-user configuration at `$HOME/.config/auto-wallpaper/config`.
- Uses the formula's service definition to let `brew services` manage a per-user LaunchAgent.
- Requires macOS-native frameworks, a supported Swift toolchain for source builds, and a current Homebrew Tier 1 host configuration for packaged installation. No existing APIs or behavior are changed.
