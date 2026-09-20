# appearance-aware-wallpaper Specification

## Purpose
TBD — describe what this capability does and why it exists.

## Requirements

### Requirement: Map the system appearance to a wallpaper mode
The utility SHALL classify the current effective macOS appearance as light or dark. Aqua and high-contrast Aqua appearances SHALL map to light, while Dark Aqua and high-contrast Dark Aqua appearances SHALL map to dark.

#### Scenario: Apply in light mode
- **WHEN** the effective system appearance is a light appearance
- **THEN** the utility selects the configured light wallpaper

#### Scenario: Apply in dark mode
- **WHEN** the effective system appearance is a dark appearance
- **THEN** the utility selects the configured dark wallpaper

### Requirement: Apply the selected wallpaper to connected displays
The `auto-wallpaper reload` command SHALL re-read the saved configuration and set the selected image as the desktop wallpaper on every display visible to the current graphical session. It SHALL attempt all displays even when one display update fails.

#### Scenario: Apply to multiple displays
- **WHEN** two or more displays are connected and every wallpaper update succeeds
- **THEN** the selected wallpaper is set on each connected display and the command exits successfully

#### Scenario: Report a partial display failure
- **WHEN** wallpaper application fails for one display and succeeds for another
- **THEN** the command reports the failed display, attempts the remaining displays, and exits with a non-zero status

### Requirement: React to appearance changes
The `auto-wallpaper watch` command SHALL listen for system appearance changes within the current graphical session and apply the wallpaper for the newly effective appearance.

#### Scenario: Switch from light to dark
- **WHEN** the watcher is running and the effective appearance changes from light to dark
- **THEN** the watcher applies the configured dark wallpaper to every connected display

#### Scenario: Switch from dark to light
- **WHEN** the watcher is running and the effective appearance changes from dark to light
- **THEN** the watcher applies the configured light wallpaper to every connected display

### Requirement: React to connected-display changes
The watcher SHALL re-evaluate connected displays when macOS reports a screen-parameter change and SHALL apply the wallpaper selected by the current appearance to displays that need it.

#### Scenario: Connect a display while watching
- **WHEN** a display becomes available while the watcher is running
- **THEN** the watcher applies the wallpaper for the current appearance to the resulting connected-display set

### Requirement: Avoid redundant wallpaper updates
The watcher SHALL serialize events and SHALL skip an update only when the effective appearance, connected-display set, and saved-configuration fingerprint match the last successful application. It SHALL re-read the saved configuration before making this decision for each appearance or display event.

#### Scenario: Receive a duplicate notification
- **WHEN** the watcher receives another notification without an appearance, display-set, or saved-configuration change
- **THEN** it does not call the wallpaper API again

#### Scenario: Use a changed configuration on the next event
- **WHEN** the saved configuration changes while the watcher is running and another appearance or display event arrives
- **THEN** the watcher reads the changed configuration and applies its selected wallpaper even if the appearance and display set are unchanged

#### Scenario: Retry after a failed application
- **WHEN** the prior application failed and another relevant notification arrives
- **THEN** the watcher attempts the application again even if the appearance is unchanged

### Requirement: Remain available after recoverable errors
The watcher SHALL report configuration and wallpaper application failures to standard error and SHALL continue listening for later events.

#### Scenario: Configured image is temporarily unavailable
- **WHEN** a selected wallpaper file is unavailable during an appearance event
- **THEN** the watcher reports the failing path and remains running so a later event can succeed
