import ArgumentParser
import MockerKit

// MARK: - Shared Mocker state

/// Lazily-initialized shared actors, created once per process
enum MockerState {
    static let containerStore = ContainerStore()
    static let imageStore = ImageStore()
    static let networkManager = NetworkManager()
    static let volumeManager = VolumeManager()
    static let imageManager = ImageManager(store: imageStore)
    static let containerEngine = ContainerEngine(
        store: containerStore,
        imageManager: imageManager,
        networkManager: networkManager
    )
    static let orchestrator = ComposeOrchestrator(
        containerEngine: containerEngine,
        imageManager: imageManager,
        networkManager: networkManager,
        volumeManager: volumeManager
    )
}

// MARK: - Root command

@main
struct MockerCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mocker",
        abstract: "A Docker-compatible container management tool powered by Apple's Containerization framework.",
        discussion: """
        Mocker provides a Docker-compatible CLI for running containers natively on macOS
        using Apple's Containerization framework. It speaks the same language as Docker —
        same commands, same flags, same output format.

        Replace docker with mocker in your existing scripts and workflows.
        """,
        version: "0.1.9",
        subcommands: [
            // Container commands
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
            // Image commands
            ImagesCommand.self,
            PullCommand.self,
            PushCommand.self,
            BuildCommand.self,
            TagCommand.self,
            RmiCommand.self,
            // Grouped subcommands
            ContainerGroupCommand.self,
            ImageGroupCommand.self,
            NetworkCommand.self,
            VolumeCommand.self,
            ComposeCommand.self,
            SystemCommand.self,
        ]
    )
}
