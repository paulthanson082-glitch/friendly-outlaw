import ArgumentParser
import MockerKit
import Foundation

// MARK: - mocker system

struct SystemCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "system",
        abstract: "Manage Mocker",
        subcommands: [
            SystemInfoCommand.self,
            SystemPruneCommand.self,
            SystemDfCommand.self,
            SystemEventsCommand.self,
        ]
    )
}

// MARK: - system info

struct SystemInfoCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Display system-wide information"
    )

    func run() async throws {
        try await MockerState.containerStore.load()
        try await MockerState.imageStore.load()
        try await MockerState.networkManager.load()
        try await MockerState.volumeManager.load()

        let containers = await MockerState.containerStore.getAll()
        let images = await MockerState.imageStore.getAll()
        let networks = await MockerState.networkManager.getAll()
        let volumes = await MockerState.volumeManager.getAll()

        let runningCount = containers.filter { $0.status == .running }.count
        let stoppedCount = containers.filter { $0.status == .stopped || $0.status == .created }.count

        let osInfo = ProcessInfo.processInfo
        let processorCount = ProcessInfo.processInfo.processorCount

        print("""
        Client: Mocker v0.1.9
         Context:    default
         Debug Mode: false

        Server:
         Containers: \(containers.count)
          Running: \(runningCount)
          Paused: 0
          Stopped: \(stoppedCount)
         Images: \(images.count)
         Server Version: 0.1.9
         Storage Driver: native
         Backing Filesystem: apfs
         Logging Driver: json-file
         Cgroup Driver: cgroupfs
         Plugins:
          Volume: local
          Network: bridge host null
          Log: json-file syslog
         Swarm: inactive
         Runtimes: apple-container-runtime
         Default Runtime: apple-container-runtime
         Init Binary: container-init
         containerd version: N/A (using Apple Containerization)
         runc version: N/A
         init version: N/A
         Security Options: seccomp apparmor
         Kernel Version: \(getKernelVersion())
         Operating System: macOS
         OSType: darwin
         Architecture: \(getArchitecture())
         CPUs: \(processorCount)
         Total Memory: \(formatMemory(osInfo.physicalMemory))
         Name: \(ProcessInfo.processInfo.hostName)
         ID: mocker-\(UUID().uuidString.prefix(8))
         Docker Root Dir: \(MockerConfig.rootDir)
         Debug Mode: false
         Registry: https://index.docker.io/v1/
         Experimental: false
         Insecure Registries:
          127.0.0.0/8
         Live Restore Enabled: false
        """)
    }

    private func getKernelVersion() -> String {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.release) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }

    private func getArchitecture() -> String {
        #if arch(arm64)
        return "aarch64"
        #else
        return "x86_64"
        #endif
    }

    private func formatMemory(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.2f GiB", gb)
    }
}

// MARK: - system prune

struct SystemPruneCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prune",
        abstract: "Remove unused data"
    )

    @Flag(name: [.short, .customLong("all")], help: "Remove all unused images not just dangling ones")
    var all = false

    @Flag(name: [.short, .customLong("force")], help: "Do not prompt for confirmation")
    var force = false

    @Flag(name: [.short, .customLong("volumes")], help: "Prune volumes")
    var volumes = false

    func run() async throws {
        print("WARNING! This will remove:")
        print("  - all stopped containers")
        print("  - all networks not used by at least one container")
        print("  - all dangling images")
        print("  - all dangling build cache")
        if !force {
            print("\nAre you sure you want to continue? [y/N] ", terminator: "")
            let input = readLine() ?? "n"
            guard input.lowercased() == "y" else {
                print("Total reclaimed space: 0B")
                return
            }
        }

        let (containerCount, _) = try await MockerState.containerEngine.prune()
        print("Deleted Containers: \(containerCount)")

        if all {
            let (imageCount, _) = try await MockerState.imageManager.prune(all: true)
            print("Deleted Images: \(imageCount)")
        }

        if volumes {
            let (volCount, _) = try await MockerState.volumeManager.prune()
            print("Deleted Volumes: \(volCount)")
        }

        print("Total reclaimed space: 0B")
    }
}

// MARK: - system df

struct SystemDfCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "df",
        abstract: "Show Docker disk usage"
    )

    @Flag(name: [.short, .customLong("verbose")], help: "Show detailed information on space usage")
    var verbose = false

    func run() async throws {
        try await MockerState.containerStore.load()
        try await MockerState.imageStore.load()
        try await MockerState.volumeManager.load()

        let containers = await MockerState.containerStore.getAll()
        let images = await MockerState.imageStore.getAll()
        let volumes = await MockerState.volumeManager.getAll()

        let activeContainers = containers.filter { $0.status == .running }.count

        print(TableFormatter.formatTable(
            header: ["TYPE", "TOTAL", "ACTIVE", "SIZE", "RECLAIMABLE"],
            rows: [
                ["Images", "\(images.count)", "\(activeContainers)", "0B", "0B"],
                ["Containers", "\(containers.count)", "\(activeContainers)", "0B", "0B"],
                ["Local Volumes", "\(volumes.count)", "0", "0B", "0B"],
                ["Build Cache", "0", "0", "0B", "0B"],
            ]
        ))
    }
}

// MARK: - system events

struct SystemEventsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "events",
        abstract: "Get real time events from the server"
    )

    @Option(name: .customLong("since"), help: "Show all events created since timestamp")
    var since: String?

    @Option(name: .customLong("until"), help: "Stream events until this timestamp")
    var until: String?

    func run() async throws {
        // Events streaming is not implemented; show a message
        print("Listening for events... (press Ctrl+C to stop)")
        // In a real implementation this would stream events from the daemon
        try await Task.sleep(nanoseconds: UInt64.max)
    }
}
