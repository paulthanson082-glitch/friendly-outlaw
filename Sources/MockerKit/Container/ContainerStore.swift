import Foundation

// MARK: - ContainerStore

/// Thread-safe actor for container metadata persistence
public actor ContainerStore {
    private var containers: [String: ContainerInfo] = [:]
    private var loaded = false

    public init() {}

    // MARK: - Load / Save

    public func load() throws {
        guard !loaded else { return }
        try MockerConfig.ensureDirectories()
        let all = try MockerPersistence.loadAll(ContainerInfo.self, fromDirectory: MockerConfig.containersDir)
        for c in all {
            containers[c.id] = c
        }
        loaded = true
    }

    private func save(_ container: ContainerInfo) throws {
        try MockerPersistence.save(container, to: MockerConfig.containerPath(id: container.id))
    }

    // MARK: - CRUD

    public func add(_ container: ContainerInfo) throws {
        try MockerConfig.ensureDirectories()
        containers[container.id] = container
        try save(container)
    }

    public func update(_ container: ContainerInfo) throws {
        try MockerConfig.ensureDirectories()
        containers[container.id] = container
        try save(container)
    }

    public func remove(id: String) throws {
        containers.removeValue(forKey: id)
        try MockerPersistence.delete(at: MockerConfig.containerPath(id: id))
    }

    public func get(id: String) -> ContainerInfo? {
        containers[id]
    }

    public func getAll() -> [ContainerInfo] {
        Array(containers.values).sorted { $0.createdAt > $1.createdAt }
    }

    public func getRunning() -> [ContainerInfo] {
        getAll().filter { $0.status == .running }
    }

    // MARK: - Lookup

    /// Find container by full ID, short ID, or name
    public func find(_ identifier: String) -> ContainerInfo? {
        // Exact ID match
        if let c = containers[identifier] { return c }
        // Name match
        if let c = containers.values.first(where: { $0.name == identifier }) { return c }
        // Prefix match on ID (short ID)
        if let c = containers.values.first(where: { $0.id.hasPrefix(identifier) }) { return c }
        return nil
    }

    /// Find multiple containers by identifiers
    public func findAll(_ identifiers: [String]) -> [ContainerInfo] {
        identifiers.compactMap { find($0) }
    }

    /// Check if name is already taken
    public func nameExists(_ name: String) -> Bool {
        containers.values.contains { $0.name == name }
    }
}
