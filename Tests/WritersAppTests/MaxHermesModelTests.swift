import XCTest
@testable import WritersApp

// MARK: - MaxHermes (Minimax) Model Tests
//
// This PR added the `.maxhermes` case to the AIModel enum, representing the
// Minimax MaxHermes model with raw value "maxhermes-01" and display name "MaxHermes".
//
// Tests in AIServiceTests.swift already verify rawValue and displayName.
// This file adds deeper coverage: Codable round-trips, AIConfiguration
// integration, and regression checks.

final class MaxHermesModelTests: XCTestCase {

    // MARK: - Raw Value

    func testMaxhermesRawValue() {
        XCTAssertEqual(AIModel.maxhermes.rawValue, "maxhermes-01",
            "maxhermes raw value must be 'maxhermes-01'")
    }

    /// Initialising from the raw string must return the .maxhermes case.
    func testMaxhermesInitFromRawValue() {
        let model = AIModel(rawValue: "maxhermes-01")
        XCTAssertNotNil(model, "AIModel must be constructible from raw value 'maxhermes-01'")
        XCTAssertEqual(model, .maxhermes)
    }

    /// A string that differs by even one character must not decode as maxhermes.
    func testMaxhermesRawValueIsCaseSensitive() {
        XCTAssertNil(AIModel(rawValue: "MaxHermes-01"),
            "Raw value matching must be case-sensitive")
        XCTAssertNil(AIModel(rawValue: "maxhermes"),
            "'maxhermes' without the version suffix must not decode as .maxhermes")
        XCTAssertNil(AIModel(rawValue: "maxhermes-1"),
            "'maxhermes-1' must not match 'maxhermes-01'")
    }

    // MARK: - Display Name

    func testMaxhermesDisplayName() {
        XCTAssertEqual(AIModel.maxhermes.displayName, "MaxHermes",
            "maxhermes display name must be 'MaxHermes'")
    }

    /// Display name must not contain any whitespace padding.
    func testMaxhermesDisplayNameIsExact() {
        let name = AIModel.maxhermes.displayName
        XCTAssertEqual(name, name.trimmingCharacters(in: .whitespaces),
            "displayName must not have leading or trailing whitespace")
    }

    // MARK: - Codable Round-Trip

    func testMaxhermesCodableRoundTripWithJSONEncoder() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(AIModel.maxhermes)
        let decoded = try decoder.decode(AIModel.self, from: data)

