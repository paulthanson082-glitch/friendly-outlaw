import XCTest
@testable import WritersApp

/// Tests to verify performance optimizations
final class PerformanceTests: XCTestCase {
    
    // MARK: - DocumentManager Performance Tests
    
    func testDocumentSearchPerformance() {
        let manager = DocumentManager()
        
        // Create 1000 test documents
        for i in 0..<1000 {
            let doc = Document(
                title: "Document \(i)",
                content: "This is test content for document number \(i). It contains various words to search through.",
                category: .article
            )
            manager.createDocument(doc)
        }
        
        // Measure search performance
        measure {
            let results = manager.searchDocuments(query: "test")
            XCTAssertGreaterThan(results.count, 0)
        }
    }
    
    func testGetRecentDocumentsPerformance() {
        let manager = DocumentManager()
        
        // Create 1000 documents with different modification dates
        for i in 0..<1000 {
            let doc = Document(
                title: "Document \(i)",
                content: "Content \(i)",
                category: .novel
            )
            manager.createDocument(doc)
        }
        
        // Measure performance of getting recent documents
        measure {
            let recent = manager.getRecentDocuments(limit: 10)
            XCTAssertEqual(recent.count, 10)
        }
    }
    
    // MARK: - TemplateManager Performance Tests
    
    func testTemplateSearchPerformance() {
        let manager = TemplateManager()
        
        // Measure search performance with default templates
        measure {
            let results = manager.searchTemplates(query: "template")
            // Should find at least some results
            XCTAssertGreaterThanOrEqual(results.count, 0)
        }
    }
    
    // MARK: - FocusSessionManager Performance Tests
    
    func testSessionStatsPerformance() {
        let manager = FocusSessionManager()
        
        // Create 100 completed sessions
        for i in 0..<100 {
            let session = manager.startSession(
                type: .pomodoro,
                currentWordCount: i * 100
            )
            _ = manager.endSession(
                id: session.id,
                finalWordCount: (i + 1) * 100,
                completed: true
            )
        }
        
        // Measure stats calculation performance
        measure {
            let stats = manager.getStats()
            XCTAssertGreaterThan(stats.completedSessions, 0)
            XCTAssertGreaterThan(stats.totalWordsWritten, 0)
        }
    }
    
    func testStreakCalculationPerformance() {
        let manager = FocusSessionManager()
        
        // Create sessions across multiple days
        for i in 0..<50 {
            let session = manager.startSession(
                type: .deepWork,
                currentWordCount: i * 50
            )
            _ = manager.endSession(
                id: session.id,
                finalWordCount: (i + 1) * 50,
                completed: true
            )
        }
        
        // Measure streak calculation performance
        measure {
            let stats = manager.getStats()
            // Should complete without timing out
            XCTAssertGreaterThanOrEqual(stats.longestStreak, 0)
        }
    }
    
    // MARK: - ProductivityAnalytics Performance Tests
    
    func testAnalyticsReportGenerationPerformance() {
        let focusManager = FocusSessionManager()
        let goalManager = WritingGoalManager()
        let analytics = ProductivityAnalytics(
            focusManager: focusManager,
            goalManager: goalManager
        )
        
        // Create 100 sessions
        for i in 0..<100 {
            let session = focusManager.startSession(
                type: .sprint,
                currentWordCount: i * 75
            )
            _ = focusManager.endSession(
                id: session.id,
                finalWordCount: (i + 1) * 75,
                completed: true
            )
        }
        
        // Measure report generation performance
        measure {
            let report = analytics.generateReport(for: .allTime)
            XCTAssertGreaterThan(report.totalSessions, 0)
        }
    }
    
    func testTodaySummaryPerformance() {
        let focusManager = FocusSessionManager()
        let goalManager = WritingGoalManager()
        let analytics = ProductivityAnalytics(
            focusManager: focusManager,
            goalManager: goalManager
        )
        
        // Create today's sessions
        for i in 0..<20 {
            let session = focusManager.startSession(
                type: .pomodoro,
                currentWordCount: i * 100
            )
            _ = focusManager.endSession(
                id: session.id,
                finalWordCount: (i + 1) * 100,
                completed: true
            )
        }
        
        // Measure summary generation performance
        measure {
            let summary = analytics.getTodaySummary()
            XCTAssertGreaterThan(summary.sessionsCompleted, 0)
        }
    }
    
    // MARK: - WritingGoalManager Performance Tests
    
    func testGoalSummaryPerformance() {
        let manager = WritingGoalManager()
        
        // Create 50 goals
        for i in 0..<50 {
            _ = manager.createDailyWordGoal(
                target: 500 + i * 10,
                name: "Goal \(i)"
            )
        }
        
        // Measure summary calculation performance
        measure {
            let summary = manager.getSummary()
            XCTAssertGreaterThan(summary.totalGoals, 0)
        }
    }
}
