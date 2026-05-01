import XCTest
@testable import WritersApp

final class IssueManagementTests: XCTestCase {
    var app: WritersApp!
    var testDocumentId: UUID!
    
    override func setUp() {
        super.setUp()
        app = WritersApp()
        
        // Create a test document for issues
        let document = app.createBlankDocument(title: "Test Document", category: .novel)
        testDocumentId = document.id
    }
    
    override func tearDown() {
        app = nil
        testDocumentId = nil
        super.tearDown()
    }
    
    // MARK: - Issue Model Tests
    
    func testIssueCreation() {
        let issue = Issue(
            documentId: testDocumentId,
            title: "Fix plot hole",
            description: "Chapter 3 character appears but wasn't introduced",
            status: .open,
            priority: .high
        )
        
        XCTAssertNotNil(issue.id)
        XCTAssertEqual(issue.documentId, testDocumentId)
        XCTAssertEqual(issue.title, "Fix plot hole")
        XCTAssertEqual(issue.status, .open)
        XCTAssertEqual(issue.priority, .high)
    }
    
    func testIssueStatusEnum() {
        XCTAssertEqual(IssueStatus.open.displayName, "Open")
        XCTAssertEqual(IssueStatus.inProgress.displayName, "In Progress")
        XCTAssertEqual(IssueStatus.resolved.displayName, "Resolved")
        XCTAssertEqual(IssueStatus.closed.displayName, "Closed")
        
        XCTAssertEqual(IssueStatus.allCases.count, 4)
    }
    
    func testIssuePriorityEnum() {
        XCTAssertEqual(IssuePriority.low.displayName, "Low")
        XCTAssertEqual(IssuePriority.medium.displayName, "Medium")
        XCTAssertEqual(IssuePriority.high.displayName, "High")
        XCTAssertEqual(IssuePriority.critical.displayName, "Critical")
        
        XCTAssertEqual(IssuePriority.allCases.count, 4)
    }
    
    // MARK: - IssueManager CRUD Tests
    
    func testCreateIssue() {
        let issue = app.createIssue(
            documentId: testDocumentId,
            title: "Research medieval weapons",
            description: "Need accurate descriptions for battle scene",
            status: .open,
            priority: .medium
        )
        
        XCTAssertNotNil(issue.id)
        XCTAssertEqual(issue.title, "Research medieval weapons")
        XCTAssertEqual(issue.status, .open)
        XCTAssertEqual(issue.priority, .medium)
    }
    
    func testGetIssue() {
        let issue = app.createIssue(
            documentId: testDocumentId,
            title: "Test Issue",
            priority: .low
        )
        
        let retrieved = app.getIssue(id: issue.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, issue.id)
        XCTAssertEqual(retrieved?.title, "Test Issue")
    }
    
    func testUpdateIssue() {
        var issue = app.createIssue(
            documentId: testDocumentId,
            title: "Original Title",
            description: "Original description"
        )
        
        issue.title = "Updated Title"
        issue.description = "Updated description"
        app.updateIssue(issue)
        
        let retrieved = app.getIssue(id: issue.id)
        XCTAssertEqual(retrieved?.title, "Updated Title")
        XCTAssertEqual(retrieved?.description, "Updated description")
    }
    
    func testDeleteIssue() {
        let issue = app.createIssue(
            documentId: testDocumentId,
            title: "To Be Deleted"
        )
        
        let issueId = issue.id
        app.deleteIssue(id: issueId)
        
        let retrieved = app.getIssue(id: issueId)
        XCTAssertNil(retrieved)
    }
    
    // MARK: - Issue Filtering Tests
    
    func testGetIssuesForDocument() {
        let doc1 = app.createBlankDocument(title: "Doc 1", category: .novel)
        let doc2 = app.createBlankDocument(title: "Doc 2", category: .shortStory)
        
        _ = app.createIssue(documentId: doc1.id, title: "Issue 1")
        _ = app.createIssue(documentId: doc1.id, title: "Issue 2")
        _ = app.createIssue(documentId: doc2.id, title: "Issue 3")
        
        let doc1Issues = app.getIssues(forDocument: doc1.id)
        XCTAssertEqual(doc1Issues.count, 2)
        
        let doc2Issues = app.getIssues(forDocument: doc2.id)
        XCTAssertEqual(doc2Issues.count, 1)
    }
    
