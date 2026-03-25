import Foundation

// MARK: - VolumeInfo

public struct VolumeInfo: Codable, Sendable, Identifiable {
    public let name: String
    public var driver: String
    public var mountpoint: String
    public var createdAt: Date
    public var labels: [String: String]
    public var options: [String: String]
    public var scope: String

    public var id: String { name }

    public init(
        name: String,
        driver: String = "local",
        mountpoint: String = "",
        createdAt: Date = Date(),
        labels: [String: String] = [:],
        options: [String: String] = [:],
        scope: String = "local"
    ) {
        self.name = name
        self.driver = driver
        self.mountpoint = mountpoint.isEmpty ? MockerConfig.volumesDir + "/" + name + "/_data" : mountpoint
        self.createdAt = createdAt
        self.labels = labels
        self.options = options
        self.scope = scope
    }
}
