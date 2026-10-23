import Foundation
import Combine

@available(iOS 16.0, macOS 14.0, *)
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
