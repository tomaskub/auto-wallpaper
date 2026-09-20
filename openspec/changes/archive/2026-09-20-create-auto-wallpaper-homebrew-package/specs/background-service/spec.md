## ADDED Requirements

### Requirement: Run the watcher in the foreground
The `auto-wallpaper watch` command SHALL load the current configuration at startup, re-read it before handling each appearance or display event, subscribe to those events, and remain active until it receives a termination signal.

#### Scenario: Start a foreground watcher
- **WHEN** the user runs `auto-wallpaper watch` with a valid configuration in a graphical session
- **THEN** the utility applies the current wallpaper and waits for appearance or display events

#### Scenario: Stop a foreground watcher
- **WHEN** the running watcher receives `SIGINT` or `SIGTERM`
- **THEN** it removes its event subscriptions and exits cleanly

#### Scenario: Continue with configuration changed by another process
- **WHEN** a successful `configure` or `reload` command changes the saved configuration while the watcher is running
- **THEN** the watcher uses the changed configuration when it handles the next appearance or display event without requiring a restart

### Requirement: Install as a Homebrew formula
The project SHALL publish an `auto-wallpaper` Homebrew formula that builds the tagged Swift package from its locked dependencies, installs the `auto-wallpaper` executable, and requires Apple Silicon with macOS 15 or later. The formula SHALL fetch dependencies before Homebrew's network-isolated install phase and SHALL build without remote dependency access during that phase.

#### Scenario: Install from the project tap
- **WHEN** the user installs the formula from the project-owned tap on an Apple Silicon Mac running macOS 15 or later in a current Tier 1 Homebrew host configuration
- **THEN** Homebrew builds and links the `auto-wallpaper` executable so it is available on the user's command path

#### Scenario: Reject an unsupported platform
- **WHEN** the user attempts to install the formula on an Intel Mac, a non-macOS operating system, or a macOS release older than 15
- **THEN** Homebrew rejects the installation with a platform requirement error

#### Scenario: Build without install-phase network access
- **WHEN** Homebrew fetches the locked dependencies and then runs a clean source build with network access disabled for the install phase
- **THEN** Swift Package Manager uses only the versions in `Package.resolved` and the fetched checkouts

### Requirement: Provide a Homebrew-managed user service
The formula SHALL define a Homebrew service that runs `auto-wallpaper watch` through the formula's stable `opt_bin` path. The service SHALL run in the current user's graphical session and SHALL NOT require root privileges.

#### Scenario: Start the watcher with Homebrew
- **WHEN** the formula is installed and the user runs `brew services start auto-wallpaper`
- **THEN** Homebrew starts the watcher as a per-user service and reports it as running

#### Scenario: Stop the watcher with Homebrew
- **WHEN** the service is running and the user runs `brew services stop auto-wallpaper`
- **THEN** Homebrew stops the watcher and retains the installed formula and wallpaper configuration

#### Scenario: Restart the watcher after an upgrade
- **WHEN** the formula has been upgraded and the user runs `brew services restart auto-wallpaper`
- **THEN** Homebrew runs the watcher through the current `opt_bin` executable path

### Requirement: Keep package removal separate from user configuration
Removing the Homebrew formula SHALL remove the packaged executable and service definition without deleting `$HOME/.config/auto-wallpaper/config` or any configured image file.

#### Scenario: Uninstall a stopped formula
- **WHEN** the service is stopped and the user runs `brew uninstall auto-wallpaper`
- **THEN** Homebrew removes the package and leaves the configuration and wallpaper image files untouched

### Requirement: Report Homebrew service state
The formula service SHALL appear in Homebrew's service status output under the name `auto-wallpaper`.

#### Scenario: Show a running service
- **WHEN** the user runs `brew services list` while the watcher service is running
- **THEN** Homebrew reports `auto-wallpaper` as started

#### Scenario: Show a stopped service
- **WHEN** the formula is installed but the watcher service is not running
- **THEN** `brew services list` does not report `auto-wallpaper` as started
