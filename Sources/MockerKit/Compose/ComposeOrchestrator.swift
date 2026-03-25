import Foundation

// MARK: - ComposeOrchestrator

public actor ComposeOrchestrator {
    private let containerEngine: ContainerEngine
    private let imageManager: ImageManager
    private let networkManager: NetworkManager
    private let volumeManager: VolumeManager

    public init(
        containerEngine: ContainerEngine,
        imageManager: ImageManager,
        networkManager: NetworkManager,
        volumeManager: VolumeManager
    ) {
        self.containerEngine = containerEngine
        self.imageManager = imageManager
        self.networkManager = networkManager
        self.volumeManager = volumeManager
    }

    // MARK: - Up

    public func up(
        file: ComposeFile,
        projectName: String,
        services: [String] = [],
        detached: Bool = true,
        build: Bool = false,
        forceRecreate: Bool = false,
        removeOrphans: Bool = false,
        scale: [String: Int] = [:]
    ) async throws {
        // Create networks
        if let networks = file.networks {
            for (name, config) in networks {
                let networkName = config?.name ?? "\(projectName)_\(name)"
                let external = config?.external ?? false
                if !external {
                    try? await networkManager.create(
                        name: networkName,
                        driver: config?.driver ?? "bridge"
                    )
                }
            }
        }

        // Create volumes
        if let volumes = file.volumes {
            for (name, config) in volumes {
                let volumeName = config?.name ?? "\(projectName)_\(name)"
                let external = config?.external ?? false
                if !external {
                    try? await volumeManager.create(name: volumeName, driver: config?.driver ?? "local")
                }
            }
        }

        // Start services in dependency order
        let serviceNames = services.isEmpty ? file.orderedServiceNames() : services
        for serviceName in serviceNames {
            guard let service = file.services[serviceName] else { continue }
            let replicas = scale[serviceName] ?? 1
            for i in 1...replicas {
                // Docker v2 naming: projectName-serviceName-index
                let containerName = "\(projectName)-\(serviceName)-\(i)"
                try await startService(
                    name: containerName,
                    serviceName: serviceName,
                    service: service,
                    projectName: projectName,
                    build: build
                )
            }
        }
    }

    private func startService(
        name: String,
        serviceName: String,
        service: ComposeService,
        projectName: String,
        build: Bool
    ) async throws {
        let imageRef: String
        if let buildConfig = service.build, build {
            let buildOpts = BuildOptions(
                tag: service.image,
                file: buildConfig.dockerfile,
                buildArgs: buildConfig.args ?? [:]
            )
            try await imageManager.build(context: buildConfig.context, options: buildOpts)
            imageRef = service.image ?? "\(projectName)_\(serviceName)"
        } else if let image = service.image {
            imageRef = image
        } else if let buildConfig = service.build {
            imageRef = service.image ?? "\(projectName)_\(serviceName)"
            let buildOpts = BuildOptions(
                tag: imageRef,
                file: buildConfig.dockerfile,
                buildArgs: buildConfig.args ?? [:]
            )
            try await imageManager.build(context: buildConfig.context, options: buildOpts)
        } else {
            throw MockerError.invalidArgument("Service \(serviceName) has no image or build configuration")
        }

        var options = ContainerRunOptions(
            name: name,
            detached: true,
            ports: service.resolvedPorts,
            environment: service.resolvedEnv,
            volumes: service.resolvedVolumes,
            networkName: "\(projectName)_default",
            labels: service.resolvedLabels.merging(
                ["com.docker.compose.project": projectName, "com.docker.compose.service": serviceName],
                uniquingKeysWith: { old, _ in old }
            ),
            restartPolicy: service.restart ?? "no",
            command: service.command?.args ?? [],
            workdir: service.workingDir,
            user: service.user,
            hostname: service.hostname
        )

        _ = try await containerEngine.run(image: imageRef, options: options)
        print("Creating \(name) ... done")
    }

    // MARK: - Down

    public func down(
        file: ComposeFile,
        projectName: String,
        removeVolumes: Bool = false,
        removeImages: Bool = false
    ) async throws {
        let serviceNames = file.orderedServiceNames().reversed()
        for serviceName in serviceNames {
            let containerName = "\(projectName)-\(serviceName)-1"
            if let container = await containerEngine.store.find(containerName) {
                _ = try? await containerEngine.remove(container.id, force: true)
                print("Stopping \(containerName) ... done")
            }
        }

        // Remove networks
        if let networks = file.networks {
            for (name, config) in networks {
                let networkName = config?.name ?? "\(projectName)_\(name)"
                let external = config?.external ?? false
                if !external {
                    try? await networkManager.remove(networkName)
                }
            }
        }

        // Remove volumes if requested
        if removeVolumes, let volumes = file.volumes {
            for (name, config) in volumes {
                let volumeName = config?.name ?? "\(projectName)_\(name)"
                let external = config?.external ?? false
                if !external {
                    try? await volumeManager.remove(volumeName)
                }
            }
        }
    }

    // MARK: - PS (list project containers)

    public func ps(file: ComposeFile, projectName: String) async -> [ContainerInfo] {
        await containerEngine.store.getAll().filter { container in
            container.labels["com.docker.compose.project"] == projectName
        }
    }

    // MARK: - Logs

    public func logs(
        file: ComposeFile,
        projectName: String,
        service: String?,
        follow: Bool = false,
        tail: String? = nil
    ) async throws {
        let containers: [ContainerInfo]
        if let svc = service {
            let name = "\(projectName)-\(svc)-1"
            containers = [await containerEngine.store.find(name)].compactMap { $0 }
        } else {
            containers = await containerEngine.store.getAll().filter { c in
                c.labels["com.docker.compose.project"] == projectName
            }
        }
        for container in containers {
            try await containerEngine.logs(container.id, follow: follow, tail: tail)
        }
    }

    // MARK: - Restart

    public func restart(
        file: ComposeFile,
        projectName: String,
        services: [String] = []
    ) async throws {
        let targets = services.isEmpty ? Array(file.services.keys) : services
        for serviceName in targets {
            let name = "\(projectName)-\(serviceName)-1"
            if let container = await containerEngine.store.find(name) {
                _ = try? await containerEngine.restart(container.id)
                print("Restarting \(name) ... done")
            }
        }
    }

    // MARK: - Pull

    public func pull(file: ComposeFile, quiet: Bool = false) async throws {
        for (_, service) in file.services {
            if let image = service.image {
                try await imageManager.pull(reference: image)
            }
        }
    }

    // MARK: - Build

    public func build(file: ComposeFile, projectName: String, services: [String] = [], noCache: Bool = false) async throws {
        let targets = services.isEmpty ? Array(file.services.keys) : services
        for serviceName in targets {
            guard let service = file.services[serviceName], let buildConfig = service.build else { continue }
            let opts = BuildOptions(
                tag: service.image ?? "\(projectName)_\(serviceName)",
                file: buildConfig.dockerfile,
                buildArgs: buildConfig.args ?? [:],
                noCache: noCache
            )
            try await imageManager.build(context: buildConfig.context, options: opts)
        }
    }
}
