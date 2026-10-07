import Foundation

/// Manages spoiler tagging and protection for documents
public class SpoilerProtectionService {
    private var tags: [UUID: SpoilerTag] = [:]
    private let tagsLock = NSLock()

    public init() {}

    // MARK: - Tag Management

    /// Creates a spoiler tag for a character range within a document.
    /// Ranges are unicode-scalar offsets. startOffset must be >= 0 and < endOffset.
    /// Returns nil if the range is invalid.
    @discardableResult
    public func tagSpoiler(
        in documentId: UUID,
        startOffset: Int,
        endOffset: Int,
        description: String = "",
        severity: SpoilerSeverity = .moderate
    ) -> SpoilerTag? {
        guard startOffset >= 0, endOffset > startOffset else { return nil }
        let tag = SpoilerTag(
            documentId: documentId,
            startOffset: startOffset,
            endOffset: endOffset,
            description: description,
            severity: severity
        )
        tagsLock.lock()
        tags[tag.id] = tag
        tagsLock.unlock()
        return tag
    }

    /// Removes a spoiler tag by ID
    public func removeSpoilerTag(id: UUID) {
        tagsLock.lock()
        tags.removeValue(forKey: id)
        tagsLock.unlock()
    }

    /// Returns all spoiler tags for a document, sorted by start offset
    public func getSpoilerTags(forDocument documentId: UUID) -> [SpoilerTag] {
        tagsLock.lock()
        let snapshot = Array(tags.values)
        tagsLock.unlock()
        return snapshot
            .filter { $0.documentId == documentId }
            .sorted { $0.startOffset < $1.startOffset }
    }

    /// Returns all spoiler tags with a given severity
    public func getSpoilerTags(withSeverity severity: SpoilerSeverity) -> [SpoilerTag] {
        tagsLock.lock()
        let snapshot = Array(tags.values)
        tagsLock.unlock()
        return snapshot
            .filter { $0.severity == severity }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// Returns true if the document has any spoiler tags
    public func hasSpoilers(in documentId: UUID) -> Bool {
        tagsLock.lock()
        let hasAny = tags.values.contains { $0.documentId == documentId }
        tagsLock.unlock()
        return hasAny
    }

    // MARK: - Content Redaction

    /// Returns the document content with spoiler regions replaced by a redaction placeholder.
    /// Overlapping tags are handled safely: the cursor only moves forward.
    public func redactSpoilers(in content: String, document documentId: UUID) -> String {
        let documentTags = getSpoilerTags(forDocument: documentId)
        guard !documentTags.isEmpty else { return content }

        let characters = Array(content.unicodeScalars)
        var pieces: [String] = []
        var index = 0

        for tag in documentTags {
            let start = max(index, max(0, min(tag.startOffset, characters.count)))
            let end = max(start, min(tag.endOffset, characters.count))

            if index < start {
                pieces.append(String(String.UnicodeScalarView(characters[index..<start])))
            }

            if end > start {
                pieces.append("[SPOILER REDACTED]")
            }
            index = max(index, end)
        }

        if index < characters.count {
            pieces.append(String(String.UnicodeScalarView(characters[index...])))
        }

        return pieces.joined()
    }

    /// Returns the document content with spoiler regions wrapped in markup tags
    /// suitable for the given export format. Overlapping tags are handled safely.
    public func exportWithSpoilerMarkup(content: String, document documentId: UUID, format: SpoilerMarkupFormat = .markdown) -> String {
        let documentTags = getSpoilerTags(forDocument: documentId)
        guard !documentTags.isEmpty else { return content }

        let characters = Array(content.unicodeScalars)
        var pieces: [String] = []
        var index = 0

        for tag in documentTags {
            let start = max(index, max(0, min(tag.startOffset, characters.count)))
            let end = max(start, min(tag.endOffset, characters.count))

            if index < start {
                pieces.append(String(String.UnicodeScalarView(characters[index..<start])))
            }

            if end > start {
                let spoilerText = String(String.UnicodeScalarView(characters[start..<end]))
                pieces.append(format.wrap(spoilerText, severity: tag.severity))
            }
            index = max(index, end)
        }

        if index < characters.count {
            pieces.append(String(String.UnicodeScalarView(characters[index...])))
        }

        return pieces.joined()
    }
}

// MARK: - Markup Format

/// Output format for spoiler markup
public enum SpoilerMarkupFormat {
    case markdown
    case html
    case plainText

    func wrap(_ text: String, severity: SpoilerSeverity) -> String {
        switch self {
        case .markdown:
            return "||SPOILER(\(severity.rawValue)): \(text)||"
        case .html:
            let escaped = text
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
            return "<span class=\"spoiler spoiler-\(severity.rawValue)\">\(escaped)</span>"
        case .plainText:
            return "[SPOILER(\(severity.rawValue)): \(text)]"
        }
    }
}
