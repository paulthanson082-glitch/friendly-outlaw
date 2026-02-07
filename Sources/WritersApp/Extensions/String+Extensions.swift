import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension String {
    /// Counts sentences in the string
    var sentenceCount: Int {
        // Simple sentence counting by looking for sentence-ending punctuation followed by space or end of string
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        
        let pattern = "[.!?]+(?=\\s|$)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            // Fallback: count sentence endings using a single regex-like approach
            let pattern = CharacterSet(charactersIn: ".!?")
            let components = self.components(separatedBy: pattern)
            let nonEmpty = components.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            return max(0, nonEmpty.count)
        }
        
        let matches = regex.matches(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count))
        // Return the count of matches; if no punctuation found but text exists, count as 1 sentence
        return matches.isEmpty ? 1 : matches.count
    }

    /// Counts paragraphs in the string
    var paragraphCount: Int {
        return components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    /// Removes template placeholder syntax
    func removingPlaceholders() -> String {
        return replacingOccurrences(of: "\\{\\{[^}]+\\}\\}", with: "", options: .regularExpression)
    }

    /// Extracts all placeholders from template content
    func extractPlaceholders() -> [String] {
        let pattern = "\\{\\{([^}]+)\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: self) else { return nil }
            return String(self[range])
        }
    }
}
