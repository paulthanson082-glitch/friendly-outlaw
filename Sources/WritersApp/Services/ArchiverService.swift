import Foundation

// MARK: - Archiver Service

/// Archiver — Agent Profile for Organizing and Preserving Creative Work
///
/// The Archiver helps writers organize completed documents, preserve milestones,
/// create thematic collections, summarize past work, and resurface relevant archived
/// material when needed. It operates alongside Hermes as a complementary agent focused
/// on retrospective organization and knowledge preservation.
///
/// Usage:
/// ```swift
/// let archiver = ArchiverService(aiService: aiService, documentManager: docMgr)
/// archiver.createCollection(name: "Fantasy Shorts", theme: "fantasy")
/// let snapshot = try await archiver.preserveMilestone(
///     documentId: doc.id,
///     title: doc.title,
///     wordCount: 5000,
///     daysStreak: 7
/// )
/// ```
public class ArchiverService {

    // MARK: - Public Properties

    public var profile: ArchiverProfile
    public let documentManager: DocumentManager

    // MARK: - Private Properties

    private let aiService: AIService?
    private let archiverPersona = """
        You are the Archiver, a wise and methodical curator of creative work. Your role is to \
        preserve, organize, and illuminate the writer's journey. You excel at:
        1. Organizing work into meaningful collections and themes
        2. Summarizing the essence of completed projects
        3. Identifying patterns and recurring elements across the writer's body of work
        4. Surfacing forgotten ideas that connect to current projects
        5. Celebrating milestones and preserving memorable moments

        When summarizing work, be concise but evocative. When tagging, be consistent and \
        interconnected. When recommending archived material, show the relevance clearly.
        You are systematic, patient, and celebrate the writer's growth.
        """

    // MARK: - Initialization

    public init(
        aiService: AIService? = nil,
        documentManager: DocumentManager,
        profile: ArchiverProfile = ArchiverProfile()
    ) {
        self.aiService = aiService
        self.documentManager = documentManager
        self.profile = profile
    }

    // MARK: - Collections

    /// Creates a new named collection for organizing archived work.
    /// - Parameters:
    ///   - name: The collection's display name.
    ///   - description: Optional description of the collection's theme or purpose.
    ///   - theme: Optional visual theme identifier (default: "default").
    ///   - tags: Optional tags to categorize the collection.
    /// - Returns: The created `ArchiveCollection`.
    public func createCollection(
        name: String,
        description: String = "",
        theme: String = "default",
        tags: [String] = []
    ) -> ArchiveCollection {
        let collection = ArchiveCollection(
            name: name,
            description: description,
            tags: tags,
            theme: theme
        )
        profile.collections.append(collection)
        return collection
    }

    /// Retrieves a collection by ID.
    /// - Parameter id: The collection's UUID.
    /// - Returns: The matching `ArchiveCollection`, or nil if not found.
    public func getCollection(_ id: UUID) -> ArchiveCollection? {
        return profile.collections.first { $0.id == id }
    }

    /// Adds a document to a collection.
    /// - Parameters:
    ///   - documentId: The document to archive.
    ///   - collectionId: The target collection.
    public func addDocumentToCollection(_ documentId: UUID, collectionId: UUID) {
        guard var collection = getCollection(collectionId) else { return }
        if !collection.documentIds.contains(documentId) {
            collection.documentIds.append(documentId)
            collection.updatedAt = Date()
            if let idx = profile.collections.firstIndex(where: { $0.id == collectionId }) {
                profile.collections[idx] = collection
            }
        }
    }

    /// Removes a document from a collection.
    /// - Parameters:
    ///   - documentId: The document to remove.
    ///   - collectionId: The collection to remove it from.
    public func removeDocumentFromCollection(_ documentId: UUID, collectionId: UUID) {
        guard var collection = getCollection(collectionId) else { return }
        collection.documentIds.removeAll { $0 == documentId }
        collection.updatedAt = Date()
        if let idx = profile.collections.firstIndex(where: { $0.id == collectionId }) {
            profile.collections[idx] = collection
        }
    }

    /// Lists all collections.
    /// - Returns: An array of all `ArchiveCollection`s in the profile.
    public func listCollections() -> [ArchiveCollection] {
        return profile.collections
    }

