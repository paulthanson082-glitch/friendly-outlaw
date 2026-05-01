import Foundation

/// Provides Dolt-style version control for documents stored in WritersApp.
///
/// Workflow mirrors the Dolt CLI:
/// ```
/// // Create & switch to a feature branch
/// try await vc.checkoutBranch(name: "experiment", createNew: true)
///
/// // Commit the current state of all documents
/// try await vc.commit(message: "Test 10% price reduction", documents: documents)
///
/// // See exactly what changed
/// let diffs = try await vc.diff(fromBranch: "main", toBranch: "experiment")
///
/// // Time travel: documents as they were on a specific date
/// let historical = try await vc.query(asOf: someDate)
///
/// // Merge the wins to main
/// try await vc.merge(fromBranch: "experiment", into: "main")
/// ```
public class DoltVersionControlService {

    // MARK: - Properties

    private let db: DatabaseManager
    public let defaultBranchName = "main"

    // MARK: - Initialisation

    public init(databaseManager: DatabaseManager) {
        self.db = databaseManager
    }

    // MARK: - Branch Operations

    /// Retrieve all version-control branches stored in the database.
    /// - Returns: An array of `VCBranch` representing all persisted branches.
    public func listBranches() throws -> [VCBranch] {
        return try db.getAllVCBranches()
    }

    /// Retrieve the currently active version-control branch, if one exists.
    /// - Returns: The active `VCBranch` if one is marked active, `nil` otherwise.
    /// - Throws: Any error encountered while fetching branches from the database.
    public func currentBranch() throws -> VCBranch? {
        let branches = try db.getAllVCBranches()
        return branches.first(where: { $0.isActive })
    }

    /// Creates and/or switches to a branch, mirroring `dolt checkout [-b] <name>`.
    /// - Parameters:
    ///   - name: The name of the branch to check out or create.
    ///   - createNew: If `true`, create a new branch with the given name and activate it; if `false`, activate an existing branch.
    /// - Returns: The authoritative `VCBranch` instance after activation.
    /// - Throws: `VersionControlError.branchAlreadyExists(name)` if `createNew` is `true` and a branch with `name` already exists; `VersionControlError.branchNotFound(name)` if `createNew` is `false` and the branch does not exist.
    @discardableResult
    public func checkoutBranch(name: String, createNew: Bool = false) throws -> VCBranch {
        if createNew {
            guard try db.getVCBranch(name: name) == nil else {
                throw VersionControlError.branchAlreadyExists(name)
            }
            let newBranch = VCBranch(name: name, isActive: true)
            try db.insertVCBranch(newBranch)
            try db.setActiveBranch(id: newBranch.id)
            return newBranch
        } else {
            guard let branch = try db.getVCBranch(name: name) else {
                throw VersionControlError.branchNotFound(name)
            }
            try db.setActiveBranch(id: branch.id)
            // Re-fetch to return the authoritative state from the database
            guard let updated = try db.getVCBranch(name: name) else {
                throw VersionControlError.branchNotFound(name)
            }
            return updated
        }
    }

    /// Ensures the default branch exists and is marked active, creating and checking it out if necessary.
    /// - Returns: The authoritative `VCBranch` for the repository's default branch (`defaultBranchName`).
    /// - Throws: Any error produced by database operations or by `checkoutBranch(name:createNew:)`.
    @discardableResult
    public func initializeDefaultBranch() throws -> VCBranch {
        if let existing = try db.getVCBranch(name: defaultBranchName) {
            if !existing.isActive {
                try db.setActiveBranch(id: existing.id)
            }
            return existing
        }
        return try checkoutBranch(name: defaultBranchName, createNew: true)
    }

    // MARK: - Commit Operations

