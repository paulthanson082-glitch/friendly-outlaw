# AI Content Generation Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a SwiftUI dashboard for Mac and iPad Pro that tracks AI-powered content generation metrics, history, and analytics with metal-themed design.

**Architecture:** Dashboard displays AI generation stats (requests, tokens, costs), content history timeline, model usage breakdown, and quality metrics. Uses tab-based navigation matching CRMDashboardView pattern. Real-time stat updates and historical trend data support strategic writing insights.

**Tech Stack:** SwiftUI, Swift 5.9+, Anthropic Claude API, metal-themed design system (consistent with CRM dashboard)

**Spec:** See this plan—it defines the feature.

## Global Constraints

- Platform: macOS 14+, iOS 16+
- Design: Metal theme (MetalTheme color system, fonts, components)
- Pattern: Tab-based dashboard with swipeable sections
- Framework: SwiftUI with MVVM pattern
- Dependencies: No new external dependencies (use Foundation, Combine)

---

## File Structure

```
Sources/WritersApp/
├── Models/
│   └── AIAnalyticsModels.swift (NEW)
├── Services/
│   └── AIAnalyticsService.swift (NEW)
├── Views/
│   ├── AIContentDashboardView.swift (NEW)
│   ├── AIMetricsCard.swift (NEW - component)
│   ├── AIGenerationHistoryView.swift (NEW - component)
│   ├── AIModelBreakdownView.swift (NEW - component)
│   └── AITrendChartView.swift (NEW - component)
└── ViewModels/
    └── AIContentDashboardViewModel.swift (NEW)

Tests/WritersAppTests/
├── AIAnalyticsServiceTests.swift (NEW)
└── AIContentDashboardViewModelTests.swift (NEW)
```

---

## Task Breakdown

### Task 1: Create Data Models (AIAnalyticsModels.swift)

**Files:**
- Create: `Sources/WritersApp/Models/AIAnalyticsModels.swift`
- Test: `Tests/WritersAppTests/AIAnalyticsModels+Tests.swift`

**Interfaces:**
- Produces: 
  - `AIGenerationRecord` (Date, assistanceType, inputTokens, outputTokens, model, status, documentId)
  - `AIAnalyticsSnapshot` (totalRequests, totalTokens, costEstimate, requestsToday, averageTokensPerRequest)
  - `ModelUsageBreakdown` (model, requestCount, tokenCount, percentage)
  - `DailyTrend` (date, requestCount, tokenCount, costEstimate)

- [ ] **Step 1: Write test file for models**

```swift
// Tests/WritersAppTests/AIAnalyticsModels+Tests.swift
import XCTest
@testable import WritersApp

class AIAnalyticsModelsTests: XCTestCase {
    func testAIGenerationRecordInitialization() {
        let record = AIGenerationRecord(
            id: UUID(),
            timestamp: Date(),
            assistanceType: .improveText,
            inputTokens: 100,
            outputTokens: 150,
            model: .claude35Sonnet,
            status: .completed,
            documentId: UUID()
        )
        XCTAssertEqual(record.inputTokens, 100)
        XCTAssertEqual(record.outputTokens, 150)
    }

    func testAIAnalyticsSnapshotCalculation() {
        let snapshot = AIAnalyticsSnapshot(
            totalRequests: 42,
            totalTokens: 15000,
            costEstimate: 0.45,
            requestsToday: 5,
            averageTokensPerRequest: 357
        )
        XCTAssertEqual(snapshot.totalRequests, 42)
    }

    func testModelUsageBreakdown() {
        let breakdown = ModelUsageBreakdown(
            model: .claude35Sonnet,
            requestCount: 30,
            tokenCount: 10000,
            percentage: 0.75
        )
        XCTAssertEqual(breakdown.percentage, 0.75)
    }
}
```

- [ ] **Step 2: Create AIAnalyticsModels.swift with all structs**

