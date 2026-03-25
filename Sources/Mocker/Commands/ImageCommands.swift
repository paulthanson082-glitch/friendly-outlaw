import ArgumentParser
import MockerKit
import Foundation

// MARK: - mocker images

struct ImagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "images",
        abstract: "List images"
    )

    @Flag(name: [.short, .customLong("quiet")], help: "Only show image IDs")
    var quiet = false

    @Flag(name: [.short, .customLong("all")], help: "Show all images (default hides intermediate)")
    var all = false

    @Flag(name: .customLong("no-trunc"), help: "Don't truncate output")
    var noTrunc = false

    @Argument(help: "Optional repository filter")
    var repository: String?

    func run() async throws {
        try await MockerState.imageStore.load()
        var images = await MockerState.imageStore.getAll()
        if let repo = repository {
            images = images.filter { $0.repository == repo }
        }
        let output = TableFormatter.formatImages(images, quiet: quiet, noTrunc: noTrunc)
        if !output.isEmpty { print(output) }
    }
}

// MARK: - mocker pull

struct PullCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pull",
        abstract: "Download an image from a registry"
    )

    @Option(name: .customLong("platform"), help: "Set platform if server is multi-platform capable")
    var platform: String?

    @Flag(name: [.short, .customLong("quiet")], help: "Suppress verbose output")
    var quiet = false

    @Argument(help: "Image reference (NAME[:TAG])")
    var reference: String

    func run() async throws {
        _ = try await MockerState.imageManager.pull(reference: reference, platform: platform)
    }
}

// MARK: - mocker push

struct PushCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "push",
        abstract: "Upload an image to a registry"
    )

    @Argument(help: "Image reference (NAME[:TAG])")
    var reference: String

    func run() async throws {
        try await MockerState.imageManager.push(reference: reference)
    }
}

// MARK: - mocker build

struct BuildCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build an image from a Dockerfile"
    )

    @Option(name: [.short, .customLong("tag")], help: "Name and optionally a tag (format: name:tag)")
    var tag: String?

    @Option(name: [.short, .customLong("file")], help: "Name of the Dockerfile")
    var file: String?

    @Option(name: .customLong("build-arg"), help: "Set build-time variables")
    var buildArgs: [String] = []

    @Flag(name: .customLong("no-cache"), help: "Do not use cache when building the image")
    var noCache = false

    @Flag(name: .customLong("pull"), help: "Always attempt to pull a newer version of the image")
    var pull = false

    @Option(name: .customLong("target"), help: "Set the target build stage to build")
    var target: String?

    @Option(name: .customLong("platform"), help: "Set target platform for build")
    var platform: String?

    @Option(name: .customLong("cache-from"), help: "Images to consider as cache sources")
    var cacheFrom: [String] = []

    @Flag(name: .customLong("load"), help: "Load into image store")
    var load = false

    @Flag(name: .customLong("push"), help: "Push after build")
    var push = false

    @Option(name: [.short, .customLong("label")], help: "Set metadata for an image")
    var labels: [String] = []

    @Flag(name: [.short, .customLong("quiet")], help: "Suppress the build output and print image ID on success")
    var quiet = false

    @Argument(help: "Build context (path or URL)")
    var context: String = "."

    func run() async throws {
        var argDict: [String: String] = [:]
        for a in buildArgs {
            let parts = a.split(separator: "=", maxSplits: 1)
            if parts.count == 2 { argDict[String(parts[0])] = String(parts[1]) }
        }
        var labelDict: [String: String] = [:]
        for l in labels {
            let parts = l.split(separator: "=", maxSplits: 1)
            if parts.count == 2 { labelDict[String(parts[0])] = String(parts[1]) }
        }
        let opts = BuildOptions(
            tag: tag,
            file: file,
            buildArgs: argDict,
            noCache: noCache,
            pull: pull,
            target: target,
            platform: platform,
            cacheFrom: cacheFrom,
            load: load,
            push: push,
            labels: labelDict,
            quiet: quiet
        )
        try await MockerState.imageManager.build(context: context, options: opts)
    }
}

// MARK: - mocker tag

struct TagCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tag",
        abstract: "Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE"
    )

    @Argument(help: "Source image")
    var source: String

    @Argument(help: "Target image reference")
    var target: String

    func run() async throws {
        try await MockerState.imageManager.tag(source: source, target: target)
    }
}

// MARK: - mocker rmi

struct RmiCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rmi",
        abstract: "Remove one or more images"
    )

    @Flag(name: [.short, .customLong("force")], help: "Force removal of the image")
    var force = false

    @Flag(name: .customLong("no-prune"), help: "Do not delete untagged parents")
    var noPrune = false

    @Argument(help: "Image references or IDs")
    var images: [String]

    func run() async throws {
        for identifier in images {
            let result = try await MockerState.imageManager.remove(identifier, force: force, noPrune: noPrune)
            print("Untagged: \(result)")
        }
    }
}

// MARK: - mocker image (group)

struct ImageGroupCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "image",
        abstract: "Manage images",
        subcommands: [
            ImagesCommand.self,
            PullCommand.self,
            PushCommand.self,
            BuildCommand.self,
            TagCommand.self,
            RmiCommand.self,
            ImageInspectCommand.self,
            ImagePruneCommand.self,
        ]
    )
}

struct ImageInspectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inspect",
        abstract: "Display detailed information on one or more images"
    )

    @Argument(help: "Image references or IDs")
    var images: [String]

    func run() async throws {
        let json = try await MockerState.imageManager.inspect(images)
        print(json)
    }
}

struct ImagePruneCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prune",
        abstract: "Remove unused images"
    )

    @Flag(name: [.short, .customLong("all")], help: "Remove all unused images, not just dangling ones")
    var all = false

    @Flag(name: [.short, .customLong("force")], help: "Do not prompt for confirmation")
    var force = false

    func run() async throws {
        let (count, space) = try await MockerState.imageManager.prune(all: all)
        print("Total reclaimed space: \(space)")
    }
}
