//
//  EncouragementServiceTests.swift
//  WritersAppTests
//
//  Tests for the EncouragementService
//

import XCTest
@testable import WritersApp

final class EncouragementServiceTests: XCTestCase {
    
    var service: EncouragementService!
    
    override func setUp() {
        super.setUp()
        service = EncouragementService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testDefaultConfiguration() {
        XCTAssertTrue(service.configuration.enabled)
        XCTAssertTrue(service.configuration.showOnMilestones)
        XCTAssertTrue(service.configuration.showOnSessionEnd)
        XCTAssertEqual(service.configuration.minimumWordsForEncouragement, 50)
        XCTAssertEqual(service.configuration.encouragementFrequency, .moderate)
    }
    
    func testCustomConfiguration() {
        let config = EncouragementConfiguration(
            enabled: false,
            showOnMilestones: false,
            showOnSessionEnd: false,
            minimumWordsForEncouragement: 100,
            encouragementFrequency: .occasional
        )
        service = EncouragementService(configuration: config)
        
        XCTAssertFalse(service.configuration.enabled)
        XCTAssertFalse(service.configuration.showOnMilestones)
        XCTAssertFalse(service.configuration.showOnSessionEnd)
        XCTAssertEqual(service.configuration.minimumWordsForEncouragement, 100)
        XCTAssertEqual(service.configuration.encouragementFrequency, .occasional)
    }
    
    // MARK: - Word Count Encouragement Tests
    
    func testWordCountEncouragementSmall() {
        let encouragement = service.getWordCountEncouragement(wordCount: 100, previousCount: 0)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .wordCount)
        XCTAssertFalse(encouragement!.message.isEmpty)
        XCTAssertEqual(encouragement?.context?["words_written"], "100")
        XCTAssertEqual(encouragement?.context?["total_words"], "100")
    }
    
