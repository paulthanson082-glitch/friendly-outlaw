import Foundation
import Yams

// MARK: - ComposeFile

public struct ComposeFile: Codable, Sendable {
    public var version: String?
    public var services: [String: ComposeService]
    public var networks: [String: ComposeNetwork]?
    public var volumes: [String: ComposeVolume?]?

    public init(
        version: String? = nil,
        services: [String: ComposeService] = [:],
        networks: [String: ComposeNetwork]? = nil,
        volumes: [String: ComposeVolume?]? = nil
    ) {
        self.version = version
        self.services = services
        self.networks = networks
        self.volumes = volumes
    }

    // MARK: - Load from file

    public static func load(from path: String) throws -> ComposeFile {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        return try loadFromString(content)
    }

    public static func loadFromString(_ yaml: String) throws -> ComposeFile {
        // Apply variable substitution
        let substituted = substituteVariables(yaml)
        let decoder = YAMLDecoder()
        return try decoder.decode(ComposeFile.self, from: substituted)
    }

    // MARK: - Variable substitution

    /// Handles ${VAR}, ${VAR:-default}, $VAR
    static func substituteVariables(_ content: String) -> String {
        var result = content
        let env = ProcessInfo.processInfo.environment

        // Handle ${VAR:-default} and ${VAR-default}
        let pattern = #"\$\{([^}:]+)(?::?-([^}]*))?\}"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, range: range).reversed()
            for match in matches {
                guard let fullRange = Range(match.range, in: result),
                      let nameRange = Range(match.range(at: 1), in: result) else { continue }
                let varName = String(result[nameRange])
                var replacement: String
                if let value = env[varName] {
                    replacement = value
                } else if match.numberOfRanges > 2, let defaultRange = Range(match.range(at: 2), in: result) {
                    replacement = String(result[defaultRange])
                } else {
                    replacement = ""
                }
                result.replaceSubrange(fullRange, with: replacement)
            }
        }

        // Handle $VAR (simple)
        for (key, value) in env.sorted(by: { $0.key.count > $1.key.count }) {
            result = result.replacingOccurrences(of: "$\(key)", with: value)
        }

        return result
    }

    // MARK: - Ordered service names (respecting depends_on)

    public func orderedServiceNames() -> [String] {
        var visited = Set<String>()
        var result: [String] = []

        func visit(_ name: String) {
            guard !visited.contains(name) else { return }
            visited.insert(name)
            if let deps = services[name]?.dependsOn {
                for dep in deps { visit(dep) }
            }
            result.append(name)
        }

        for name in services.keys.sorted() { visit(name) }
        return result
    }
}

// MARK: - ComposeService

public struct ComposeService: Codable, Sendable {
    public var image: String?
    public var build: ComposeBuild?
    public var command: ComposeCommand?
    public var environment: ComposeEnvironment?
    public var envFile: [String]?
    public var ports: [ComposePort]?
    public var volumes: [String]?
    public var networks: [String]?
    public var dependsOn: [String]?
    public var labels: ComposeLabels?
    public var restart: String?
    public var hostname: String?
    public var user: String?
    public var workingDir: String?
    public var healthcheck: ComposeHealthcheck?
    public var deploy: ComposeDeploy?

    private enum CodingKeys: String, CodingKey {
        case image, build, command, environment, ports, volumes, networks, labels, restart, hostname, user, deploy, healthcheck
        case envFile = "env_file"
        case dependsOn = "depends_on"
        case workingDir = "working_dir"
    }

    public var resolvedEnv: [String: String] {
        var result: [String: String] = [:]
        switch environment {
        case .dict(let d):
            result = d
        case .list(let list):
            for item in list {
                let parts = item.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    result[String(parts[0])] = String(parts[1])
                } else {
                    let key = String(parts[0])
                    result[key] = ProcessInfo.processInfo.environment[key] ?? ""
                }
            }
        case nil:
            break
        }
        return result
    }

    public var resolvedPorts: [PortMapping] {
        ports?.compactMap { port in
            switch port {
            case .string(let s): return PortMapping.parse(s)
            case .short(let hostPort, let containerPort): return PortMapping(hostPort: hostPort, containerPort: containerPort)
            case .long(let target, let published): return PortMapping(hostPort: published ?? target, containerPort: target)
            }
        } ?? []
    }

    public var resolvedVolumes: [VolumeMount] {
        volumes?.compactMap { VolumeMount.parse($0) } ?? []
    }

    public var resolvedLabels: [String: String] {
        switch labels {
        case .dict(let d): return d
        case .list(let list):
            var result: [String: String] = [:]
            for item in list {
                let parts = item.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    result[String(parts[0])] = String(parts[1])
                }
            }
            return result
        case nil: return [:]
        }
    }
}

