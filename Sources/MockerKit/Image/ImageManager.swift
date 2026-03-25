import Foundation

// MARK: - ImageManager

public actor ImageManager {
    public let store: ImageStore

    public init(store: ImageStore) {
        self.store = store
    }

    // MARK: - Pull

    public func pull(reference: String, platform: String? = nil) async throws -> String {
        try await store.load()
        let (repo, tag) = ImageInfo.parseReference(reference)
        let fullRef = "\(repo):\(tag)"

        // Check if already present
        if await store.referenceExists(repository: repo, tag: tag) {
            print("\(tag): Image is up to date for \(fullRef)")
            return fullRef
        }

        print("Pulling from \(repo)")
        var args = ["image", "pull", fullRef]
        if let p = platform { args.insert(contentsOf: ["--platform", p], at: 2) }
        try await runContainerCLI(args)

        // Record metadata
        let image = ImageInfo(
            repository: repo,
            tag: tag,
            size: 0
        )
        try await store.add(image)
        print("Status: Downloaded newer image for \(fullRef)")
        return fullRef
    }

    // MARK: - Push

    public func push(reference: String) async throws {
        try await store.load()
        var args = ["image", "push", reference]
        try await runContainerCLI(args)
    }

    // MARK: - Build

    public func build(context: String, options: BuildOptions) async throws {
        try await store.load()
        var args = ["image", "build"]
        if let tag = options.tag { args.append(contentsOf: ["-t", tag]) }
        if let file = options.file { args.append(contentsOf: ["-f", file]) }
        for (k, v) in options.buildArgs { args.append(contentsOf: ["--build-arg", "\(k)=\(v)"]) }
        if options.noCache { args.append("--no-cache") }
        if options.pull { args.append("--pull") }
        if let target = options.target { args.append(contentsOf: ["--target", target]) }
        if let platform = options.platform { args.append(contentsOf: ["--platform", platform]) }
        for cf in options.cacheFrom { args.append(contentsOf: ["--cache-from", cf]) }
        if options.load { args.append("--load") }
        if options.push { args.append("--push") }
        if options.quiet { args.append("-q") }
        for (k, v) in options.labels { args.append(contentsOf: ["--label", "\(k)=\(v)"]) }
        args.append(context)
        try await runContainerCLI(args)

        // Record metadata if tag provided
        if let tag = options.tag {
            let (repo, imgTag) = ImageInfo.parseReference(tag)
            let image = ImageInfo(repository: repo, tag: imgTag, size: 0)
            try await store.add(image)
        }
    }

    // MARK: - Tag

    public func tag(source: String, target: String) async throws {
        try await store.load()
        guard await store.find(source) != nil else {
            throw MockerError.imageNotFound(source)
        }
        let (repo, tag) = ImageInfo.parseReference(target)
        let newImage = ImageInfo(repository: repo, tag: tag, size: 0)
        try await store.add(newImage)
        try await runContainerCLI(["image", "tag", source, target])
    }

    // MARK: - Remove

    public func remove(_ identifier: String, force: Bool = false, noPrune: Bool = false) async throws -> String {
        try await store.load()
        guard let image = await store.find(identifier) else {
            throw MockerError.imageNotFound(identifier)
        }
        var args = ["image", "rm"]
        if force { args.append("--force") }
        if noPrune { args.append("--no-prune") }
        args.append(image.reference)
        try await runContainerCLI(args)
        try await store.remove(id: image.id)
        return image.reference
    }

    // MARK: - Inspect

    public func inspect(_ identifiers: [String]) async throws -> String {
        try await store.load()
        var results: [ImageInfo] = []
        for ident in identifiers {
            if let img = await store.find(ident) {
                results.append(img)
            } else {
                throw MockerError.imageNotFound(ident)
            }
        }
        return try MockerPersistence.toJSONString(results)
    }

    // MARK: - Prune

    public func prune(all: Bool = false) async throws -> (count: Int, spaceSaved: String) {
        try await store.load()
        let all_images = await store.getAll()
        var count = 0
        for img in all_images {
            try? await store.remove(id: img.id)
            count += 1
        }
        return (count, "0B")
    }

    // MARK: - Helpers

    @discardableResult
    private func runContainerCLI(_ args: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: MockerConfig.containerCLI)
        process.arguments = args
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            if !FileManager.default.fileExists(atPath: MockerConfig.containerCLI) {
                return ""
            }
            throw MockerError.ioError("Failed to run container CLI: \(error.localizedDescription)")
        }
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            let msg = errorOutput.isEmpty ? output : errorOutput
            throw MockerError.commandFailed(msg.trimmingCharacters(in: .whitespacesAndNewlines), process.terminationStatus)
        }
        return output
    }
}