    func testWordCountEncouragementMedium() {
        let encouragement = service.getWordCountEncouragement(wordCount: 200, previousCount: 0)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .wordCount)
        XCTAssertFalse(encouragement!.message.isEmpty)
    }
    
    func testWordCountEncouragementLarge() {
        let encouragement = service.getWordCountEncouragement(wordCount: 400, previousCount: 0)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .wordCount)
        XCTAssertFalse(encouragement!.message.isEmpty)
    }
    
    func testWordCountEncouragementHuge() {
        let encouragement = service.getWordCountEncouragement(wordCount: 750, previousCount: 0)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .wordCount)
        XCTAssertFalse(encouragement!.message.isEmpty)
    }
    
    func testWordCountEncouragementMassive() {
        let encouragement = service.getWordCountEncouragement(wordCount: 1500, previousCount: 0)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .wordCount)
        XCTAssertFalse(encouragement!.message.isEmpty)
    }
    
    func testWordCountEncouragementBelowMinimum() {
        let encouragement = service.getWordCountEncouragement(wordCount: 30, previousCount: 0)
        
        XCTAssertNil(encouragement, "Should not provide encouragement for word count below minimum")
    }
    
    func testWordCountEncouragementDisabled() {
        service.configuration.enabled = false
        let encouragement = service.getWordCountEncouragement(wordCount: 100, previousCount: 0)
        
        XCTAssertNil(encouragement, "Should not provide encouragement when disabled")
    }
    
    func testWordCountEncouragementWithPreviousCount() {
        let encouragement = service.getWordCountEncouragement(wordCount: 250, previousCount: 100)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.context?["words_written"], "150")
        XCTAssertEqual(encouragement?.context?["total_words"], "250")
    }
    
    // MARK: - Session Encouragement Tests
    
    func testSessionEncouragementShort() {
        let encouragement = service.getSessionEncouragement(durationMinutes: 10, wordsWritten: 50)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .sessionDuration)
        XCTAssertFalse(encouragement!.message.isEmpty)
        XCTAssertEqual(encouragement?.context?["duration_minutes"], "10")
        XCTAssertEqual(encouragement?.context?["words_written"], "50")
    }
    
    func testSessionEncouragementMedium() {
        let encouragement = service.getSessionEncouragement(durationMinutes: 20, wordsWritten: 200)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .sessionDuration)
        XCTAssertFalse(encouragement!.message.isEmpty)
    }
    
    func testSessionEncouragementLong() {
        let encouragement = service.getSessionEncouragement(durationMinutes: 45, wordsWritten: 500)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .sessionDuration)
        XCTAssertFalse(encouragement!.message.isEmpty)
    }
    
    func testSessionEncouragementMarathon() {
        let encouragement = service.getSessionEncouragement(durationMinutes: 90, wordsWritten: 1000)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .sessionDuration)
        XCTAssertFalse(encouragement!.message.isEmpty)
    }
    
    func testSessionEncouragementDisabled() {
        service.configuration.showOnSessionEnd = false
        let encouragement = service.getSessionEncouragement(durationMinutes: 30, wordsWritten: 300)
        
        XCTAssertNil(encouragement, "Should not provide session encouragement when disabled")
    }
    
    // MARK: - Milestone Encouragement Tests
    
    func testMilestoneEncouragementWordCount() {
        let milestone = WritingMilestone(type: .totalWords, value: 1000)
        let encouragement = service.getMilestoneEncouragement(milestone: milestone)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .milestone)
        XCTAssertFalse(encouragement!.message.isEmpty)
        XCTAssertTrue(encouragement!.message.contains("1000") || encouragement!.message.contains("thousand"))
    }
    
    func testMilestoneEncouragementDocumentCount() {
        let milestone = WritingMilestone(type: .documentCount, value: 10)
        let encouragement = service.getMilestoneEncouragement(milestone: milestone)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .milestone)
        XCTAssertTrue(encouragement!.message.contains("10"))
    }
    
    func testMilestoneEncouragementConsecutiveDays() {
        let milestone = WritingMilestone(type: .consecutiveDays, value: 7)
        let encouragement = service.getMilestoneEncouragement(milestone: milestone)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .milestone)
        XCTAssertTrue(encouragement!.message.contains("7"))
    }
    
    func testMilestoneEncouragementSessions() {
        let milestone = WritingMilestone(type: .sessionsCompleted, value: 50)
        let encouragement = service.getMilestoneEncouragement(milestone: milestone)
        
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .milestone)
        XCTAssertTrue(encouragement!.message.contains("50"))
    }
    
    func testMilestoneEncouragementDisabled() {
        service.configuration.showOnMilestones = false
        let milestone = WritingMilestone(type: .totalWords, value: 5000)
        let encouragement = service.getMilestoneEncouragement(milestone: milestone)
        
        XCTAssertNil(encouragement, "Should not provide milestone encouragement when disabled")
    }
    
    // MARK: - General Encouragement Tests
    
    func testGeneralEncouragement() {
        let encouragement = service.getGeneralEncouragement()
        
        XCTAssertEqual(encouragement.type, .general)
        XCTAssertFalse(encouragement.message.isEmpty)
    }
    
    func testPerseveranceEncouragement() {
        let encouragement = service.getPerseveranceEncouragement()
        
        XCTAssertEqual(encouragement.type, .perseverance)
        XCTAssertFalse(encouragement.message.isEmpty)
    }
    
    // MARK: - History Tests
    
    func testEncouragementHistory() {
        XCTAssertTrue(service.getHistory().isEmpty)
        
        _ = service.getGeneralEncouragement()
        XCTAssertEqual(service.getHistory().count, 1)
        
        _ = service.getWordCountEncouragement(wordCount: 100, previousCount: 0)
        XCTAssertEqual(service.getHistory().count, 2)
        
        _ = service.getSessionEncouragement(durationMinutes: 30, wordsWritten: 300)
        XCTAssertEqual(service.getHistory().count, 3)
    }
    
    func testEncouragementHistoryLimit() {
        // Add 15 encouragements
        for _ in 0..<15 {
            _ = service.getGeneralEncouragement()
        }
        
        let history = service.getHistory(limit: 10)
        XCTAssertEqual(history.count, 10, "History should be limited to requested count")
    }
    
    func testClearHistory() {
        _ = service.getGeneralEncouragement()
        _ = service.getGeneralEncouragement()
        XCTAssertEqual(service.getHistory().count, 2)
        
        service.clearHistory()
        XCTAssertTrue(service.getHistory().isEmpty)
    }
    
    // MARK: - Message Variety Tests
    
    func testMessageVariety() {
        var messages = Set<String>()
        
        // Generate multiple general encouragements
        for _ in 0..<20 {
            let encouragement = service.getGeneralEncouragement()
            messages.insert(encouragement.message)
        }
        
        // Should have some variety (not all the same message)
        XCTAssertGreaterThan(messages.count, 1, "Should provide variety in messages")
    }
    
    // MARK: - Integration with WritersApp
    
    func testWritersAppIntegration() {
        let app = WritersApp()
        
        // Test encouragement is available
        XCTAssertTrue(app.isEncouragementEnabled)
        
        // Test getting encouragement
        let encouragement = app.getGeneralEncouragement()
        XCTAssertFalse(encouragement.message.isEmpty)
        
        // Test toggling encouragement
        app.setEncouragementEnabled(false)
        XCTAssertFalse(app.isEncouragementEnabled)
        
        app.setEncouragementEnabled(true)
        XCTAssertTrue(app.isEncouragementEnabled)
    }
    
    func testWritersAppDocumentEncouragement() {
        let app = WritersApp()
        let document = app.createBlankDocument(title: "Test", category: .novel)
        
        // Update document with some content
        let updatedDocument = Document(
            id: document.id,
            title: document.title,
            content: String(repeating: "word ", count: 100),
            category: document.category
        )
        
        let encouragement = app.getEncouragementForDocument(updatedDocument)
        XCTAssertNotNil(encouragement)
        XCTAssertEqual(encouragement?.type, .wordCount)
    }
}
