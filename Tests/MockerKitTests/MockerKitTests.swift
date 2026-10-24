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
        XCTAssertEqual(image.shortId, "sha256abcdef12")
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

    // MARK: - ImageInfo.shortId: bare sha256 prefix (no colon)
    //
    // PR change: IDs that start with "sha256" but have no colon now return the first 14
    // characters of the full ID instead of falling through to the 12-character default.

    /// Normal case: ID starts with "sha256" (no colon) and is long enough → first 14 chars returned.
    func testImageInfoShortId_sha256BarePrefix_returns14Chars() {
        let image = ImageInfo(
            id: "sha256abcdef12345678901234",
            repository: "myapp",
            tag: "v1"
        )
        XCTAssertEqual(image.shortId, "sha256abcdef12",
            "Bare 'sha256' prefix without colon must return first 14 characters")
    }

    /// Boundary: ID is exactly 14 characters starting with "sha256" → full ID returned.
    func testImageInfoShortId_sha256BarePrefix_exactlyFourteenChars() {
        let image = ImageInfo(
            id: "sha256abcdefgh",   // exactly 14 chars
            repository: "alpine",
            tag: "edge"
        )
        XCTAssertEqual(image.shortId, "sha256abcdefgh",
            "When ID has exactly 14 characters and bare 'sha256' prefix, all 14 must be returned")
    }

    /// Boundary: ID is shorter than 14 characters starting with "sha256" → returns all available chars.
    func testImageInfoShortId_sha256BarePrefix_shorterThanFourteen() {
        let image = ImageInfo(
            id: "sha256abc",   // 9 chars < 14
            repository: "minimal",
            tag: "latest"
        )
        XCTAssertEqual(image.shortId, "sha256abc",
            "When bare-prefix ID is shorter than 14 chars, shortId must return all available characters")
    }

    /// The first branch (sha256: with colon) must NOT be affected by the new bare-prefix branch.
    func testImageInfoShortId_sha256ColonPrefix_stillReturns12HexChars() {
        let hexDigest = "sha256:abcdef123456789012345678"
        let image = ImageInfo(id: hexDigest, repository: "postgres", tag: "15")
        XCTAssertEqual(image.shortId, "abcdef123456",
            "Digest-form 'sha256:' prefix must still return first 12 hex characters after the colon")
    }

    /// Non-sha256 IDs must still fall through to the default 12-character short-ID convention.
    func testImageInfoShortId_nonSha256Id_stillReturns12Chars() {
        let image = ImageInfo(
            id: "abcdef1234567890abcdef12",
            repository: "redis",
            tag: "7"
        )
        XCTAssertEqual(image.shortId, "abcdef123456",
            "Non-sha256 IDs must still use the standard Docker 12-character short-ID convention")
    }

    /// Regression: an ID starting with "sha256" (no colon) must NOT be treated as the colon variant.
    func testImageInfoShortId_sha256BarePrefix_doesNotConfuseWithColonVariant() {
        // "sha256:" is 7 chars; this ID has "sha256" (6 chars) followed by non-colon content.
        let image = ImageInfo(
            id: "sha256xyz1234567890abcdef",
            repository: "node",
            tag: "20"
        )
        let short = image.shortId
        XCTAssertEqual(short, "sha256xyz12345",
            "Bare 'sha256' prefix must return first 14 chars, not strip the prefix like the colon variant")
        XCTAssertFalse(short.hasPrefix("xyz"),
            "Bare 'sha256' prefix must not be treated as the colon-variant and strip the prefix")
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
        XCTAssertTrue(TableFormatter.relativeTime(twoWeeksAgo).contains("weeks"))
    }

    func testTableFormatter_relativeTime_months() {
        let now = Date()
        let twoMonthsAgo = now.addingTimeInterval(-60 * 24 * 3600)
        XCTAssertTrue(TableFormatter.relativeTime(twoMonthsAgo).contains("months"))
    }

    func testTableFormatter_relativeTime_years() {
        let now = Date()
        let twoYearsAgo = now.addingTimeInterval(-730 * 24 * 3600)
        XCTAssertTrue(TableFormatter.relativeTime(twoYearsAgo).contains("years"))
    }

    func testTableFormatter_formatVolumes_headers() {
        let output = TableFormatter.formatVolumes([])
        XCTAssertTrue(output.contains("DRIVER"))
        XCTAssertTrue(output.contains("VOLUME NAME"))
    }

    func testTableFormatter_formatVolumes_withContent() {
        let volumes = [
            VolumeInfo(name: "pgdata", driver: "local"),
            VolumeInfo(name: "redisdata", driver: "nfs"),
        ]
        let output = TableFormatter.formatVolumes(volumes)
        XCTAssertTrue(output.contains("pgdata"))
        XCTAssertTrue(output.contains("redisdata"))
        XCTAssertTrue(output.contains("local"))
        XCTAssertTrue(output.contains("nfs"))
    }

    func testTableFormatter_formatStats_headers() {
        let output = TableFormatter.formatStats([], noStream: true)
        XCTAssertTrue(output.contains("CONTAINER ID"))
        XCTAssertTrue(output.contains("NAME"))
        XCTAssertTrue(output.contains("CPU %"))
        XCTAssertTrue(output.contains("MEM USAGE / LIMIT"))
        XCTAssertTrue(output.contains("NET I/O"))
        XCTAssertTrue(output.contains("BLOCK I/O"))
        XCTAssertTrue(output.contains("PIDS"))
    }

    func testTableFormatter_formatStats_withContent() {
        let stats = ContainerStats(
            containerId: "abcdef123456789012",
            name: "web",
            cpuPercent: 2.5,
            memUsage: 52_428_800,    // 50 MB
            memLimit: 536_870_912,   // 512 MB
            networkRx: 1_048_576,    // 1 MB
            networkTx: 2_097_152,    // 2 MB
            blockRead: 4_096,        // 4 kB
            blockWrite: 8_192,       // 8 kB
            pids: 3
        )
        let output = TableFormatter.formatStats([stats], noStream: true)
        XCTAssertTrue(output.contains("abcdef123456"))
        XCTAssertTrue(output.contains("web"))
        XCTAssertTrue(output.contains("2.50%"))
        XCTAssertTrue(output.contains("3"))
    }

    func testTableFormatter_formatStats_memPercent() {
        let stats = ContainerStats(
            containerId: "abc123",
            name: "app",
            cpuPercent: 0,
            memUsage: 268_435_456,   // 256 MB
            memLimit: 536_870_912,   // 512 MB — 50%
            networkRx: 0,
            networkTx: 0,
            blockRead: 0,
            blockWrite: 0,
            pids: 1
        )
        let output = TableFormatter.formatStats([stats], noStream: true)
        XCTAssertTrue(output.contains("50.00%"))
    }

    func testTableFormatter_formatStats_zeroMemLimit() {
        // memPercent should return 0 when limit is 0
        let stats = ContainerStats(
            containerId: "abc123",
            name: "app",
            cpuPercent: 0,
            memUsage: 0,
            memLimit: 0,
            networkRx: 0,
            networkTx: 0,
            blockRead: 0,
            blockWrite: 0,
            pids: 1
        )
        let output = TableFormatter.formatStats([stats], noStream: true)
        XCTAssertTrue(output.contains("0.00%"))
    }

    func testTableFormatter_formatComposePS_headers() {
        let output = TableFormatter.formatComposePS([], projectName: "myproject")
        XCTAssertTrue(output.contains("NAME"))
        XCTAssertTrue(output.contains("IMAGE"))
        XCTAssertTrue(output.contains("SERVICE"))
        XCTAssertTrue(output.contains("STATUS"))
        XCTAssertTrue(output.contains("PORTS"))
    }

    func testTableFormatter_formatComposePS_withContent() {
        let container = ContainerInfo(
            id: "abc123",
            name: "myproject-web-1",
            image: "nginx:latest",
            status: .running,
            labels: ["com.docker.compose.service": "web"]
        )
        let output = TableFormatter.formatComposePS([container], projectName: "myproject")
        XCTAssertTrue(output.contains("myproject-web-1"))
        XCTAssertTrue(output.contains("nginx:latest"))
        XCTAssertTrue(output.contains("web"))
    }

    func testTableFormatter_formatComposePS_missingServiceLabel() {
        let container = ContainerInfo(
            id: "abc123",
            name: "orphan-container",
            image: "alpine:latest"
            // no compose labels
        )
        let output = TableFormatter.formatComposePS([container], projectName: "myproject")
        // Should not crash; service column should be empty string
        XCTAssertTrue(output.contains("orphan-container"))
        XCTAssertTrue(output.contains("alpine:latest"))
    }

    func testTableFormatter_formatPS_noTrunc() {
        let fullId = "abcdef1234567890abcdef1234567890"
        let container = ContainerInfo(id: fullId, name: "web", image: "nginx", status: .running)
        let output = TableFormatter.formatPS([container], all: false, quiet: true, noTrunc: true)
        XCTAssertEqual(output, fullId)
    }

    func testTableFormatter_formatPS_multipleContainers_quiet() {
        let c1 = ContainerInfo(id: "aaaaaa111111222222", name: "web", image: "nginx")
        let c2 = ContainerInfo(id: "bbbbbb333333444444", name: "db", image: "postgres")
        let output = TableFormatter.formatPS([c1, c2], all: false, quiet: true, noTrunc: false)
        let lines = output.split(separator: "\n").map { String($0) }
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(String(lines[0]), c1.shortId)
        XCTAssertEqual(String(lines[1]), c2.shortId)
    }

    func testTableFormatter_formatPS_withPorts() {
        let container = ContainerInfo(
            id: "abc123",
            name: "web",
            image: "nginx",
            status: .running,
            ports: [PortMapping(hostPort: 8080, containerPort: 80)]
        )
        let output = TableFormatter.formatPS([container], all: false, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("8080"))
        XCTAssertTrue(output.contains("80"))
    }

    func testTableFormatter_formatPS_commandTruncation() {
        let longCommand = "/usr/bin/some-very-long-command-that-should-be-truncated --option=value"
        let container = ContainerInfo(
            id: "abc123",
            name: "web",
            image: "nginx",
            command: longCommand
        )
        let output = TableFormatter.formatPS([container], all: false, quiet: false, noTrunc: false)
        // Command column is truncated to 20 chars — output should contain "..." for long commands
        XCTAssertTrue(output.contains("..."))
    }

    func testTableFormatter_formatPS_commandNoTrunc() {
        let longCommand = "/usr/bin/some-very-long-command"
        let container = ContainerInfo(
            id: "abc123",
            name: "web",
            image: "nginx",
            command: longCommand
        )
        let output = TableFormatter.formatPS([container], all: false, quiet: false, noTrunc: true)
        XCTAssertTrue(output.contains(longCommand))
    }

    func testTableFormatter_formatImages_tableView() {
        let images = [
            ImageInfo(repository: "nginx", tag: "latest", size: 10_485_760),
        ]
        let output = TableFormatter.formatImages(images, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("REPOSITORY"))
        XCTAssertTrue(output.contains("TAG"))
        XCTAssertTrue(output.contains("IMAGE ID"))
        XCTAssertTrue(output.contains("SIZE"))
        XCTAssertTrue(output.contains("nginx"))
        XCTAssertTrue(output.contains("latest"))
    }

    func testTableFormatter_formatImages_noTrunc() {
        let fullId = "sha256abcdef1234567890abcdef1234567890"
        let image = ImageInfo(id: fullId, repository: "alpine", tag: "3.18")
        let output = TableFormatter.formatImages([image], quiet: true, noTrunc: true)
        XCTAssertEqual(output, fullId)
    }

    func testTableFormatter_formatTable_columnAlignment() {
        let header = ["COL1", "COL2"]
        let rows = [
            ["short", "a very long value"],
            ["medium val", "x"],
        ]
        let output = TableFormatter.formatTable(header: header, rows: rows)
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false)
        XCTAssertEqual(lines.count, 3) // header + 2 rows
        // All lines should have the same length (padded to column widths)
        let lengths = lines.map { $0.count }
        XCTAssertEqual(lengths[0], lengths[1])
        XCTAssertEqual(lengths[1], lengths[2])
    }

    func testTableFormatter_formatTable_emptyRows() {
        let header = ["ID", "NAME"]
        let output = TableFormatter.formatTable(header: header, rows: [])
        // Only the header row should appear
        let lines = output.split(separator: "\n")
        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(output.contains("ID"))
        XCTAssertTrue(output.contains("NAME"))
    }

    func testTableFormatter_formatNetworks_content() {
        let networks = [
            NetworkInfo(id: "aabbcc112233", name: "mybridge", driver: "bridge"),
            NetworkInfo(id: "ddeeff445566", name: "overlay-net", driver: "overlay"),
        ]
        let output = TableFormatter.formatNetworks(networks)
        XCTAssertTrue(output.contains("mybridge"))
        XCTAssertTrue(output.contains("overlay-net"))
        XCTAssertTrue(output.contains("bridge"))
        XCTAssertTrue(output.contains("overlay"))
        XCTAssertTrue(output.contains("SCOPE"))
    }
}

