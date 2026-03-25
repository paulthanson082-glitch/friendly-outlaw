import ArgumentParser
import MockerKit
import Foundation

// MARK: - mocker run

struct RunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Create and run a new container from an image"
    )

    @Flag(name: .shortAndLong, help: "Run container in background and print container ID")
    var detach = false

    @Flag(name: [.short], help: "Keep STDIN open even if not attached")
    var interactive = false

    @Flag(name: [.short], help: "Allocate a pseudo-TTY")
    var tty = false

    @Flag(name: .customShort("r", allowingJoined: false), inversion: .prefixedNo, help: "Automatically remove the container when it exits")
    var rm = false

    @Option(name: .customLong("name"), help: "Assign a name to the container")
    var name: String?

    @Option(name: [.short, .customLong("publish")], help: "Publish container port(s) to the host", transform: { PortMapping.parse($0) ?? PortMapping(hostPort: 0, containerPort: 0) })
    var ports: [PortMapping] = []

    @Option(name: [.short, .customLong("env")], help: "Set environment variables")
    var environment: [String] = []

    @Option(name: .customLong("env-file"), help: "Read in a file of environment variables")
    var envFile: String?

    @Option(name: [.short, .customLong("volume")], help: "Bind mount a volume")
    var volumes: [String] = []

    @Option(name: .customLong("network"), help: "Connect a container to a network")
    var network: String?

    @Option(name: [.short, .customLong("label")], help: "Set metadata on a container")
    var labels: [String] = []

    @Option(name: .customLong("restart"), help: "Restart policy (no, always, on-failure, unless-stopped)")
    var restart: String = "no"

    @Option(name: [.short, .customLong("workdir")], help: "Working directory inside the container")
    var workdir: String?

    @Option(name: [.short, .customLong("user")], help: "Username or UID")
    var user: String?

    @Option(name: .customLong("hostname"), help: "Container host name")
    var hostname: String?

    @Option(name: [.short, .customLong("memory")], help: "Memory limit")
    var memory: String?

    @Option(name: .customLong("cpu-shares"), help: "CPU shares (relative weight)")
    var cpuShares: Int?

    @Flag(name: .customLong("privileged"), help: "Give extended privileges to this container")
    var privileged = false

    @Flag(name: .customLong("init"), help: "Run an init inside the container")
    var initProcess = false

    @Option(name: .customLong("shm-size"), help: "Size of /dev/shm")
    var shmSize: String?

    @Argument(help: "Image to run")
    var image: String

    @Argument(parsing: .captureForPassthrough, help: "Command and arguments to run")
    var command: [String] = []

    func run() async throws {
        var env: [String: String] = [:]
        for e in environment {
            let parts = e.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                env[String(parts[0])] = String(parts[1])
            } else {
                let key = String(parts[0])
                env[key] = ProcessInfo.processInfo.environment[key] ?? ""
            }
        }

        var labelDict: [String: String] = [:]
        for l in labels {
            let parts = l.split(separator: "=", maxSplits: 1)
            if parts.count == 2 { labelDict[String(parts[0])] = String(parts[1]) }
        }

        let opts = ContainerRunOptions(
            name: name,
            detached: detach,
            interactive: interactive,
            tty: tty,
            remove: rm,
            ports: ports.filter { $0.hostPort > 0 },
            environment: env,
            envFile: envFile,
            volumes: volumes.compactMap { VolumeMount.parse($0) },
            networkName: network,
            labels: labelDict,
            restartPolicy: restart,
            command: command,
            workdir: workdir,
            user: user,
            hostname: hostname,
            memory: memory,
            cpuShares: cpuShares,
            privileged: privileged,
            init_: initProcess,
            shmSize: shmSize
        )

        let result = try await MockerState.containerEngine.run(image: image, options: opts)
        if detach {
            print(result)
        }
    }
}

// MARK: - mocker ps

