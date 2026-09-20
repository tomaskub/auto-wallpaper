## Purpose

Define the automated Swift test check that pull requests targeting `main` must pass before merge.

## Requirements

### Requirement: Pull requests run the Swift test suite
The repository SHALL start a GitHub Actions test check for each pull request whose base branch is `main`. The check SHALL test the pull request's current head commit by running the complete Swift package test suite on a macOS environment compatible with the package manifest.

#### Scenario: A pull request is opened against main
- **WHEN** a contributor opens a pull request whose base branch is `main`
- **THEN** GitHub Actions starts the Swift test check for the pull request's head commit

#### Scenario: A pull request receives a new commit
- **WHEN** a contributor pushes a new commit to an open pull request targeting `main`
- **THEN** GitHub Actions starts the Swift test check for the new head commit

#### Scenario: A pull request targets another branch
- **WHEN** a contributor opens or updates a pull request whose base branch is not `main`
- **THEN** the pull request test workflow does not start for that event

### Requirement: Superseded test runs are cancelled
The repository SHALL cancel an in-progress pull request test run when a newer commit triggers another run for the same pull request.

#### Scenario: A new commit arrives during a test run
- **WHEN** a test run is in progress and a contributor pushes another commit to the same pull request
- **THEN** GitHub Actions cancels the older run and continues with the run for the latest head commit

### Requirement: The test workflow has least-privilege access
The pull request test workflow MUST use a read-only repository token and MUST NOT run pull request code with a privileged `pull_request_target` context.

#### Scenario: A pull request comes from a fork
- **WHEN** GitHub Actions runs the test workflow for a pull request from a fork
- **THEN** the workflow can read the checked-out source but cannot write repository contents

### Requirement: Passing tests are required before merge
The repository SHALL require the pull request's current Swift test check to complete successfully before GitHub permits the pull request to merge into `main`.

#### Scenario: Tests are pending
- **WHEN** the required Swift test check for the current head commit is queued or running
- **THEN** GitHub does not permit the pull request to merge into `main`

#### Scenario: Tests fail or are cancelled
- **WHEN** the required Swift test check for the current head commit fails or is cancelled
- **THEN** GitHub does not permit the pull request to merge into `main`

#### Scenario: Tests pass
- **WHEN** the required Swift test check for the current head commit succeeds and all other repository rules are satisfied
- **THEN** GitHub permits the pull request to merge into `main`
