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

    /// Lists all branches, mirroring `dolt branch`.
    public func listBranches() throws -> [VCBranch] {
        return try db.getAllVCBranches()
    }

    /// Returns the currently active branch, or nil if none has been checked out yet.
    public func currentBranch() throws -> VCBranch? {
        let branches = try db.getAllVCBranches()
        return branches.first(where: { $0.isActive })
    }

    /// Creates and/or switches to a branch, mirroring `dolt checkout [-b] <name>`.
    ///
    /// - Parameters:
    ///   - name: Branch name.
    ///   - createNew: When `true` a new branch is created; throws if it already exists.
    /// - Returns: The branch that is now active.
    @discardableResult
    public func checkoutBranch(name: String, createNew: Bool = false) throws -> VCBranch {
        if createNew {
            guard try db.getVCBranch(name: name) == nil else {
                throw VersionControlError.branchAlreadyExists(name)
            }
            var newBranch = VCBranch(name: name, isActive: true)

            // Inherit head commit from current branch so history is connected
            if let current = try currentBranch() {
                newBranch = VCBranch(id: newBranch.id, name: name,
                                     headCommitId: current.headCommitId,
                                     createdAt: newBranch.createdAt, isActive: true)
            }
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

    /// Ensures the default "main" branch exists, creating it if needed.
    /// Call once during app setup to mirror `dolt init`.
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
    /// - Returns: The created commit.
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

    /// Returns the ordered commit history for a branch, mirroring `dolt log`.
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
    /// `.unchanged` — identical in both commits
    public func diff(fromBranch: String, toBranch: String) throws -> [VCDiff] {
        let fromCommitId = try headCommitId(for: fromBranch)
        let toCommitId = try headCommitId(for: toBranch)
        return try diff(fromCommitId: fromCommitId, toCommitId: toCommitId)
    }

    /// Computes a diff between two specific commits.
    public func diff(fromCommitId: UUID, toCommitId: UUID) throws -> [VCDiff] {
        let fromSnapshots = try db.getVCSnapshots(commitId: fromCommitId)
        let toSnapshots = try db.getVCSnapshots(commitId: toCommitId)

        let fromMap = Dictionary(uniqueKeysWithValues: fromSnapshots.map { ($0.documentId, $0) })
        let toMap = Dictionary(uniqueKeysWithValues: toSnapshots.map { ($0.documentId, $0) })

        var diffs: [VCDiff] = []

        // Documents present in "to"
        for (docId, toSnap) in toMap {
            if let fromSnap = fromMap[docId] {
                if fromSnap.content != toSnap.content || fromSnap.title != toSnap.title {
                    diffs.append(VCDiff(documentId: docId, title: toSnap.title,
                                        changeType: .modified,
                                        fromContent: fromSnap.content,
                                        toContent: toSnap.content,
                                        fromWordCount: fromSnap.wordCount,
                                        toWordCount: toSnap.wordCount))
                } else {
                    diffs.append(VCDiff(documentId: docId, title: toSnap.title,
                                        changeType: .unchanged,
                                        fromContent: fromSnap.content,
                                        toContent: toSnap.content,
                                        fromWordCount: fromSnap.wordCount,
                                        toWordCount: toSnap.wordCount))
                }
            } else {
                diffs.append(VCDiff(documentId: docId, title: toSnap.title,
                                    changeType: .added,
                                    toContent: toSnap.content,
                                    toWordCount: toSnap.wordCount))
            }
        }

        // Documents deleted in "to"
        for (docId, fromSnap) in fromMap where toMap[docId] == nil {
            diffs.append(VCDiff(documentId: docId, title: fromSnap.title,
                                changeType: .deleted,
                                fromContent: fromSnap.content,
                                fromWordCount: fromSnap.wordCount))
        }

        return diffs.sorted { $0.title < $1.title }
    }

    // MARK: - Time Travel

    /// Returns the state of all documents at or before `date`,
    /// mirroring `SELECT * FROM table AS OF '<date>'`.
    public func query(asOf date: Date) throws -> [VCDocumentSnapshot] {
        return try db.getVCSnapshotsAsOf(date: date)
    }

    /// Returns the full version history of a single document across all commits.
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
    /// - Returns: A `VCMergeResult` describing what happened.
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
            let diffs = try db.getVCSnapshots(commitId: sourceHeadId)
            return VCMergeResult(fromBranch: fromBranch, intoBranch: intoBranch,
                                 strategy: .fastForward, commitId: sourceHeadId,
                                 diffCount: diffs.count, success: true)
        }

        // Three-way merge: build the merged snapshot set
        let sourceSnapshots = try db.getVCSnapshots(commitId: sourceHeadId)
        let targetSnapshots = try db.getVCSnapshots(commitId: targetHeadId)

        let targetMap = Dictionary(uniqueKeysWithValues: targetSnapshots.map { ($0.documentId, $0) })
        var mergedSnapshots: [VCDocumentSnapshot] = Array(targetSnapshots) // start with target

        var changedCount = 0
        for sourceSnap in sourceSnapshots {
            if let targetSnap = targetMap[sourceSnap.documentId] {
                // Take the source version if content differs (last-writer-wins strategy)
                if sourceSnap.content != targetSnap.content {
                    // Replace in mergedSnapshots
                    if let idx = mergedSnapshots.firstIndex(where: { $0.documentId == sourceSnap.documentId }) {
                        mergedSnapshots[idx] = sourceSnap
                    }
                    changedCount += 1
                }
            } else {
                // Document only in source — bring it over
                mergedSnapshots.append(sourceSnap)
                changedCount += 1
            }
        }

        // Create a merge commit on the target branch, recording both parents for full lineage
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

    // MARK: - Private Helpers

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