```swift
// Sources/WritersApp/Models/AIAnalyticsModels.swift
import Foundation

// MARK: - AI Generation Record

/// Single tracked AI generation event
public struct AIGenerationRecord: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let assistanceType: AIAssistanceType
    public let inputTokens: Int
    public let outputTokens: Int
    public let model: AIModel
    public let status: GenerationStatus
    public let documentId: UUID?
    public var totalTokens: Int { inputTokens + outputTokens }

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        assistanceType: AIAssistanceType,
        inputTokens: Int,
        outputTokens: Int,
        model: AIModel,
        status: GenerationStatus,
        documentId: UUID? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.assistanceType = assistanceType
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.model = model
        self.status = status
        self.documentId = documentId
    }
}

// MARK: - Generation Status

public enum GenerationStatus: String, Codable {
    case pending
    case completed
    case failed
    case cancelled

    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    public var icon: String {
        switch self {
        case .pending: return "hourglass.tophalf.filled"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "minus.circle.fill"
        }
    }
}

// MARK: - Analytics Snapshot

/// Current AI usage analytics
public struct AIAnalyticsSnapshot {
    public let totalRequests: Int
    public let totalTokens: Int
    public let costEstimate: Double
    public let requestsToday: Int
    public let averageTokensPerRequest: Int

    public init(
        totalRequests: Int,
        totalTokens: Int,
        costEstimate: Double,
        requestsToday: Int,
        averageTokensPerRequest: Int
    ) {
        self.totalRequests = totalRequests
        self.totalTokens = totalTokens
        self.costEstimate = costEstimate
        self.requestsToday = requestsToday
        self.averageTokensPerRequest = averageTokensPerRequest
    }
}

// MARK: - Model Usage Breakdown

/// Per-model usage statistics
public struct ModelUsageBreakdown: Identifiable {
    public let id: String
    public let model: AIModel
    public let requestCount: Int
    public let tokenCount: Int
    public let percentage: Double

    public init(
        model: AIModel,
        requestCount: Int,
        tokenCount: Int,
        percentage: Double
    ) {
        self.id = model.rawValue
        self.model = model
        self.requestCount = requestCount
        self.tokenCount = tokenCount
        self.percentage = percentage
    }
}

// MARK: - Daily Trend

/// Daily aggregated AI usage
public struct DailyTrend: Identifiable {
    public let id: String
    public let date: Date
    public let requestCount: Int
    public let tokenCount: Int
    public let costEstimate: Double

    public init(
        date: Date,
        requestCount: Int,
        tokenCount: Int,
        costEstimate: Double
    ) {
        self.id = ISO8601DateFormatter().string(from: date)
        self.date = date
        self.requestCount = requestCount
        self.tokenCount = tokenCount
        self.costEstimate = costEstimate
    }
}

// MARK: - Assistance Type Extension for Analytics

extension AIAssistanceType {
    public var analyticsKey: String {
        switch self {
        case .continueWriting: return "continue_writing"
        case .improveText: return "improve_text"
        case .grammarCheck: return "grammar_check"
        case .styleSuggestions: return "style_suggestions"
        case .generateOutline: return "generate_outline"
        case .brainstormIdeas: return "brainstorm_ideas"
        case .brainstormIdeasCategorized: return "brainstorm_categorized"
        case .characterDevelopment: return "character_development"
        case .plotSuggestions: return "plot_suggestions"
        case .dialogueImprovement: return "dialogue_improvement"
        case .descriptionEnhancement: return "description_enhancement"
        case .titleGeneration: return "title_generation"
        case .summarize: return "summarize"
        case .expandText: return "expand_text"
        case .simplifyText: return "simplify_text"
        case .changetone: return "change_tone"
        case .custom: return "custom"
        case .extractQuotes: return "extract_quotes"
        case .verifyWithCitations: return "verify_with_citations"
        case .analyzeWithUncertainty: return "analyze_uncertainty"
        case .chainOfThoughtVerification: return "chain_of_thought"
        case .writingAdvisor: return "writing_advisor"
        }
    }
}
```

- [ ] **Step 3: Run tests to verify models**

```bash
swift test --filter AIAnalyticsModelsTests
```

- [ ] **Step 4: Commit models**

```bash
git add Sources/WritersApp/Models/AIAnalyticsModels.swift Tests/WritersAppTests/AIAnalyticsModels+Tests.swift
git commit -m "feat: add AI analytics data models

- AIGenerationRecord for tracking individual generation events
- AIAnalyticsSnapshot for current usage metrics
- ModelUsageBreakdown for per-model statistics
- DailyTrend for historical tracking

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01A7XeKMFih58GmUd9uA7Pus"
```

---

### Task 2: Create AI Analytics Service

