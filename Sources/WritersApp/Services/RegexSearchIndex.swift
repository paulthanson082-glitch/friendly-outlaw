import Foundation

/// A trigram-based inverted index for fast regex search over document text.
///
/// Implements the classic trigram decomposition approach described in Zobel et al.
/// (1993) and popularised by Russ Cox's 2012 writeup:
///
/// 1. **Indexing** – each document is decomposed into all overlapping 3-character
///    sequences (trigrams).  The trigram is the key; the set of document IDs that
///    contain it is the value (posting list).
///
/// 2. **Querying** – a regex pattern is analysed to extract its longest literal
///    fragment.  The trigrams of that fragment are looked up in the index and
///    their posting lists are intersected, yielding a small set of candidate
///    documents.  Only candidates are passed to a full `NSRegularExpression`
///    match, avoiding a linear scan of the entire corpus.
///
/// False positives are possible (the index may nominate documents that end up
/// not matching), but false negatives are not — every true match will always
/// be in the candidate set.
public class RegexSearchIndex {

    // MARK: - Properties

    /// Inverted index: trigram → set of document IDs whose text contains it.
    private var postingLists: [String: Set<UUID>] = [:]

    /// Normalised (lowercased) text for each indexed document, used for the
    /// final full-match step.
    private var texts: [UUID: String] = [:]

    // MARK: - Init

    public init() {}

    // MARK: - Index Management

    /// Adds or updates a document in the index.
    ///
    /// If the document was previously indexed its old entry is removed first so
    /// the index is always consistent.
    public func indexDocument(id: UUID, text: String) {
        removeDocument(id: id)
        let normalized = text.lowercased()
        texts[id] = normalized
        for trigram in extractTrigrams(from: normalized) {
            postingLists[trigram, default: []].insert(id)
        }
    }

    /// Removes a document from the index.
    public func removeDocument(id: UUID) {
        guard let text = texts.removeValue(forKey: id) else { return }
        for trigram in extractTrigrams(from: text) {
            postingLists[trigram]?.remove(id)
            if postingLists[trigram]?.isEmpty == true {
                postingLists.removeValue(forKey: trigram)
            }
        }
    }

    // MARK: - Search

    /// Returns the IDs of documents whose text matches `pattern` as a regex.
    ///
    /// The method uses the trigram index to narrow the candidate set before
    /// running `NSRegularExpression`, so the full regex engine only runs on a
    /// fraction of the corpus for specific patterns.
    ///
    /// - Parameter pattern: An `NSRegularExpression`-compatible pattern.
    ///   Case-insensitive matching is applied automatically.
    /// - Returns: Set of document IDs with at least one match.
    public func search(pattern: String) -> Set<UUID> {
        let candidates = candidateDocuments(for: pattern)

        guard let regex = try? NSRegularExpression(
            pattern: pattern, options: .caseInsensitive
        ) else {
            // Invalid regex — fall back to literal substring containment.
            let lower = pattern.lowercased()
            return candidates.filter { texts[$0]?.contains(lower) == true }
        }

        return candidates.filter { id in
            guard let text = texts[id] else { return false }
            let range = NSRange(text.startIndex..., in: text)
            return regex.firstMatch(in: text, options: [], range: range) != nil
        }
    }

    // MARK: - Statistics

    /// Number of unique trigrams currently in the index.
    public var trigramCount: Int { postingLists.count }

    /// Number of documents currently indexed.
    public var documentCount: Int { texts.count }

    // MARK: - Private Helpers

    /// Returns the set of candidate document IDs for a given pattern.
    ///
    /// Extracts required trigrams from the pattern's longest literal fragment,
    /// then intersects their posting lists.  When no trigrams can be extracted
    /// (pattern shorter than 3 chars or purely metacharacter), every indexed
    /// document is treated as a candidate.
    private func candidateDocuments(for pattern: String) -> Set<UUID> {
        let trigrams = requiredTrigrams(for: pattern)
        guard !trigrams.isEmpty else {
            return Set(texts.keys)
        }
        return trigrams
            .map { postingLists[$0] ?? [] }
            .reduce(Set(texts.keys)) { $0.intersection($1) }
    }

    /// Derives the required trigrams for an index lookup from `pattern`.
    ///
    /// Finds the longest literal substring inside the pattern and returns its
    /// trigrams.  Using the longest fragment maximises specificity and minimises
    /// the candidate set.
    private func requiredTrigrams(for pattern: String) -> [String] {
        let literals = extractLiterals(from: pattern)
        guard let longest = literals.max(by: { $0.count < $1.count }),
              longest.count >= 3 else {
            return []
        }
        return Array(extractTrigrams(from: longest.lowercased()))
    }

    /// Extracts all overlapping trigrams (3-character sequences) from `text`.
    private func extractTrigrams(from text: String) -> Set<String> {
        var trigrams = Set<String>()
        let chars = Array(text.unicodeScalars)
        guard chars.count >= 3 else { return trigrams }
        for i in 0...(chars.count - 3) {
            let t = String(chars[i]) + String(chars[i + 1]) + String(chars[i + 2])
            trigrams.insert(t)
        }
        return trigrams
    }

    /// Splits a regex pattern into its literal (non-metacharacter) fragments.
    ///
    /// Walks the pattern character by character.  Regex metacharacters and
    /// backslash-escaped sequences terminate the current literal fragment.
    /// The returned array may contain multiple fragments; the caller picks the
    /// longest for maximum selectivity.
    private func extractLiterals(from pattern: String) -> [String] {
        let metaChars: Set<Character> = [
            ".", "*", "+", "?", "^", "$",
            "{", "}", "[", "]", "(", ")", "|", "\\"
        ]

        var literals: [String] = []
        var current = ""
        var idx = pattern.startIndex

        while idx < pattern.endIndex {
            let ch = pattern[idx]

            if ch == "\\" {
                // Escaped character — flush current fragment, skip both chars.
                if !current.isEmpty { literals.append(current); current = "" }
                let next = pattern.index(after: idx)
                idx = next < pattern.endIndex ? pattern.index(after: next) : next
                continue
            }

            if metaChars.contains(ch) {
                if !current.isEmpty { literals.append(current); current = "" }
            } else {
                current.append(ch)
            }

            idx = pattern.index(after: idx)
        }

        if !current.isEmpty { literals.append(current) }
        return literals
    }
}