// MARK: - ImageInfo.shortId: bare sha256 prefix (no colon)
//
// PR change: IDs that start with "sha256" but have no colon (i.e. no "sha256:" digest form)
// now return the first 14 characters of the full ID, instead of falling through to
// the default 12-character short-ID convention.

final class ImageInfoShortIdBarePrefixTests: XCTestCase {

    // MARK: - New branch: bare "sha256" prefix without colon returns first 14 characters

    /// Standard case: ID longer than 14 chars starting with "sha256" (no colon).
    func testShortId_sha256BarePrefix_returns14Chars() {
        let image = ImageInfo(
            id: "sha256abcdef12345678901234",
            repository: "myapp",
            tag: "v1"
        )
        XCTAssertEqual(image.shortId, "sha256abcdef12",
            "Bare 'sha256' prefix without colon must return exactly the first 14 characters")
    }

    /// Boundary: ID is exactly 14 characters starting with "sha256" → full ID returned unchanged.
    func testShortId_sha256BarePrefix_exactlyFourteenCharsReturnsFullId() {
        let image = ImageInfo(
            id: "sha256abcdefgh",  // exactly 14 chars
            repository: "alpine",
            tag: "edge"
        )
        XCTAssertEqual(image.shortId, "sha256abcdefgh",
            "When the bare-prefix ID is exactly 14 characters, shortId must equal the full ID")
    }