**Files:**
- Create: `Sources/WritersApp/Services/AIAnalyticsService.swift`
- Test: `Tests/WritersAppTests/AIAnalyticsServiceTests.swift`

**Interfaces:**
- Consumes: 
  - `AIGenerationRecord`, `AIAnalyticsSnapshot`, `ModelUsageBreakdown`, `DailyTrend` from Task 1
  - FileManager for persistent storage
- Produces:
  - `AIAnalyticsService` (trackGeneration, getSnapshot, getModelBreakdown, getTrends, getRecentsRecords)

- [ ] **Step 1: Write tests for analytics service**

```swift
// Tests/WritersAppTests/AIAnalyticsServiceTests.swift
import XCTest
@testable import WritersApp

class AIAnalyticsServiceTests: XCTestCase {
    var service: AIAnalyticsService!

    override func setUp() {
        super.setUp()
        service = AIAnalyticsService()
    }

    func testTrackGeneration() {
        let record = AIGenerationRecord(
            timestamp: Date(),
            assistanceType: .improveText,
            inputTokens: 100,
            outputTokens: 150,
            model: .claude35Sonnet,
            status: .completed
        )
        service.trackGeneration(record)
        let snapshot = service.getSnapshot()
        XCTAssertEqual(snapshot.totalRequests, 1)
        XCTAssertEqual(snapshot.totalTokens, 250)
    }

    func testGetSnapshot() {
        let snapshot = service.getSnapshot()
        XCTAssertGreaterThanOrEqual(snapshot.totalRequests, 0)
    }

    func testGetModelBreakdown() {
        let record1 = AIGenerationRecord(
            timestamp: Date(),
            assistanceType: .improveText,
            inputTokens: 100,
            outputTokens: 150,
            model: .claude35Sonnet,
            status: .completed
        )
        service.trackGeneration(record1)
        let breakdown = service.getModelBreakdown()
        XCTAssertGreaterThan(breakdown.count, 0)
    }

    func testGetTrends() {
        let trends = service.getTrends(days: 30)
        XCTAssertGreaterThanOrEqual(trends.count, 0)
    }

    func testGetRecentRecords() {
        let records = service.getRecentRecords(limit: 10)
        XCTAssertLessThanOrEqual(records.count, 10)
    }
}
```

- [ ] **Step 2: Create AIAnalyticsService.swift**

```swift
// Sources/WritersApp/Services/AIAnalyticsService.swift
import Foundation

public class AIAnalyticsService {
    private var records: [AIGenerationRecord] = []
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.writersapp.analytics", attributes: .concurrent)
    private var lock = NSLock()

    private let analyticsDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("WritersApp/Analytics")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    public init() {
        loadRecords()
    }

    // MARK: - Public API

    public func trackGeneration(_ record: AIGenerationRecord) {
        lock.lock()
        defer { lock.unlock() }
        records.append(record)
        saveRecords()
    }

    public func getSnapshot() -> AIAnalyticsSnapshot {
        lock.lock()
        defer { lock.unlock() }

        let total = records.count
        let totalTokens = records.reduce(0) { $0 + $1.totalTokens }
        let costEstimate = Double(totalTokens) * 0.00001 // Approx cost per token
        let today = Calendar.current.startOfDay(for: Date())
        let todaysRecords = records.filter { Calendar.current.startOfDay(for: $0.timestamp) == today }
        let avgTokens = total > 0 ? totalTokens / total : 0

        return AIAnalyticsSnapshot(
            totalRequests: total,
            totalTokens: totalTokens,
            costEstimate: costEstimate,
            requestsToday: todaysRecords.count,
            averageTokensPerRequest: avgTokens
        )
    }

    public func getModelBreakdown() -> [ModelUsageBreakdown] {
        lock.lock()
        defer { lock.unlock() }

        let byModel = Dictionary(grouping: records, by: { $0.model })
        let total = records.reduce(0) { $0 + $1.totalTokens }

        return byModel.map { model, modelRecords in
            let requestCount = modelRecords.count
            let tokenCount = modelRecords.reduce(0) { $0 + $1.totalTokens }
            let percentage = total > 0 ? Double(tokenCount) / Double(total) : 0

            return ModelUsageBreakdown(
                model: model,
                requestCount: requestCount,
                tokenCount: tokenCount,
                percentage: percentage
            )
        }
        .sorted { $0.tokenCount > $1.tokenCount }
    }

    public func getTrends(days: Int = 30) -> [DailyTrend] {
        lock.lock()
        defer { lock.unlock() }

        var dailyStats: [String: (requests: Int, tokens: Int)] = [:]

        for record in records {
            let dateKey = ISO8601DateFormatter().string(from: record.timestamp)
            var stat = dailyStats[dateKey] ?? (requests: 0, tokens: 0)
            stat.requests += 1
            stat.tokens += record.totalTokens
            dailyStats[dateKey] = stat
        }

        let trends = dailyStats.map { dateKey, stat in
            let formatter = ISO8601DateFormatter()
            let date = formatter.date(from: dateKey) ?? Date()
            let cost = Double(stat.tokens) * 0.00001

            return DailyTrend(
                date: date,
                requestCount: stat.requests,
                tokenCount: stat.tokens,
                costEstimate: cost
            )
        }

        return trends.sorted { $0.date < $1.date }
    }

    public func getRecentRecords(limit: Int = 20) -> [AIGenerationRecord] {
        lock.lock()
        defer { lock.unlock() }
        return Array(records.suffix(limit).reversed())
    }

    public func getRecordsForDocument(_ documentId: UUID) -> [AIGenerationRecord] {
        lock.lock()
        defer { lock.unlock() }
        return records.filter { $0.documentId == documentId }
    }

    // MARK: - Private Storage

    private func saveRecords() {
        let encoder = JSONEncoder()
        let url = analyticsDirectory.appendingPathComponent("records.json")
        if let data = try? encoder.encode(records) {
            try? data.write(to: url)
        }
    }

    private func loadRecords() {
        let url = analyticsDirectory.appendingPathComponent("records.json")
        if let data = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([AIGenerationRecord].self, from: data) {
                records = decoded
            }
        }
    }
}
```