    /// Deletes a collection by ID.
    /// - Parameter id: The collection to delete.
    public func deleteCollection(_ id: UUID) {
        profile.collections.removeAll { $0.id == id }
    }

    // MARK: - Snapshots

    /// Preserves a milestone as an archive snapshot.
    /// - Parameters:
    ///   - documentId: The document associated with this milestone.
    ///   - title: A descriptive title for the snapshot.
    ///   - wordCount: Word count at the time of the snapshot.
    ///   - characterCount: Character count at the time of the snapshot.
    ///   - sessionCount: Number of writing sessions completed.
    ///   - daysStreak: Current writing streak length.
    ///   - summary: AI-generated or manual summary of what was accomplished.
    ///   - tags: Optional tags for organizing the snapshot.
    /// - Returns: The created `ArchiveSnapshot`.
    public func preserveMilestone(
        documentId: UUID,
        title: String,
        wordCount: Int = 0,
        characterCount: Int = 0,
        sessionCount: Int = 0,
        daysStreak: Int = 0,
        summary: String = "",
        tags: [String] = []
    ) -> ArchiveSnapshot {
        let snapshot = ArchiveSnapshot(
            documentId: documentId,
            wordCount: wordCount,
            characterCount: characterCount,
            sessionCount: sessionCount,
            daysStreak: daysStreak,
            title: title,
            summary: summary,
            tags: tags
        )
        profile.snapshots.append(snapshot)
        profile.lastArchiveAt = Date()
        return snapshot
    }

    /// Retrieves a snapshot by ID.
    /// - Parameter id: The snapshot's UUID.
    /// - Returns: The matching `ArchiveSnapshot`, or nil if not found.
    public func getSnapshot(_ id: UUID) -> ArchiveSnapshot? {
        return profile.snapshots.first { $0.id == id }
    }

    /// Gets all snapshots for a specific document.
    /// - Parameter documentId: The document to filter by.
    /// - Returns: An array of `ArchiveSnapshot`s for that document, in chronological order.
    public func getSnapshots(forDocument documentId: UUID) -> [ArchiveSnapshot] {
        return profile.snapshots
            .filter { $0.documentId == documentId }
            .sorted { $0.timestamp < $1.timestamp }
    }