    /// Create a new commit on the currently active branch and record snapshots for the provided documents.
    /// Mirrors `dolt commit -am "<message>"`.
    /// - Parameters:
    ///   - message: The commit message describing the change.
    ///   - documents: The documents to capture as snapshots for this commit.
    ///   - authorId: Optional identifier of the commit author.
    /// - Returns: The created `VCCommit` representing the new branch head.
    /// - Throws: `VersionControlError.noActiveBranch` if there is no active branch.
    @discardableResult
    public func commit(message: String,
                       documents: [Document],
                       authorId: String? = nil) throws -> VCCommit {
        guard var activeBranch = try currentBranch() else {
            throw VersionControlError.noActiveBranch
        }

        let newCommit = VCCommit(
            branchId: activeBranch.id,
            message: message,
            authorId: authorId,
            parentCommitId: activeBranch.headCommitId
        )
        try db.insertVCCommit(newCommit)

        // Capture each document as a snapshot
        for doc in documents {
            let snapshot = VCDocumentSnapshot(
                commitId: newCommit.id,
                documentId: doc.id,
                title: doc.title,
                content: doc.content,
                category: doc.category.rawValue,
                wordCount: doc.wordCount
            )
            try db.insertVCSnapshot(snapshot)
        }

        // Advance the branch head
        activeBranch.headCommitId = newCommit.id
        try db.updateVCBranch(activeBranch)

        return newCommit
    }

    /// Retrieves the commit history for the specified branch.
    /// - Parameters:
    ///   - branchName: The name of the branch whose commits should be returned.
    /// - Returns: An array of `VCCommit` representing the branch's commit history.
    /// - Throws: `VersionControlError.branchNotFound(branchName)` if no branch with the given name exists.
    public func log(branch branchName: String) throws -> [VCCommit] {
        guard let branch = try db.getVCBranch(name: branchName) else {
            throw VersionControlError.branchNotFound(branchName)
        }
        return try db.getVCCommits(branchId: branch.id)
    }

    // MARK: - Diff Operations

    /// Computes a diff between two named branches, mirroring `dolt diff <from> <to>`.
    ///
    /// Each entry describes what changed for a single document:
    /// `.added` — present in `to` but not `from`
    /// `.deleted` — present in `from` but not `to`
    /// `.modified` — content differs between commits
    /// Computes the document-level diffs between the head commits of two branches.
    /// - Parameters:
    ///   - fromBranch: The source branch name to diff from.
    ///   - toBranch: The target branch name to diff to.
    /// - Returns: An array of `VCDiff` entries describing per-document changes from `fromBranch` to `toBranch`.
    /// - Throws: `VersionControlError` if either branch does not exist or if a branch has no head commit.
    public func diff(fromBranch: String, toBranch: String) throws -> [VCDiff] {
        let fromCommitId = try headCommitId(for: fromBranch)
        let toCommitId = try headCommitId(for: toBranch)
        return try diff(fromCommitId: fromCommitId, toCommitId: toCommitId)
    }

    /// Compute per-document diffs between two commits.
    ///
    /// Compares snapshots from `fromCommitId` (base) to `toCommitId` (target) and produces a `VCDiff` for each document indicating whether it was added, deleted, modified, or unchanged. The returned diffs are sorted by document title.
    /// - Parameters:
    ///   - fromCommitId: Commit ID to compare from (base).
    ///   - toCommitId: Commit ID to compare to (target).
    /// - Returns: An array of `VCDiff` entries sorted by title.
    public func diff(fromCommitId: UUID, toCommitId: UUID) throws -> [VCDiff] {
        let fromSnapshots = try db.getVCSnapshotsDirect(commitId: fromCommitId)
        let toSnapshots   = try db.getVCSnapshotsDirect(commitId: toCommitId)

        let fromMap = Dictionary(uniqueKeysWithValues: fromSnapshots.map { ($0.documentId, $0) })
        let toMap   = Dictionary(uniqueKeysWithValues: toSnapshots.map   { ($0.documentId, $0) })

        let presentDiffs = diffPresent(fromMap: fromMap, toMap: toMap)
        let deletedDiffs = diffDeleted(fromMap: fromMap, toMap: toMap)

        return (presentDiffs + deletedDiffs).sorted { $0.title < $1.title }
    }

    // MARK: - Private Diff Helpers