- [ ] **Step 3: Run tests**

```bash
swift test --filter AIAnalyticsServiceTests
```

- [ ] **Step 4: Commit service**

```bash
git add Sources/WritersApp/Services/AIAnalyticsService.swift Tests/WritersAppTests/AIAnalyticsServiceTests.swift
git commit -m "feat: add AI analytics service

- Track individual generation events
- Calculate usage snapshots and trends
- Per-model breakdown analysis
- Persistent storage via JSON

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01A7XeKMFih58GmUd9uA7Pus"
```

---

### Task 3: Create Dashboard ViewModel

**Files:**
- Create: `Sources/WritersApp/ViewModels/AIContentDashboardViewModel.swift`
- Test: `Tests/WritersAppTests/AIContentDashboardViewModelTests.swift`

**Interfaces:**
- Consumes: `AIAnalyticsService`, `AIGenerationRecord`, `AIAnalyticsSnapshot`, `ModelUsageBreakdown`, `DailyTrend`
- Produces:
  - `AIContentDashboardViewModel` (published properties: snapshot, modelBreakdown, trends, recentRecords)

- [ ] **Step 1: Write ViewModel tests**

```swift
// Tests/WritersAppTests/AIContentDashboardViewModelTests.swift
import XCTest
@testable import WritersApp

class AIContentDashboardViewModelTests: XCTestCase {
    var viewModel: AIContentDashboardViewModel!
    var analyticsService: AIAnalyticsService!

    override func setUp() {
        super.setUp()
        analyticsService = AIAnalyticsService()
        viewModel = AIContentDashboardViewModel(analyticsService: analyticsService)
    }

    func testInitialState() {
        XCTAssertEqual(viewModel.snapshot.totalRequests, 0)
    }

    func testReload() {
        let record = AIGenerationRecord(
            timestamp: Date(),
            assistanceType: .improveText,
            inputTokens: 100,
            outputTokens: 150,
            model: .claude35Sonnet,
            status: .completed
        )
        analyticsService.trackGeneration(record)
        viewModel.reload()
        XCTAssertEqual(viewModel.snapshot.totalRequests, 1)
    }
}
```

- [ ] **Step 2: Create ViewModel**

