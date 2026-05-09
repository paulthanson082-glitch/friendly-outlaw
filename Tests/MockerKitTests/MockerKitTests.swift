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

// MARK: - ImageInfo.shortId: Additional boundary and regression tests
//
// PR change: IDs starting with "sha256" (no colon) return first 14 chars.
// These tests complement ImageInfoShortIdBarePrefixTests with further edge cases.

final class ImageInfoShortIdAdditionalTests: XCTestCase {

    // MARK: - Content variations after the "sha256" prefix

    /// Bare-prefix ID containing only digits after "sha256" returns first 14 chars.
    func testShortId_sha256BarePrefix_allDigitsAfterPrefix() {
        let image = ImageInfo(
            id: "sha2561234567890123456",
            repository: "img",
            tag: "latest"
        )
        XCTAssertEqual(image.shortId, "sha25612345678",
            "Bare sha256-prefix ID with digits must return first 14 characters")
        XCTAssertEqual(image.shortId.count, 14)
    }

    /// Bare-prefix ID containing mixed hex chars after "sha256" returns first 14 chars.
    func testShortId_sha256BarePrefix_hexMixedCase() {
        let image = ImageInfo(
            id: "sha256abcdef012345678",
            repository: "img",
            tag: "latest"
        )
        XCTAssertEqual(image.shortId.count, 14)
        XCTAssertTrue(image.shortId.hasPrefix("sha256"))
    }

    // MARK: - Colon-variant is unaffected (regression)

    /// sha256: prefix still returns exactly 12 hex chars after the colon.
    func testShortId_sha256ColonVariant_returns12CharsAfterColon_regression() {
        let image = ImageInfo(
            id: "sha256:deadbeef123456789012",
            repository: "ubuntu",
            tag: "22.04"
        )
        XCTAssertEqual(image.shortId, "deadbeef1234",
            "Colon-variant must still return 12 hex chars after the colon")
    }

    /// sha256: prefix with a minimum-length digest (12 chars after colon) returns all of them.
    func testShortId_sha256ColonVariant_exactlyTwelveHexCharsAfterColon() {
        let image = ImageInfo(
            id: "sha256:abcdef123456",
            repository: "alpine",
            tag: "3.18"
        )
        XCTAssertEqual(image.shortId, "abcdef123456")
    }

    // MARK: - Non-sha256 IDs (regression)

    /// Non-sha256 ID of more than 12 characters returns first 12.
    func testShortId_nonSha256_longId_returns12Chars() {
        let image = ImageInfo(
            id: "deadbeef1234567890abcdef",
            repository: "mysql",
            tag: "8"
        )
        XCTAssertEqual(image.shortId, "deadbeef1234")
        XCTAssertEqual(image.shortId.count, 12)
    }

    /// Non-sha256 ID of fewer than 12 characters returns the full ID.
    func testShortId_nonSha256_shortId_returnsAll() {
        let image = ImageInfo(
            id: "abc123",
            repository: "scratch",
            tag: "latest"
        )
        XCTAssertEqual(image.shortId, "abc123")
    }

    // MARK: - Case sensitivity: "SHA256" (uppercase) must NOT match the bare-prefix branch

    /// An ID starting with "SHA256" (uppercase) must fall through to the default branch.
    func testShortId_sha256UppercasePrefix_fallsThroughToDefault() {
        let image = ImageInfo(
            id: "SHA256abcdef1234567890",
            repository: "img",
            tag: "latest"
        )
        // The implementation uses hasPrefix("sha256") which is case-sensitive,
        // so "SHA256..." must NOT return 14 chars like the bare-prefix branch.
        // It must return the first 12 chars (default branch).
        XCTAssertEqual(image.shortId.count, 12,
            "Uppercase 'SHA256' prefix must not trigger the bare-prefix branch")
        XCTAssertEqual(image.shortId, "SHA256abcdef")
    }

    // MARK: - Length boundary: exactly 6 characters ("sha256" itself)

    /// An ID that is exactly "sha256" (6 chars, no suffix) returns the full 6 chars.
    func testShortId_sha256BarePrefix_idIsExactlyPrefixOnly() {
        let image = ImageInfo(
            id: "sha256",
            repository: "img",
            tag: "latest"
        )
        // The ID equals the prefix exactly; it starts with "sha256" and has no colon.
        // Prefix(14) of a 6-char string returns all 6 chars.
        XCTAssertEqual(image.shortId, "sha256")
    }

    // MARK: - shortId consistency across multiple calls

    /// Calling shortId multiple times on the same ImageInfo returns the same value.
    func testShortId_sha256BarePrefix_isIdempotent() {
        let image = ImageInfo(
            id: "sha256abcdef12345678",
            repository: "nginx",
            tag: "latest"
        )
        let first = image.shortId
        let second = image.shortId
        XCTAssertEqual(first, second, "shortId must be deterministic across multiple calls")
    }

    // MARK: - Interaction with other ImageInfo fields

    /// shortId behaviour is independent of repository and tag values.
    func testShortId_sha256BarePrefix_independentOfRepositoryAndTag() {
        let id = "sha256abcdef12345678"
        let repositories = ["nginx", "my-org/my-app", "registry.io:5000/repo"]
        let tags = ["latest", "v1.0.0", "edge"]

        for repo in repositories {
            for tag in tags {
                let image = ImageInfo(id: id, repository: repo, tag: tag)
                XCTAssertEqual(image.shortId, "sha256abcdef12",
                    "shortId must be the same regardless of repository='\(repo)' tag='\(tag)'")
            }
        }
    }
}
