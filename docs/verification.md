# OpenSpec verification matrix

This matrix maps each scenario in `create-auto-wallpaper-homebrew-package` to an automated test or a release check. Checks marked manual can change the desktop, service state, or Homebrew installation and must run on a supported Apple Silicon Mac before release.

## Wallpaper configuration

| Scenario | Verification |
| --- | --- |
| Configure valid wallpapers | `CommandTests.testConfigureSavesThenApplies` plus a manual check with two real images |
| Reject a partial configuration | `CommandTests.testConfigureRequiresBothOptions` |
| Reject a missing image | `ConfigurationTests.testImageValidationReportsModeAndMissingCanonicalPath` and the release CLI smoke test |
| Reject an undecodable file | `ConfigurationTests.testImageValidationRejectsUndecodableFile` |
| Save the first configuration | `ConfigurationTests.testConfigurationRoundTripAndPermissions` |
| Configuration replacement fails | `ConfigurationTests.testFailedReplacementPreservesExistingDocument` |
| Show configured paths | `CommandTests.testConfiguredStatusIsReadOnlyAndIncludesAppearance` |
| Show an unconfigured installation | `CommandTests.testUnconfiguredStatusIsReadOnlyAndIncludesAppearance` and the release CLI smoke test |
| Apply a manually edited configuration | `CommandTests.testReloadUsesManualEditAndReappliesUnchangedConfiguration` |
| Reapply an unchanged configuration | `CommandTests.testReloadUsesManualEditAndReappliesUnchangedConfiguration` |
| Reject an invalid edited configuration | `CommandTests.testInvalidReloadReturnsFailureWithoutUpdatingDisplays` |
| Reload without configuration | `ConfigurationTests.testMissingConfigurationHasActionableError` |
| Read an unsupported configuration version | `ConfigurationTests.testUnsupportedVersionDoesNotOverwriteDocument` |

## Appearance-aware wallpaper

| Scenario | Verification |
| --- | --- |
| Apply in light mode | `CoordinatorTests.testReloadSelectsDarkWallpaperAndUpdatesEveryDisplay` exercises selection with the inverse mode, and command tests exercise light selection |
| Apply in dark mode | `CoordinatorTests.testReloadSelectsDarkWallpaperAndUpdatesEveryDisplay` |
| Apply to multiple displays | `CoordinatorTests.testReloadSelectsDarkWallpaperAndUpdatesEveryDisplay` |
| Report a partial display failure | `CoordinatorTests.testPartialFailureStillAttemptsEveryDisplayAndAggregatesFailures` |
| Switch from light to dark | `WatcherTests.testAppearanceAndDisplayChangesCauseApplications` plus a manual system appearance check |
| Switch from dark to light | `WatcherTests.testAppearanceAndDisplayChangesCauseApplications` plus a manual system appearance check |
| Connect a display while watching | `WatcherTests.testAppearanceAndDisplayChangesCauseApplications` plus a manual display connection check |
| Receive a duplicate notification | `WatcherTests.testStartupReloadAndDuplicateSuppression` |
| Use a changed configuration on the next event | `WatcherTests.testChangedConfigurationIsReadOnNextEvent` |
| Retry after a failed application | `WatcherTests.testFailureDoesNotAdvanceStateAndNextEventRetries` |
| Configured image is temporarily unavailable | `WatcherTests.testFailureDoesNotAdvanceStateAndNextEventRetries`; manually move an image and restore it while watching |

## Background service and Homebrew

| Scenario | Verification |
| --- | --- |
| Start a foreground watcher | Watcher startup tests plus a manual run in a graphical session |
| Stop a foreground watcher | `WatcherTests.testStopRemovesSubscription`; manually send both `SIGINT` and `SIGTERM` |
| Continue with configuration changed by another process | `WatcherTests.testChangedConfigurationIsReadOnNextEvent` |
| Install from the project tap | Manual clean-cache source installation after publishing the tag |
| Reject an unsupported platform | Formula metadata audit; inspect failures on Intel, non-macOS, or pre-macOS 15 hosts when available |
| Build without install-phase network access | Manual `brew fetch --build-from-source`, then source install with network access disabled |
| Start the watcher with Homebrew | Manual per-user `brew services start auto-wallpaper` and `brew services list` |
| Stop the watcher with Homebrew | Manual `brew services stop auto-wallpaper` |
| Restart the watcher after an upgrade | Manual upgrade and restart; inspect the generated service for the `opt_bin` path |
| Uninstall a stopped formula | Manual uninstall with before-and-after checks of the configuration and image files |
| Show a running service | Manual `brew services list` while running |
| Show a stopped service | Manual `brew services list` after stopping |