```swift
// Sources/WritersApp/ViewModels/AIContentDashboardViewModel.swift
import Foundation
import Combine

@available(iOS 16.0, macOS 13.0, *)
@MainActor
public class AIContentDashboardViewModel: ObservableObject {
    @Published var snapshot: AIAnalyticsSnapshot
    @Published var modelBreakdown: [ModelUsageBreakdown] = []
    @Published var trends: [DailyTrend] = []
    @Published var recentRecords: [AIGenerationRecord] = []

    private let analyticsService: AIAnalyticsService

    public init(analyticsService: AIAnalyticsService) {
        self.analyticsService = analyticsService
        self.snapshot = analyticsService.getSnapshot()
        reload()
    }

    public func reload() {
        snapshot = analyticsService.getSnapshot()
        modelBreakdown = analyticsService.getModelBreakdown()
        trends = analyticsService.getTrends(days: 30)
        recentRecords = analyticsService.getRecentRecords(limit: 20)
    }
}
```

- [ ] **Step 3: Run tests**

```bash
swift test --filter AIContentDashboardViewModelTests
```

- [ ] **Step 4: Commit ViewModel**

```bash
git add Sources/WritersApp/ViewModels/AIContentDashboardViewModel.swift Tests/WritersAppTests/AIContentDashboardViewModelTests.swift
git commit -m "feat: add AI dashboard view model

- Aggregates analytics data for dashboard display
- Published properties for SwiftUI reactivity
- Reload method for data refresh

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01A7XeKMFih58GmUd9uA7Pus"
```

---

### Task 4: Create Dashboard Main View

**Files:**
- Create: `Sources/WritersApp/Views/AIContentDashboardView.swift`

**Interfaces:**
- Consumes: `AIContentDashboardViewModel`, `AIAnalyticsService`, MetalTheme
- Produces: `AIContentDashboardView` (main dashboard View)

- [ ] **Step 1: Create dashboard main view**

```swift
// Sources/WritersApp/Views/AIContentDashboardView.swift
#if canImport(SwiftUI)
import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
public struct AIContentDashboardView: View {
    @StateObject private var viewModel: AIContentDashboardViewModel
    @State private var selectedTab: AIContentTab = .overview

    public init(analyticsService: AIAnalyticsService) {
        _viewModel = StateObject(wrappedValue: AIContentDashboardViewModel(analyticsService: analyticsService))
    }

    public var body: some View {
        ZStack {
            MetalTheme.abyssGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                aiHeader

                // Tab bar
                aiTabBar

                // Content
                Group {
                    switch selectedTab {
                    case .overview:
                        AIOverviewSection(viewModel: viewModel)
                    case .history:
                        AIGenerationHistoryView(records: viewModel.recentRecords)
                    case .models:
                        AIModelBreakdownView(breakdown: viewModel.modelBreakdown)
                    case .trends:
                        AITrendChartView(trends: viewModel.trends)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
        }
        .onAppear { viewModel.reload() }
    }

    private var aiHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "sparkles.triangle.and.line.horizontal")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(MetalTheme.crimson)
            VStack(alignment: .leading, spacing: 2) {
                Text("AI INSIGHTS")
                    .font(.system(size: 20, weight: .black))
                    .tracking(4)
                    .foregroundColor(MetalTheme.chrome)
                Text("Content Generation Analytics")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundColor(MetalTheme.steel)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(viewModel.snapshot.totalRequests)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(MetalTheme.ember)
                Text("TOTAL")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(MetalTheme.steel)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(MetalTheme.obsidian)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(MetalTheme.bloodRed.opacity(0.6)),
            alignment: .bottom
        )
    }

    private var aiTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AIContentTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 16, weight: selectedTab == tab ? .bold : .regular))
                        Text(tab.label)
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(1.5)
                    }
                    .foregroundColor(selectedTab == tab ? MetalTheme.crimson : MetalTheme.steel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == tab ? MetalTheme.crimson : .clear),
                        alignment: .bottom
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(MetalTheme.obsidian)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(MetalTheme.chainLink),
            alignment: .bottom
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
enum AIContentTab: CaseIterable {
    case overview, history, models, trends

    var label: String {
        switch self {
        case .overview: return "OVERVIEW"
        case .history: return "HISTORY"
        case .models: return "MODELS"
        case .trends: return "TRENDS"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .history: return "clock.fill"
        case .models: return "cube.fill"
        case .trends: return "chart.line.uptrend.xyaxis"
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct AIOverviewSection: View {
    @ObservedObject var viewModel: AIContentDashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MetalTheme.sectionTitle("The Metrics").padding(.top, 8)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    AIMetricCard(
                        value: "\(viewModel.snapshot.totalRequests)",
                        label: "TOTAL REQUESTS",
                        icon: "sparkles",
                        color: MetalTheme.chrome
                    )
                    AIMetricCard(
                        value: "\(viewModel.snapshot.totalTokens)",
                        label: "TOKENS USED",
                        icon: "text.badge.plus",
                        color: MetalTheme.gold
                    )
                    AIMetricCard(
                        value: "\(viewModel.snapshot.requestsToday)",
                        label: "TODAY",
                        icon: "sun.max.fill",
                        color: MetalTheme.ember
                    )
                    AIMetricCard(
                        value: String(format: "$%.2f", viewModel.snapshot.costEstimate),
                        label: "COST EST.",
                        icon: "dollarsign.circle.fill",
                        color: MetalTheme.toxicGreen
                    )
                }

                MetalTheme.sectionTitle("Model Distribution").padding(.top, 4)
                modelDistribution

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
    }

    private var modelDistribution: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.modelBreakdown) { breakdown in
                HStack(spacing: 10) {
                    Text(breakdown.model.displayName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(MetalTheme.chrome)
                        .frame(width: 140, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(MetalTheme.gunmetal)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(modelColor(breakdown.model))
                                .frame(width: geo.size.width * breakdown.percentage, height: 8)
                        }
                    }
                    .frame(height: 8)
                    Text("\(breakdown.requestCount)")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundColor(MetalTheme.steel)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .metalCard()
    }

    private func modelColor(_ model: AIModel) -> Color {
        switch model {
        case .claude35Sonnet: return MetalTheme.crimson
        case .claude3Opus: return MetalTheme.ember
        case .claude3Sonnet: return MetalTheme.gold
        case .claude3Haiku: return MetalTheme.steel
        }
    }
}

struct AIMetricCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color.opacity(0.8))
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(MetalTheme.steel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .metalCard()
    }
}

#endif
```