    /// Boundary: ID shorter than 14 characters starting with "sha256" → all available chars returned.
    func testShortId_sha256BarePrefix_shorterThanFourteen_returnsAll() {
        let image = ImageInfo(
            id: "sha256abc",  // 9 chars < 14
            repository: "minimal",
            tag: "latest"
        )
        XCTAssertEqual(image.shortId, "sha256abc",
            "When bare-prefix ID is shorter than 14 chars, shortId must return all available characters")
    }

    /// Boundary: ID is exactly 15 characters → first 14 returned.
    func testShortId_sha256BarePrefix_fifteenChars_returns14() {
        let image = ImageInfo(
            id: "sha256abcdef123",  // 15 chars
            repository: "redis",
            tag: "7"
        )
        XCTAssertEqual(image.shortId, "sha256abcdef12",
            "A 15-char bare-prefix ID must return the first 14 characters")
    }

    /// Regression: the "sha256:" digest form (with colon) must NOT be affected by the new branch.
    func testShortId_sha256ColonPrefix_stillReturns12HexCharsAfterColon() {
        let image = ImageInfo(
            id: "sha256:abcdef123456789012345678",
            repository: "postgres",
            tag: "15"
        )
        XCTAssertEqual(image.shortId, "abcdef123456",
            "Digest-form 'sha256:' prefix must still return first 12 hex characters after the colon")
    }

