import Foundation

// MARK: - ImageInfo

public struct ImageInfo: Codable, Sendable, Identifiable {
    public let id: String
    public var repository: String
    public var tag: String
    public var digest: String?
    public var createdAt: Date
    public var size: Int64
    public var labels: [String: String]
    public var architecture: String
    public var os: String

    public init(
        id: String = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased(),
        repository: String,
        tag: String = "latest",
        digest: String? = nil,
        createdAt: Date = Date(),
        size: Int64 = 0,
        labels: [String: String] = [:],
        architecture: String = "arm64",
        os: String = "linux"
    ) {
        self.id = id
        self.repository = repository
        self.tag = tag
        self.digest = digest
        self.createdAt = createdAt
        self.size = size
        self.labels = labels
        self.architecture = architecture
        self.os = os
    }

    /// Returns a shortened image ID suitable for display:
    /// - IDs in digest form `sha256:<hex>` strip the prefix and return the first 12 hex characters.
    /// - IDs with a bare `sha256` prefix but no colon return the first 14 characters.
    /// - All other IDs return the first 12 characters (Docker short-ID convention).
    public var shortId: String {
        let digestPrefix = "sha256:"
        if id.hasPrefix(digestPrefix) {
            return String(id.dropFirst(digestPrefix.count).prefix(12))
        }
        if id.hasPrefix("sha256") {
            return String(id.prefix(12))
        }
        return String(id.prefix(12))
    }

    /// Full image reference e.g. "nginx:1.25"
    public var reference: String {
        "\(repository):\(tag)"
    }

    /// Human-readable size
    public var sizeDescription: String {
        formatBytes(size)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024
        if gb >= 1 { return String(format: "%.2f GB", gb) }
        if mb >= 1 { return String(format: "%.2f MB", mb) }
        if kb >= 1 { return String(format: "%.2f kB", kb) }
        return "\(bytes) B"
    }

    /// Parse image reference into repository and tag
    public static func parseReference(_ ref: String) -> (repository: String, tag: String) {
        // Handle digest references like name@sha256:...
        if ref.contains("@") {
            let parts = ref.split(separator: "@", maxSplits: 1)
            return (String(parts[0]), "latest")
        }
        // Handle registry/repo:tag
        let colonIndex = ref.lastIndex(of: ":")
        if let idx = colonIndex {
            // Make sure it's not a registry port (e.g. registry:5000/repo)
            let afterColon = String(ref[ref.index(after: idx)...])
            if afterColon.contains("/") {
                return (ref, "latest")
            }
            return (String(ref[..<idx]), afterColon)
        }
        return (ref, "latest")
    }
}

// MARK: - BuildOptions

public struct BuildOptions: Sendable {
    public var tag: String?
    public var file: String?
    public var buildArgs: [String: String]
    public var noCache: Bool
    public var pull: Bool
    public var target: String?
    public var platform: String?
    public var cacheFrom: [String]
    public var load: Bool
    public var push: Bool
    public var labels: [String: String]
    public var quiet: Bool

    public init(
        tag: String? = nil,
        file: String? = nil,
        buildArgs: [String: String] = [:],
        noCache: Bool = false,
        pull: Bool = false,
        target: String? = nil,
        platform: String? = nil,
        cacheFrom: [String] = [],
        load: Bool = false,
        push: Bool = false,
        labels: [String: String] = [:],
        quiet: Bool = false
    ) {
        self.tag = tag
        self.file = file
        self.buildArgs = buildArgs
        self.noCache = noCache
        self.pull = pull
        self.target = target
        self.platform = platform
        self.cacheFrom = cacheFrom
        self.load = load
        self.push = push
        self.labels = labels
        self.quiet = quiet
    }
}
