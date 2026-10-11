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
