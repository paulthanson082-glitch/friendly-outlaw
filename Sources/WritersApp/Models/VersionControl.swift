import Foundation

// MARK: - Errors

/// Errors that can occur during version control operations
public enum VersionControlError: Error, LocalizedError {
    case branchNotFound(String)
    case commitNotFound(String)
    case branchAlreadyExists(String)
    case mergeConflict(String)
    case noActiveBranch
    case notInitialized

    public var errorDescription: String? {
        switch self {
        case .branchNotFound(let name):
            return "Branch not found: \(name)"
        case .commitNotFound(let id):
            return "Commit not found: \(id)"
        case .branchAlreadyExists(let name):
            return "Branch already exists: \(name)"
        case .mergeConflict(let detail):
            return "Merge conflict: \(detail)"
        case .noActiveBranch:
            return "No active branch — use checkoutBranch() first"
        case .notInitialized:
            return "Version control not initialized"
        }
    }
}

// MARK: - Branch

/// A named pointer to the tip of a commit history, analogous to a Git/Dolt branch
public struct VCBranch: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public var headCommitId: UUID?
    /// The commit this branch was forked from; used for LCA computation during merges.
    public var baseCommitId: UUID?
    public let createdAt: Date
    public var isActive: Bool

    public init(id: UUID = UUID(), name: String, headCommitId: UUID? = nil,
                baseCommitId: UUID? = nil,
                createdAt: Date = Date(), isActive: Bool = false) {
        self.id = id
        self.name = name
        self.headCommitId = headCommitId
        self.baseCommitId = baseCommitId
        self.createdAt = createdAt
        self.isActive = isActive
    }
}

// MARK: - Commit

/// A saved snapshot of all documents at a point in time, analogous to a Dolt commit
public struct VCCommit: Codable, Identifiable {
    public let id: UUID
    public let branchId: UUID
    public let message: String
    public let authorId: String?
    public let timestamp: Date
    /// The primary parent commit (the commit this one was built on top of).
    public let parentCommitId: UUID?
    /// The second parent commit, set only for merge commits to preserve source-branch lineage.
    public let secondParentCommitId: UUID?

    public init(id: UUID = UUID(), branchId: UUID, message: String, authorId: String? = nil,
                timestamp: Date = Date(), parentCommitId: UUID? = nil,
                secondParentCommitId: UUID? = nil) {
        self.id = id
        self.branchId = branchId
        self.message = message
        self.authorId = authorId
        self.timestamp = timestamp
        self.parentCommitId = parentCommitId
        self.secondParentCommitId = secondParentCommitId
    }
}

// MARK: - Document Snapshot

/// A snapshot of a single document captured inside a commit
public struct VCDocumentSnapshot: Codable, Identifiable {
    public let id: UUID
    public let commitId: UUID
    public let documentId: UUID
    public let title: String
    public let content: String
    public let category: String
    public let wordCount: Int
    public let capturedAt: Date

    public init(id: UUID = UUID(), commitId: UUID, documentId: UUID, title: String,
                content: String, category: String, wordCount: Int, capturedAt: Date = Date()) {
        self.id = id
        self.commitId = commitId
        self.documentId = documentId
        self.title = title
        self.content = content
        self.category = category
        self.wordCount = wordCount
        self.capturedAt = capturedAt
    }
}

// MARK: - Diff

/// The type of change a document underwent between two commits
public enum VCChangeType: String, Codable {
    case added
    case modified
    case deleted
    case unchanged
}

/// A diff entry for one document between two commits or branches
public struct VCDiff: Codable, Identifiable {
    public let id: UUID
    public let documentId: UUID
    public let title: String
    public let changeType: VCChangeType
    public let fromContent: String?
    public let toContent: String?
    public let fromWordCount: Int?
    public let toWordCount: Int?

    public init(id: UUID = UUID(), documentId: UUID, title: String, changeType: VCChangeType,
                fromContent: String? = nil, toContent: String? = nil,
                fromWordCount: Int? = nil, toWordCount: Int? = nil) {
        self.id = id
        self.documentId = documentId
        self.title = title
        self.changeType = changeType
        self.fromContent = fromContent
        self.toContent = toContent
        self.fromWordCount = fromWordCount
        self.toWordCount = toWordCount
    }

    /// Word count delta between the two versions
    public var wordCountDelta: Int {
        (toWordCount ?? 0) - (fromWordCount ?? 0)
    }
}

// MARK: - Merge Result

/// Result of merging one branch into another
public struct VCMergeResult: Codable {
    public let fromBranch: String
    public let intoBranch: String
    public let strategy: MergeStrategy
    public let commitId: UUID?
    public let diffCount: Int
    public let success: Bool

    public enum MergeStrategy: String, Codable {
        case fastForward = "fast-forward"
        case threeWay    = "three-way"
    }

    public init(fromBranch: String, intoBranch: String, strategy: MergeStrategy,
                commitId: UUID? = nil, diffCount: Int, success: Bool) {
        self.fromBranch = fromBranch
        self.intoBranch = intoBranch
        self.strategy = strategy
        self.commitId = commitId
        self.diffCount = diffCount
        self.success = success
    }
}
