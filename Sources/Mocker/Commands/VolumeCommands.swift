import ArgumentParser
import MockerKit
import Foundation

// MARK: - mocker volume

struct VolumeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "volume",
        abstract: "Manage volumes",
        subcommands: [
            VolumeCreateCommand.self,
            VolumeLsCommand.self,
            VolumeRmCommand.self,
            VolumeInspectCommand.self,
            VolumePruneCommand.self,
        ]
    )
}

// MARK: - volume create

struct VolumeCreateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a volume"
    )

    @Option(name: [.short, .customLong("driver")], help: "Specify volume driver name")
    var driver: String = "local"

    @Option(name: [.short, .customLong("label")], help: "Set metadata for a volume")
    var labels: [String] = []

    @Option(name: .customLong("opt"), help: "Set driver specific options")
    var options: [String] = []

    @Argument(help: "Volume name (optional, auto-generated if omitted)")
    var name: String?

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
        let volume = try await MockerState.volumeManager.create(
            name: name,
            driver: driver,
            labels: labelDict,
            options: optDict
        )
        print(volume.name)
    }
}

// MARK: - volume ls

struct VolumeLsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ls",
        abstract: "List volumes"
    )

    @Flag(name: [.short, .customLong("quiet")], help: "Only display volume names")
    var quiet = false

    func run() async throws {
        try await MockerState.volumeManager.load()
        let volumes = await MockerState.volumeManager.getAll()
        if quiet {
            for vol in volumes { print(vol.name) }
        } else {
            print(TableFormatter.formatVolumes(volumes))
        }
    }
}

// MARK: - volume rm

struct VolumeRmCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rm",
        abstract: "Remove one or more volumes"
    )

    @Flag(name: [.short, .customLong("force")], help: "Force the removal of one or more volumes")
    var force = false

    @Argument(help: "Volume names")
    var volumes: [String]

    func run() async throws {
        for name in volumes {
            let result = try await MockerState.volumeManager.remove(name, force: force)
            print(result)
        }
    }
}

// MARK: - volume inspect

struct VolumeInspectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inspect",
        abstract: "Display detailed information on one or more volumes"
    )

    @Argument(help: "Volume names")
    var volumes: [String]

    func run() async throws {
        try await MockerState.volumeManager.load()
        let json = try await MockerState.volumeManager.inspect(volumes)
        print(json)
    }
}

// MARK: - volume prune

struct VolumePruneCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prune",
        abstract: "Remove unused local volumes"
    )

    @Flag(name: [.short, .customLong("force")], help: "Do not prompt for confirmation")
    var force = false

    @Flag(name: [.short, .customLong("all")], help: "Remove all unused volumes, not just anonymous ones")
    var all = false

    func run() async throws {
        let (count, space) = try await MockerState.volumeManager.prune()
        print("Total reclaimed space: \(space)")
    }
}