struct PSCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ps",
        abstract: "List containers"
    )

    @Flag(name: [.short, .customLong("all")], help: "Show all containers (default shows just running)")
    var all = false

    @Flag(name: [.short, .customLong("quiet")], help: "Only display container IDs")
    var quiet = false

    @Flag(name: .customLong("no-trunc"), help: "Don't truncate output")
    var noTrunc = false

    @Option(name: [.short, .customLong("filter")], help: "Filter output based on conditions provided")
    var filter: String?

    func run() async throws {
        try await MockerState.containerStore.load()
        let containers = await MockerState.containerStore.getAll()
        let filtered = all ? containers : containers.filter { $0.status == .running }
        let output = TableFormatter.formatPS(filtered, all: all, quiet: quiet, noTrunc: noTrunc)
        if !output.isEmpty { print(output) }
    }
}

// MARK: - mocker start

struct StartCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Start one or more stopped containers"
    )

    @Argument(help: "Container names or IDs")
    var containers: [String]

    func run() async throws {
        for identifier in containers {
            let result = try await MockerState.containerEngine.start(identifier)
            print(result)
        }
    }
}

// MARK: - mocker stop

struct StopCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stop",
        abstract: "Stop one or more running containers"
    )

    @Option(name: [.short, .customLong("time")], help: "Seconds to wait for stop before killing")
    var time: Int = 10

    @Argument(help: "Container names or IDs")
    var containers: [String]

    func run() async throws {
        for identifier in containers {
            let result = try await MockerState.containerEngine.stop(identifier, timeout: time)
            print(result)
        }
    }
}

// MARK: - mocker restart

struct RestartCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "restart",
        abstract: "Restart one or more containers"
    )

    @Option(name: [.short, .customLong("time")], help: "Seconds to wait for stop before killing")
    var time: Int = 10

    @Argument(help: "Container names or IDs")
    var containers: [String]

    func run() async throws {
        for identifier in containers {
            let result = try await MockerState.containerEngine.restart(identifier, timeout: time)
            print(result)
        }
    }
}

// MARK: - mocker kill

struct KillCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "kill",
        abstract: "Kill one or more running containers"
    )

    @Option(name: [.short, .customLong("signal")], help: "Signal to send to the container")
    var signal: String = "KILL"

    @Argument(help: "Container names or IDs")
    var containers: [String]

    func run() async throws {
        for identifier in containers {
            let result = try await MockerState.containerEngine.kill(identifier, signal: signal)
            print(result)
        }
    }
}

// MARK: - mocker rm

struct RmCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rm",
        abstract: "Remove one or more containers"
    )

    @Flag(name: [.short, .customLong("force")], help: "Force the removal of a running container")
    var force = false

    @Flag(name: [.short, .customLong("volumes")], help: "Remove anonymous volumes associated with the container")
    var volumes = false

    @Argument(help: "Container names or IDs")
    var containers: [String]

    func run() async throws {
        for identifier in containers {
            let result = try await MockerState.containerEngine.remove(identifier, force: force, volumes: volumes)
            print(result)
        }
    }
}

// MARK: - mocker exec

struct ExecCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "exec",
        abstract: "Execute a command in a running container"
    )

    @Flag(name: [.short], help: "Keep STDIN open")
    var interactive = false

    @Flag(name: [.short], help: "Allocate a pseudo-TTY")
    var tty = false

    @Flag(name: [.short, .customLong("detach")], help: "Detached mode: run command in the background")
    var detach = false

    @Option(name: [.short, .customLong("workdir")], help: "Working directory inside the container")
    var workdir: String?

    @Option(name: [.short, .customLong("env")], help: "Set environment variables")
    var envVars: [String] = []

    @Argument(help: "Container name or ID")
    var container: String

    @Argument(parsing: .captureForPassthrough, help: "Command to execute")
    var command: [String]

    func run() async throws {
        var env: [String: String] = [:]
        for e in envVars {
            let parts = e.split(separator: "=", maxSplits: 1)
            if parts.count == 2 { env[String(parts[0])] = String(parts[1]) }
        }
        try await MockerState.containerEngine.exec(
            container,
            command: command,
            interactive: interactive,
            tty: tty,
            detached: detach,
            workdir: workdir,
            env: env
        )
    }
}

// MARK: - mocker logs