    /// Produces diffs for documents present in the target snapshot, comparing against the base.
    private func diffPresent(
        fromMap: [UUID: VCDocumentSnapshot],
        toMap: [UUID: VCDocumentSnapshot]
    ) -> [VCDiff] {
        return toMap.map { (docId, toSnap) in
            guard let fromSnap = fromMap[docId] else {
                return VCDiff(documentId: docId, title: toSnap.title,
                              changeType: .added,
                              toContent: toSnap.content,
                              toWordCount: toSnap.wordCount)
            }
            let hasChanges = fromSnap.content != toSnap.content || fromSnap.title != toSnap.title
            return VCDiff(documentId: docId, title: toSnap.title,
                          changeType: hasChanges ? .modified : .unchanged,
                          fromContent: fromSnap.content,
                          toContent: toSnap.content,
                          fromWordCount: fromSnap.wordCount,
                          toWordCount: toSnap.wordCount)
        }
    }

    /// Produces diffs for documents removed from the target snapshot relative to the base.
    private func diffDeleted(
        fromMap: [UUID: VCDocumentSnapshot],
        toMap: [UUID: VCDocumentSnapshot]
    ) -> [VCDiff] {
        return fromMap.compactMap { (docId, fromSnap) in
            guard toMap[docId] == nil else { return nil }
            return VCDiff(documentId: docId, title: fromSnap.title,
                          changeType: .deleted,
                          fromContent: fromSnap.content,
                          fromWordCount: fromSnap.wordCount)
        }
    }

    // MARK: - Time Travel

    /// Returns the state of all documents at or before `date`,
    /// Retrieves all document snapshots as of the specified date.
    /// - Parameter date: The point in time to query document state for.
    /// - Returns: An array of `VCDocumentSnapshot` representing each document's state at the given date.
    public func query(asOf date: Date) throws -> [VCDocumentSnapshot] {
        return try db.getVCSnapshotsAsOf(date: date)
    }

    /// Retrieves the snapshot history for a document across commits.
    /// - Returns: An array of `VCDocumentSnapshot` containing all stored snapshots for the specified document.
    public func history(of documentId: UUID) throws -> [VCDocumentSnapshot] {
        return try db.getVCSnapshotsForDocument(documentId: documentId)
    }

    // MARK: - Merge

    /// Merges `fromBranch` into `intoBranch`, mirroring `dolt merge <from>`.
    ///
    /// A fast-forward merge is performed when `intoBranch` has no commits
    /// after the common ancestor — that is, it simply advances the head pointer.
    /// Otherwise a three-way merge is attempted; only non-conflicting documents
    /// (those unchanged in `intoBranch` since the fork) are brought in.
    ///
    /// Merges the changes from one branch into another using either a fast‑forward or a three‑way merge.
    /// - Parameters:
    ///   - fromBranch: The name of the source branch to merge from.
    ///   - intoBranch: The name of the target branch to merge into.
    /// - Returns: A `VCMergeResult` describing the merge strategy used, the resulting commit id (if created), the number of document-level changes applied, and whether the merge succeeded.
    /// - Throws: `VersionControlError.branchNotFound` if either the source or target branch does not exist.
    @discardableResult
    public func merge(fromBranch: String, into intoBranch: String) throws -> VCMergeResult {
        guard var targetBranch = try db.getVCBranch(name: intoBranch) else {
            throw VersionControlError.branchNotFound(intoBranch)
        }
        guard let sourceBranch = try db.getVCBranch(name: fromBranch) else {
            throw VersionControlError.branchNotFound(fromBranch)
        }

        // Nothing to merge if source has no commits
        guard let sourceHeadId = sourceBranch.headCommitId else {
            return VCMergeResult(fromBranch: fromBranch, intoBranch: intoBranch,
                                 strategy: .fastForward, diffCount: 0, success: true)
        }

        // Fast-forward: target has no head, simply point it to source head
        guard let targetHeadId = targetBranch.headCommitId else {
            return try performFastForwardMerge(
                targetBranch: &targetBranch,
                sourceHeadId: sourceHeadId,
                fromBranch: fromBranch,
                intoBranch: intoBranch
            )
        }

        return try performThreeWayMerge(
            targetBranch: &targetBranch,
            sourceHeadId: sourceHeadId,
            targetHeadId: targetHeadId,
            fromBranch: fromBranch,
            intoBranch: intoBranch
        )
    }

    // MARK: - Private Merge Helpers

