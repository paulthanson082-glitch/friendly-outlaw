# Metal Dashboard Preview

This change adds the Metal Dashboard UI (preview) files for testing and review.

## Test results (automated)

- `swift test` executed on 2026-02-08 — 201 tests passed, 0 failures.

All tests in `WritersApp` passed locally after making the test harness run on the `MainActor` to accommodate the MainActor-isolated view model.