- [ ] **Step 2: Test view builds**

```bash
swift build
```

- [ ] **Step 3: Commit main view**

```bash
git add Sources/WritersApp/Views/AIContentDashboardView.swift
git commit -m "feat: add AI content dashboard main view

- Tab-based navigation (overview, history, models, trends)
- Metal-themed header and controls
- Overview section with metric cards
- Model usage distribution

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01A7XeKMFih58GmUd9uA7Pus"
```

---

### Task 5: Create History, Models, and Trends Views

**Files:**
- Create: `Sources/WritersApp/Views/AIGenerationHistoryView.swift`
- Create: `Sources/WritersApp/Views/AIModelBreakdownView.swift`
- Create: `Sources/WritersApp/Views/AITrendChartView.swift`

**Interfaces:**
- Consumes: `AIGenerationRecord`, `ModelUsageBreakdown`, `DailyTrend`, MetalTheme
- Produces: Three view components for dashboard tabs

- [ ] **Step 1: Create history view**

```swift
// Sources/WritersApp/Views/AIGenerationHistoryView.swift
#if canImport(SwiftUI)
import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
struct AIGenerationHistoryView: View {
    let records: [AIGenerationRecord]

    var body: some View {
        VStack(spacing: 0) {
            MetalTheme.sectionTitle("Recent Generations")
                .padding(.top, 12)
                .padding(.horizontal, 16)

            if records.isEmpty {
                CRMEmptyState(icon: "clock", message: "No generations yet.\nStart using AI features to track your content.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(records) { record in
                            AIGenerationRow(record: record)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct AIGenerationRow: View {
    let record: AIGenerationRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(MetalTheme.gunmetal)
                    .frame(width: 36, height: 36)
                Image(systemName: record.status.icon)
                    .font(.system(size: 14))
                    .foregroundColor(statusColor(record.status))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.assistanceType.displayName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(MetalTheme.chrome)
                    Spacer()
                    Text(relativeTimeString(record.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(MetalTheme.steel)
                }

                HStack(spacing: 12) {
                    Label("\(record.inputTokens) in", systemImage: "arrow.down")
                        .font(.system(size: 11))
                        .foregroundColor(MetalTheme.steel.opacity(0.7))
                    Label("\(record.outputTokens) out", systemImage: "arrow.up")
                        .font(.system(size: 11))
                        .foregroundColor(MetalTheme.steel.opacity(0.7))
                }

                Text(record.model.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(MetalTheme.chainLink)
            }
        }
        .padding(10)
        .background(MetalTheme.obsidian)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(MetalTheme.chainLink, lineWidth: 0.5)
        )
    }

    private func statusColor(_ status: GenerationStatus) -> Color {
        switch status {
        case .completed: return MetalTheme.toxicGreen
        case .failed: return MetalTheme.crimson
        case .pending: return MetalTheme.ember
        case .cancelled: return MetalTheme.steel
        }
    }

    private func relativeTimeString(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date, to: Date())
        if let hour = components.hour, hour > 0 { return "\(hour)h ago" }
        if let minute = components.minute, minute > 0 { return "\(minute)m ago" }
        return "now"
    }
}

#endif
```

