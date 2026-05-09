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
}





























































































































































































































































































































































































































































































































































        // Row line should start with "a" followed by spaces to match header width
        XCTAssertTrue(lines[1].hasPrefix("a"))
    }

    // MARK: - formatNetworks Additional Tests

    func testTableFormatter_formatNetworks_emptyList_showsHeaderOnly() {
        let output = TableFormatter.formatNetworks([])
        let lines = output.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines[0].contains("NETWORK ID"))
        XCTAssertTrue(lines[0].contains("NAME"))
        XCTAssertTrue(lines[0].contains("DRIVER"))
        XCTAssertTrue(lines[0].contains("SCOPE"))
    }

    func testTableFormatter_formatNetworks_multipleNetworks() {
        let networks = [
            NetworkInfo(name: "bridge", driver: "bridge"),
            NetworkInfo(name: "host", driver: "host"),
            NetworkInfo(name: "none", driver: "null"),
        ]
        let output = TableFormatter.formatNetworks(networks)
        XCTAssertTrue(output.contains("bridge"))
        XCTAssertTrue(output.contains("host"))
        XCTAssertTrue(output.contains("none"))
        let lines = output.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 4) // header + 3 rows
    }

    func testTableFormatter_formatNetworks_showsScope() {
        let network = NetworkInfo(name: "mynet", driver: "bridge", scope: "local")
        let output = TableFormatter.formatNetworks([network])
        XCTAssertTrue(output.contains("local"), "Network scope should appear in output")
    }

    func testTableFormatter_formatNetworks_showsDriver() {
        let network = NetworkInfo(name: "mynet", driver: "overlay")
        let output = TableFormatter.formatNetworks([network])
        XCTAssertTrue(output.contains("overlay"), "Network driver should appear in output")
    }

    // MARK: - relativeTime Boundary Tests

    func testTableFormatter_relativeTime_zeroSeconds() {
        // Exactly 0 seconds ago — should show "0 seconds ago"
        let now = Date()
        let result = TableFormatter.relativeTime(now)
        XCTAssertTrue(result.contains("seconds"), "0s should show 'seconds'")
    }

    func testTableFormatter_relativeTime_exactlyOneMinute() {
        // 60 seconds = 1 minute boundary: should switch from "seconds" to "minutes"
        let now = Date()
        let sixtySecondsAgo = now.addingTimeInterval(-60)
        let result = TableFormatter.relativeTime(sixtySecondsAgo)
        XCTAssertTrue(result.contains("minutes"), "60s should show 'minutes', got: \(result)")
        XCTAssertFalse(result.contains("seconds"), "60s should not show 'seconds'")
    }

    func testTableFormatter_relativeTime_fiftyNineSeconds() {
        // 59 seconds should still show "seconds"
        let now = Date()
        let result = TableFormatter.relativeTime(now.addingTimeInterval(-59))
        XCTAssertTrue(result.contains("seconds"), "59s should show 'seconds'")
    }

    func testTableFormatter_relativeTime_exactlyOneHour() {
        // 3600 seconds = 1 hour boundary
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let result = TableFormatter.relativeTime(oneHourAgo)
        XCTAssertTrue(result.contains("hours"), "3600s should show 'hours', got: \(result)")
        XCTAssertFalse(result.contains("minutes"), "3600s should not show 'minutes'")
    }

    func testTableFormatter_relativeTime_exactlyOneDay() {
        // 86400 seconds = 1 day boundary
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-86400)
        let result = TableFormatter.relativeTime(oneDayAgo)
        XCTAssertTrue(result.contains("days"), "86400s should show 'days', got: \(result)")
        XCTAssertFalse(result.contains("hours"), "86400s should not show 'hours'")
    }

    func testTableFormatter_relativeTime_exactlyOneWeek() {
        // 7 days boundary: days = 7 → not < 7, so shows weeks
        let now = Date()
        let oneWeekAgo = now.addingTimeInterval(-7 * 24 * 3600)
        let result = TableFormatter.relativeTime(oneWeekAgo)
        XCTAssertTrue(result.contains("weeks"), "7 days should show 'weeks', got: \(result)")
        XCTAssertFalse(result.contains("days"), "7 days should not show 'days'")
    }

    func testTableFormatter_relativeTime_sixDays() {
        // 6 days should still show "days"
        let now = Date()
        let sixDaysAgo = now.addingTimeInterval(-6 * 24 * 3600)
        let result = TableFormatter.relativeTime(sixDaysAgo)
        XCTAssertTrue(result.contains("days"), "6 days should show 'days', got: \(result)")
    }

    // MARK: - formatStats Block I/O Tests

    func testTableFormatter_formatStats_showsBlockIO_kilobytes() {
        let stats = [
            ContainerStats(
                containerId: "abc123def456789",
                name: "web",
                cpuPercent: 0.0,
                memUsage: 0,
                memLimit: 0,
                networkRx: 0,
                networkTx: 0,
                blockRead: 2048,   // 2 kB
                blockWrite: 1024,  // 1 kB
                pids: 1
            )
        ]
        let output = TableFormatter.formatStats(stats, noStream: true)
        XCTAssertTrue(output.contains("kB"), "Block I/O in kB range should show 'kB'")
    }

    func testTableFormatter_formatStats_showsBlockIO_megabytes() {
        let stats = [
            ContainerStats(
                containerId: "abc123def456789",
                name: "web",
                cpuPercent: 0.0,
                memUsage: 0,
                memLimit: 0,
                networkRx: 0,
                networkTx: 0,
                blockRead: 10_485_760,  // 10 MB
                blockWrite: 5_242_880,  // 5 MB
                pids: 1
            )
        ]
        let output = TableFormatter.formatStats(stats, noStream: true)
        XCTAssertTrue(output.contains("MB"), "Block I/O in MB range should show 'MB'")
    }

    func testTableFormatter_formatStats_zeroBlockIO() {
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
                pids: 1
            )
        ]
        let output = TableFormatter.formatStats(stats, noStream: true)
        // "0B / 0B" should appear for block I/O
        XCTAssertTrue(output.contains("0B"), "Zero block I/O should show '0B'")
    }

    // MARK: - formatTable Edge Case Tests

    func testTableFormatter_formatTable_rowWithFewerCellsThanHeader() {
        // Rows with fewer cells than header should not crash and should be rendered
        let header = ["COL1", "COL2", "COL3"]
        let rows = [["only-one"]]  // only 1 cell vs 3-column header
        // Should not crash; prefix(colCount) handles truncation
        let output = TableFormatter.formatTable(header: header, rows: rows)
        XCTAssertTrue(output.contains("COL1"))
        XCTAssertTrue(output.contains("only-one"))
    }

    func testTableFormatter_formatTable_cellLongerThanHeader() {
        // A data cell longer than the header should expand the column width
        let header = ["X"]
        let rows = [["a-very-long-value-here"]]
        let output = TableFormatter.formatTable(header: header, rows: rows)
        XCTAssertTrue(output.contains("a-very-long-value-here"))
        // Header should be padded to match data width
        let lines = output.components(separatedBy: "\n")
        // "X" padded to 22 chars = "X" + 21 spaces
        XCTAssertTrue(lines[0].hasPrefix("X"))
    }

    func testTableFormatter_formatTable_preservesOrder() {
        // Rows should appear in the same order as input
        let header = ["ID"]
        let rows = [["row1"], ["row2"], ["row3"]]
        let output = TableFormatter.formatTable(header: header, rows: rows)
        let lines = output.components(separatedBy: "\n")
        // Header is padded to match widest cell (4 chars), then data rows appear in order
        XCTAssertTrue(lines[0].hasPrefix("ID"))
        XCTAssertEqual(lines[1].trimmingCharacters(in: .whitespaces), "row1")
        XCTAssertEqual(lines[2].trimmingCharacters(in: .whitespaces), "row2")
        XCTAssertEqual(lines[3].trimmingCharacters(in: .whitespaces), "row3")
    }

    // MARK: - formatPS Command Truncation Boundary Tests

    func testTableFormatter_formatPS_commandAtTruncationBoundary_notTruncated() {
        // A command that when quoted produces exactly 20 chars should NOT be truncated
        // Raw cmd = 18 chars → quoted = "\"" + 18 + "\"" = 20 chars → no truncation
        let cmd18 = String(repeating: "a", count: 18)
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "web",
            image: "nginx:latest",
            command: cmd18
        )
        let output = TableFormatter.formatPS([container], all: false, quiet: false, noTrunc: false)
        XCTAssertFalse(output.contains("..."), "Command of 18 chars (quoted=20) should NOT be truncated")
    }

    func testTableFormatter_formatPS_commandJustOverTruncationBoundary_isTruncated() {
        // Raw cmd = 19 chars → quoted = "\"" + 19 + "\"" = 21 chars → truncated to 20 (17 + "...")
        let cmd19 = String(repeating: "b", count: 19)
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "web",
            image: "nginx:latest",
            command: cmd19
        )
        let output = TableFormatter.formatPS([container], all: false, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("..."), "Command of 19 chars (quoted=21) should be truncated")
    }

    // MARK: - formatPS Headers Completeness

    func testTableFormatter_formatPS_headers_complete() {
        let output = TableFormatter.formatPS([], all: false, quiet: false, noTrunc: false)
        XCTAssertTrue(output.contains("CONTAINER ID"), "Header should include 'CONTAINER ID'")
        XCTAssertTrue(output.contains("IMAGE"), "Header should include 'IMAGE'")
        XCTAssertTrue(output.contains("COMMAND"), "Header should include 'COMMAND'")
        XCTAssertTrue(output.contains("CREATED"), "Header should include 'CREATED'")
        XCTAssertTrue(output.contains("STATUS"), "Header should include 'STATUS'")
        XCTAssertTrue(output.contains("PORTS"), "Header should include 'PORTS'")
        XCTAssertTrue(output.contains("NAMES"), "Header should include 'NAMES'")
    }

    // MARK: - formatComposePS Additional Tests

    func testTableFormatter_formatComposePS_emptyList_showsHeaderOnly() {
        let output = TableFormatter.formatComposePS([], projectName: "myproject")
        let lines = output.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 1, "Empty compose ps should show header row only")
        XCTAssertTrue(lines[0].contains("NAME"))
        XCTAssertTrue(lines[0].contains("IMAGE"))
        XCTAssertTrue(lines[0].contains("SERVICE"))
    }

    func testTableFormatter_formatComposePS_showsCommand() {
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "myapp-web-1",
            image: "nginx:latest",
            command: "nginx -g daemon off;",
            labels: ["com.docker.compose.service": "web"]
        )
        let output = TableFormatter.formatComposePS([container], projectName: "myapp")
        XCTAssertTrue(output.contains("nginx"), "Compose ps should include container command")
    }

    func testTableFormatter_formatComposePS_showsCreatedColumn() {
        let container = ContainerInfo(
            id: "abc123def456789",
            name: "myapp-web-1",
            image: "nginx:latest",
            labels: ["com.docker.compose.service": "web"]
        )
        let output = TableFormatter.formatComposePS([container], projectName: "myapp")
        // CREATED column header should be present
        XCTAssertTrue(output.contains("CREATED"), "Compose ps should show 'CREATED' header")
    }

    // MARK: - formatStats Network I/O kB boundary

    func testTableFormatter_formatStats_networkIO_kilobytes() {
        let stats = [
            ContainerStats(
                containerId: "abc123def456789",
                name: "web",
                cpuPercent: 0.0,
                memUsage: 0,
                memLimit: 0,
                networkRx: 1024,  // exactly 1 kB
                networkTx: 2048,  // 2 kB
                blockRead: 0,
                blockWrite: 0,
                pids: 1
            )
        ]
        let output = TableFormatter.formatStats(stats, noStream: true)
        XCTAssertTrue(output.contains("kB"), "Network I/O of 1024+ bytes should show 'kB'")
    }

    func testTableFormatter_formatStats_networkIO_megabytes() {
        let stats = [
            ContainerStats(
                containerId: "abc123def456789",
                name: "web",
                cpuPercent: 0.0,
                memUsage: 0,
                memLimit: 0,
                networkRx: 2_097_152,  // 2 MB
                networkTx: 1_048_576,  // 1 MB
                blockRead: 0,
                blockWrite: 0,
                pids: 1
            )
        ]
        let output = TableFormatter.formatStats(stats, noStream: true)
        XCTAssertTrue(output.contains("MB"), "Network I/O of 1MB+ should show 'MB'")
    }
}
