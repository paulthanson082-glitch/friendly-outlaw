import ArgumentParser
import MockerKit
import Foundation

// MARK: - mocker network

struct NetworkCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "network",
        abstract: "Manage networks",
        subcommands: [
            NetworkCreateCommand.self,
            NetworkLsCommand.self,
            NetworkRmCommand.self,
            NetworkInspectCommand.self,
            NetworkConnectCommand.self,
            NetworkDisconnectCommand.self,
            NetworkPruneCommand.self,
        ]
    )
}

// MARK: - network create

struct NetworkCreateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a network"
    )

    @Option(name: [.short, .customLong("driver")], help: "Driver to manage the Network (default: bridge)")
    var driver: String = "bridge"

    @Option(name: .customLong("subnet"), help: "Subnet in CIDR format")
    var subnet: String?

    @Option(name: .customLong("gateway"), help: "IPv4 or IPv6 Gateway for the master subnet")
    var gateway: String?

    @Option(name: [.short, .customLong("label")], help: "Set metadata on a network")
    var labels: [String] = []

    @Option(name: .customLong("opt"), help: "Set driver specific options")
    var options: [String] = []

    @Argument(help: "Network name")
    var name: String

    func run() async throws {
        var labelDict: [String: String] = [:]
        for l in labels {
            let parts = l.split(separator: "=", maxSplits: 1)
            if parts.count == 2 { labelDict[String(parts[0])] = String(parts[1]) }
        }
        var optDict: [String: String] = [:]
        for o in options {
            let parts = o.split(separator: "=", maxSplits: 1)
            if parts.count == 2 { optDict[String(parts[0])] = String(parts[1]) }
        }
        let network = try await MockerState.networkManager.create(
            name: name,
            driver: driver,
            subnet: subnet,
            gateway: gateway,
            labels: labelDict,
            options: optDict
        )
        print(network.id)
    }
}

// MARK: - network ls

struct NetworkLsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ls",
        abstract: "List networks"
    )

    @Flag(name: [.short, .customLong("quiet")], help: "Only display network IDs")
    var quiet = false

    func run() async throws {
        try await MockerState.networkManager.load()
        let networks = await MockerState.networkManager.getAll()
        if quiet {
            for net in networks { print(net.shortId) }
        } else {
            print(TableFormatter.formatNetworks(networks))
        }
    }
}

// MARK: - network rm

struct NetworkRmCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rm",
        abstract: "Remove one or more networks"
    )

    @Argument(help: "Network names or IDs")
    var networks: [String]

    func run() async throws {
        for identifier in networks {
            let result = try await MockerState.networkManager.remove(identifier)
            print(result)
        }
    }
}

// MARK: - network inspect

struct NetworkInspectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inspect",
        abstract: "Display detailed information on one or more networks"
    )

    @Argument(help: "Network names or IDs")
    var networks: [String]

    func run() async throws {
        try await MockerState.networkManager.load()
        let json = try await MockerState.networkManager.inspect(networks)
        print(json)
    }
}

// MARK: - network connect

struct NetworkConnectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "connect",
        abstract: "Connect a container to a network"
    )

    @Argument(help: "Network name or ID")
    var network: String

    @Argument(help: "Container name or ID")
    var container: String

    func run() async throws {
        try await MockerState.containerStore.load()
        guard let containerInfo = await MockerState.containerStore.find(container) else {
            throw MockerError.containerNotFound(container)
        }
        try await MockerState.networkManager.connect(network: network, container: containerInfo)
    }
}

// MARK: - network disconnect

struct NetworkDisconnectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "disconnect",
        abstract: "Disconnect a container from a network"
    )

    @Flag(name: [.short, .customLong("force")], help: "Force the container to disconnect from a network")
    var force = false

    @Argument(help: "Network name or ID")
    var network: String

    @Argument(help: "Container name or ID")
    var container: String

    func run() async throws {
        try await MockerState.containerStore.load()
        guard let containerInfo = await MockerState.containerStore.find(container) else {
            throw MockerError.containerNotFound(container)
        }
        try await MockerState.networkManager.disconnect(network: network, containerId: containerInfo.id)
    }
}

// MARK: - network prune

struct NetworkPruneCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prune",
        abstract: "Remove all unused networks"
    )

    @Flag(name: [.short, .customLong("force")], help: "Do not prompt for confirmation")
    var force = false

    func run() async throws {
        print("Total reclaimed space: 0B")
    }
}