    func testGetIssuesByStatus() {
        _ = app.createIssue(documentId: testDocumentId, title: "Open Issue", status: .open)
        _ = app.createIssue(documentId: testDocumentId, title: "In Progress Issue", status: .inProgress)
        _ = app.createIssue(documentId: testDocumentId, title: "Resolved Issue", status: .resolved)
        
        let openIssues = app.getIssues(withStatus: .open)
        XCTAssertEqual(openIssues.count, 1)
        XCTAssertEqual(openIssues.first?.title, "Open Issue")
        
        let inProgressIssues = app.getIssues(withStatus: .inProgress)
        XCTAssertEqual(inProgressIssues.count, 1)
        
        let resolvedIssues = app.getIssues(withStatus: .resolved)
        XCTAssertEqual(resolvedIssues.count, 1)
    }
    
    func testGetIssuesByPriority() {
        _ = app.createIssue(documentId: testDocumentId, title: "Low Priority", priority: .low)
        _ = app.createIssue(documentId: testDocumentId, title: "High Priority", priority: .high)
        _ = app.createIssue(documentId: testDocumentId, title: "Critical Priority", priority: .critical)
        
        let lowPriorityIssues = app.getIssues(withPriority: .low)
        XCTAssertEqual(lowPriorityIssues.count, 1)
        
        let highPriorityIssues = app.getIssues(withPriority: .high)
        XCTAssertEqual(highPriorityIssues.count, 1)
        
        let criticalIssues = app.getIssues(withPriority: .critical)
        XCTAssertEqual(criticalIssues.count, 1)
    }
    
    func testSearchIssues() {
        _ = app.createIssue(documentId: testDocumentId, title: "Character development", description: "Add backstory")
        _ = app.createIssue(documentId: testDocumentId, title: "Plot revision", description: "Fix pacing issues")
        _ = app.createIssue(documentId: testDocumentId, title: "Grammar check", description: "Review dialogue")
        
        let characterResults = app.searchIssues(query: "character")
        XCTAssertEqual(characterResults.count, 1)
        XCTAssertEqual(characterResults.first?.title, "Character development")
        
        let plotResults = app.searchIssues(query: "plot")
        XCTAssertEqual(plotResults.count, 1)
        
        let dialogueResults = app.searchIssues(query: "dialogue")
        XCTAssertEqual(dialogueResults.count, 1)
        
        // Empty query should return empty array (not all issues)
        let allResults = app.searchIssues(query: "")
        XCTAssertTrue(allResults.isEmpty)
    }
    
    // MARK: - Issue Status Update Tests
    
    func testUpdateIssueStatus() {
        let issue = app.createIssue(
            documentId: testDocumentId,
            title: "Test Status Update",
            status: .open
        )
        
        app.updateIssueStatus(id: issue.id, status: .inProgress)
        
        let retrieved = app.getIssue(id: issue.id)
        XCTAssertEqual(retrieved?.status, .inProgress)
    }
    
    func testUpdateIssuePriority() {
        let issue = app.createIssue(
            documentId: testDocumentId,
            title: "Test Priority Update",
            priority: .low
        )
        
        app.updateIssuePriority(id: issue.id, priority: .critical)
        
        let retrieved = app.getIssue(id: issue.id)
        XCTAssertEqual(retrieved?.priority, .critical)
    }
    
    func testResolvedAtTimestamp() {
        var issue = app.createIssue(
            documentId: testDocumentId,
            title: "Test Resolved Timestamp",
            status: .open
        )
        
        XCTAssertNil(issue.metadata.resolvedAt)
        
        app.updateIssueStatus(id: issue.id, status: .resolved)
        
        let retrieved = app.getIssue(id: issue.id)
        XCTAssertNotNil(retrieved?.metadata.resolvedAt)
    }
    
    // MARK: - Issue Statistics Tests
    
    func testIssueStatisticsByStatus() {
        _ = app.createIssue(documentId: testDocumentId, title: "Issue 1", status: .open)
        _ = app.createIssue(documentId: testDocumentId, title: "Issue 2", status: .open)
        _ = app.createIssue(documentId: testDocumentId, title: "Issue 3", status: .inProgress)
        _ = app.createIssue(documentId: testDocumentId, title: "Issue 4", status: .resolved)
        
        let (byStatus, _) = app.getIssueStatistics()
        
        XCTAssertEqual(byStatus[.open], 2)
        XCTAssertEqual(byStatus[.inProgress], 1)
        XCTAssertEqual(byStatus[.resolved], 1)
        XCTAssertEqual(byStatus[.closed], 0)
    }
    
