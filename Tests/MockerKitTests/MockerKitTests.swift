import XCTest
@testable import MockerKit

final class MockerKitTests: XCTestCase {

    // MARK: - ContainerInfo Tests

    func testContainerInfoShortId() {
        let container = ContainerInfo(
            id: "abcdef1234567890abcdef1234567890",
            name: "test",
            image: "nginx:latest"
        )
        XCTAssertEqual(container.shortId, "abcdef123456")
    }

    func testContainerInfoReference() {
        let container = ContainerInfo(name: "web", image: "nginx:1.25")
        XCTAssertEqual(container.image, "nginx:1.25")
    }

    func testContainerStatusDescription_running() {
        var container = ContainerInfo(name: "web", image: "nginx:latest", status: .running)
        container = ContainerInfo(
            id: container.id,
            name: container.name,
            image: container.image,
            status: .running,
            startedAt: Date().addingTimeInterval(-120)
        )
        XCTAssertTrue(container.statusDescription.hasPrefix("Up"))
    }

    func testContainerStatusDescription_stopped() {
        let container = ContainerInfo(
            name: "web",
            image: "nginx:latest",
            status: .stopped,
            finishedAt: Date().addingTimeInterval(-3600)
        )
        XCTAssertTrue(container.statusDescription.contains("Exited"))
    }

    // MARK: - PortMapping Tests

    func testPortMappingParse_standard() {
        let mapping = PortMapping.parse("8080:80")
        XCTAssertNotNil(mapping)
        XCTAssertEqual(mapping?.hostPort, 8080)
        XCTAssertEqual(mapping?.containerPort, 80)
        XCTAssertEqual(mapping?.protocol, "tcp")
    }

    func testPortMappingParse_withProtocol() {
        let mapping = PortMapping.parse("5353:53/udp")
        XCTAssertNotNil(mapping)
        XCTAssertEqual(mapping?.hostPort, 5353)
        XCTAssertEqual(mapping?.containerPort, 53)
        XCTAssertEqual(mapping?.protocol, "udp")
    }

    func testPortMappingParse_invalid() {
        XCTAssertNil(PortMapping.parse("not-a-port"))
    }

    func testPortMappingDescription() {
        let mapping = PortMapping(hostPort: 8080, containerPort: 80)
        XCTAssertEqual(mapping.description, "0.0.0.0:8080->80/tcp")
    }

    // MARK: - VolumeMount Tests

    func testVolumeMountParse_readWrite() {
        let mount = VolumeMount.parse("/host/data:/app/data")
        XCTAssertNotNil(mount)
        XCTAssertEqual(mount?.hostPath, "/host/data")
        XCTAssertEqual(mount?.containerPath, "/app/data")
        XCTAssertEqual(mount?.readOnly, false)
    }

    func testVolumeMountParse_readOnly() {
        let mount = VolumeMount.parse("/host/config:/etc/config:ro")
        XCTAssertNotNil(mount)
        XCTAssertEqual(mount?.readOnly, true)
    }

    func testVolumeMountParse_invalid() {
        XCTAssertNil(VolumeMount.parse("/only-one-part"))
    }

    // MARK: - ImageInfo Tests

    func testImageInfoShortId() {
        let image = ImageInfo(
            id: "sha256abcdef123456789012345678901234",
            repository: "nginx",
            tag: "latest"
        )
        XCTAssertEqual(image.shortId, "sha256abcdef")
    }

    func testImageInfoReference() {
        let image = ImageInfo(repository: "postgres", tag: "15")
        XCTAssertEqual(image.reference, "postgres:15")
    }

    func testImageInfoParseReference_withTag() {
        let (repo, tag) = ImageInfo.parseReference("nginx:1.25")
        XCTAssertEqual(repo, "nginx")
        XCTAssertEqual(tag, "1.25")
    }

    func testImageInfoParseReference_noTag() {
        let (repo, tag) = ImageInfo.parseReference("alpine")
        XCTAssertEqual(repo, "alpine")
        XCTAssertEqual(tag, "latest")
    }

    func testImageInfoParseReference_registry() {
        let (repo, tag) = ImageInfo.parseReference("registry.example.com/myapp:v1.0")
        XCTAssertEqual(repo, "registry.example.com/myapp")
        XCTAssertEqual(tag, "v1.0")
    }

