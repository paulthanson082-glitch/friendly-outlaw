---
name: add-version-control-op
description: Add a new version control operation to the DoltVersionControlService. Invoke when asked to extend branch/commit/merge/diff/time-travel capabilities.
---

# Add a Version Control Operation

The friendly-outlaw app uses a Git-inspired document version control system backed by SQLite. Follow these steps to extend it.

## Architecture recap

```
DoltVersionControlService   ← business logic (Sources/WritersApp/Services/)
        │
        └── DatabaseManager ← SQLite persistence (Sources/WritersApp/Services/)
                │
                └── VersionControl models (Sources/WritersApp/Models/VersionControl.swift)
```

Key types: `VCBranch`, `VCCommit`, `VCDocumentSnapshot`, `VCDiff`, `VCMergeResult`

## Step 1 — Define model types (if needed)

File: `Sources/WritersApp/Models/VersionControl.swift`

Add any new structs or enums. Ensure they conform to `Codable` and `Identifiable` (UUID `id`).

```swift
public struct MyNewType: Codable, Identifiable {
    public let id: UUID
    // ...
}
```

## Step 2 — Add persistence to DatabaseManager (if new data needs storing)

File: `Sources/WritersApp/Services/DatabaseManager.swift`

- Add `CREATE TABLE IF NOT EXISTS` in `setupSchema()`
- Add CRUD methods following existing patterns (use `CSQLite` directly, no ORM)
- Use `DatabaseError` for typed error propagation
- Never execute raw user strings — use `sqlite3_bind_*` for parameters

## Step 3 — Implement the operation on DoltVersionControlService

File: `Sources/WritersApp/Services/DoltVersionControlService.swift`

```swift
/// One-sentence description.
public func myOperation(/* params */) throws -> ReturnType {
    guard isInitialized else { throw VersionControlError.notInitialized }
    // implementation
}
```

Throw `VersionControlError` cases for known failure modes. Add new cases to the enum in `VersionControl.swift` if needed.

## Step 4 — Expose on WritersApp facade (if user-facing)

File: `Sources/WritersApp/WritersApp.swift`

Delegate to `versionControl`:

```swift
public func myOperation(/* params */) throws -> ReturnType {
    return try versionControl.myOperation(/* params */)
}
```

## Step 5 — Write tests using an in-memory database

File: `Tests/WritersAppTests/WritersAppTests.swift`

Always use `:memory:` for test isolation:

```swift
func testMyOperation() throws {
    let db = DatabaseManager(databasePath: ":memory:")
    let vc = DoltVersionControlService(databaseManager: db)
    try vc.initializeDefaultBranch()

    // arrange
    // act
    // assert
}
```

## Step 6 — Build and test

```bash
swift test
```

Or invoke the `build-and-test` skill.
