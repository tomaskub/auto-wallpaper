## Context

The repository is a Swift 6 package with AppKit code, a macOS 15 deployment target, and test targets for both the core library and CLI. It has no GitHub Actions workflow today. Contributors can open and merge a pull request without GitHub running `swift test` against the proposed commit.

The workflow and the GitHub repository setting must work together. A workflow reports a check, but it does not block a merge until the repository requires that check on `main`.

## Goals / Non-Goals

**Goals:**

- Run the complete Swift package test suite for every pull request targeting `main`.
- Give the test job a stable check name that GitHub can require.
- Prevent merging while the check is pending or unsuccessful.
- Avoid duplicate work when new commits supersede an in-progress run.

**Non-Goals:**

- Add linting, formatting, coverage reporting, release automation, or a runner matrix.
- Run tests for direct pushes or scheduled events.
- Change the Swift package, its tests, or its dependencies.
- Define unrelated review, approval, or direct-push policies for `main`.

## Decisions

### Use a pull request workflow scoped to `main`

The workflow will listen to the `pull_request` event for `main`. The event's default activity types cover newly opened pull requests, reopened pull requests, and new commits. This is narrower than running on every push and directly matches the merge gate.

The alternative was a combined pull request and push workflow. That would provide post-merge confirmation, but it adds runner usage without strengthening the pre-merge rule requested by this change.

### Run the package tests on a macOS 15 runner

The test job will use a GitHub-hosted macOS 15 runner and execute `swift test`. A macOS runner is required because the package imports AppKit and declares macOS 15 as its minimum platform. The package already pins its dependency graph in `Package.resolved`, so no separate dependency installation step is needed.

The alternative was `macos-latest`. A fixed major runner label avoids an unplanned operating system and Xcode upgrade changing CI behavior.

### Keep the workflow token read-only

The workflow will grant `contents: read` and use the pull request event rather than `pull_request_target`. This gives forked pull requests enough access to check out and test their code without exposing a write-capable token to untrusted changes.

### Use a stable required check

The workflow and job names will remain stable so the resulting status check can be selected in the protection settings for `main`. The repository administrator will require that check after it has appeared in GitHub from an initial workflow run. A renamed job must be coordinated with the required-check setting or merges could remain blocked on a check that no longer reports.

### Cancel superseded runs

The workflow will use a concurrency group based on the workflow and pull request, with cancellation enabled. Pushing another commit to the same pull request will stop the older run and test the current head commit.

## Risks / Trade-offs

- A GitHub-hosted runner image update can change the installed Swift toolchain. Pin the macOS major version, keep `Package.swift` authoritative for Swift compatibility, and update the runner deliberately when required.
- macOS runners consume more hosted-runner minutes than Linux runners. Use one job and one supported runner because AppKit rules out Linux for the full suite.
- The required check cannot be selected until GitHub has observed it. Merge the workflow setup with administrator controls in place, trigger one run, then add the reported check to the `main` protection settings before treating rollout as complete.
- Renaming the workflow job can desynchronize the protection rule. Treat the check name as a compatibility contract and update the repository setting in the same maintenance window as any rename.

## Migration Plan

1. Add and validate the workflow file.
2. Open or update a pull request so GitHub records the new check name.
3. Add that check to the required status checks for `main` through the repository's ruleset or branch protection settings.
4. Confirm that a successful run permits merging and an unsuccessful or pending run blocks it.

Rollback consists of removing the required check from the repository settings before deleting the workflow. This order avoids leaving pull requests blocked on a check that can no longer run.

## Open Questions

None.