struct LogsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logs",
        abstract: "Fetch the logs of a container"
    )

    @Flag(name: [.short, .customLong("follow")], help: "Follow log output")
    var follow = false

    @Option(name: .customLong("tail"), help: "Number of lines to show from the end")
    var tail: String?

    @Option(name: .customLong("since"), help: "Show logs since timestamp")
    var since: String?

    @Flag(name: [.short, .customLong("timestamps")], help: "Show timestamps")
    var timestamps = false

    @Argument(help: "Container name or ID")
    var container: String

    func run() async throws {
        try await MockerState.containerEngine.logs(container, follow: follow, tail: tail, since: since, timestamps: timestamps)
    }
}

// MARK: - mocker inspect

struct InspectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inspect",
        abstract: "Return low-level information on Docker objects"
    )

    @Option(name: [.short, .customLong("format")], help: "Format output using a Go template")
    var format: String?

    @Option(name: .customLong("type"), help: "Return JSON for specified type (container, image, network, volume)")
    var type_: String?

    @Argument(help: "Names or IDs of containers or images")
    var targets: [String]

    func run() async throws {
        try await MockerState.containerStore.load()
        try await MockerState.imageStore.load()

        var jsonOutputs: [String] = []
        for target in targets {
            if let _ = await MockerState.containerStore.find(target) {
                let json = try await MockerState.containerEngine.inspect([target])
                jsonOutputs.append(json)
            } else if let _ = await MockerState.imageStore.find(target) {
                let json = try await MockerState.imageManager.inspect([target])
                jsonOutputs.append(json)
            } else {
                throw MockerError.containerNotFound(target)
            }
        }
        print(jsonOutputs.joined(separator: "\n"))
    }
}

// MARK: - mocker stats

struct StatsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stats",
        abstract: "Display a live stream of container(s) resource usage statistics"
    )

    @Flag(name: .customLong("no-stream"), help: "Disable streaming stats and only pull the first result")
    var noStream = false

    @Flag(name: [.short, .customLong("all")], help: "Show all containers")
    var all = false

    @Argument(help: "Container names or IDs (default: running containers)")
    var containers: [String] = []

    func run() async throws {
        let stats = try await MockerState.containerEngine.stats(containers: containers, noStream: noStream)
        let output = TableFormatter.formatStats(stats, noStream: noStream)
        if !output.isEmpty { print(output) }
    }
}

// MARK: - mocker commit

struct CommitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "commit",
        abstract: "Create a new image from a container's changes"
    )

    @Option(name: [.short, .customLong("message")], help: "Commit message")
    var message: String = ""

    @Option(name: [.short, .customLong("author")], help: "Author (e.g., 'John Doe <john@example.com>')")
    var author: String?

    @Argument(help: "Container name or ID")
    var container: String

    @Argument(help: "Repository[:tag]")
    var repository: String

    func run() async throws {
        let (repo, tag) = ImageInfo.parseReference(repository)
        let result = try await MockerState.containerEngine.commit(container, repository: repo, tag: tag, message: message)
        print(result)
    }
}

// MARK: - mocker export

struct ExportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Export a container's filesystem as a tar archive"
    )

    @Option(name: [.short, .customLong("output")], help: "Write to a file, instead of STDOUT")
    var output: String?

    @Argument(help: "Container name or ID")
    var container: String

    func run() async throws {
        try await MockerState.containerEngine.export(container, output: output)
    }
}

// MARK: - mocker container (group)

struct ContainerGroupCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "container",
        abstract: "Manage containers",
        subcommands: [
            RunCommand.self,
            PSCommand.self,
            StartCommand.self,
            StopCommand.self,
            RestartCommand.self,
            KillCommand.self,
            RmCommand.self,
            ExecCommand.self,
            LogsCommand.self,
            InspectCommand.self,
            StatsCommand.self,
            CommitCommand.self,
            ExportCommand.self,
            ContainerPruneCommand.self,
        ]
    )
}

struct ContainerPruneCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prune",
        abstract: "Remove all stopped containers"
    )

    @Flag(name: [.short, .customLong("force")], help: "Do not prompt for confirmation")
    var force = false

    func run() async throws {
        let (count, space) = try await MockerState.containerEngine.prune()
        if count > 0 {
            print("Total reclaimed space: \(space)")
        }
    }
}
