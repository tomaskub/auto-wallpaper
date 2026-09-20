## Why

Pull requests can currently be merged without an automated test run, so regressions may reach `main` before anyone runs the Swift test suite locally. A required GitHub Actions check will make a passing test run part of the merge process.

## What Changes

- Add a GitHub Actions workflow that runs the Swift package tests for pull requests targeting `main`.
- Run the workflow on a macOS runner compatible with the package's macOS 15 and AppKit requirements.
- Configure the repository merge policy so the test job must pass before a pull request can merge.
- Keep the workflow read-only and cancel stale runs when a pull request receives newer commits.

## Capabilities

### New Capabilities

- `pull-request-test-gate`: Defines the automated Swift test check and the requirement that it pass before merging into `main`.

### Modified Capabilities

None.

## Impact

- Adds a workflow under `.github/workflows/`.
- Uses GitHub-hosted macOS runner minutes for pull request validation.
- Adds a required status check to the protection rules or ruleset for `main`.
- Does not change application code, public APIs, runtime dependencies, or release artifacts.