// MARK: - ComposeBuild

public struct ComposeBuild: Codable, Sendable {
    public var context: String
    public var dockerfile: String?
    public var args: [String: String]?
    public var target: String?
    public var platforms: [String]?

    public init(from decoder: Decoder) throws {
        // Can be a plain string (context path) or an object
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            context = string
            dockerfile = nil
            args = nil
            target = nil
            platforms = nil
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            context = try container.decodeIfPresent(String.self, forKey: .context) ?? "."
            dockerfile = try container.decodeIfPresent(String.self, forKey: .dockerfile)
            args = try container.decodeIfPresent([String: String].self, forKey: .args)
            target = try container.decodeIfPresent(String.self, forKey: .target)
            platforms = try container.decodeIfPresent([String].self, forKey: .platforms)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case context, dockerfile, args, target, platforms
    }
}

// MARK: - ComposeCommand

public enum ComposeCommand: Codable, Sendable {
    case string(String)
    case list([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else {
            self = .list(try container.decode([String].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .list(let l): try container.encode(l)
        }
    }

    public var args: [String] {
        switch self {
        case .string(let s): return s.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        case .list(let l): return l
        }
    }
}

// MARK: - ComposeEnvironment

public enum ComposeEnvironment: Codable, Sendable {
    case dict([String: String])
    case list([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dict = try? container.decode([String: String].self) {
            self = .dict(dict)
        } else {
            self = .list(try container.decode([String].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .dict(let d): try container.encode(d)
        case .list(let l): try container.encode(l)
        }
    }
}

// MARK: - ComposePort

public enum ComposePort: Codable, Sendable {
    case string(String)
    case short(Int, Int)
    case long(target: Int, published: Int?)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let num = try? container.decode(Int.self) {
            self = .short(num, num)
        } else {
            struct LongPort: Codable {
                var target: Int
                var published: Int?
            }
            let long = try decoder.singleValueContainer().decode(LongPort.self)
            self = .long(target: long.target, published: long.published)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .short(let h, let c): try container.encode("\(h):\(c)")
        case .long(let t, let p): try container.encode("\(p ?? t):\(t)")
        }
    }
}

// MARK: - ComposeLabels

public enum ComposeLabels: Codable, Sendable {
    case dict([String: String])
    case list([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dict = try? container.decode([String: String].self) {
            self = .dict(dict)
        } else {
            self = .list(try container.decode([String].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .dict(let d): try container.encode(d)
        case .list(let l): try container.encode(l)
        }
    }
}

// MARK: - ComposeNetwork

public struct ComposeNetwork: Codable, Sendable {
    public var driver: String?
    public var external: Bool?
    public var name: String?
    public var labels: [String: String]?
}

// MARK: - ComposeVolume

public struct ComposeVolume: Codable, Sendable {
    public var driver: String?
    public var external: Bool?
    public var name: String?
    public var labels: [String: String]?
}

// MARK: - ComposeHealthcheck

public struct ComposeHealthcheck: Codable, Sendable {
    public var test: ComposeCommand?
    public var interval: String?
    public var timeout: String?
    public var retries: Int?
    public var startPeriod: String?

    private enum CodingKeys: String, CodingKey {
        case test, interval, timeout, retries
        case startPeriod = "start_period"
    }
}

// MARK: - ComposeDeploy

public struct ComposeDeploy: Codable, Sendable {
    public var replicas: Int?
    public var resources: ComposeResources?
    public var restartPolicy: ComposeRestartPolicy?

    private enum CodingKeys: String, CodingKey {
        case replicas, resources
        case restartPolicy = "restart_policy"
    }
}

public struct ComposeResources: Codable, Sendable {
    public var limits: ComposeResourceLimits?
    public var reservations: ComposeResourceLimits?
}

public struct ComposeResourceLimits: Codable, Sendable {
    public var cpus: String?
    public var memory: String?
}

public struct ComposeRestartPolicy: Codable, Sendable {
    public var condition: String?
    public var delay: String?
    public var maxAttempts: Int?

    private enum CodingKeys: String, CodingKey {
        case condition, delay
        case maxAttempts = "max_attempts"
    }
}
