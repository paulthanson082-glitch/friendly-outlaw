# Multi-Language Mobile App Support

## Overview
Comprehensive guide for implementing multi-language support in the friendly-outlaw mobile application. This document covers localization strategies, implementation patterns, and best practices for delivering content in multiple languages.

## Language Configuration

### Supported Languages
- English (en)
- Spanish (es)
- French (fr)
- German (de)
- Mandarin (zh)
- Japanese (ja)
- Portuguese (pt)

### Setup

```swift
// Language manager initialization
let languageManager = LanguageManager.shared
languageManager.setLanguage(.english)
```

## String Localization

### File Structure
```
Resources/
├── Localizable.strings (en)
├── Localizable.strings (es)
├── Localizable.strings (fr)
└── Localizable.strings (de)
```

### String Keys
```swift
// Define localization keys in Strings file
"app.title" = "Friendly Outlaw"
"app.welcome" = "Welcome to Friendly Outlaw"
"navigation.home" = "Home"
"navigation.settings" = "Settings"
"errors.network" = "Network connection failed"
```

### Usage Pattern
```swift
Text(LocalizedStringKey("app.welcome"))
```

## Date & Number Formatting

```swift
let locale = Locale(identifier: currentLanguage)
let formatter = DateFormatter()
formatter.locale = locale
formatter.dateFormat = "EEEE, MMMM d, yyyy"
```

## RTL Language Support

For languages like Arabic and Hebrew:

```swift
View()
    .environment(\.layoutDirection, .rightToLeft)
```

## Best Practices

1. **Never hardcode strings** - Always use localization keys
2. **Plan for string expansion** - Some languages require more space
3. **Test all languages** - Include RTL testing in QA
4. **Use native formatters** - Leverage system locale for dates/numbers
5. **Keep strings concise** - Easier to maintain and translate
6. **Pluralization** - Handle singular/plural forms per language

## Testing Multilingual Features

```swift
// Test language switching
func testLanguageSwitch() {
    languageManager.setLanguage(.spanish)
    XCTAssertEqual(LocalizedString("app.title"), "Forastero Amable")
}

// Test date formatting
func testDateFormatting() {
    let date = Date(timeIntervalSince1970: 0)
    let formatted = formatDate(date, locale: Locale(identifier: "de_DE"))
    XCTAssertEqual(formatted, "1. Januar 1970")
}
```

## Dynamic Language Switching

```swift
struct LanguagePickerView: View {
    @StateObject var languageManager = LanguageManager.shared
    
    var body: some View {
        Picker("Language", selection: $languageManager.currentLanguage) {
            ForEach(Language.allCases, id: \.self) { lang in
                Text(lang.displayName).tag(lang)
            }
        }
        .onChange(of: languageManager.currentLanguage) { oldValue, newValue in
            languageManager.setLanguage(newValue)
            // Refresh UI with new language
        }
    }
}
```

## Pseudo-Localization for Testing

Use pseudo-localization to identify untranslated strings:
- En-Pseudo: [en_PSEUDO]
- Uses extended ASCII characters to simulate longer translated text

## Performance Considerations

- **Lazy loading** - Load translations only for current language
- **Caching** - Cache translated strings in memory
- **Memory** - Clean up unused language data when switching

## Integration with Backend

```swift
// Fetch translated content from API
let endpoint = "/api/content/\(languageCode)"
let translatedContent = try await fetchContent(endpoint)
```

## Troubleshooting

**Strings not updating after language switch:**
- Ensure ObservedObject is properly configured
- Call view refresh methods after language change

**Incorrect date formatting:**
- Verify locale identifier is correct
- Test with DateFormatter.DateStyle options

**RTL layout issues:**
- Use semantic layout (leading/trailing instead of left/right)
- Test with actual RTL content

## Resources

- Apple Localization Documentation
- CLDR (Common Locale Data Repository)
- Translation service APIs (Google Translate, AWS Translate)
