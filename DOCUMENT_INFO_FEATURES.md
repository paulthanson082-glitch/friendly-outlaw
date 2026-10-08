# Document Info Sheet & All Suggestions View

## Features Overview

### Document Info Sheet

Provides comprehensive metadata and statistics for any document:

- **Word Count:** Real-time word count with updates
- **Character Count:** Including/excluding spaces
- **Reading Time:** Estimated reading time (200 words/min)
- **Creation Date:** Document creation timestamp
- **Last Modified:** Last edit timestamp
- **File Size:** Current document size in KB/MB
- **Status:** Draft, In Review, Published
- **Tags:** User-defined document categories

### All Suggestions View

Unified view of all writing suggestions and improvements:

**Suggestion Categories:**
- Grammar & Syntax
- Style & Clarity
- Vocabulary & Tone
- Structure & Flow
- Readability Metrics
- AI-Generated Ideas

**Features:**
- Filter by category
- Sort by priority or date
- Accept/reject suggestions individually
- Batch apply suggestions
- Undo/redo suggestion changes
- Comment on suggestions

### Implementation Details

```swift
// Document Info Sheet
struct DocumentInfoSheet: View {
    @ObservedObject var document: Document
    
    var body: some View {
        Form {
            Section("Metadata") {
                LabeledContent("Created", value: document.createdDate)
                LabeledContent("Modified", value: document.modifiedDate)
                LabeledContent("Status", value: document.status.rawValue)
            }
            
            Section("Statistics") {
                LabeledContent("Words", value: String(document.wordCount))
                LabeledContent("Characters", value: String(document.characterCount))
                LabeledContent("Reading Time", value: "\(document.readingTime) min")
            }
            
            Section("Organization") {
                TagCloud(tags: document.tags)
            }
        }
    }
}

// All Suggestions View
struct AllSuggestionsView: View {
    @StateObject var suggestionManager: SuggestionManager
    @State var selectedCategory: SuggestionCategory = .all
    @State var sortBy: SuggestionSort = .priority
    
    var filteredSuggestions: [Suggestion] {
        suggestionManager.suggestions
            .filter { selectedCategory == .all || $0.category == selectedCategory }
            .sorted { sort(a: $0, b: $1) }
    }
    
    var body: some View {
        NavigationView {
            List(filteredSuggestions) { suggestion in
                SuggestionRow(suggestion: suggestion)
                    .contextMenu {
                        Button("Accept") { suggestionManager.accept(suggestion) }
                        Button("Reject") { suggestionManager.reject(suggestion) }
                        Button("Comment") { /* show comment sheet */ }
                    }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(SuggestionCategory.allCases, id: \.self) { category in
                                Text(category.label).tag(category)
                            }
                        }
                        Picker("Sort", selection: $sortBy) {
                            ForEach(SuggestionSort.allCases, id: \.self) { sort in
                                Text(sort.label).tag(sort)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}
```

### Integration with Document Manager

- Auto-update info sheet on document changes
- Refresh suggestions on AI operations
- Sync suggestion state across devices
- Archive old suggestions

### User Experience

1. Open document
2. Tap Info button to see document metadata
3. Tap Suggestions to view all improvement ideas
4. Filter by category or priority
5. Accept/reject suggestions
6. See stats update in real-time

### Testing

- Unit tests for info calculation
- UI tests for sheet rendering
- Integration tests for suggestion flow
