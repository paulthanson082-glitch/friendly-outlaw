import Foundation

// MARK: - VolumeManager

public actor VolumeManager {
    private var volumes: [String: VolumeInfo] = [:]
    private var loaded = false

    public init() {}

    // MARK: - Load / Save

    public func load() throws {
        guard !loaded else { return }
        try MockerConfig.ensureDirectories()
        let all = try MockerPersistence.loadAll(VolumeInfo.self, fromDirectory: MockerConfig.volumesDir)
        for vol in all {
            volumes[vol.name] = vol
        }
        loaded = true
    }

    private func save(_ volume: VolumeInfo) throws {
        try MockerPersistence.save(volume, to: MockerConfig.volumePath(name: volume.name))
    }

    // MARK: - Create

    public func create(
        name: String? = nil,
        driver: String = "local",
        labels: [String: String] = [:],
        options: [String: String] = [:]
    ) throws -> VolumeInfo {
        try load()
        let volumeName = name ?? generateName()
        if volumes[volumeName] != nil {
            throw MockerError.commandFailed("volume \"\(volumeName)\" already exists", 1)
        }
        let mountpoint = MockerConfig.volumesDir + "/" + volumeName + "/_data"
        try FileManager.default.createDirectory(atPath: mountpoint, withIntermediateDirectories: true)
        let volume = VolumeInfo(
            name: volumeName,
            driver: driver,
            mountpoint: mountpoint,
            labels: labels,
            options: options
        )
        volumes[volumeName] = volume
        try save(volume)
        return volume
    }

    // MARK: - Remove

    public func remove(_ name: String, force: Bool = false) throws -> String {
        try load()
        guard let volume = volumes[name] else {
            throw MockerError.volumeNotFound(name)
        }
        volumes.removeValue(forKey: name)
        try MockerPersistence.delete(at: MockerConfig.volumePath(name: name))
        // Remove data directory
        try? FileManager.default.removeItem(atPath: volume.mountpoint)
        return name
    }

    // MARK: - List

    public func getAll() -> [VolumeInfo] {
        Array(volumes.values).sorted { $0.name < $1.name }
    }

    // MARK: - Inspect

    public func inspect(_ names: [String]) throws -> String {
        try load()
        var results: [VolumeInfo] = []
        for name in names {
            guard let vol = volumes[name] else {
                throw MockerError.volumeNotFound(name)
            }
            results.append(vol)
        }
        return try MockerPersistence.toJSONString(results)
    }

    // MARK: - Find

    public func find(_ name: String) -> VolumeInfo? {
        volumes[name]
    }

    // MARK: - Prune

    public func prune() throws -> (count: Int, spaceSaved: String) {
        try load()
        let all = Array(volumes.values)
        var count = 0
        for vol in all {
            try? remove(vol.name)
            count += 1
        }
        return (count, "0B")
    }

    // MARK: - Helpers

    private func generateName() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(24).description
    }
}
