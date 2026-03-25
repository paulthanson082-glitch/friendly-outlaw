import ArgumentParser
import MockerKit
import Foundation

// MARK: - mocker compose

struct ComposeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "compose",
        abstract: "Define and run multi-container applications with Docker",
        subcommands: [
            ComposeUpCommand.self,
            ComposeDownCommand.self,
            ComposePSCommand.self,
            ComposeLogsCommand.self,
            ComposeRestartCommand.self,
            ComposePullCommand.self,
            ComposeBuildCommand.self,
            ComposeStartCommand.self,
            ComposeStopCommand.self,
            ComposeKillCommand.self,
            ComposeExecCommand.self,
            ComposeRunCommand.self,
            ComposeConfigCommand.self,
            ComposeTopCommand.self,
        ]
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    // These are used by subcommands via inheritance-like shared state
}

// MARK: - Compose helpers

func resolveComposeFile(_ files: [String]) -> String? {
    if !files.isEmpty { return files[0] }
    for name in ["compose.yaml", "compose.yml", "docker-compose.yml", "docker-compose.yaml"] {
        if FileManager.default.fileExists(atPath: name) { return name }
    }
    return nil
}

func resolveProjectName(_ name: String?, filePath: String?) -> String {
    if let n = name { return n }
    if let path = filePath {
        let url = URL(fileURLWithPath: path)
        return url.deletingLastPathComponent().lastPathComponent
    }
    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent
}

// MARK: - compose up

struct ComposeUpCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "up",
        abstract: "Create and start containers"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    @Flag(name: [.short, .customLong("detach")], help: "Detached mode: Run containers in the background")
    var detach = false

    @Flag(name: .customLong("build"), help: "Build images before starting containers")
    var build = false

    @Flag(name: .customLong("force-recreate"), help: "Recreate containers even if their configuration hasn't changed")
    var forceRecreate = false

    @Flag(name: .customLong("remove-orphans"), help: "Remove containers for services not defined in the Compose file")
    var removeOrphans = false

    @Flag(name: .customLong("no-build"), help: "Don't build an image, even if it's missing")
    var noBuild = false

    @Option(name: .customLong("scale"), help: "Scale SERVICE to NUM instances (e.g. web=3)")
    var scale: [String] = []

    @Argument(help: "Services to start (default: all)")
    var services: [String] = []

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        let project = resolveProjectName(projectName, filePath: filePath)

        var scaleDict: [String: Int] = [:]
        for s in scale {
            let parts = s.split(separator: "=", maxSplits: 1)
            if parts.count == 2, let n = Int(parts[1]) {
                scaleDict[String(parts[0])] = n
            }
        }

        try await MockerState.orchestrator.up(
            file: composeFile,
            projectName: project,
            services: services,
            detached: detach || true, // Always detach for now
            build: build,
            forceRecreate: forceRecreate,
            removeOrphans: removeOrphans,
            scale: scaleDict
        )
    }
}

// MARK: - compose down

struct ComposeDownCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "down",
        abstract: "Stop and remove containers, networks"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    @Flag(name: [.short, .customLong("volumes")], help: "Remove named volumes declared in the volumes section")
    var volumes = false

    @Flag(name: .customLong("rmi"), help: "Remove images used by services")
    var removeImages = false

    @Flag(name: .customLong("remove-orphans"), help: "Remove containers for services not defined in the Compose file")
    var removeOrphans = false

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        let project = resolveProjectName(projectName, filePath: filePath)
        try await MockerState.orchestrator.down(
            file: composeFile,
            projectName: project,
            removeVolumes: volumes,
            removeImages: removeImages
        )
    }
}

// MARK: - compose ps

struct ComposePSCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ps",
        abstract: "List containers"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    @Flag(name: [.short, .customLong("quiet")], help: "Only display IDs")
    var quiet = false

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        let project = resolveProjectName(projectName, filePath: filePath)
        let containers = await MockerState.orchestrator.ps(file: composeFile, projectName: project)
        if quiet {
            containers.forEach { print($0.shortId) }
        } else {
            print(TableFormatter.formatComposePS(containers, projectName: project))
        }
    }
}

// MARK: - compose logs

struct ComposeLogsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logs",
        abstract: "View output from containers"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    @Flag(name: [.short, .customLong("follow")], help: "Follow log output")
    var follow = false

    @Option(name: .customLong("tail"), help: "Number of lines to show from the end")
    var tail: String?

    @Argument(help: "Service name(s)")
    var services: [String] = []

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        let project = resolveProjectName(projectName, filePath: filePath)
        let serviceName = services.first
        try await MockerState.orchestrator.logs(
            file: composeFile,
            projectName: project,
            service: serviceName,
            follow: follow,
            tail: tail
        )
    }
}

// MARK: - compose restart

struct ComposeRestartCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "restart",
        abstract: "Restart service containers"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    @Argument(help: "Service names (default: all)")
    var services: [String] = []

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        let project = resolveProjectName(projectName, filePath: filePath)
        try await MockerState.orchestrator.restart(file: composeFile, projectName: project, services: services)
    }
}

// MARK: - compose pull

struct ComposePullCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pull",
        abstract: "Pull service images"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Flag(name: [.short, .customLong("quiet")], help: "Pull without printing progress information")
    var quiet = false

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        try await MockerState.orchestrator.pull(file: composeFile, quiet: quiet)
    }
}