- [ ] **Step 2: Create models view**

```swift
// Sources/WritersApp/Views/AIModelBreakdownView.swift
#if canImport(SwiftUI)
import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
struct AIModelBreakdownView: View {
    let breakdown: [ModelUsageBreakdown]

    var body: some View {
        VStack(spacing: 0) {
            MetalTheme.sectionTitle("Model Usage")
                .padding(.top, 12)
                .padding(.horizontal, 16)

            if breakdown.isEmpty {
                CRMEmptyState(icon: "cube", message: "No model data yet.\nUse AI features to see usage breakdown.")
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(breakdown) { item in
                            AIModelCard(breakdown: item)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct AIModelCard: View {
    let breakdown: ModelUsageBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(breakdown.model.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(MetalTheme.chrome)
                    Text("\(breakdown.requestCount) request\(breakdown.requestCount == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(MetalTheme.steel)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f%%", breakdown.percentage * 100))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(modelColor(breakdown.model))
                    Text("of tokens")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(MetalTheme.steel)
                }
            }

            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(MetalTheme.gunmetal)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(modelColor(breakdown.model))
                            .frame(width: geo.size.width * breakdown.percentage)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(breakdown.tokenCount) tokens")
                        .font(.system(size: 11))
                        .foregroundColor(MetalTheme.steel)
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(MetalTheme.obsidian)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(MetalTheme.chainLink, lineWidth: 0.5)
        )
    }

    private func modelColor(_ model: AIModel) -> Color {
        switch model {
        case .claude35Sonnet: return MetalTheme.crimson
        case .claude3Opus: return MetalTheme.ember
        case .claude3Sonnet: return MetalTheme.gold
        case .claude3Haiku: return MetalTheme.steel
        }
    }
}

#endif
```

- [ ] **Step 3: Create trends view**

```swift
// Sources/WritersApp/Views/AITrendChartView.swift
#if canImport(SwiftUI)
import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
struct AITrendChartView: View {
    let trends: [DailyTrend]

    var body: some View {
        VStack(spacing: 0) {
            MetalTheme.sectionTitle("30-Day Trends")
                .padding(.top, 12)
                .padding(.horizontal, 16)

            if trends.isEmpty {
                CRMEmptyState(icon: "chart.line.uptrend.xyaxis", message: "No trend data yet.\nCheck back after using AI features.")
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        requestsTrendCard
                        tokensTrendCard
                        costTrendCard
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var requestsTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Requests", systemImage: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(MetalTheme.chrome)
                Spacer()
                Text("\(trends.reduce(0) { $0 + $1.requestCount }) total")
                    .font(.system(size: 11))
                    .foregroundColor(MetalTheme.steel)
            }

            VStack(spacing: 4) {
                ForEach(trends.suffix(7)) { trend in
                    HStack(spacing: 8) {
                        Text(shortDate(trend.date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(MetalTheme.steel)
                            .frame(width: 40, alignment: .leading)
                        
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(MetalTheme.crimson)
                                .frame(width: max(2, geo.size.width * CGFloat(trend.requestCount) / 10))
                        }
                        
                        Text("\(trend.requestCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(MetalTheme.ember)
                            .frame(width: 20, alignment: .trailing)
                    }
                }
            }
        }
        .metalCard()
    }

    private var tokensTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tokens", systemImage: "text.badge.plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(MetalTheme.chrome)
                Spacer()
                Text("\(trends.reduce(0) { $0 + $1.tokenCount }) total")
                    .font(.system(size: 11))
                    .foregroundColor(MetalTheme.steel)
            }

            VStack(spacing: 4) {
                ForEach(trends.suffix(7)) { trend in
                    HStack(spacing: 8) {
                        Text(shortDate(trend.date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(MetalTheme.steel)
                            .frame(width: 40, alignment: .leading)
                        
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(MetalTheme.gold)
                                .frame(width: max(2, geo.size.width * CGFloat(trend.tokenCount) / 1000))
                        }
                        
                        Text("\(trend.tokenCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(MetalTheme.gold)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .metalCard()
    }

    private var costTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Cost", systemImage: "dollarsign.circle")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(MetalTheme.chrome)
                Spacer()
                Text(String(format: "$%.2f", trends.reduce(0) { $0 + $1.costEstimate }))
                    .font(.system(size: 11))
                    .foregroundColor(MetalTheme.steel)
            }

            VStack(spacing: 4) {
                ForEach(trends.suffix(7)) { trend in
                    HStack(spacing: 8) {
                        Text(shortDate(trend.date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(MetalTheme.steel)
                            .frame(width: 40, alignment: .leading)
                        
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(MetalTheme.toxicGreen)
                                .frame(width: max(2, geo.size.width * CGFloat(trend.costEstimate) / 0.1))
                        }
                        
                        Text(String(format: "$%.2f", trend.costEstimate))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(MetalTheme.toxicGreen)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .metalCard()
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#endif
```

