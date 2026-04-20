import XCTest
@testable import WritersApp

// MARK: - AppTheme Tests

final class AppThemeTests: XCTestCase {

    func testAppThemeRawValues() {
        XCTAssertEqual(AppTheme.light.rawValue, "light")
        XCTAssertEqual(AppTheme.dark.rawValue, "dark")
        XCTAssertEqual(AppTheme.system.rawValue, "system")
    }

    func testAppThemeDisplayNames() {
        XCTAssertEqual(AppTheme.light.displayName, "Light")
        XCTAssertEqual(AppTheme.dark.displayName, "Dark")
        XCTAssertEqual(AppTheme.system.displayName, "System")
    }

    func testAppThemeInitFromRawValue() {
        XCTAssertEqual(AppTheme(rawValue: "light"), .light)
        XCTAssertEqual(AppTheme(rawValue: "dark"), .dark)
        XCTAssertEqual(AppTheme(rawValue: "system"), .system)
    }

    func testAppThemeInitFromUnknownRawValueReturnsNil() {
        XCTAssertNil(AppTheme(rawValue: "unknown"))
        XCTAssertNil(AppTheme(rawValue: "Light")) // case-sensitive
        XCTAssertNil(AppTheme(rawValue: ""))
    }

    func testAppThemeCodableRoundTrip() throws {
        for theme in [AppTheme.light, .dark, .system] {
            let encoded = try JSONEncoder().encode(theme)
            let decoded = try JSONDecoder().decode(AppTheme.self, from: encoded)
            XCTAssertEqual(decoded, theme)
        }
    }
}

// MARK: - AppSettings Tests

final class AppSettingsTests: XCTestCase {

    func testDefaultValues() {
        let settings = AppSettings()
        XCTAssertFalse(settings.isDarkModeEnabled)
        XCTAssertTrue(settings.isAutoSaveEnabled)
        XCTAssertEqual(settings.autoSaveIntervalSeconds, 30)
        XCTAssertEqual(settings.fontSize, 14)
        XCTAssertNil(settings.defaultWordCountGoal)
        XCTAssertEqual(settings.theme, .system)
        XCTAssertTrue(settings.spellCheckEnabled)
        XCTAssertTrue(settings.grammarCheckEnabled)
    }

    func testCustomValues() {
        let settings = AppSettings(
            isDarkModeEnabled: true,
            isAutoSaveEnabled: false,
            autoSaveIntervalSeconds: 60,
            fontSize: 18,
            defaultWordCountGoal: 500,
            theme: .dark,
            spellCheckEnabled: false,
            grammarCheckEnabled: false
        )
        XCTAssertTrue(settings.isDarkModeEnabled)
        XCTAssertFalse(settings.isAutoSaveEnabled)
        XCTAssertEqual(settings.autoSaveIntervalSeconds, 60)
        XCTAssertEqual(settings.fontSize, 18)
        XCTAssertEqual(settings.defaultWordCountGoal, 500)
        XCTAssertEqual(settings.theme, .dark)
        XCTAssertFalse(settings.spellCheckEnabled)
        XCTAssertFalse(settings.grammarCheckEnabled)
    }

    func testAppSettingsIsIdentifiable() {
        let settings1 = AppSettings()
        let settings2 = AppSettings()
        XCTAssertNotEqual(settings1.id, settings2.id)
    }

    func testAppSettingsWithExplicitId() {
        let knownId = UUID()
        let settings = AppSettings(id: knownId)
        XCTAssertEqual(settings.id, knownId)
    }

    func testAppSettingsCodableRoundTrip() throws {
        let original = AppSettings(
            isDarkModeEnabled: true,
            isAutoSaveEnabled: false,
            autoSaveIntervalSeconds: 120,
            fontSize: 16,
            defaultWordCountGoal: 1000,
            theme: .dark,
            spellCheckEnabled: false,
            grammarCheckEnabled: true
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.isDarkModeEnabled, original.isDarkModeEnabled)
        XCTAssertEqual(decoded.isAutoSaveEnabled, original.isAutoSaveEnabled)
        XCTAssertEqual(decoded.autoSaveIntervalSeconds, original.autoSaveIntervalSeconds)
        XCTAssertEqual(decoded.fontSize, original.fontSize)
        XCTAssertEqual(decoded.defaultWordCountGoal, original.defaultWordCountGoal)
        XCTAssertEqual(decoded.theme, original.theme)
        XCTAssertEqual(decoded.spellCheckEnabled, original.spellCheckEnabled)
        XCTAssertEqual(decoded.grammarCheckEnabled, original.grammarCheckEnabled)
    }

    func testAppSettingsCodableWithNilWordCountGoal() throws {
        let original = AppSettings(defaultWordCountGoal: nil)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: encoded)
        XCTAssertNil(decoded.defaultWordCountGoal)
    }

    func testAppSettingsWithLightTheme() throws {
        let original = AppSettings(theme: .light)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: encoded)
        XCTAssertEqual(decoded.theme, .light)
    }
}
