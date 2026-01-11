import Foundation

extension String {
    /// Counts sentences in the string
    var sentenceCount: Int {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.orthography.rawValue)
        let matches = detector?.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
        return matches?.count ?? 0
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