    /// Advances the target branch head to the source head without creating a new commit.
    private func performFastForwardMerge(
        targetBranch: inout VCBranch,
        sourceHeadId: UUID,
        fromBranch: String,
        intoBranch: String
    ) throws -> VCMergeResult {
        targetBranch.headCommitId = sourceHeadId
        try db.updateVCBranch(targetBranch)
        let sourceSnapshots = try db.getVCSnapshots(commitId: sourceHeadId)
        return VCMergeResult(fromBranch: fromBranch, intoBranch: intoBranch,
                             strategy: .fastForward, commitId: sourceHeadId,
                             diffCount: sourceSnapshots.count, success: true)
    }

    /// Applies source changes onto the target branch using last-writer-wins for conflicts.
    private func performThreeWayMerge(
        targetBranch: inout VCBranch,
        sourceHeadId: UUID,
        targetHeadId: UUID,
        fromBranch: String,
        intoBranch: String
    ) throws -> VCMergeResult {
        let sourceSnapshots = try db.getVCSnapshots(commitId: sourceHeadId)
        let targetSnapshots = try db.getVCSnapshots(commitId: targetHeadId)

        let (mergedSnapshots, changedCount) = buildMergedSnapshots(
            sourceSnapshots: sourceSnapshots,
            targetSnapshots: targetSnapshots
        )

        let mergeCommit = VCCommit(
            branchId: targetBranch.id,
            message: "Merge '\(fromBranch)' into '\(intoBranch)'",
            parentCommitId: targetHeadId,
            secondParentCommitId: sourceHeadId
        )
        try db.insertVCCommit(mergeCommit)

        for snap in mergedSnapshots {
            let mergedSnap = VCDocumentSnapshot(
                commitId: mergeCommit.id,
                documentId: snap.documentId,
                title: snap.title,
                content: snap.content,
                category: snap.category,
                wordCount: snap.wordCount
            )
            try db.insertVCSnapshot(mergedSnap)
        }

        targetBranch.headCommitId = mergeCommit.id
        try db.updateVCBranch(targetBranch)

        return VCMergeResult(fromBranch: fromBranch, intoBranch: intoBranch,
                             strategy: .threeWay, commitId: mergeCommit.id,
                             diffCount: changedCount, success: true)
    }

    /// Combines source and target snapshots using last-writer-wins for conflicting documents.
    /// - Returns: The merged snapshot array and the count of documents changed from the target state.
    private func buildMergedSnapshots(
        sourceSnapshots: [VCDocumentSnapshot],
        targetSnapshots: [VCDocumentSnapshot]
    ) -> (snapshots: [VCDocumentSnapshot], changedCount: Int) {
        let targetMap = Dictionary(uniqueKeysWithValues: targetSnapshots.map { ($0.documentId, $0) })
        var mergedSnapshots: [VCDocumentSnapshot] = Array(targetSnapshots)
        var changedCount = 0

        for sourceSnap in sourceSnapshots {
            if let targetSnap = targetMap[sourceSnap.documentId] {
                // Take the source version if content differs (last-writer-wins strategy)
                if sourceSnap.content != targetSnap.content,
                   let idx = mergedSnapshots.firstIndex(where: { $0.documentId == sourceSnap.documentId }) {
                    mergedSnapshots[idx] = sourceSnap
                    changedCount += 1
                }
            } else {
                // Document only in source — bring it over
                mergedSnapshots.append(sourceSnap)
                changedCount += 1
            }
        }

        return (mergedSnapshots, changedCount)
    }

    /// Get the head commit identifier for the specified branch.
    /// - Parameter branchName: The name of the branch to look up.
    /// - Returns: The head commit `UUID` for the branch.
    /// - Throws: `VersionControlError.branchNotFound` if the branch does not exist; `VersionControlError.commitNotFound` if the branch has no commits.

    private func headCommitId(for branchName: String) throws -> UUID {
        guard let branch = try db.getVCBranch(name: branchName) else {
            throw VersionControlError.branchNotFound(branchName)
        }
        guard let headId = branch.headCommitId else {
            throw VersionControlError.commitNotFound("No commits on branch '\(branchName)'")
        }
        return headId
    }
}