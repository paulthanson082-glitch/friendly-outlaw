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