    /// Regression: non-sha256 IDs must continue using the 12-char short-ID convention.
    func testShortId_nonSha256Id_stillReturns12Chars() {
        let image = ImageInfo(
            id: "abcdef1234567890abcdef12",
            repository: "redis",
            tag: "7"
        )
        XCTAssertEqual(image.shortId, "abcdef123456",
            "Non-sha256 IDs must still use the standard Docker 12-character short-ID convention")
    }

    /// Bare "sha256" prefix must NOT strip the prefix as the colon-variant does.
    func testShortId_sha256BarePrefix_doesNotStripPrefix() {
        let image = ImageInfo(
            id: "sha256xyz1234567890abcdef",
            repository: "node",
            tag: "20"
        )
        let short = image.shortId
        XCTAssertEqual(short, "sha256xyz12345",
            "Bare 'sha256' prefix must return first 14 chars including the 'sha256' text")
        XCTAssertTrue(short.hasPrefix("sha256"),
            "Short ID must retain the 'sha256' prefix – it must not be stripped like in the colon-variant")
    }

    /// The returned shortId for bare-prefix IDs must always start with "sha256".
    func testShortId_sha256BarePrefix_resultStartsWithSha256() {
        let ids = [
            "sha256ffffffff000000aabbcc",
            "sha256aabbccddeeff112233",
            "sha256000000000000111111"
        ]
        for id in ids {
            let image = ImageInfo(id: id, repository: "test", tag: "latest")
            XCTAssertTrue(image.shortId.hasPrefix("sha256"),
                "shortId for bare-prefix ID '\(id)' must start with 'sha256'")
        }
    }

    /// shortId length for a long bare-prefix ID must be exactly 14.
    func testShortId_sha256BarePrefix_lengthIsAlways14ForLongId() {
        let image = ImageInfo(
            id: "sha256" + String(repeating: "a", count: 40),
            repository: "img",
            tag: "latest"
        )
        XCTAssertEqual(image.shortId.count, 14,
            "shortId for a long bare-prefix ID must have exactly 14 characters")
    }
}
