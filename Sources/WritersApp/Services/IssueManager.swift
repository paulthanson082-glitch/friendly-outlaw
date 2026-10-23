import Foundation

/// Manages issue storage, retrieval, and operations
public class IssueManager {
    private var issues: [UUID: Issue]
    
    public init() {
        self.issues = [:]
    }
    
    // MARK: - Issue Management
    
    /// Creates a new issue
    public func createIssue(_ issue: Issue) {
        issues[issue.id] = issue
    }
    
    /// Retrieves an issue by ID
    public func getIssue(id: UUID) -> Issue? {
        return issues[id]
    }
    
    /// Retrieves all issues
    public func getAllIssues() -> [Issue] {
        return Array(issues.values)
            .sorted { $0.metadata.created > $1.metadata.created }
    }
    
    /// Retrieves issues for a specific document
    public func getIssues(forDocument documentId: UUID) -> [Issue] {
        return issues.values.filter { $0.documentId == documentId }
            .sorted { $0.metadata.created > $1.metadata.created }
    }
    
    /// Retrieves issues by status
    public func getIssues(withStatus status: IssueStatus) -> [Issue] {
        return issues.values.filter { $0.status == status }
            .sorted { $0.metadata.created > $1.metadata.created }
    }
    
    /// Retrieves issues by priority
    public func getIssues(withPriority priority: IssuePriority) -> [Issue] {
        return issues.values.filter { $0.priority == priority }
            .sorted { $0.metadata.created > $1.metadata.created }
    }
    
    /// Searches issues by title or description
    public func searchIssues(query: String) -> [Issue] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return getAllIssues() }

        return issues.values.filter { issue in
            issue.title.localizedCaseInsensitiveContains(trimmedQuery) ||
            issue.description.localizedCaseInsensitiveContains(trimmedQuery)
        }.sorted { $0.metadata.created > $1.metadata.created }
    }
    
    /// Updates an existing issue
    public func updateIssue(_ issue: Issue) {
        var updatedIssue = issue
        updatedIssue.metadata.modified = Date()
        
        // Set resolvedAt when status changes to resolved
        if updatedIssue.status == .resolved && updatedIssue.metadata.resolvedAt == nil {
            updatedIssue.metadata.resolvedAt = Date()
        }
        
        issues[issue.id] = updatedIssue
    }
    
    /// Deletes an issue
    public func deleteIssue(id: UUID) {
        issues.removeValue(forKey: id)
    }
    
    /// Updates the status of an issue
    public func updateIssueStatus(id: UUID, status: IssueStatus) {
        guard var issue = issues[id] else { return }
        issue.status = status
        issue.metadata.modified = Date()
        
        if status == .resolved && issue.metadata.resolvedAt == nil {
            issue.metadata.resolvedAt = Date()
        } else if status == .open {
            issue.metadata.resolvedAt = nil
        }
        
        issues[id] = issue
    }
    
    /// Reopens a resolved or closed issue, clearing its resolved date
    public func reopenIssue(id: UUID) {
        updateIssueStatus(id: id, status: .open)
    }
    
    /// Updates the priority of an issue
    public func updateIssuePriority(id: UUID, priority: IssuePriority) {
        guard var issue = issues[id] else { return }
        issue.priority = priority
        issue.metadata.modified = Date()
        issues[id] = issue
    }
    
    // MARK: - Statistics
    
    /// Gets count of issues by status
    public func getIssueCountByStatus() -> [IssueStatus: Int] {
        var counts: [IssueStatus: Int] = [:]
        for status in IssueStatus.allCases {
            counts[status] = issues.values.filter { $0.status == status }.count
        }
        return counts
    }
    
    /// Gets count of issues by priority
    public func getIssueCountByPriority() -> [IssuePriority: Int] {
        var counts: [IssuePriority: Int] = [:]
        for priority in IssuePriority.allCases {
            counts[priority] = issues.values.filter { $0.priority == priority }.count
        }
        return counts
    }
    
    /// Gets open issues for a document
    public func getOpenIssues(forDocument documentId: UUID) -> [Issue] {
        return issues.values.filter { $0.documentId == documentId && $0.status == .open }
            .sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    /// Gets critical issues across all documents
    public func getCriticalIssues() -> [Issue] {
        return issues.values.filter { $0.priority == .critical && $0.status != .closed }
            .sorted { $0.metadata.created > $1.metadata.created }
    }
}
