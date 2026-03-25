import Foundation

// MARK: - NetworkManager

public actor NetworkManager {
    private var networks: [String: NetworkInfo] = [:]
    private var loaded = false

    public init() {}

    // MARK: - Load / Save

    public func load() throws {
        guard !loaded else { return }
        try MockerConfig.ensureDirectories()
        let all = try MockerPersistence.loadAll(NetworkInfo.self, fromDirectory: MockerConfig.networksDir)
        for net in all {
            networks[net.id] = net
        }
        // Ensure default networks are present
        for defaultNet in [NetworkInfo.bridge, NetworkInfo.host, NetworkInfo.none] {
            if networks[defaultNet.id] == nil {
                networks[defaultNet.id] = defaultNet
                try? MockerPersistence.save(defaultNet, to: MockerConfig.networkPath(id: defaultNet.id))
            }
        }
        loaded = true
    }

    private func save(_ network: NetworkInfo) throws {
        try MockerPersistence.save(network, to: MockerConfig.networkPath(id: network.id))
    }

    // MARK: - Create

    public func create(
        name: String,
        driver: String = "bridge",
        subnet: String? = nil,
        gateway: String? = nil,
        labels: [String: String] = [:],
        options: [String: String] = [:]
    ) throws -> NetworkInfo {
        try load()
        if let existing = networks.values.first(where: { $0.name == name }) {
            _ = existing
            throw MockerError.commandFailed("network with name \(name) already exists", 1)
        }
        let ipam = IPAMConfig(driver: "default", subnet: subnet, gateway: gateway)
        let network = NetworkInfo(name: name, driver: driver, ipam: ipam, labels: labels, options: options)
        networks[network.id] = network
        try save(network)
        return network
    }

    // MARK: - Remove

    public func remove(_ identifier: String) throws -> String {
        try load()
        guard let network = find(identifier) else {
            throw MockerError.networkNotFound(identifier)
        }
        // Prevent removing default networks
        if ["bridge", "host", "none"].contains(network.name) {
            throw MockerError.commandFailed("network \(network.name) id \(network.shortId) is a pre-defined network and cannot be removed", 1)
        }
        networks.removeValue(forKey: network.id)
        try MockerPersistence.delete(at: MockerConfig.networkPath(id: network.id))
        return identifier
    }

    // MARK: - Connect / Disconnect

    public func connect(network identifier: String, container: ContainerInfo) throws {
        try load()
        guard var network = find(identifier) else {
            throw MockerError.networkNotFound(identifier)
        }
        let connected = ConnectedContainer(
            containerId: container.id,
            name: container.name,
            ipAddress: generateIP()
        )
        network.connectedContainers[container.id] = connected
        networks[network.id] = network
        try save(network)
    }

    public func disconnect(network identifier: String, containerId: String) throws {
        try load()
        guard var network = find(identifier) else {
            throw MockerError.networkNotFound(identifier)
        }
        network.connectedContainers.removeValue(forKey: containerId)
        networks[network.id] = network
        try save(network)
    }

    // MARK: - List

    public func getAll() -> [NetworkInfo] {
        Array(networks.values).sorted { $0.name < $1.name }
    }

    // MARK: - Inspect

    public func inspect(_ identifiers: [String]) throws -> String {
        try load()
        var results: [NetworkInfo] = []
        for ident in identifiers {
            guard let net = find(ident) else {
                throw MockerError.networkNotFound(ident)
            }
            results.append(net)
        }
        return try MockerPersistence.toJSONString(results)
    }

    // MARK: - Lookup

    public func find(_ identifier: String) -> NetworkInfo? {
        if let n = networks[identifier] { return n }
        if let n = networks.values.first(where: { $0.name == identifier }) { return n }
        if let n = networks.values.first(where: { $0.id.hasPrefix(identifier) }) { return n }
        return nil
    }

    // MARK: - Helpers

    private func generateIP() -> String {
        let last = Int.random(in: 2..<254)
        return "172.17.0.\(last)"
    }
}
