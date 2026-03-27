import Foundation

// MARK: - ContainerInfo

public struct ContainerInfo: Codable, Sendable, Identifiable {
    public let id: String
    public var name: String
    public var image: String
    public var status: ContainerStatus
    public var command: String
    public var createdAt: Date
    public var startedAt: Date?
    public var finishedAt: Date?
    public var ports: [PortMapping]
    public var environment: [String: String]
    public var volumes: [VolumeMount]
    public var networkName: String?
    public var labels: [String: String]
    public var restartPolicy: String

    public init(
        id: String = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased(),
        name: String,
        image: String,
        status: ContainerStatus = .created,
        command: String = "",
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        finishedAt: Date? = nil,
        ports: [PortMapping] = [],
        environment: [String: String] = [:],
        volumes: [VolumeMount] = [],
        networkName: String? = nil,
        labels: [String: String] = [:],
        restartPolicy: String = "no"
    ) {
        self.id = id
        self.name = name
        self.image = image
        self.status = status
        self.command = command
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.ports = ports
        self.environment = environment
        self.volumes = volumes
        self.networkName = networkName
        self.labels = labels
        self.restartPolicy = restartPolicy
    }

    /// Short 12-character ID matching Docker's format
    public var shortId: String {
        String(id.prefix(12))
    }

    /// Human-readable status string
    public var statusDescription: String {
        switch status {
        case .created:
            return "Created"
        case .running:
            if let started = startedAt {
                let elapsed = Date().timeIntervalSince(started)
                return "Up \(formatDuration(elapsed))"
            }
            return "Up"
        case .paused:
            return "Paused"
        case .stopped:
            if let finished = finishedAt {
                let elapsed = Date().timeIntervalSince(finished)
                return "Exited (0) \(formatDuration(elapsed)) ago"
            }
            return "Exited"
        case .removing:
            return "Removal In Progress"
        case .dead:
            return "Dead"
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        if s < 60 { return "\(s) seconds" }
        let m = s / 60
        if m < 60 { return "\(m) minutes" }
        let h = m / 60
        if h < 24 { return "\(h) hours" }
        let d = h / 24
        return "\(d) days"
    }
}

// MARK: - ContainerStatus

public enum ContainerStatus: String, Codable, Sendable {
    case created
    case running
    case paused
    case stopped
    case removing
    case dead
}

// MARK: - PortMapping

public struct PortMapping: Codable, Sendable {
    public let hostPort: Int
    public let containerPort: Int
    public let `protocol`: String

    public init(hostPort: Int, containerPort: Int, `protocol`: String = "tcp") {
        self.hostPort = hostPort
        self.containerPort = containerPort
        self.`protocol` = `protocol`
    }

    public var description: String {
        "0.0.0.0:\(hostPort)->\(containerPort)/\(`protocol`)"
    }

    /// Parse from Docker -p format: "8080:80" or "8080:80/tcp"
    public static func parse(_ spec: String) -> PortMapping? {
        let parts = spec.split(separator: ":")
        guard parts.count == 2 else { return nil }
        let hostStr = String(parts[0])
        let rest = String(parts[1])
        let containerParts = rest.split(separator: "/")
        let proto = containerParts.count > 1 ? String(containerParts[1]) : "tcp"
        guard let hostPort = Int(hostStr),
              let containerPort = Int(String(containerParts[0])) else { return nil }
        return PortMapping(hostPort: hostPort, containerPort: containerPort, `protocol`: proto)
    }
}

// MARK: - VolumeMount

public struct VolumeMount: Codable, Sendable {
    public let hostPath: String
    public let containerPath: String
    public let readOnly: Bool

    public init(hostPath: String, containerPath: String, readOnly: Bool = false) {
        self.hostPath = hostPath
        self.containerPath = containerPath
        self.readOnly = readOnly
    }

    /// Parse from Docker -v format: "/host:/container" or "/host:/container:ro"
    public static func parse(_ spec: String) -> VolumeMount? {
        let parts = spec.split(separator: ":")
        if parts.count < 2 { return nil }
        let hostPath = String(parts[0])
        let containerPath = String(parts[1])
        let readOnly = parts.count > 2 && String(parts[2]) == "ro"
        return VolumeMount(hostPath: hostPath, containerPath: containerPath, readOnly: readOnly)
    }
}

// MARK: - ContainerRunOptions

public struct ContainerRunOptions: Sendable {
    public var name: String?
    public var detached: Bool
    public var interactive: Bool
    public var tty: Bool
    public var remove: Bool
    public var ports: [PortMapping]
    public var environment: [String: String]
    public var envFile: String?
    public var volumes: [VolumeMount]
    public var networkName: String?
    public var labels: [String: String]
    public var restartPolicy: String
    public var command: [String]
    public var workdir: String?
    public var user: String?
    public var hostname: String?
    public var memory: String?
    public var cpuShares: Int?
    public var privileged: Bool
    public var init_: Bool
    public var shmSize: String?

    public init(
        name: String? = nil,
        detached: Bool = false,
        interactive: Bool = false,
        tty: Bool = false,
        remove: Bool = false,
        ports: [PortMapping] = [],
        environment: [String: String] = [:],
        envFile: String? = nil,
        volumes: [VolumeMount] = [],
        networkName: String? = nil,
        labels: [String: String] = [:],
        restartPolicy: String = "no",
        command: [String] = [],
        workdir: String? = nil,
        user: String? = nil,
        hostname: String? = nil,
        memory: String? = nil,
        cpuShares: Int? = nil,
        privileged: Bool = false,
        init_: Bool = false,
        shmSize: String? = nil
    ) {
        self.name = name
        self.detached = detached
        self.interactive = interactive
        self.tty = tty
        self.remove = remove
        self.ports = ports
        self.environment = environment
        self.envFile = envFile
        self.volumes = volumes
        self.networkName = networkName
        self.labels = labels
        self.restartPolicy = restartPolicy
        self.command = command
        self.workdir = workdir
        self.user = user
        self.hostname = hostname
        self.memory = memory
        self.cpuShares = cpuShares
        self.privileged = privileged
        self.init_ = init_
        self.shmSize = shmSize
    }
}

// MARK: - ContainerStats

public struct ContainerStats: Sendable {
    public let containerId: String
    public let name: String
    public let cpuPercent: Double
    public let memUsage: UInt64
    public let memLimit: UInt64
    public let networkRx: UInt64
    public let networkTx: UInt64
    public let blockRead: UInt64
    public let blockWrite: UInt64
    public let pids: Int

    public var memPercent: Double {
        guard memLimit > 0 else { return 0 }
        return Double(memUsage) / Double(memLimit) * 100
    }

    public init(
        containerId: String,
        name: String,
        cpuPercent: Double,
        memUsage: UInt64,
        memLimit: UInt64,
        networkRx: UInt64,
        networkTx: UInt64,
        blockRead: UInt64,
        blockWrite: UInt64,
        pids: Int
    ) {
        self.containerId = containerId
        self.name = name
        self.cpuPercent = cpuPercent
        self.memUsage = memUsage
        self.memLimit = memLimit
        self.networkRx = networkRx
        self.networkTx = networkTx
        self.blockRead = blockRead
        self.blockWrite = blockWrite
        self.pids = pids
    }
}