// MARK: - compose build

struct ComposeBuildCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build or rebuild services"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    @Flag(name: .customLong("no-cache"), help: "Do not use cache when building the image")
    var noCache = false

    @Argument(help: "Service names (default: all)")
    var services: [String] = []

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        let project = resolveProjectName(projectName, filePath: filePath)
        try await MockerState.orchestrator.build(file: composeFile, projectName: project, services: services, noCache: noCache)
    }
}

// MARK: - compose start

struct ComposeStartCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Start services"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    @Argument(help: "Service names (default: all)")
    var services: [String] = []

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        let project = resolveProjectName(projectName, filePath: filePath)
        let serviceNames = services.isEmpty ? Array(composeFile.services.keys) : services
        for svc in serviceNames {
            let name = "\(project)-\(svc)-1"
            _ = try? await MockerState.containerEngine.start(name)
        }
    }
}

// MARK: - compose stop

struct ComposeStopCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stop",
        abstract: "Stop services"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    @Argument(help: "Service names (default: all)")
    var services: [String] = []

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        let project = resolveProjectName(projectName, filePath: filePath)
        let serviceNames = services.isEmpty ? Array(composeFile.services.keys) : services
        for svc in serviceNames {
            let name = "\(project)-\(svc)-1"
            _ = try? await MockerState.containerEngine.stop(name)
        }
    }
}

// MARK: - compose kill

struct ComposeKillCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "kill",
        abstract: "Force stop service containers"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    @Option(name: [.short, .customLong("signal")], help: "Signal to send to the container")
    var signal: String = "SIGKILL"

    @Argument(help: "Service names")
    var services: [String] = []

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        let project = resolveProjectName(projectName, filePath: filePath)
        let serviceNames = services.isEmpty ? Array(composeFile.services.keys) : services
        for svc in serviceNames {
            let name = "\(project)-\(svc)-1"
            _ = try? await MockerState.containerEngine.kill(name, signal: signal)
        }
    }
}

// MARK: - compose exec

struct ComposeExecCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "exec",
        abstract: "Execute a command in a running container"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    @Flag(name: [.short], help: "Disable pseudo-TTY allocation")
    var noTty = false

    @Flag(name: [.short, .customLong("detach")], help: "Detached mode")
    var detach = false

    @Argument(help: "Service name")
    var service: String

    @Argument(parsing: .captureForPassthrough, help: "Command to execute")
    var command: [String]

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let project = resolveProjectName(projectName, filePath: filePath)
        let containerName = "\(project)-\(service)-1"
        try await MockerState.containerEngine.exec(
            containerName,
            command: command,
            interactive: true,
            tty: !noTty,
            detached: detach
        )
    }
}

// MARK: - compose run

struct ComposeRunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run a one-off command on a service"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    @Flag(name: [.short, .customLong("detach")], help: "Run in background")
    var detach = false

    @Flag(name: .customLong("rm"), help: "Automatically remove the container when it exits")
    var rm = false

    @Option(name: [.short, .customLong("env")], help: "Set environment variables")
    var envVars: [String] = []

    @Argument(help: "Service name")
    var service: String

    @Argument(parsing: .captureForPassthrough, help: "Command to run")
    var command: [String] = []

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        let project = resolveProjectName(projectName, filePath: filePath)

        guard let serviceConfig = composeFile.services[service] else {
            throw MockerError.invalidArgument("service \"\(service)\" is not defined")
        }
        guard let image = serviceConfig.image else {
            throw MockerError.invalidArgument("service \"\(service)\" has no image")
        }

        var env = serviceConfig.resolvedEnv
        for e in envVars {
            let parts = e.split(separator: "=", maxSplits: 1)
            if parts.count == 2 { env[String(parts[0])] = String(parts[1]) }
        }

        let opts = ContainerRunOptions(
            detached: detach,
            remove: rm,
            environment: env,
            command: command.isEmpty ? serviceConfig.command?.args ?? [] : command
        )
        _ = try await MockerState.containerEngine.run(image: image, options: opts)
    }
}

// MARK: - compose config

struct ComposeConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Parse, resolve and render compose file in canonical format"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Flag(name: [.short, .customLong("quiet")], help: "Only validate the configuration, don't print anything")
    var quiet = false

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        if !quiet {
            let json = try MockerPersistence.toJSONString(composeFile)
            print(json)
        }
    }
}

// MARK: - compose top

struct ComposeTopCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "top",
        abstract: "Display the running processes"
    )

    @Option(name: [.short, .customLong("file")], help: "Compose configuration files")
    var files: [String] = []

    @Option(name: [.short, .customLong("project-name")], help: "Project name")
    var projectName: String?

    @Argument(help: "Services to show")
    var services: [String] = []

    func run() async throws {
        guard let filePath = resolveComposeFile(files) else {
            throw MockerError.ioError("no configuration file provided: not found")
        }
        let composeFile = try ComposeFile.load(from: filePath)
        let project = resolveProjectName(projectName, filePath: filePath)
        let containers = await MockerState.orchestrator.ps(file: composeFile, projectName: project)
        for c in containers {
            print(c.name)
        }
    }
}
