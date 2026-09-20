# wallpaper-configuration Specification

## Purpose
TBD — describe what this capability does and why it exists.

## Requirements

### Requirement: Configure a complete wallpaper pair
The `auto-wallpaper configure` command SHALL require a light wallpaper path and a dark wallpaper path in the same invocation. It SHALL resolve each path to a canonical absolute path before saving it.

#### Scenario: Configure valid wallpapers
- **WHEN** the user runs `auto-wallpaper configure --light <light-path> --dark <dark-path>` and both paths identify readable image files
- **THEN** the utility saves both canonical paths as one configuration and applies the wallpaper selected by the current appearance

#### Scenario: Reject a partial configuration
- **WHEN** the user omits either the light path or the dark path
- **THEN** the command exits with a usage error and does not change the saved configuration

### Requirement: Validate wallpaper files before saving
The utility SHALL accept a wallpaper only when the path identifies a readable regular file that AppKit can decode as an image. Validation failure SHALL identify the affected mode and path.

#### Scenario: Reject a missing image
- **WHEN** either configured path does not exist
- **THEN** the command exits with a non-zero status, reports the missing path, and preserves the previous configuration

#### Scenario: Reject an undecodable file
- **WHEN** either path identifies a file that AppKit cannot decode as an image
- **THEN** the command exits with a non-zero status, identifies that file as invalid, and preserves the previous configuration

### Requirement: Persist configuration atomically
The utility SHALL store the configuration as a versioned JSON document at `$HOME/.config/auto-wallpaper/config`. It SHALL resolve the current user's home directory through the operating system rather than require a `HOME` environment variable. A write failure SHALL leave the last complete document intact.

#### Scenario: Save the first configuration
- **WHEN** valid wallpapers are configured and the application-support directory does not exist
- **THEN** the utility creates the required directory and atomically writes a versioned configuration document

#### Scenario: Configuration replacement fails
- **WHEN** a new configuration cannot replace the existing document
- **THEN** the command exits with a non-zero status and the previous complete configuration remains readable

### Requirement: Inspect configuration without changing it
The `auto-wallpaper status` command SHALL report the configuration file path, whether the utility is configured, and the current effective appearance. When configured, it SHALL print the saved light and dark wallpaper paths. The command SHALL NOT modify configuration or wallpaper state.

#### Scenario: Show configured paths
- **WHEN** the user runs `auto-wallpaper status` with a valid saved configuration
- **THEN** the output includes the canonical light and dark wallpaper paths and identifies the current effective appearance as light or dark

#### Scenario: Show an unconfigured installation
- **WHEN** the user runs `auto-wallpaper status` before a configuration exists
- **THEN** the output identifies `auto-wallpaper` as unconfigured, reports the current effective appearance, and does not create a configuration file

### Requirement: Reload configuration on demand
The `auto-wallpaper reload` command SHALL read `$HOME/.config/auto-wallpaper/config` again, validate its contents, select the wallpaper for the current appearance, and apply it immediately to every connected display.

#### Scenario: Apply a manually edited configuration
- **WHEN** the user changes the saved configuration to a valid wallpaper pair and runs `auto-wallpaper reload`
- **THEN** the utility applies the newly selected wallpaper without restarting the Homebrew service

#### Scenario: Reapply an unchanged configuration
- **WHEN** the saved configuration is valid and the user runs `auto-wallpaper reload` without changing it
- **THEN** the utility applies the selected wallpaper again to every connected display

#### Scenario: Reject an invalid edited configuration
- **WHEN** the user edits the saved configuration into an invalid document and runs `auto-wallpaper reload`
- **THEN** the command exits with a non-zero status, reports the validation error, and does not change any display wallpaper

### Requirement: Detect unreadable saved configuration
Commands that need wallpaper configuration SHALL fail with an actionable error when the configuration is absent, uses an unsupported schema version, or cannot be decoded.

#### Scenario: Reload without configuration
- **WHEN** the user runs `auto-wallpaper reload` before configuring wallpapers
- **THEN** the command exits with a non-zero status and directs the user to run `auto-wallpaper configure`

#### Scenario: Read an unsupported configuration version
- **WHEN** a stored document has a schema version the installed utility does not support
- **THEN** the command exits with a non-zero status and reports the unsupported version without overwriting the document