- [ ] **Step 4: Build and verify**

```bash
swift build
```

- [ ] **Step 5: Commit views**

```bash
git add Sources/WritersApp/Views/AIGenerationHistoryView.swift Sources/WritersApp/Views/AIModelBreakdownView.swift Sources/WritersApp/Views/AITrendChartView.swift
git commit -m "feat: add AI dashboard tab views

- AIGenerationHistoryView: timeline of recent generations
- AIModelBreakdownView: per-model usage cards
- AITrendChartView: 30-day trends for requests, tokens, cost

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01A7XeKMFih58GmUd9uA7Pus"
```

---

### Task 6: Integration with AIService

**Files:**
- Modify: `Sources/WritersApp/Services/AIService.swift`

**Interfaces:**
- Consumes: `AIAnalyticsService`, `AIGenerationRecord`
- Produces: Modified AIService that tracks all generations

- [ ] **Step 1: Modify AIService to inject analytics**

Read the current AIService and add tracking calls after each successful generation.

```bash
# Add property to AIService
private var analyticsService: AIAnalyticsService?

# Add method to enableAnalytics
public func enableAnalytics(_ analyticsService: AIAnalyticsService) {
    self.analyticsService = analyticsService
}

# In sendRequest method, track results
if let service = analyticsService {
    let record = AIGenerationRecord(
        timestamp: Date(),
        assistanceType: .custom("request"),
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        model: configuration.model,
        status: .completed
    )
    service.trackGeneration(record)
}
```

- [ ] **Step 2: Commit integration**

```bash
git add Sources/WritersApp/Services/AIService.swift
git commit -m "feat: integrate analytics tracking into AIService

- Inject AIAnalyticsService into AIService
- Track successful generations automatically
- Record tokens and model usage

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01A7XeKMFih58GmUd9uA7Pus"
```

---

## Summary Checklist

- [ ] Task 1: Data models created and tested
- [ ] Task 2: Analytics service implemented and tested
- [ ] Task 3: ViewModel created and tested
- [ ] Task 4: Main dashboard view completed
- [ ] Task 5: Tab views (history, models, trends) completed
- [ ] Task 6: AIService integration complete
- [ ] All tests passing: `swift test`
- [ ] Build succeeds: `swift build`
- [ ] Dashboard displays correctly on Mac and iPad Pro

---

## Next Steps (Post-Implementation)

1. **Test on devices:** Run on Mac and iPad Pro, verify responsive layout
2. **Accessibility:** Ensure labels and colors meet WCAG standards
3. **Performance:** Profile memory usage with many generation records
4. **Export:** Add ability to export analytics as CSV/JSON
5. **Persistence:** Extend storage to support cloud sync (iCloud)
6. **Real-time updates:** Add push notifications for milestone events
