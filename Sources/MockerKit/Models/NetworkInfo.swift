import Foundation

// MARK: - NetworkInfo

public struct NetworkInfo: Codable, Sendable, Identifiable {
    public let id: String
    public var name: String
    public var driver: String
    public var scope: String
    public var ipam: IPAMConfig
    public var createdAt: Date
    public var labels: [String: String]
    public var options: [String: String]
    public var connectedContainers: [String: ConnectedContainer]

    public init(
        id: String = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased(),
        name: String,
        driver: String = "bridge",
        scope: String = "local",
        ipam: IPAMConfig = IPAMConfig(),
        createdAt: Date = Date(),
        labels: [String: String] = [:],
        options: [String: String] = [:],
        connectedContainers: [String: ConnectedContainer] = [:]
    ) {
        self.id = id
        self.name = name
        self.driver = driver
        self.scope = scope
        self.ipam = ipam
        self.createdAt = createdAt
        self.labels = labels
        self.options = options
        self.connectedContainers = connectedContainers
    }

    public var shortId: String {
        String(id.prefix(12))
    }
}

// MARK: - IPAMConfig

public struct IPAMConfig: Codable, Sendable {
    public var driver: String
    public var subnet: String?
    public var gateway: String?

    public init(driver: String = "default", subnet: String? = nil, gateway: String? = nil) {
        self.driver = driver
        self.subnet = subnet
        self.gateway = gateway
    }
}

// MARK: - ConnectedContainer

public struct ConnectedContainer: Codable, Sendable {
    public let containerId: String
    public let name: String
    public var ipAddress: String?
    public var macAddress: String?

    public init(containerId: String, name: String, ipAddress: String? = nil, macAddress: String? = nil) {
        self.containerId = containerId
        self.name = name
        self.ipAddress = ipAddress
        self.macAddress = macAddress
    }
}

// MARK: - Default networks

public extension NetworkInfo {
    static let bridge = NetworkInfo(
        id: "bridge000000000000000000000000000000000000000000000000000000000000",
        name: "bridge",
        driver: "bridge",
        scope: "local",
        ipam: IPAMConfig(driver: "default", subnet: "172.17.0.0/16", gateway: "172.17.0.1")
    )

    static let host = NetworkInfo(
        id: "host0000000000000000000000000000000000000000000000000000000000000000",
        name: "host",
        driver: "host",
        scope: "local"
    )

    static let none = NetworkInfo(
        id: "none0000000000000000000000000000000000000000000000000000000000000000",
        name: "none",
        driver: "null",
        scope: "local"
    )
}