    func testIssueStatisticsByPriority() {
        _ = app.createIssue(documentId: testDocumentId, title: "Issue 1", priority: .low)
        _ = app.createIssue(documentId: testDocumentId, title: "Issue 2", priority: .medium)
        _ = app.createIssue(documentId: testDocumentId, title: "Issue 3", priority: .medium)
        _ = app.createIssue(documentId: testDocumentId, title: "Issue 4", priority: .critical)
        
        let (_, byPriority) = app.getIssueStatistics()
        
        XCTAssertEqual(byPriority[.low], 1)
        XCTAssertEqual(byPriority[.medium], 2)
        XCTAssertEqual(byPriority[.high], 0)
        XCTAssertEqual(byPriority[.critical], 1)
    }
    
    func testGetOpenIssuesForDocument() {
        _ = app.createIssue(documentId: testDocumentId, title: "Open Issue 1", status: .open, priority: .high)
        _ = app.createIssue(documentId: testDocumentId, title: "Open Issue 2", status: .open, priority: .low)
        _ = app.createIssue(documentId: testDocumentId, title: "Closed Issue", status: .closed, priority: .high)
        
        let openIssues = app.getOpenIssues(forDocument: testDocumentId)
        XCTAssertEqual(openIssues.count, 2)
        
        // Should contain both open issues
        let titles = openIssues.map { $0.title }
        XCTAssertTrue(titles.contains("Open Issue 1"))
        XCTAssertTrue(titles.contains("Open Issue 2"))
    }
    
    func testGetCriticalIssues() {
        let doc1 = app.createBlankDocument(title: "Doc 1", category: .novel)
        let doc2 = app.createBlankDocument(title: "Doc 2", category: .article)
        
        _ = app.createIssue(documentId: doc1.id, title: "Critical Issue 1", status: .open, priority: .critical)
        _ = app.createIssue(documentId: doc2.id, title: "Critical Issue 2", status: .inProgress, priority: .critical)
        _ = app.createIssue(documentId: doc1.id, title: "Critical Issue 3", status: .closed, priority: .critical)
        _ = app.createIssue(documentId: doc1.id, title: "High Priority", status: .open, priority: .high)
        
        let criticalIssues = app.getCriticalIssues()
        
        // Should return critical issues that are not closed
        XCTAssertEqual(criticalIssues.count, 2)
        XCTAssertTrue(criticalIssues.allSatisfy { $0.priority == .critical })
        XCTAssertTrue(criticalIssues.allSatisfy { $0.status != .closed })
    }
    
    // MARK: - Issue Metadata Tests
    
    func testIssueMetadataTags() {
        var issue = app.createIssue(
            documentId: testDocumentId,
            title: "Test Tags"
        )
        
        issue.metadata.tags = ["research", "plot", "urgent"]
        app.updateIssue(issue)
        
        let retrieved = app.getIssue(id: issue.id)
        XCTAssertEqual(retrieved?.metadata.tags.count, 3)
        XCTAssertTrue(retrieved?.metadata.tags.contains("research") ?? false)
    }
    
    func testIssueMetadataNotes() {
        var issue = app.createIssue(
            documentId: testDocumentId,
            title: "Test Notes"
        )
        
        issue.metadata.notes = "Additional context about this issue"
        app.updateIssue(issue)
        
        let retrieved = app.getIssue(id: issue.id)
        XCTAssertEqual(retrieved?.metadata.notes, "Additional context about this issue")
    }
    
    func testIssueMetadataTimestamps() {
        let issue = app.createIssue(
            documentId: testDocumentId,
            title: "Test Timestamps"
        )
        
        XCTAssertNotNil(issue.metadata.created)
        XCTAssertNotNil(issue.metadata.modified)
        XCTAssertNil(issue.metadata.resolvedAt)
        
        // Modified should be equal to or after created
        XCTAssertTrue(issue.metadata.modified >= issue.metadata.created)
    }
    
    // MARK: - Issue Codable Tests
    
    func testIssueCodable() throws {
        let issue = Issue(
            documentId: testDocumentId,
            title: "Test Codable",
            description: "Testing JSON encoding/decoding",
            status: .inProgress,
            priority: .high
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(issue)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Issue.self, from: data)
        
        XCTAssertEqual(decoded.id, issue.id)
        XCTAssertEqual(decoded.documentId, issue.documentId)
        XCTAssertEqual(decoded.title, issue.title)
        XCTAssertEqual(decoded.description, issue.description)
        XCTAssertEqual(decoded.status, issue.status)
        XCTAssertEqual(decoded.priority, issue.priority)
    }
}
