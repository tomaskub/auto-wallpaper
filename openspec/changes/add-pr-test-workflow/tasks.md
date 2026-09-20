## 1. Add the pull request workflow

- [x] 1.1 Create `.github/workflows/pull-request-tests.yml` with a stable workflow and job name, a `pull_request` trigger limited to `main`, and `contents: read` permissions.
- [x] 1.2 Configure one macOS 15 job that checks out the pull request head and runs `swift test`.
- [x] 1.3 Add pull-request-scoped concurrency with cancellation so a new commit supersedes an older in-progress run.

## 2. Validate the workflow

- [x] 2.1 Validate the workflow YAML and run `swift test` locally to confirm the planned CI command passes the complete package test suite.
- [x] 2.2 Open or update a pull request against `main`, then confirm GitHub runs the check for the current head commit with read-only permissions.
- [x] 2.3 Push a follow-up commit while a run is active and confirm GitHub cancels the superseded run.

## 3. Enforce the merge gate

- [ ] 3.1 After GitHub records the check name, add it as a required status check in the ruleset or branch protection settings for `main`.
- [ ] 3.2 Confirm GitHub blocks merging while the required check is pending, failed, or cancelled.
- [ ] 3.3 Confirm GitHub allows merging after the required check passes and all other repository rules are satisfied.