    func testImageInfoSizeDescription() {
        let smallImage = ImageInfo(repository: "alpine", size: 5_242_880) // 5 MB
        XCTAssertTrue(smallImage.sizeDescription.contains("MB"))

        let largeImage = ImageInfo(repository: "ubuntu", size: 1_073_741_824) // 1 GB
        XCTAssertTrue(largeImage.sizeDescription.contains("GB"))
    }

    // MARK: - ContainerStore Tests

    func testContainerStore_addAndFind() async throws {
        let store = ContainerStore()
        // Use in-memory by not loading from disk
        let container = ContainerInfo(id: "test123", name: "test-web", image: "nginx:latest")
        try await store.add(container)

        let found = await store.find("test-web")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "test-web")
    }

    func testContainerStore_findByShortId() async throws {
        let store = ContainerStore()
        let container = ContainerInfo(id: "abcdef123456789012345678", name: "myapp", image: "myapp:latest")
        try await store.add(container)

        let found = await store.find("abcdef123456")
        XCTAssertNotNil(found)
    }

    func testContainerStore_nameExists() async throws {
        let store = ContainerStore()
        let container = ContainerInfo(name: "unique-name", image: "nginx")
        try await store.add(container)
        let exists = await store.nameExists("unique-name")
        XCTAssertTrue(exists)
        let notExists = await store.nameExists("other-name")
        XCTAssertFalse(notExists)
    }

    func testContainerStore_remove() async throws {
        let store = ContainerStore()
        let container = ContainerInfo(id: "removeme", name: "removeme-app", image: "nginx")
        try await store.add(container)
        try await store.remove(id: "removeme")
        let found = await store.find("removeme-app")
        XCTAssertNil(found)
    }

    // MARK: - ImageStore Tests

    func testImageStore_addAndFind() async throws {
        let store = ImageStore()
        let image = ImageInfo(repository: "nginx", tag: "1.25")
        try await store.add(image)

        let found = await store.find("nginx:1.25")
        XCTAssertNotNil(found)
    }

    func testImageStore_findByShortId() async throws {
        let store = ImageStore()
        let image = ImageInfo(id: "abcdef123456789012", repository: "alpine", tag: "latest")
        try await store.add(image)
        let found = await store.find("abcdef123456")
        XCTAssertNotNil(found)
    }

    func testImageStore_referenceExists() async throws {
        let store = ImageStore()
        let image = ImageInfo(repository: "postgres", tag: "15")
        try await store.add(image)
        let exists = await store.referenceExists(repository: "postgres", tag: "15")
        XCTAssertTrue(exists)
        let notExists = await store.referenceExists(repository: "postgres", tag: "16")
        XCTAssertFalse(notExists)
    }

    // MARK: - NetworkInfo Tests

    func testNetworkInfoShortId() {
        let network = NetworkInfo(
            id: "abcdef1234567890abcdef1234",
            name: "mynet"
        )
        XCTAssertEqual(network.shortId, "abcdef123456")
    }

    func testNetworkManager_createAndFind() async throws {
        let manager = NetworkManager()
        // Pre-load defaults
        try await manager.load()

        let network = try await manager.create(name: "test-network-\(UUID().uuidString.prefix(8))")
        XCTAssertEqual(network.driver, "bridge")

        let found = await manager.find(network.name)
        XCTAssertNotNil(found)
    }

    func testNetworkManager_removeDefaultFails() async throws {
        let manager = NetworkManager()
        try await manager.load()
        do {
            _ = try await manager.remove("bridge")
            XCTFail("Expected an error to be thrown when removing default network")
        } catch {
            // Expected: default networks cannot be removed
        }
    }

    // MARK: - VolumeManager Tests (sync subset)

    func testVolumeInfo_defaultMountpoint() {
        let vol = VolumeInfo(name: "pgdata")
        XCTAssertTrue(vol.mountpoint.contains("pgdata"))
        XCTAssertTrue(vol.mountpoint.hasSuffix("_data"))
    }

    // MARK: - MockerConfig Tests

    func testMockerConfig_paths() {
        XCTAssertTrue(MockerConfig.rootDir.hasSuffix(".mocker"))
        XCTAssertTrue(MockerConfig.containersDir.hasSuffix("containers"))
        XCTAssertTrue(MockerConfig.imagesDir.hasSuffix("images"))
        XCTAssertTrue(MockerConfig.networksDir.hasSuffix("networks"))
        XCTAssertTrue(MockerConfig.volumesDir.hasSuffix("volumes"))
    }

    func testMockerConfig_containerPath() {
        let path = MockerConfig.containerPath(id: "abc123")
        XCTAssertTrue(path.hasSuffix("containers/abc123.json"))
    }

    // MARK: - MockerError Tests

    func testMockerError_descriptions() {
        let errors: [(MockerError, String)] = [
            (.containerNotFound("myapp"), "No such container: myapp"),
            (.imageNotFound("nginx:missing"), "No such image: nginx:missing"),
            (.networkNotFound("mynet"), "network mynet not found"),
            (.volumeNotFound("pgdata"), "no such volume"),
            (.nameConflict("web"), "web"),
        ]
        for (error, expected) in errors {
            XCTAssertTrue(error.errorDescription?.contains(expected) ?? false,
                          "Error \(error) should contain '\(expected)'")
        }
    }

    // MARK: - ComposeFile Tests

    func testComposeFile_parseSimple() throws {
        let yaml = """
        version: "3.8"
        services:
          web:
            image: nginx:1.25
            ports:
              - "8080:80"
          db:
            image: postgres:15
            environment:
              POSTGRES_PASSWORD: secret
        """
        let compose = try ComposeFile.loadFromString(yaml)
        XCTAssertEqual(compose.services.count, 2)
        XCTAssertEqual(compose.services["web"]?.image, "nginx:1.25")
        XCTAssertEqual(compose.services["db"]?.image, "postgres:15")
    }

    func testComposeFile_variableSubstitution() {
        let yaml = """
        services:
          web:
            image: nginx:${NGINX_VERSION:-1.25}
        """
        let env = ProcessInfo.processInfo.environment
        let substituted = ComposeFile.substituteVariables(yaml)
        // If NGINX_VERSION is not set, should use default "1.25"
        if env["NGINX_VERSION"] == nil {
            XCTAssertTrue(substituted.contains("nginx:1.25"))
        }
    }

    func testComposeFile_dependsOnOrdering() throws {
        let yaml = """
        services:
          web:
            image: nginx
            depends_on:
              - api
          api:
            image: myapp
            depends_on:
              - db
          db:
            image: postgres
        """
        let compose = try ComposeFile.loadFromString(yaml)
        let order = compose.orderedServiceNames()
        let dbIdx = order.firstIndex(of: "db")!
        let apiIdx = order.firstIndex(of: "api")!
        let webIdx = order.firstIndex(of: "web")!
        XCTAssertLessThan(dbIdx, apiIdx)
        XCTAssertLessThan(apiIdx, webIdx)
    }

    func testComposeService_resolvedPorts() throws {
        let yaml = """
        services:
          web:
            image: nginx
            ports:
              - "8080:80"
              - "443:443"
        """
        let compose = try ComposeFile.loadFromString(yaml)
        let ports = compose.services["web"]?.resolvedPorts ?? []
        XCTAssertEqual(ports.count, 2)
        XCTAssertEqual(ports[0].hostPort, 8080)
        XCTAssertEqual(ports[0].containerPort, 80)
    }

    func testComposeService_resolvedEnvFromDict() throws {
        let yaml = """
        services:
          db:
            image: postgres
            environment:
              POSTGRES_DB: myapp
              POSTGRES_PORT: "5432"
        """
        let compose = try ComposeFile.loadFromString(yaml)
        let env = compose.services["db"]?.resolvedEnv ?? [:]
        XCTAssertEqual(env["POSTGRES_DB"], "myapp")
        XCTAssertEqual(env["POSTGRES_PORT"], "5432")
    }

    func testComposeService_resolvedEnvFromList() throws {
        let yaml = """
        services:
          app:
            image: myapp
            environment:
              - APP_ENV=production
              - DEBUG=false
        """
        let compose = try ComposeFile.loadFromString(yaml)
        let env = compose.services["app"]?.resolvedEnv ?? [:]
        XCTAssertEqual(env["APP_ENV"], "production")
        XCTAssertEqual(env["DEBUG"], "false")
    }

    // MARK: - TableFormatter Tests

    func testTableFormatter_formatPS_quiet() {
        let containers = [
            ContainerInfo(id: "abc123def456789", name: "web", image: "nginx", status: .running),
        ]
        let output = TableFormatter.formatPS(containers, all: false, quiet: true, noTrunc: false)
        XCTAssertEqual(output, "abc123def456")
    }

    func testTableFormatter_formatPS_headers() {
        let containers: [ContainerInfo] = []
        let output = TableFormatter.formatPS(containers, all: false, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("CONTAINER ID"))
        XCTAssertTrue(output.contains("IMAGE"))
        XCTAssertTrue(output.contains("STATUS"))
    }

    func testTableFormatter_formatImages_quiet() {
        let images = [
            ImageInfo(id: "abc123def456789", repository: "nginx", tag: "latest"),
        ]
        let output = TableFormatter.formatImages(images, quiet: true, noTrunc: false)
        XCTAssertEqual(output, "abc123def456")
    }

    func testTableFormatter_formatNetworks() {
        let networks = [NetworkInfo(name: "bridge", driver: "bridge")]
        let output = TableFormatter.formatNetworks(networks)
        XCTAssertTrue(output.contains("bridge"))
        XCTAssertTrue(output.contains("NETWORK ID"))
    }

    func testTableFormatter_relativeTime() {
        let now = Date()
        XCTAssertTrue(TableFormatter.relativeTime(now.addingTimeInterval(-30)).contains("seconds"))
        XCTAssertTrue(TableFormatter.relativeTime(now.addingTimeInterval(-120)).contains("minutes"))
        XCTAssertTrue(TableFormatter.relativeTime(now.addingTimeInterval(-7200)).contains("hours"))
        XCTAssertTrue(TableFormatter.relativeTime(now.addingTimeInterval(-172800)).contains("days"))
    }

    func testTableFormatter_relativeTime_weeks() {
        let now = Date()
        let twoWeeksAgo = now.addingTimeInterval(-14 * 24 * 3600)
        let result = TableFormatter.relativeTime(twoWeeksAgo)
        XCTAssertTrue(result.contains("weeks"), "Expected 'weeks' in '\(result)'")
    }

    func testTableFormatter_relativeTime_months() {
        let now = Date()
        let sixtyDaysAgo = now.addingTimeInterval(-60 * 24 * 3600)
        let result = TableFormatter.relativeTime(sixtyDaysAgo)
        XCTAssertTrue(result.contains("months"), "Expected 'months' in '\(result)'")
    }

    func testTableFormatter_relativeTime_years() {
        let now = Date()
        let fourHundredDaysAgo = now.addingTimeInterval(-400 * 24 * 3600)
        let result = TableFormatter.relativeTime(fourHundredDaysAgo)
        XCTAssertTrue(result.contains("years"), "Expected 'years' in '\(result)'")
    }

    func testTableFormatter_formatPS_noTrunc_showsFullId() {
        let fullId = "abcdef1234567890abcdef1234567890"
        let containers = [
            ContainerInfo(id: fullId, name: "web", image: "nginx:latest", status: .running),
        ]
        let output = TableFormatter.formatPS(containers, all: false, quiet: false, noTrunc: true)
        XCTAssertTrue(output.contains(fullId), "noTrunc should show full ID")
    }

    func testTableFormatter_formatPS_quiet_noTrunc_showsFullId() {
        let fullId = "abcdef1234567890abcdef1234567890"
        let containers = [
            ContainerInfo(id: fullId, name: "web", image: "nginx:latest"),
        ]
        let output = TableFormatter.formatPS(containers, all: false, quiet: true, noTrunc: true)
        XCTAssertEqual(output, fullId)
    }

    func testTableFormatter_formatPS_emptyList_showsHeaderOnly() {
        let output = TableFormatter.formatPS([], all: false, quiet: false, noTrunc: false)
        // Should have header but no data rows
        let lines = output.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines[0].contains("CONTAINER ID"))
        XCTAssertTrue(lines[0].contains("NAMES"))
    }

    func testTableFormatter_formatPS_quiet_emptyList() {
        let output = TableFormatter.formatPS([], all: false, quiet: true, noTrunc: false)
        XCTAssertEqual(output, "")
    }

    func testTableFormatter_formatPS_multipleContainers() {
        let containers = [
            ContainerInfo(id: "aaa111222333444", name: "web", image: "nginx:latest", status: .running),
            ContainerInfo(id: "bbb555666777888", name: "db", image: "postgres:15", status: .stopped),
        ]
        let output = TableFormatter.formatPS(containers, all: false, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("web"))
        XCTAssertTrue(output.contains("db"))
        XCTAssertTrue(output.contains("nginx:latest"))
        XCTAssertTrue(output.contains("postgres:15"))
    }

    func testTableFormatter_formatPS_quiet_multipleContainers() {
        let containers = [
            ContainerInfo(id: "aaa111222333444", name: "web", image: "nginx:latest"),
            ContainerInfo(id: "bbb555666777888", name: "db", image: "postgres:15"),
        ]
        let output = TableFormatter.formatPS(containers, all: false, quiet: true, noTrunc: false)
        let lines = output.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0], "aaa111222333")
        XCTAssertEqual(lines[1], "bbb555666777")
    }

    func testTableFormatter_formatPS_withPorts() {
        let ports = [PortMapping(hostPort: 8080, containerPort: 80)]
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "web",
            image: "nginx:latest",
            status: .running,
            ports: ports
        )
        let output = TableFormatter.formatPS([container], all: false, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("8080"))
        XCTAssertTrue(output.contains("80"))
    }

    func testTableFormatter_formatPS_withCommand() {
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "web",
            image: "nginx:latest",
            command: "nginx -g daemon off;"
        )
        let output = TableFormatter.formatPS([container], all: false, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("nginx"))
    }

    func testTableFormatter_formatPS_longCommandTruncated() {
        let longCmd = String(repeating: "x", count: 50)
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "web",
            image: "nginx:latest",
            command: longCmd
        )
        let output = TableFormatter.formatPS([container], all: false, quiet: false, noTrunc: false)
        // Command column is truncated to 20 chars (with "...") when noTrunc is false
        XCTAssertTrue(output.contains("..."), "Long command should be truncated with '...'")
        XCTAssertFalse(output.contains(longCmd), "Full long command should not appear when noTrunc is false")
    }

    func testTableFormatter_formatPS_longCommandNotTruncatedWithNoTrunc() {
        let longCmd = String(repeating: "x", count: 50)
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "web",
            image: "nginx:latest",
            command: longCmd
        )
        let output = TableFormatter.formatPS([container], all: false, quiet: false, noTrunc: true)
        XCTAssertTrue(output.contains(longCmd), "Full long command should appear when noTrunc is true")
    }

    func testTableFormatter_formatPS_emptyCommand_showsQuotes() {
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "web",
            image: "nginx:latest",
            command: ""
        )
        let output = TableFormatter.formatPS([container], all: false, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("\"\""), "Empty command should render as '\"\"'")
    }

    // MARK: - formatImages Additional Tests

    func testTableFormatter_formatImages_nonQuiet_showsHeaders() {
        let images = [
            ImageInfo(id: "abc123def456789", repository: "nginx", tag: "latest"),
        ]
        let output = TableFormatter.formatImages(images, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("REPOSITORY"))
        XCTAssertTrue(output.contains("TAG"))
        XCTAssertTrue(output.contains("IMAGE ID"))
        XCTAssertTrue(output.contains("SIZE"))
    }

    func testTableFormatter_formatImages_nonQuiet_showsData() {
        let images = [
            ImageInfo(id: "abc123def456789", repository: "nginx", tag: "1.25"),
        ]
        let output = TableFormatter.formatImages(images, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("nginx"))
        XCTAssertTrue(output.contains("1.25"))
    }

    func testTableFormatter_formatImages_noTrunc_showsFullId() {
        let fullId = "sha256abcdef123456789012345678901234"
        let images = [
            ImageInfo(id: fullId, repository: "nginx", tag: "latest"),
        ]
        let output = TableFormatter.formatImages(images, quiet: false, noTrunc: true)
        XCTAssertTrue(output.contains(fullId), "noTrunc should show full image ID")
    }

    func testTableFormatter_formatImages_quiet_noTrunc() {
        let fullId = "sha256abcdef123456789012345678901234"
        let images = [
            ImageInfo(id: fullId, repository: "nginx", tag: "latest"),
        ]
        let output = TableFormatter.formatImages(images, quiet: true, noTrunc: true)
        XCTAssertEqual(output, fullId)
    }

    func testTableFormatter_formatImages_quiet_emptyList() {
        let output = TableFormatter.formatImages([], quiet: true, noTrunc: false)
        XCTAssertEqual(output, "")
    }

    func testTableFormatter_formatImages_emptyList_showsHeaderOnly() {
        let output = TableFormatter.formatImages([], quiet: false, noTrunc: false)
        let lines = output.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines[0].contains("REPOSITORY"))
    }

    func testTableFormatter_formatImages_sizeInOutput() {
        let images = [
            ImageInfo(id: "abc123def456789", repository: "ubuntu", size: 1_073_741_824), // 1 GB
        ]
        let output = TableFormatter.formatImages(images, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("GB"), "Image size should show GB for large images")
    }

    func testTableFormatter_formatImages_multipleImages() {
        let images = [
            ImageInfo(id: "aaa111222333444", repository: "nginx", tag: "latest"),
            ImageInfo(id: "bbb555666777888", repository: "postgres", tag: "15"),
        ]
        let output = TableFormatter.formatImages(images, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("nginx"))
        XCTAssertTrue(output.contains("postgres"))
    }

    func testTableFormatter_formatImages_quiet_multipleImages() {
        let images = [
            ImageInfo(id: "aaa111222333444", repository: "nginx", tag: "latest"),
            ImageInfo(id: "bbb555666777888", repository: "postgres", tag: "15"),
        ]
        let output = TableFormatter.formatImages(images, quiet: true, noTrunc: false)
        let lines = output.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0], "aaa111222333")
        XCTAssertEqual(lines[1], "bbb555666777")
    }

    // MARK: - formatVolumes Tests

    func testTableFormatter_formatVolumes_showsHeaders() {
        let volumes: [VolumeInfo] = []
        let output = TableFormatter.formatVolumes(volumes)
        XCTAssertTrue(output.contains("DRIVER"))
        XCTAssertTrue(output.contains("VOLUME NAME"))
    }

    func testTableFormatter_formatVolumes_showsVolumeData() {
        let volumes = [VolumeInfo(name: "pgdata", driver: "local")]
        let output = TableFormatter.formatVolumes(volumes)
        XCTAssertTrue(output.contains("pgdata"))
        XCTAssertTrue(output.contains("local"))
    }

    func testTableFormatter_formatVolumes_multipleVolumes() {
        let volumes = [
            VolumeInfo(name: "pgdata", driver: "local"),
            VolumeInfo(name: "redis-data", driver: "local"),
        ]
        let output = TableFormatter.formatVolumes(volumes)
        XCTAssertTrue(output.contains("pgdata"))
        XCTAssertTrue(output.contains("redis-data"))
        let lines = output.components(separatedBy: "\n")
        // Header + 2 data rows = 3 lines
        XCTAssertEqual(lines.count, 3)
    }

    func testTableFormatter_formatVolumes_customDriver() {
        let volumes = [VolumeInfo(name: "nfs-vol", driver: "nfs")]
        let output = TableFormatter.formatVolumes(volumes)
        XCTAssertTrue(output.contains("nfs"))
        XCTAssertTrue(output.contains("nfs-vol"))
    }

    // MARK: - formatStats Tests

    func testTableFormatter_formatStats_showsHeaders() {
        let stats: [ContainerStats] = []
        let output = TableFormatter.formatStats(stats, noStream: true)
        XCTAssertTrue(output.contains("CONTAINER ID"))
        XCTAssertTrue(output.contains("NAME"))
        XCTAssertTrue(output.contains("CPU %"))
        XCTAssertTrue(output.contains("MEM USAGE / LIMIT"))
        XCTAssertTrue(output.contains("NET I/O"))
        XCTAssertTrue(output.contains("BLOCK I/O"))
        XCTAssertTrue(output.contains("PIDS"))
    }

    func testTableFormatter_formatStats_showsCpuPercent() {
        let stats = [
            ContainerStats(
                containerId: "abc123def456789",
                name: "web",
                cpuPercent: 12.34,
                memUsage: 1_048_576,
                memLimit: 2_147_483_648,
                networkRx: 1024,
                networkTx: 512,
                blockRead: 0,
                blockWrite: 0,
                pids: 5
            )
        ]
        let output = TableFormatter.formatStats(stats, noStream: true)
        XCTAssertTrue(output.contains("12.34%"), "CPU percent should be formatted with 2 decimal places")
    }

    func testTableFormatter_formatStats_showsMemUsageAndLimit() {
        let stats = [
            ContainerStats(
                containerId: "abc123def456789",
                name: "web",
                cpuPercent: 0.5,
                memUsage: 5_242_880,    // 5 MB
                memLimit: 1_073_741_824, // 1 GB
                networkRx: 0,
                networkTx: 0,
                blockRead: 0,
                blockWrite: 0,
                pids: 2
            )
        ]
        let output = TableFormatter.formatStats(stats, noStream: true)
        XCTAssertTrue(output.contains("MB"), "Memory usage should display in MB")
        XCTAssertTrue(output.contains("GB"), "Memory limit should display in GB")
    }

    func testTableFormatter_formatStats_showsMemPercent() {
        let memUsage: UInt64 = 536_870_912   // 512 MB
        let memLimit: UInt64 = 1_073_741_824  // 1 GB
        let stats = [
            ContainerStats(
                containerId: "abc123def456789",
                name: "web",
                cpuPercent: 0.0,
                memUsage: memUsage,
                memLimit: memLimit,
                networkRx: 0,
                networkTx: 0,
                blockRead: 0,
                blockWrite: 0,
                pids: 1
            )
        ]
        let output = TableFormatter.formatStats(stats, noStream: true)
        // memPercent = 50.00%
        XCTAssertTrue(output.contains("50.00%"), "Memory percent should be 50.00% for half usage")
    }

    func testTableFormatter_formatStats_showsShortContainerId() {
        let stats = [
            ContainerStats(
                containerId: "abcdef1234567890xyz",
                name: "web",
                cpuPercent: 0.0,
                memUsage: 0,
                memLimit: 0,
                networkRx: 0,
                networkTx: 0,
                blockRead: 0,
                blockWrite: 0,
                pids: 0
            )
        ]
        let output = TableFormatter.formatStats(stats, noStream: true)
        XCTAssertTrue(output.contains("abcdef123456"), "Stats should show 12-char container ID")
        XCTAssertFalse(output.contains("abcdef1234567890xyz"), "Stats should not show full long ID")
    }

    func testTableFormatter_formatStats_showsPids() {
        let stats = [
            ContainerStats(
                containerId: "abc123def456789",
                name: "web",
                cpuPercent: 0.0,
                memUsage: 0,
                memLimit: 0,
                networkRx: 0,
                networkTx: 0,
                blockRead: 0,
                blockWrite: 0,
                pids: 42
            )
        ]
        let output = TableFormatter.formatStats(stats, noStream: true)
        XCTAssertTrue(output.contains("42"), "PID count should appear in stats output")
    }

    func testTableFormatter_formatStats_networkIO_bytes() {
        let stats = [
            ContainerStats(
                containerId: "abc123def456789",
                name: "web",
                cpuPercent: 0.0,
                memUsage: 0,
                memLimit: 0,
                networkRx: 512,
                networkTx: 256,
                blockRead: 0,
                blockWrite: 0,
                pids: 1
            )
        ]
        let output = TableFormatter.formatStats(stats, noStream: true)
        XCTAssertTrue(output.contains("512B"), "Network RX should show in bytes")
        XCTAssertTrue(output.contains("256B"), "Network TX should show in bytes")
    }

    func testTableFormatter_formatStats_zeroMemLimit_zeroPercent() {
        let stats = [
            ContainerStats(
                containerId: "abc123def456789",
                name: "web",
                cpuPercent: 0.0,
                memUsage: 1024,
                memLimit: 0,  // zero limit → 0% mem
                networkRx: 0,
                networkTx: 0,
                blockRead: 0,
                blockWrite: 0,
                pids: 1
            )
        ]
        let output = TableFormatter.formatStats(stats, noStream: true)
        XCTAssertTrue(output.contains("0.00%"), "Zero memLimit should yield 0.00% memory usage")
    }

    // MARK: - formatComposePS Tests

    func testTableFormatter_formatComposePS_showsHeaders() {
        let output = TableFormatter.formatComposePS([], projectName: "myapp")
        XCTAssertTrue(output.contains("NAME"))
        XCTAssertTrue(output.contains("IMAGE"))
        XCTAssertTrue(output.contains("SERVICE"))
        XCTAssertTrue(output.contains("STATUS"))
    }

    func testTableFormatter_formatComposePS_showsContainerData() {
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "myapp-web-1",
            image: "nginx:latest",
            status: .running,
            labels: ["com.docker.compose.service": "web"]
        )
        let output = TableFormatter.formatComposePS([container], projectName: "myapp")
        XCTAssertTrue(output.contains("myapp-web-1"))
        XCTAssertTrue(output.contains("nginx:latest"))
        XCTAssertTrue(output.contains("web"))
    }

    func testTableFormatter_formatComposePS_showsServiceLabel() {
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "myapp-db-1",
            image: "postgres:15",
            labels: ["com.docker.compose.service": "database"]
        )
        let output = TableFormatter.formatComposePS([container], projectName: "myapp")
        XCTAssertTrue(output.contains("database"), "Service label should appear in compose ps output")
    }

    func testTableFormatter_formatComposePS_noServiceLabel_showsEmpty() {
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "standalone-container",
            image: "alpine:latest"
            // No compose labels
        )
        let output = TableFormatter.formatComposePS([container], projectName: "myapp")
        XCTAssertTrue(output.contains("standalone-container"))
        XCTAssertTrue(output.contains("alpine:latest"))
    }

    func testTableFormatter_formatComposePS_withPorts() {
        let ports = [PortMapping(hostPort: 3000, containerPort: 3000)]
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "myapp-api-1",
            image: "myapp:latest",
            ports: ports,
            labels: ["com.docker.compose.service": "api"]
        )
        let output = TableFormatter.formatComposePS([container], projectName: "myapp")
        XCTAssertTrue(output.contains("3000"))
    }

    func testTableFormatter_formatComposePS_multipleContainers() {
        let containers = [
            ContainerInfo(
                id: "aaa111222333444",
                name: "myapp-web-1",
                image: "nginx:latest",
                labels: ["com.docker.compose.service": "web"]
            ),
            ContainerInfo(
                id: "bbb555666777888",
                name: "myapp-db-1",
                image: "postgres:15",
                labels: ["com.docker.compose.service": "db"]
            ),
        ]
        let output = TableFormatter.formatComposePS(containers, projectName: "myapp")
        XCTAssertTrue(output.contains("myapp-web-1"))
        XCTAssertTrue(output.contains("myapp-db-1"))
        let lines = output.components(separatedBy: "\n")
        // Header + 2 rows = 3 lines
        XCTAssertEqual(lines.count, 3)
    }

    // MARK: - formatTable Generic Tests

    func testTableFormatter_formatTable_basicAlignment() {
        let header = ["NAME", "VALUE"]
        let rows = [["short", "x"], ["a-much-longer-name", "y"]]
        let output = TableFormatter.formatTable(header: header, rows: rows)
        let lines = output.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 3) // header + 2 rows
        // Column widths should match longest entry
        XCTAssertTrue(lines[0].hasPrefix("NAME"))
        XCTAssertTrue(lines[1].contains("short"))
        XCTAssertTrue(lines[2].contains("a-much-longer-name"))
    }

    func testTableFormatter_formatTable_emptyRows() {
        let header = ["COL1", "COL2", "COL3"]
        let output = TableFormatter.formatTable(header: header, rows: [])
        let lines = output.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines[0].contains("COL1"))
        XCTAssertTrue(lines[0].contains("COL2"))
        XCTAssertTrue(lines[0].contains("COL3"))
    }

    func testTableFormatter_formatTable_separatorBetweenColumns() {
        let header = ["A", "B"]
        let rows = [["1", "2"]]
        let output = TableFormatter.formatTable(header: header, rows: rows)
        // Columns are separated by 3 spaces
        XCTAssertTrue(output.contains("   "), "Columns should be separated by three spaces")
    }

    func testTableFormatter_formatTable_singleColumn() {
        let header = ["ONLY"]
        let rows = [["value1"], ["value2"]]
        let output = TableFormatter.formatTable(header: header, rows: rows)
        XCTAssertTrue(output.contains("ONLY"))
        XCTAssertTrue(output.contains("value1"))
        XCTAssertTrue(output.contains("value2"))
    }

    func testTableFormatter_formatTable_columnsPaddedToWidth() {
        let header = ["SHORT", "LONGCOLUMNNAME"]
        let rows = [["a", "b"]]
        let output = TableFormatter.formatTable(header: header, rows: rows)
        // "a" should be padded to match "SHORT" (5 chars), then "   " separator
        let lines = output.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 2)
        // Row line should start with "a" followed by spaces to match header width
        XCTAssertTrue(lines[1].hasPrefix("a"))
    }
}
