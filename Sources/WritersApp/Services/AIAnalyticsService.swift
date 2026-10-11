// Sources/WritersApp/Services/AIAnalyticsService.swift
import Foundation

public class AIAnalyticsService {
    private var records: [AIGenerationRecord] = []
    private let fileManager = FileManager.default
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
