# auto-wallpaper

`auto-wallpaper` keeps the desktop wallpaper in sync with the current macOS light or dark appearance. It is a command-line tool with an optional per-user Homebrew service. It has no menu bar item, application bundle, or Dock icon.

## Requirements

- Apple Silicon Mac
- macOS 15 Sequoia or later
- A signed-in graphical session
- Homebrew for packaged installation

The package floor follows the supported platform in the original release plan. As of September 2026, Homebrew lists Apple Silicon Macs running macOS 15, 26, or 27 as Tier 1 when the rest of its Tier 1 conditions are met. Check the [current Homebrew support tiers](https://docs.brew.sh/Support-Tiers) before each release because macOS 15 is expected to leave Tier 1 in or after September 2027.

## Install

The first release will be available from the project tap after `v0.1.0` is published:

```sh
brew tap tomaskub/tap
brew install tomaskub/tap/auto-wallpaper
```

To build the current checkout instead:

```sh
swift build -c release
.build/release/auto-wallpaper --help
```

## Configure wallpapers

Set both paths in one command:

```sh
auto-wallpaper configure \
  --light "$HOME/Pictures/light.jpg" \
  --dark "$HOME/Pictures/dark.jpg"
```

The command resolves relative paths against the current directory, expands a leading `~`, validates both images, saves the configuration, and applies the image for the current appearance. A failed validation leaves the previous configuration intact.

Inspect the saved paths and current appearance without changing anything:

```sh
auto-wallpaper status
```

Apply the saved configuration again after editing it or changing displays:

```sh
auto-wallpaper reload
```

## Configuration file

The tool stores one JSON document at `~/.config/auto-wallpaper/config`:

```json
{
  "dark" : "/Users/example/Pictures/dark.jpg",
  "light" : "/Users/example/Pictures/light.jpg",
  "version" : 1
}
```

The paths point to the original image files. Moving or deleting an image makes that path invalid. The parent directory uses mode `0700`, and the configuration file uses mode `0600`.

## Run as a service

Start the watcher for the current user. Do not use `sudo`, because AppKit needs the signed-in user's graphical session.

```sh
brew services start auto-wallpaper
brew services list
```

Restart it after an upgrade:

```sh
brew services restart auto-wallpaper
```

Stop it without removing the configuration:

```sh
brew services stop auto-wallpaper
```

For foreground diagnostics, run:

```sh
auto-wallpaper watch
```

The watcher reports recoverable errors to standard error and keeps listening. It reloads the saved document before each appearance or display event.

## Upgrade

```sh
brew update
brew upgrade auto-wallpaper
brew services restart auto-wallpaper
```

The Homebrew service uses the stable `opt_bin` executable path, so its LaunchAgent does not retain an old versioned Cellar path.

## Troubleshooting

- `No configuration found`: run `auto-wallpaper configure` with both image paths.
- `file does not exist`: check whether the configured image moved or was deleted.
- `AppKit cannot decode the file`: use an image format that macOS can open.
- `No connected displays`: run the command from a signed-in graphical session.
- A service will not start: run `auto-wallpaper watch` in Terminal and inspect the error. Also confirm that you started the service without `sudo`.
- A manually edited configuration fails: restore valid JSON with `version`, `light`, and `dark` fields, then run `auto-wallpaper reload`.

## Uninstall

Stop the service and remove the package and tap:

```sh
brew services stop auto-wallpaper
brew uninstall auto-wallpaper
brew untap tomaskub/tap
```

Homebrew does not remove the configuration or image files. Remove the configuration separately if you no longer want it:

```sh
rm -r "$HOME/.config/auto-wallpaper"
```

## Release process

1. Merge the release branch into `main`. A squash merge is suitable for this initial feature.
2. Pull the resulting `main` commit and run `swift test` and `swift build -c release`.
3. Confirm that the minimum macOS version still belongs to Homebrew's current Tier 1 Apple Silicon matrix.
4. Create an annotated `v0.1.0` tag on the tested `main` commit and push the tag.
5. Download `https://github.com/tomaskub/auto-wallpaper/archive/refs/tags/v0.1.0.tar.gz` and calculate its SHA-256 checksum.
6. Update `Formula/auto-wallpaper.rb` in `tomaskub/homebrew-tap` with that URL, checksum, version-locked fetch behavior, and `GPL-3.0-or-later` license identifier.
7. Run the formula checks listed below, then commit and push the tap update.

Do not tag the feature branch before merging. The tag should identify the exact `main` commit that passed the release checks. If the checks require a source change, fix it, merge again, and tag the corrected commit.

## Manual release checks

Automated tests cover configuration parsing and replacement, path and image errors, appearance mapping, multi-display attempts, watcher state changes, command parsing, and read-only status behavior. The following checks require a supported Mac and must run before publishing the formula:

- Configure real light and dark images, then switch appearance in both directions.
- Connect or disconnect a display and confirm that the watcher updates the resulting display set.
- Send `SIGINT` and `SIGTERM` to a foreground watcher and confirm clean shutdown.
- Run `brew style`, `brew audit --new --formula`, a clean-cache `brew fetch --build-from-source`, a network-isolated source installation, and `brew test`.
- Start, list, restart, and stop the per-user service. Confirm that it runs through `opt_bin/auto-wallpaper` after an upgrade.
- Stop and uninstall the formula. Confirm that `~/.config/auto-wallpaper/config` and both configured images remain unchanged.

## License

Copyright 2026 Tomasz Kubiak.

This project is licensed under the GNU General Public License, version 3 or any later version. See [LICENSE](LICENSE). The GPL includes warranty and liability disclaimers to the extent permitted by applicable law.
