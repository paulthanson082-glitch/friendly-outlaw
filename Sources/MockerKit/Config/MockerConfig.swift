import Foundation

// MARK: - MockerConfig

public enum MockerConfig {
    /// Root directory for all Mocker state: ~/.mocker/
    public static var rootDir: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return home + "/.mocker"
    }

    public static var containersDir: String { rootDir + "/containers" }
    public static var imagesDir: String { rootDir + "/images" }
    public static var networksDir: String { rootDir + "/networks" }
    public static var volumesDir: String { rootDir + "/volumes" }

    /// Path to Apple container CLI
    public static let containerCLI = "/usr/local/bin/container"

    /// Ensure all directories exist
    public static func ensureDirectories() throws {
        let fm = FileManager.default
        for dir in [containersDir, imagesDir, networksDir, volumesDir] {
            try fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
    }

    /// Path for a container JSON file
    public static func containerPath(id: String) -> String {
        containersDir + "/" + id + ".json"
    }

    /// Path for an image JSON file
    public static func imagePath(id: String) -> String {
        imagesDir + "/" + id + ".json"
    }

    /// Path for a network JSON file
    public static func networkPath(id: String) -> String {
        networksDir + "/" + id + ".json"
    }

    /// Path for a volume JSON file
    public static func volumePath(name: String) -> String {
        volumesDir + "/" + name + ".json"
    }
}

// MARK: - JSON Persistence Helpers

public enum MockerPersistence {
    private static let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()

    private static let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    public static func save<T: Encodable>(_ value: T, to path: String) throws {
        let data = try encoder.encode(value)
        try data.write(to: URL(fileURLWithPath: path))
    }

    public static func load<T: Decodable>(_ type: T.Type, from path: String) throws -> T {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try decoder.decode(type, from: data)
    }

    public static func loadAll<T: Decodable>(_ type: T.Type, fromDirectory dir: String) throws -> [T] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: dir) else { return [] }
        let files = try fm.contentsOfDirectory(atPath: dir)
        return try files
            .filter { $0.hasSuffix(".json") }
            .compactMap { filename -> T? in
                let path = dir + "/" + filename
                return try? load(type, from: path)
            }
    }

    public static func delete(at path: String) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: path) {
            try fm.removeItem(atPath: path)
        }
    }

    /// Encode value to pretty-printed JSON string
    public static func toJSONString<T: Encodable>(_ value: T) throws -> String {
        let data = try encoder.encode(value)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
