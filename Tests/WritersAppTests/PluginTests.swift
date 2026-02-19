import XCTest
@testable import WritersApp

final class PluginTests: XCTestCase {
    var pluginManager: PluginManager!
    var memoryPlugin: ClaudeMemoryPlugin!
    var testStoragePath: String!

    override func setUp() async throws {
        try await super.setUp()

        // Use a temporary directory for tests
        testStoragePath = NSTemporaryDirectory() + "WritersAppPluginTests/\(UUID().uuidString)"
        pluginManager = PluginManager(storagePath: testStoragePath)
        memoryPlugin = ClaudeMemoryPlugin(storagePath: testStoragePath + "/memory")

        // Initialize the memory plugin
        try await memoryPlugin.initialize()
    }

    override func tearDown() async throws {
        // Shutdown plugin
        try? await memoryPlugin.shutdown()

        // Clean up test directory
        try? FileManager.default.removeItem(atPath: testStoragePath)

        memoryPlugin = nil
        pluginManager = nil
        testStoragePath = nil

        try await super.tearDown()
    }

    // MARK: - Plugin Manager Tests

    func testPluginRegistration() async throws {
        pluginManager.register(plugin: memoryPlugin)

        let plugins = pluginManager.getAllPlugins()
        XCTAssertEqual(plugins.count, 1)

        let retrieved = pluginManager.getPlugin(id: "claude-memory")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "Claude Memory")
    }

    func testPluginUnregistration() async throws {
        pluginManager.register(plugin: memoryPlugin)
        XCTAssertEqual(pluginManager.getAllPlugins().count, 1)

        await pluginManager.unregister(pluginId: "claude-memory")
        XCTAssertEqual(pluginManager.getAllPlugins().count, 0)
    }

    func testPluginCapabilities() async throws {
        pluginManager.register(plugin: memoryPlugin)

        let memoryPlugins = pluginManager.getPlugins(with: .memory)
        XCTAssertEqual(memoryPlugins.count, 1)

        let toolPlugins = pluginManager.getPlugins(with: .tools)
        XCTAssertEqual(toolPlugins.count, 0)
    }

    func testPluginEnableDisable() async throws {
        pluginManager.register(plugin: memoryPlugin)

        // Plugin should be enabled by default
        XCTAssertTrue(memoryPlugin.isEnabled)

        // Disable
        try await pluginManager.disablePlugin(id: "claude-memory")
        XCTAssertFalse(memoryPlugin.isEnabled)

        // Enable
        try await pluginManager.enablePlugin(id: "claude-memory")
        XCTAssertTrue(memoryPlugin.isEnabled)
    }

    // MARK: - Memory Plugin Tests

    func testMemoryPluginProperties() {
        XCTAssertEqual(memoryPlugin.id, "claude-memory")
        XCTAssertEqual(memoryPlugin.name, "Claude Memory")
        XCTAssertEqual(memoryPlugin.version, "1.0.0")
        XCTAssertTrue(memoryPlugin.capabilities.contains(.memory))
        XCTAssertTrue(memoryPlugin.capabilities.contains(.customActions))
    }

    func testStoreAndRetrieveMemory() async throws {
        // Store a memory
        let storeAction = PluginAction(type: .storeMemory, parameters: [
            "key": "test-key",
            "value": "test-value",
            "category": "test-category",
            "tags": ["tag1", "tag2"],
            "importance": 0.8
        ])

        let storeResult = try await memoryPlugin.execute(action: storeAction)
        XCTAssertTrue(storeResult.success)

        // Retrieve the memory
        let retrieveAction = PluginAction(type: .retrieveMemory, parameters: ["key": "test-key"])
        let retrieveResult = try await memoryPlugin.execute(action: retrieveAction)

        XCTAssertTrue(retrieveResult.success)
        XCTAssertEqual(retrieveResult.data as? String, "test-value")
    }

    func testSearchMemory() async throws {
        // Store multiple memories
        let memories = [
            ("apple-recipe", "How to make apple pie", "recipes"),
            ("banana-smoothie", "Blend banana with milk", "recipes"),
            ("car-maintenance", "Change oil every 5000 miles", "automotive")
        ]

        for (key, value, category) in memories {
            let action = PluginAction(type: .storeMemory, parameters: [
                "key": key,
                "value": value,
                "category": category
            ])
            _ = try await memoryPlugin.execute(action: action)
        }

        // Search for recipes
        let searchAction = PluginAction(type: .searchMemory, parameters: [
            "query": "banana",
            "limit": 10
        ])

        let searchResult = try await memoryPlugin.execute(action: searchAction)
        XCTAssertTrue(searchResult.success)

        if let results = searchResult.data as? [[String: Any]] {
            XCTAssertGreaterThan(results.count, 0)
            // The banana smoothie should be in results
            let hasMatch = results.contains { ($0["key"] as? String) == "banana-smoothie" }
            XCTAssertTrue(hasMatch)
        } else {
            XCTFail("Search should return array of results")
        }
    }

    func testListMemories() async throws {
        // Store some memories
        for i in 1...5 {
            let action = PluginAction(type: .storeMemory, parameters: [
                "key": "memory-\(i)",
                "value": "value-\(i)",
                "category": "test"
            ])
            _ = try await memoryPlugin.execute(action: action)
        }

        let listAction = PluginAction(type: .listMemories, parameters: [
            "limit": 100,
            "sortBy": "created"
        ])

        let listResult = try await memoryPlugin.execute(action: listAction)
        XCTAssertTrue(listResult.success)

        if let memories = listResult.data as? [[String: Any]] {
            XCTAssertEqual(memories.count, 5)
        } else {
            XCTFail("List should return array of memories")
        }
    }

    func testClearSpecificMemory() async throws {
        // Store a memory
        let storeAction = PluginAction(type: .storeMemory, parameters: [
            "key": "to-delete",
            "value": "delete me"
        ])
        _ = try await memoryPlugin.execute(action: storeAction)

        // Clear it
        let clearAction = PluginAction(type: .clearMemory, parameters: ["key": "to-delete"])
        let clearResult = try await memoryPlugin.execute(action: clearAction)
        XCTAssertTrue(clearResult.success)

        // Try to retrieve - should be nil
        let retrieveAction = PluginAction(type: .retrieveMemory, parameters: ["key": "to-delete"])
        let retrieveResult = try await memoryPlugin.execute(action: retrieveAction)
        XCTAssertNil(retrieveResult.data)
    }

    func testClearMemoryByCategory() async throws {
        // Store memories in different categories
        for i in 1...3 {
            _ = try await memoryPlugin.execute(action: PluginAction(type: .storeMemory, parameters: [
                "key": "cat-a-\(i)",
                "value": "value",
                "category": "category-a"
            ]))
        }

        for i in 1...2 {
            _ = try await memoryPlugin.execute(action: PluginAction(type: .storeMemory, parameters: [
                "key": "cat-b-\(i)",
                "value": "value",
                "category": "category-b"
            ]))
        }

        // Clear category-a
        let clearAction = PluginAction(type: .clearMemory, parameters: ["category": "category-a"])
        let clearResult = try await memoryPlugin.execute(action: clearAction)
        XCTAssertTrue(clearResult.success)

        if let data = clearResult.data as? [String: Any], let cleared = data["cleared"] as? Int {
            XCTAssertEqual(cleared, 3)
        }

        // Verify category-b still has memories
        let listAction = PluginAction(type: .listMemories, parameters: ["category": "category-b"])
        let listResult = try await memoryPlugin.execute(action: listAction)

        if let memories = listResult.data as? [[String: Any]] {
            XCTAssertEqual(memories.count, 2)
        }
    }

    func testMemoryStats() async throws {
        // Store some memories with varying importance
        for i in 1...5 {
            _ = try await memoryPlugin.execute(action: PluginAction(type: .storeMemory, parameters: [
                "key": "stat-test-\(i)",
                "value": "value",
                "category": i <= 3 ? "cat-1" : "cat-2",
                "importance": Double(i) / 10.0
            ]))
        }

        let statsAction = PluginAction(type: .custom, parameters: ["action": "getStats"])
        let statsResult = try await memoryPlugin.execute(action: statsAction)
        XCTAssertTrue(statsResult.success)

        if let stats = statsResult.data as? [String: Any] {
            XCTAssertEqual(stats["totalMemories"] as? Int, 5)

            if let categoryCounts = stats["categoryCounts"] as? [String: Int] {
                XCTAssertEqual(categoryCounts["cat-1"], 3)
                XCTAssertEqual(categoryCounts["cat-2"], 2)
            }
        } else {
            XCTFail("Stats should return dictionary")
        }
    }

    func testMemoryImportance() async throws {
        // Store with low importance
        _ = try await memoryPlugin.execute(action: PluginAction(type: .storeMemory, parameters: [
            "key": "low-importance",
            "value": "not very important",
            "importance": 0.2
        ]))

        // Store with high importance
        _ = try await memoryPlugin.execute(action: PluginAction(type: .storeMemory, parameters: [
            "key": "high-importance",
            "value": "very important",
            "importance": 0.9
        ]))

        // Search with min importance filter
        let searchAction = PluginAction(type: .searchMemory, parameters: [
            "query": "important",
            "minImportance": 0.5
        ])

        let result = try await memoryPlugin.execute(action: searchAction)
        if let results = result.data as? [[String: Any]] {
            // Should only find the high-importance memory
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.first?["key"] as? String, "high-importance")
        }
    }

    func testMemoryTags() async throws {
        // Store memory with tags
        _ = try await memoryPlugin.execute(action: PluginAction(type: .storeMemory, parameters: [
            "key": "tagged-memory",
            "value": "has tags",
            "tags": ["swift", "ios", "development"]
        ]))

        // Add more tags
        let addTagsAction = PluginAction(type: .custom, parameters: [
            "action": "addTags",
            "key": "tagged-memory",
            "tags": ["mobile", "swift"] // "swift" already exists
        ])

        let result = try await memoryPlugin.execute(action: addTagsAction)
        XCTAssertTrue(result.success)

        if let data = result.data as? [String: Any], let tags = data["tags"] as? [String] {
            // Should have unique tags only
            XCTAssertEqual(Set(tags), Set(["swift", "ios", "development", "mobile"]))
        }
    }

    func testGetCategories() async throws {
        // Store memories in different categories
        let categories = ["writing", "coding", "research"]
        for (i, cat) in categories.enumerated() {
            _ = try await memoryPlugin.execute(action: PluginAction(type: .storeMemory, parameters: [
                "key": "cat-test-\(i)",
                "value": "value",
                "category": cat
            ]))
        }

        let getCategoriesAction = PluginAction(type: .custom, parameters: ["action": "getCategories"])
        let result = try await memoryPlugin.execute(action: getCategoriesAction)
        XCTAssertTrue(result.success)

        if let cats = result.data as? [String] {
            XCTAssertEqual(Set(cats), Set(categories))
        }
    }

    // MARK: - Plugin Configuration Tests

    func testPluginConfigurationPersistence() {
        let config = PluginConfiguration(
            id: "test-plugin",
            name: "Test Plugin",
            enabled: true,
            settings: ["key1": "value1", "key2": "value2"]
        )

        pluginManager.saveConfiguration(config)

        // Create new manager with same path to test loading
        let newManager = PluginManager(storagePath: testStoragePath)
        if let loadedConfig = newManager.loadConfiguration(pluginId: "test-plugin") {
            XCTAssertEqual(loadedConfig.id, "test-plugin")
            XCTAssertEqual(loadedConfig.name, "Test Plugin")
            XCTAssertEqual(loadedConfig.enabled, true)
            XCTAssertEqual(loadedConfig.settings["key1"], "value1")
        } else {
            XCTFail("Configuration should be loaded")
        }
    }

    // MARK: - Error Handling Tests

    func testInvalidActionError() async throws {
        // Try to execute an unsupported action
        let invalidAction = PluginAction(type: .executeTool, parameters: [:])

        do {
            _ = try await memoryPlugin.execute(action: invalidAction)
            XCTFail("Should throw action not supported error")
        } catch let error as PluginError {
            switch error {
            case .actionNotSupported:
                // Expected
                break
            default:
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testMissingParameterError() async throws {
        // Try to store without required key
        let missingKeyAction = PluginAction(type: .storeMemory, parameters: [
            "value": "some value"
            // Missing "key"
        ])

        do {
            _ = try await memoryPlugin.execute(action: missingKeyAction)
            XCTFail("Should throw invalid parameters error")
        } catch let error as PluginError {
            switch error {
            case .invalidParameters:
                // Expected
                break
            default:
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testRetrieveNonexistentMemory() async throws {
        let retrieveAction = PluginAction(type: .retrieveMemory, parameters: ["key": "nonexistent"])
        let result = try await memoryPlugin.execute(action: retrieveAction)

        XCTAssertTrue(result.success)
        XCTAssertNil(result.data)
    }

    func testMemoryKeyWithSpecialCharacters() async throws {
        // Store a memory whose key contains spaces and special characters.
        // This exercises the sanitizedForFilename path in saveMemory / deleteMemoryFile.
        let storeAction = PluginAction(type: .storeMemory, parameters: [
            "key": "YC Stuff",
            "value": "startup memories",
            "category": "projects"
        ])
        let storeResult = try await memoryPlugin.execute(action: storeAction)
        XCTAssertTrue(storeResult.success)

        // Retrieve using the original (unsanitized) key
        let retrieveAction = PluginAction(type: .retrieveMemory, parameters: ["key": "YC Stuff"])
        let retrieveResult = try await memoryPlugin.execute(action: retrieveAction)
        XCTAssertTrue(retrieveResult.success)
        XCTAssertEqual(retrieveResult.data as? String, "startup memories")

        // Delete using the original key — the file must be found for deletion to succeed
        let clearAction = PluginAction(type: .clearMemory, parameters: ["key": "YC Stuff"])
        let clearResult = try await memoryPlugin.execute(action: clearAction)
        XCTAssertTrue(clearResult.success)

        // Verify it is gone
        let checkAction = PluginAction(type: .retrieveMemory, parameters: ["key": "YC Stuff"])
        let checkResult = try await memoryPlugin.execute(action: checkAction)
        XCTAssertNil(checkResult.data)
    }

    func testIndexRebuildAfterCorruption() async throws {
        // Store some memories so they are persisted to disk
        for i in 1...3 {
            _ = try await memoryPlugin.execute(action: PluginAction(type: .storeMemory, parameters: [
                "key": "rebuild-test-\(i)",
                "value": "value-\(i)",
                "category": "rebuild-category"
            ]))
        }
        try await memoryPlugin.shutdown()

        // Simulate index file corruption by deleting it
        let indexPath = testStoragePath + "/memory/index.json"
        try? FileManager.default.removeItem(atPath: indexPath)

        // Re-initialize — rebuildIndexIfNeeded() should reconstruct the index from loaded memories
        let newPlugin = ClaudeMemoryPlugin(storagePath: testStoragePath + "/memory")
        try await newPlugin.initialize()

        // All three memories should still be retrievable
        let listAction = PluginAction(type: .listMemories, parameters: ["limit": 10])
        let listResult = try await newPlugin.execute(action: listAction)
        XCTAssertTrue(listResult.success)
        if let memories = listResult.data as? [[String: Any]] {
            XCTAssertEqual(memories.count, 3)
        } else {
            XCTFail("Memories should be accessible after index rebuild")
        }

        try await newPlugin.shutdown()

        // The index file should have been recreated by the rebuild
        XCTAssertTrue(FileManager.default.fileExists(atPath: indexPath))
    }
}

// MARK: - Plugin Protocol Tests

final class MockPluginTests: XCTestCase {

    func testPluginProtocolConformance() async throws {
        let mockPlugin = MockPlugin()

        XCTAssertEqual(mockPlugin.id, "mock-plugin")
        XCTAssertEqual(mockPlugin.version, "1.0.0")
        XCTAssertTrue(mockPlugin.capabilities.contains(.tools))

        try await mockPlugin.initialize()
        XCTAssertTrue(mockPlugin.isInitialized)

        let result = try await mockPlugin.execute(action: PluginAction(type: .listTools, parameters: [:]))
        XCTAssertTrue(result.success)

        try await mockPlugin.shutdown()
        XCTAssertFalse(mockPlugin.isInitialized)
    }
}

// Mock plugin for testing
class MockPlugin: Plugin {
    var id: String = "mock-plugin"
    var name: String = "Mock Plugin"
    var version: String = "1.0.0"
    var description: String = "A mock plugin for testing"
    var isEnabled: Bool = true
    var capabilities: [PluginCapability] = [.tools, .customActions]

    var isInitialized = false

    func initialize() async throws {
        isInitialized = true
    }

    func shutdown() async throws {
        isInitialized = false
    }

    func execute(action: PluginAction) async throws -> PluginResult {
        guard isInitialized else {
            throw PluginError.notInitialized
        }

        switch action.type {
        case .listTools:
            return PluginResult.success(data: ["tool1", "tool2"])
        default:
            throw PluginError.actionNotSupported(action.type.rawValue)
        }
    }
}