        XCTAssertEqual(decoded, .maxhermes,
            "AIModel.maxhermes must survive a JSON encode/decode round-trip")
    }

    /// The encoded JSON must contain the exact raw value string.
    func testMaxhermesEncodesAsRawValueString() throws {
        let data = try JSONEncoder().encode(AIModel.maxhermes)
        let jsonString = String(data: data, encoding: .utf8)!
        XCTAssertTrue(jsonString.contains("maxhermes-01"),
            "Encoded JSON must contain the raw value string 'maxhermes-01'")
    }

    func testAllModelsCanRoundTripCodable() throws {
        let models: [AIModel] = [.claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude3Haiku, .maxhermes]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for model in models {
            let data = try encoder.encode(model)
            let decoded = try decoder.decode(AIModel.self, from: data)
            XCTAssertEqual(decoded, model,
                "Codable round-trip failed for model: \(model.rawValue)")
        }
    }

    // MARK: - AIConfiguration Integration

    /// AIConfiguration must accept maxhermes as its model.
    func testAIConfigurationWithMaxhermesModel() {
        let config = AIConfiguration(apiKey: "test-key", model: .maxhermes)
        XCTAssertEqual(config.model, .maxhermes)
        XCTAssertEqual(config.model.rawValue, "maxhermes-01")
    }

    /// AIConfiguration created with maxhermes must preserve the model after init.
    func testAIConfigurationMaxhermesModelIsPreserved() {
        let config = AIConfiguration(
            apiKey: "mk-test-key",
            model: .maxhermes,
            maxTokens: 8192,
            temperature: 0.5
        )
        XCTAssertEqual(config.model, .maxhermes,
            "model must be .maxhermes after init")
        XCTAssertEqual(config.apiKey, "mk-test-key")
        XCTAssertEqual(config.maxTokens, 8192)
        XCTAssertEqual(config.temperature, 0.5)
    }

    // MARK: - AIService Initialization with MaxHermes

    /// AIService must initialize successfully when configured with maxhermes.
    func testAIServiceInitializationWithMaxhermes() {
        let config = AIConfiguration(apiKey: "test-key", model: .maxhermes)
        let service = AIService(configuration: config)
        XCTAssertNotNil(service,
            "AIService must be constructible with the maxhermes model")
    }

    // MARK: - Equality and Inequality

    func testMaxhermesEqualToItself() {
        XCTAssertEqual(AIModel.maxhermes, AIModel.maxhermes)
    }

    func testMaxhermesNotEqualToOtherModels() {
        XCTAssertNotEqual(AIModel.maxhermes, .claude35Sonnet)
        XCTAssertNotEqual(AIModel.maxhermes, .claude3Opus)
        XCTAssertNotEqual(AIModel.maxhermes, .claude3Sonnet)
        XCTAssertNotEqual(AIModel.maxhermes, .claude3Haiku)
    }

    // MARK: - Regression: Existing Claude Models Unaffected

    /// Adding maxhermes must not alter the rawValues of pre-existing Claude models.
    func testExistingClaudeModelRawValuesUnchanged() {
        XCTAssertEqual(AIModel.claude35Sonnet.rawValue, "claude-3-5-sonnet-20241022")
        XCTAssertEqual(AIModel.claude3Opus.rawValue, "claude-3-opus-20240229")
        XCTAssertEqual(AIModel.claude3Sonnet.rawValue, "claude-3-sonnet-20240229")
        XCTAssertEqual(AIModel.claude3Haiku.rawValue, "claude-3-haiku-20240307")
    }

    /// Adding maxhermes must not alter the display names of pre-existing Claude models.
    func testExistingClaudeModelDisplayNamesUnchanged() {
        XCTAssertEqual(AIModel.claude35Sonnet.displayName, "Claude 3.5 Sonnet")
        XCTAssertEqual(AIModel.claude3Opus.displayName, "Claude 3 Opus")
        XCTAssertEqual(AIModel.claude3Sonnet.displayName, "Claude 3 Sonnet")
        XCTAssertEqual(AIModel.claude3Haiku.displayName, "Claude 3 Haiku")
    }

    // MARK: - Boundary: Decoding unknown model raw value

    /// A completely unknown raw value must not decode as any AIModel case.
    func testUnknownRawValueDecodesAsNil() {
        XCTAssertNil(AIModel(rawValue: "unknown-model"),
            "An unknown raw value must return nil from AIModel init")
    }

    // MARK: - displayName uniqueness

    /// Each model's displayName must be unique to avoid UI confusion.
    func testAllModelDisplayNamesAreUnique() {
        let names = [
            AIModel.claude35Sonnet.displayName,
            AIModel.claude3Opus.displayName,
            AIModel.claude3Sonnet.displayName,
            AIModel.claude3Haiku.displayName,
            AIModel.maxhermes.displayName
        ]
        let uniqueNames = Set(names)
        XCTAssertEqual(uniqueNames.count, names.count,
            "All AIModel display names must be unique")
    }

    /// Each model's rawValue must be unique.
    func testAllModelRawValuesAreUnique() {
        let rawValues = [
            AIModel.claude35Sonnet.rawValue,
            AIModel.claude3Opus.rawValue,
            AIModel.claude3Sonnet.rawValue,
            AIModel.claude3Haiku.rawValue,
            AIModel.maxhermes.rawValue
        ]
        let uniqueRawValues = Set(rawValues)
        XCTAssertEqual(uniqueRawValues.count, rawValues.count,
            "All AIModel raw values must be unique")
    }
}