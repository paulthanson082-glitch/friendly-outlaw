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
    ///
    /// - Parameters:
    ///   - name: Branch name.
    ///   - createNew: When `true` a new branch is created; throws if it already exists.
    /// Checks out the specified branch, activating it in the repository; optionally creates and activates a new branch with the same head as the current branch.
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
            // Capture the parent branch's head to use as the base commit for LCA during merges.
            let parentHead = try currentBranch()?.headCommitId

            // The DB record stores headCommitId=nil (the new branch has no commits yet).
            // baseCommitId records where the branch was forked from; commit() uses it as the
            // parentCommitId for the first commit so the chain stays connected.
            let newBranch = VCBranch(name: name, headCommitId: nil,
                                     baseCommitId: parentHead,
                                     isActive: true)
            try db.insertVCBranch(newBranch)
            try db.setActiveBranch(id: newBranch.id)

            // Return a view with headCommitId = parentHead so that callers reading the
            // returned value see the inherited head state.  The DB record retains nil —
            // currentBranch() always reads from the DB, so it correctly returns nil head
            // for this branch until the first commit lands on it.
            return VCBranch(id: newBranch.id, name: name,
                            headCommitId: parentHead,
                            baseCommitId: parentHead,
                            createdAt: newBranch.createdAt, isActive: true)
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

    /// Ensures the default "main" branch exists, creating it if needed.
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

    /// Records a snapshot of all provided documents on the active branch,
    /// mirroring `dolt commit -am "<message>"`.
    ///
    /// - Parameters:
    ///   - message: Human-readable description of the change.
    ///   - documents: The current state of every document to capture.
    ///   - authorId: Optional author identifier.
    /// Create a new commit on the currently active branch and record snapshots for the provided documents.
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
            // Use the branch's current head as parent, falling back to the base commit
            // so the first commit on a new branch is still linked into the parent chain.
            parentCommitId: activeBranch.headCommitId ?? activeBranch.baseCommitId
        )
        try db.insertVCCommit(newCommit)

        // Capture each document as a snapshot (delta — only what was provided)
        for doc in documents {
            let snapshot = VCDocumentSnapshot(
                commitId: newCommit.id,
                documentId: doc.id,
                title: doc.title,
                content: doc.content,
                category: String(describing: doc.category),
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
    /// - Returns: An array of `VCDiff` entries describing per-document changes between the two commits.
    public func diff(fromCommitId: UUID, toCommitId: UUID) throws -> [VCDiff] {
        // Use direct (delta) snapshots so that an empty commit correctly
        // shows deletions rather than inheriting unchanged docs from the chain.
        let fromSnapshots = try db.getVCSnapshotsDirect(commitId: fromCommitId)
        let toSnapshots   = try db.getVCSnapshotsDirect(commitId: toCommitId)

        let fromById = Dictionary(uniqueKeysWithValues: fromSnapshots.map { ($0.documentId, $0) })
        let toById   = Dictionary(uniqueKeysWithValues: toSnapshots.map   { ($0.documentId, $0) })

        var diffs: [VCDiff] = []
        var unmatchedFrom = fromById  // tracks from-snaps not yet matched
        var unmatchedTo   = toById    // tracks to-snaps not yet matched

        // --- Pass 1: Match by document ID ---
        for (docId, toSnap) in toById {
            if let fromSnap = fromById[docId] {
                unmatchedFrom.removeValue(forKey: docId)
                unmatchedTo.removeValue(forKey: docId)
                let changeType: VCChangeType =
                    (fromSnap.content != toSnap.content || fromSnap.title != toSnap.title)
                    ? .modified : .unchanged
                diffs.append(VCDiff(documentId: docId, title: toSnap.title,
                                    changeType: changeType,
                                    fromContent: fromSnap.content, toContent: toSnap.content,
                                    fromWordCount: fromSnap.wordCount, toWordCount: toSnap.wordCount))
            }
        }

        // --- Pass 2: Match remaining by title (handles document re-creation with new ID) ---
        let fromByTitle = Dictionary(unmatchedFrom.values.map { ($0.title, $0) },
                                     uniquingKeysWith: { first, _ in first })
        for (_, toSnap) in unmatchedTo {
            if let fromSnap = fromByTitle[toSnap.title] {
                unmatchedFrom.removeValue(forKey: fromSnap.documentId)
                let changeType: VCChangeType = fromSnap.content != toSnap.content ? .modified : .unchanged
                diffs.append(VCDiff(documentId: toSnap.documentId, title: toSnap.title,
                                    changeType: changeType,
                                    fromContent: fromSnap.content, toContent: toSnap.content,
                                    fromWordCount: fromSnap.wordCount, toWordCount: toSnap.wordCount))
            } else {
                diffs.append(VCDiff(documentId: toSnap.documentId, title: toSnap.title,
                                    changeType: .added,
                                    toContent: toSnap.content, toWordCount: toSnap.wordCount))
            }
        }

        // --- Pass 3: Any remaining from-snaps were deleted ---
        for (_, fromSnap) in unmatchedFrom {
            diffs.append(VCDiff(documentId: fromSnap.documentId, title: fromSnap.title,
                                changeType: .deleted,
                                fromContent: fromSnap.content, fromWordCount: fromSnap.wordCount))
        }

        return diffs.sorted { $0.title < $1.title }
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
            targetBranch.headCommitId = sourceHeadId
            try db.updateVCBranch(targetBranch)
            // diffCount = number of documents arriving in the target for the first time
            let diffs = try db.getVCSnapshots(commitId: sourceHeadId)
            return VCMergeResult(fromBranch: fromBranch, intoBranch: intoBranch,
                                 strategy: .fastForward, commitId: sourceHeadId,
                                 diffCount: diffs.count, success: true)
        }

        // Three-way merge using the Lowest Common Ancestor as the base.
        let lcaId = try findLCA(commitId1: targetHeadId, commitId2: sourceHeadId)

        let baseSnapshots   = lcaId != nil ? try db.getVCSnapshotsDirect(commitId: lcaId!) : []
        let sourceSnapshots = try db.getVCSnapshotsDirect(commitId: sourceHeadId)
        let targetSnapshots = try db.getVCSnapshotsDirect(commitId: targetHeadId)

        let baseMap   = Dictionary(baseSnapshots.map   { ($0.documentId, $0) }, uniquingKeysWith: { f, _ in f })
        let sourceMap = Dictionary(sourceSnapshots.map { ($0.documentId, $0) }, uniquingKeysWith: { f, _ in f })
        let targetMap = Dictionary(targetSnapshots.map { ($0.documentId, $0) }, uniquingKeysWith: { f, _ in f })

        // Collect all document IDs mentioned across base, source, and target
        var allIds: Set<UUID> = []
        allIds.formUnion(baseMap.keys)
        allIds.formUnion(sourceMap.keys)
        allIds.formUnion(targetMap.keys)

        var mergedSnapshots: [VCDocumentSnapshot] = []
        var changedCount = 0

        for docId in allIds {
            let base   = baseMap[docId]
            let source = sourceMap[docId]
            let target = targetMap[docId]

            switch (base, source, target) {
            case (_, nil, nil):
                // Only in base — deleted by both; omit.
                break
            case (nil, let s?, nil):
                // Added by source only — add.
                mergedSnapshots.append(s); changedCount += 1
            case (nil, nil, let t?):
                // Added by target only — keep.
                mergedSnapshots.append(t)
            case (nil, let s?, let t?):
                // Added independently by both; prefer source if content differs.
                if s.content == t.content {
                    mergedSnapshots.append(t)
                } else {
                    mergedSnapshots.append(s); changedCount += 1
                }
            case (let b?, nil, let t?):
                // Deleted by source, unchanged in target — apply the deletion when target
                // hasn't diverged from base (t == b means no target-side modification).
                if t.content == b.content {
                    // Document is removed from the merge result; count as one change.
                    changedCount += 1
                } else {
                    // Target modified it independently; keep target's version.
                    mergedSnapshots.append(t)
                }
            case (let b?, let s?, nil):
                // Modified by source, deleted by target — keep source modification.
                _ = b; mergedSnapshots.append(s); changedCount += 1
            case (let b?, let s?, let t?):
                // Existed in base; compare changes.
                let sourceChanged = s.content != b.content
                let targetChanged = t.content != b.content
                switch (sourceChanged, targetChanged) {
                case (false, false):
                    mergedSnapshots.append(t) // unchanged in both
                case (true, false):
                    mergedSnapshots.append(s); changedCount += 1 // only source changed
                case (false, true):
                    mergedSnapshots.append(t) // only target changed
                case (true, true):
                    // Both changed; prefer source (last-writer wins)
                    mergedSnapshots.append(s); changedCount += 1
                }
            }
        }

        // Create a merge commit on the target branch, recording both parents for full lineage.
        // The merge commit stores the complete merged state so getVCSnapshots returns it directly.
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

    /// Finds the Lowest Common Ancestor of two commits by walking their parent chains.
    private func findLCA(commitId1: UUID, commitId2: UUID) throws -> UUID? {
        // Collect all ancestors of commit1 (including itself)
        var ancestors1: Set<UUID> = []
        var current: UUID? = commitId1
        while let cId = current {
            ancestors1.insert(cId)
            current = try db.getVCCommitById(id: cId)?.parentCommitId
        }
        // Walk commit2's chain and return the first commit also in commit1's ancestry
        current = commitId2
        while let cId = current {
            if ancestors1.contains(cId) { return cId }
            current = try db.getVCCommitById(id: cId)?.parentCommitId
        }
        return nil
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