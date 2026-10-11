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
