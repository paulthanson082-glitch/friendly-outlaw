#if canImport(SwiftUI)
import SwiftUI

// MARK: - AIContentDashboardView

/// Full AI Content Generation dashboard with metal theme.
/// Four sections: The Usage Snapshot (stats), The Chronicle (generation history),
/// The Models (model breakdown), and The Trends (usage trends).
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
                aiContentHeader

                // Tab bar
                aiContentTabBar

                // Content
                Group {
                    switch selectedTab {
                    case .overview:  AIOverviewSection(viewModel: viewModel)
                    case .history:   AIHistorySection(viewModel: viewModel)
                    case .models:    AIModelsSection(viewModel: viewModel)
                    case .trends:    AITrendsSection(viewModel: viewModel)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
        }
        .onAppear { viewModel.reload() }
    }

    // MARK: - Header

    private var aiContentHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(MetalTheme.crimson)
            VStack(alignment: .leading, spacing: 2) {
                Text("THE MUSE")
                    .font(.system(size: 20, weight: .black))
                    .tracking(4)
                    .foregroundColor(MetalTheme.chrome)
                Text("AI Content Generation")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundColor(MetalTheme.steel)
            }
            Spacer()
            // Quick stat pill
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

    // MARK: - Tab Bar

    private var aiContentTabBar: some View {
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

// MARK: - AIContentTab

@available(iOS 16.0, macOS 13.0, *)
enum AIContentTab: CaseIterable {
    case overview, history, models, trends

    var label: String {
        switch self {
        case .overview:  return "OVERVIEW"
        case .history:   return "CHRONICLE"
        case .models:    return "MODELS"
        case .trends:    return "TRENDS"
        }
    }

    var systemImage: String {
        switch self {
        case .overview:  return "chart.bar.fill"
        case .history:   return "clock.fill"
        case .models:    return "cpu.fill"
        case .trends:    return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Overview Section

@available(iOS 16.0, macOS 13.0, *)
private struct AIOverviewSection: View {
    @ObservedObject var viewModel: AIContentDashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MetalTheme.sectionTitle("The Usage Snapshot").padding(.top, 8)

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    AIMetricCard(
                        value: "\(viewModel.snapshot.totalRequests)",
                        label: "REQUESTS",
                        icon: "bolt.fill",
                        color: MetalTheme.ember
                    )
                    AIMetricCard(
                        value: "\(viewModel.snapshot.totalTokens)",
                        label: "TOKENS",
                        icon: "textformat.alt",
                        color: MetalTheme.chrome
                    )
                    AIMetricCard(
                        value: "\(viewModel.snapshot.requestsToday)",
                        label: "TODAY",
                        icon: "calendar.badge.clock",
                        color: MetalTheme.toxicGreen
                    )
                    AIMetricCard(
                        value: String(format: "$%.2f", viewModel.snapshot.costEstimate),
                        label: "COST EST.",
                        icon: "dollarsign.circle.fill",
                        color: MetalTheme.gold
                    )
                }

                // Average tokens per request
                if viewModel.snapshot.totalRequests > 0 {
                    averageTokensCard
                }

                // Model breakdown
                if !viewModel.modelBreakdown.isEmpty {
                    MetalTheme.sectionTitle("Model Breakdown").padding(.top, 4)
                    modelDistribution
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
    }

    private var averageTokensCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                MetalTheme.sectionTitle("Avg Tokens/Request")
                Text("\(viewModel.snapshot.averageTokensPerRequest)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(MetalTheme.chrome)
            }
            Spacer()
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(MetalTheme.forgeGradient)
        }
        .metalCard()
    }

    private var modelDistribution: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.modelBreakdown) { breakdown in
                HStack(spacing: 10) {
                    Text(breakdown.model.displayName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(MetalTheme.chrome)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                    Text(String(format: "%.0f%%", breakdown.percentage * 100))
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundColor(MetalTheme.steel)
                        .frame(width: 40, alignment: .trailing)
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
        case .claude3Haiku: return MetalTheme.toxicGreen
        }
    }
}

// MARK: - History Section

@available(iOS 16.0, macOS 13.0, *)
private struct AIHistorySection: View {
    @ObservedObject var viewModel: AIContentDashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            MetalTheme.sectionTitle("Recent Generations")
                .padding(.top, 12)
                .padding(.horizontal, 16)

            if viewModel.recentRecords.isEmpty {
                AIEmptyState(icon: "clock", message: "No generations logged yet.\nStart using AI features to track your usage.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.recentRecords) { record in
                            GenerationRecordRow(record: record)
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

// MARK: - Models Section

@available(iOS 16.0, macOS 13.0, *)
private struct AIModelsSection: View {
    @ObservedObject var viewModel: AIContentDashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            MetalTheme.sectionTitle("Model Usage Statistics")
                .padding(.top, 12)
                .padding(.horizontal, 16)

            if viewModel.modelBreakdown.isEmpty {
                AIEmptyState(icon: "cpu", message: "No model data available yet.\nStart using AI features to generate data.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.modelBreakdown) { breakdown in
                            ModelBreakdownCard(breakdown: breakdown)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}

// MARK: - Trends Section

@available(iOS 16.0, macOS 13.0, *)
private struct AITrendsSection: View {
    @ObservedObject var viewModel: AIContentDashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            MetalTheme.sectionTitle("Usage Trends (30 Days)")
                .padding(.top, 12)
                .padding(.horizontal, 16)

            if viewModel.trends.isEmpty {
                AIEmptyState(icon: "chart.line", message: "No trend data available yet.\nData will appear as you use AI features.")
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Quick stats
                        trendsOverviewCards

                        // Daily breakdown
                        MetalTheme.sectionTitle("Daily Activity")
                            .padding(.top, 8)
                            .padding(.horizontal, 16)

                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.trends) { trend in
                                TrendDayRow(trend: trend)
                            }
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
        }
    }

    private var trendsOverviewCards: some View {
        let totalRequests = viewModel.trends.reduce(0) { $0 + $1.requestCount }
        let totalTokens = viewModel.trends.reduce(0) { $0 + $1.tokenCount }
        let totalCost = viewModel.trends.reduce(0) { $0 + $1.costEstimate }

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                AIMetricCard(
                    value: "\(totalRequests)",
                    label: "30-DAY",
                    icon: "bolt.fill",
                    color: MetalTheme.ember
                )
                AIMetricCard(
                    value: "\(totalTokens)",
                    label: "TOTAL TOKENS",
                    icon: "textformat.alt",
                    color: MetalTheme.chrome
                )
            }
            HStack {
                VStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(MetalTheme.gold.opacity(0.8))
                    Text(String(format: "$%.2f", totalCost))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(MetalTheme.gold)
                    Text("30-DAY COST")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(1.5)
                        .foregroundColor(MetalTheme.steel)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .metalCard()

                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - AIMetricCard

@available(iOS 16.0, macOS 13.0, *)
private struct AIMetricCard: View {
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
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
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

// MARK: - GenerationRecordRow

@available(iOS 16.0, macOS 13.0, *)
private struct GenerationRecordRow: View {
    let record: AIGenerationRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Type icon
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
                    Text(shortDate(record.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(MetalTheme.steel)
                }

                HStack(spacing: 16) {
                    Label("\(record.inputTokens)", systemImage: "arrow.down")
                        .font(.system(size: 11))
                        .foregroundColor(MetalTheme.steel)
                    Label("\(record.outputTokens)", systemImage: "arrow.up")
                        .font(.system(size: 11))
                        .foregroundColor(MetalTheme.steel)
                    Spacer()
                    Text(record.model.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(MetalTheme.chainLink)
                }
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
        case .pending: return MetalTheme.ember
        case .failed: return MetalTheme.crimson
        case .cancelled: return MetalTheme.steel
        }
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    private func shortDate(_ date: Date) -> String {
        GenerationRecordRow.shortDateFormatter.string(from: date)
    }
}

// MARK: - ModelBreakdownCard

@available(iOS 16.0, macOS 13.0, *)
private struct ModelBreakdownCard: View {
    let breakdown: ModelUsageBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(breakdown.model.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(MetalTheme.chrome)
                    Text("\(breakdown.requestCount) request\(breakdown.requestCount == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(MetalTheme.steel)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f%%", breakdown.percentage * 100))
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(modelColor(breakdown.model))
                    Text("OF USAGE")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(MetalTheme.steel)
                }
            }

            // Token bar
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(MetalTheme.gunmetal)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(modelColor(breakdown.model))
                            .frame(width: geo.size.width * breakdown.percentage)
                    }
                }
                .frame(height: 12)

                Text("\(breakdown.tokenCount)")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundColor(MetalTheme.steel)
                    .frame(width: 50, alignment: .trailing)
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
        case .claude3Haiku: return MetalTheme.toxicGreen
        }
    }
}

// MARK: - TrendDayRow

@available(iOS 16.0, macOS 13.0, *)
private struct TrendDayRow: View {
    let trend: DailyTrend

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(trend.date))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(MetalTheme.chrome)
                Text(formatDayOfWeek(trend.date))
                    .font(.system(size: 10))
                    .foregroundColor(MetalTheme.steel)
            }
            .frame(width: 60, alignment: .leading)

            // Request count
            VStack(alignment: .center, spacing: 2) {
                Text("\(trend.requestCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(MetalTheme.ember)
                Text("reqs")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(MetalTheme.steel)
            }
            .frame(width: 40)

            // Token bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(MetalTheme.gunmetal)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(MetalTheme.forgeGradient)
                        .frame(height: 20)
                }
            }
            .frame(height: 20)

            // Tokens and cost
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(trend.tokenCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(MetalTheme.chrome)
                Text(String(format: "$%.3f", trend.costEstimate))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(MetalTheme.gold)
            }
            .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(MetalTheme.obsidian)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(MetalTheme.chainLink, lineWidth: 0.5)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// MARK: - AIEmptyState

@available(iOS 16.0, macOS 13.0, *)
private struct AIEmptyState: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(MetalTheme.chainLink)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(MetalTheme.steel)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(40)
    }
}

#endif