    /// Lists all snapshots in the archive.
    /// - Returns: An array of all `ArchiveSnapshot`s.
    public func listSnapshots() -> [ArchiveSnapshot] {
        return profile.snapshots.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Organization & Tagging

    /// Organizes documents by automatically tagging and categorizing them.
    /// Uses AI to generate meaningful tags if aiService is available.
    /// - Parameters:
    ///   - documentIds: Documents to organize.
    ///   - context: Optional `ArchiverContext` for filtering/prioritization.
    /// - Returns: A dictionary mapping document IDs to generated tags.
    public func organizeByTags(
        _ documentIds: [UUID],
        context: ArchiverContext = ArchiverContext()
    ) async throws -> [UUID: [String]] {
        var results: [UUID: [String]] = [:]

        for docId in documentIds {
            guard let doc = documentManager.getDocument(id: docId) else {
                results[docId] = []
                continue
            }

            var tags = doc.metadata.tags
            if let aiService = aiService {
                let prompt = """
                    Generate 3-5 concise, interconnected tags for this writing project:
                    Title: \(doc.title)
                    Content excerpt: \(doc.content.prefix(500))

                    Return only the tags as a comma-separated list.
                    """
                do {
                    let aiTags = try await aiService.getAssistance(
                        text: prompt,
                        type: .custom("generate_tags")
                    )
                    tags.append(contentsOf: aiTags.generatedContent
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    )
                    tags = Array(Set(tags)).sorted()
                } catch {
                    // Silently fall back to existing tags
                }
            }
            results[docId] = tags
        }

        return results
    }

    // MARK: - Summarization

    /// Generates an AI-powered summary of a document for the archive.
    /// - Parameter documentId: The document to summarize.
    /// - Returns: A summary string, or empty string if AI is unavailable.
    public func summarizeDocument(_ documentId: UUID) async throws -> String {
        guard let doc = documentManager.getDocument(id: documentId) else {
            return ""
        }
        guard let aiService = aiService else {
            return ""
        }

        let prompt = """
            Summarize this creative work in 2–3 sentences for an archive.
            Capture the essence: what is it about, what makes it memorable?

            Title: \(doc.title)
            Content: \(doc.content)
            """

        do {
            let response = try await aiService.getAssistance(
                text: prompt,
                type: .summarize
            )
            return response.generatedContent
        } catch {
            return ""
        }
    }

    // MARK: - Retrieval & Recommendations

    /// Searches the archive for documents and snapshots matching a query.
    /// Searches across titles, summaries, and tags.
    /// - Parameters:
    ///   - query: Search query string.
    ///   - limit: Maximum number of results to return.
    /// - Returns: A tuple of matching (documents, snapshots, collections).
    public func search(
        _ query: String,
        limit: Int = 10
    ) -> (documents: [Document], snapshots: [ArchiveSnapshot], collections: [ArchiveCollection]) {
        let lowerQuery = query.lowercased()

        let matchingDocs = Array(profile.collections
            .flatMap { col in col.documentIds.compactMap { documentManager.getDocument(id: $0) } }
            .filter { doc in
                doc.title.lowercased().contains(lowerQuery) ||
                doc.content.lowercased().contains(lowerQuery) ||
                doc.metadata.tags.contains { $0.lowercased().contains(lowerQuery) }
            }
            .prefix(limit))

        let matchingSnapshots = Array(profile.snapshots
            .filter { snap in
                snap.title.lowercased().contains(lowerQuery) ||
                snap.summary.lowercased().contains(lowerQuery) ||
                snap.tags.contains { $0.lowercased().contains(lowerQuery) }
            }
            .prefix(limit))

        let matchingCollections = Array(profile.collections
            .filter { col in
                col.name.lowercased().contains(lowerQuery) ||
                col.description.lowercased().contains(lowerQuery) ||
                col.tags.contains { $0.lowercased().contains(lowerQuery) }
            }
            .prefix(limit))

        return (matchingDocs, matchingSnapshots, matchingCollections)
    }

    /// Suggests archived documents relevant to the current work.
    /// Uses simple keyword overlap; AI-powered matching requires aiService.
    /// - Parameters:
    ///   - currentDocumentId: The document to find related work for.
    ///   - limit: Maximum suggestions to return.
    /// - Returns: An array of related `Document`s from the archive.
    public func suggestRelated(
        to currentDocumentId: UUID,
        limit: Int = 5
    ) async -> [Document] {
        guard let current = documentManager.getDocument(id: currentDocumentId) else {
            return []
        }

        let archived = profile.collections
            .flatMap { col in col.documentIds.compactMap { documentManager.getDocument(id: $0) } }
            .filter { $0.id != currentDocumentId }

        var scored: [(doc: Document, score: Int)] = []
        let currentTags = Set(current.metadata.tags)

        for doc in archived {
            var score = 0
            let docTags = Set(doc.metadata.tags)
            score += docTags.intersection(currentTags).count * 10
            let currentTitlePrefix = String(current.title.lowercased().prefix(3))
            if doc.title.lowercased().contains(currentTitlePrefix) {
                score += 5
            }
            if score > 0 {
                scored.append((doc, score))
            }
        }

        return Array(scored
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.doc })
    }

    // MARK: - Statistics

    /// Computes archive statistics.
    /// - Returns: A dictionary of aggregate stats (collection count, snapshot count, etc.).
    public func getArchiveStats() -> [String: Any] {
        let allDocs = Set(profile.collections.flatMap { $0.documentIds })
        let totalWords = allDocs
            .compactMap { documentManager.getDocument(id: $0) }
            .reduce(0) { $0 + $1.content.split(separator: " ").count }

        return [
            "collectionCount": profile.collections.count,
            "snapshotCount": profile.snapshots.count,
            "archivedDocumentCount": allDocs.count,
            "totalWordsArchived": totalWords,
            "createdAt": profile.createdAt,
            "lastArchiveAt": profile.lastArchiveAt ?? profile.createdAt
        ]
    }
}
