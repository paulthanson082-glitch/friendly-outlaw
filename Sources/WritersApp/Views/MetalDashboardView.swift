#if canImport(SwiftUI)
import SwiftUI

// MARK: - Metal Dashboard View

/// The main iPad Pro dashboard — a brutal, heavy metal-themed command center
/// for your writing life. Inspired by Whitechapel and Lamb of God.
///
/// Sections:
/// - **The Mantra** — rotating metal-inspired motivational quote
/// - **Kill Count** — total words, documents, streaks, focus time
/// - **The Armory** — quick-start focus sessions (Pomodoro, Sprint, Deep Work)
/// - **War Room** — recent documents
/// - **The Gauntlet** — writing goals and progress
/// - **The Forge** — quick actions: new doc, browse templates
@available(iOS 16.0, macOS 13.0, *)
public struct MetalDashboardView: View {
    @StateObject private var viewModel: MetalDashboardViewModel


    @MainActor
    public init(viewModel: MetalDashboardViewModel? = nil) {
        let vm = viewModel ?? MetalDashboardViewModel()
        _viewModel = StateObject(wrappedValue: vm)
    @MainActor
    public init(viewModel: MetalDashboardViewModel = MetalDashboardViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                dashboardHeader

                // Mantra banner
                mantraBanner

                // Kill Count stats row
                killCountSection

                // Two-column layout for middle sections
                HStack(alignment: .top, spacing: 20) {
                    // Left column
                    VStack(spacing: 20) {
                        armorySection
                        gauntletSection
                    }
                    .frame(maxWidth: .infinity)

                    // Right column
                    VStack(spacing: 20) {
                        warRoomSection
                        forgeSection
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
        .background(MetalTheme.abyssGradient.ignoresSafeArea())
        .onAppear {
            viewModel.loadDashboard()
        }
    }

    // MARK: - Dashboard Header

    private var dashboardHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("WRITERS APP")
                    .font(.system(size: 28, weight: .black, design: .default))
                    .tracking(4)
                    .foregroundColor(MetalTheme.chrome)

                Text("iPad Pro Dashboard")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MetalTheme.steel)
            }

            Spacer()

            // Current focus session badge
            if let session = viewModel.currentFocusSession, session.state == .active {
                activeFocusBadge(session: session)
            }
        }
    }

    private func activeFocusBadge(session: FocusSession) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(MetalTheme.crimson)
                .frame(width: 8, height: 8)

            Text(session.type.displayName.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(MetalTheme.ember)

            if session.targetDuration > 0 {
                Text(viewModel.formatTimeRemaining(session.timeRemaining))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(MetalTheme.chrome)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(MetalTheme.gunmetal)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(MetalTheme.crimson.opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Mantra Banner

    private var mantraBanner: some View {
        VStack(spacing: 10) {
            Text("\u{201C}\(viewModel.currentMantra.quote)\u{201D}")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(MetalTheme.chrome)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("- \(viewModel.currentMantra.attribution)")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(MetalTheme.bloodRed)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .background(MetalTheme.obsidian)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MetalTheme.bloodRed.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            viewModel.refreshMantra()
        }
    }

    // MARK: - Kill Count (Stats)

    private var killCountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MetalTheme.sectionTitle("Kill Count")

            HStack(spacing: 0) {
                killCountStat(
                    value: "\(viewModel.totalWords)",
                    label: "Total Words",
                    icon: "textformat.abc",
                    accentColor: MetalTheme.crimson
                )

                killCountDivider

                killCountStat(
                    value: "\(viewModel.totalDocuments)",
                    label: "Documents",
                    icon: "doc.text.fill",
                    accentColor: MetalTheme.ember
                )

                killCountDivider

                killCountStat(
                    value: streakDisplayValue,
                    label: "Day Streak",
                    icon: "flame.fill",
                    accentColor: viewModel.writingStreak.isStreakActive ? MetalTheme.toxicGreen : MetalTheme.steel
                )

                killCountDivider

                killCountStat(
                    value: viewModel.formatDuration(viewModel.focusStats.totalFocusTime),
                    label: "Focus Time",
                    icon: "timer",
                    accentColor: MetalTheme.gold
                )

                killCountDivider

                killCountStat(
                    value: "\(viewModel.focusStats.completedSessions)",
                    label: "Sessions",
                    icon: "checkmark.seal.fill",
                    accentColor: MetalTheme.chrome
                )
            }
            .metalCard()
        }
    }

    private var streakDisplayValue: String {
        let streak = viewModel.writingStreak
        return "\(streak.currentStreak)"
    }

    private func killCountStat(value: String, label: String, icon: String, accentColor: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(accentColor)

            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(MetalTheme.chrome)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1.5)
                .foregroundColor(MetalTheme.steel)
        }
        .frame(maxWidth: .infinity)
    }

    private var killCountDivider: some View {
        Rectangle()
            .fill(MetalTheme.chainLink)
            .frame(width: 1, height: 60)
    }

    // MARK: - The Armory (Focus Sessions)

    private var armorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MetalTheme.sectionTitle("The Armory")

            VStack(spacing: 10) {
                ForEach(FocusSessionType.allCases, id: \.self) { type in
                    focusSessionButton(type: type)
                }
            }
            .metalCard()

            // Today's session summary
            if viewModel.todayFocusStats.totalSessions > 0 {
                todayFocusSummary
            }
        }
    }

    private func focusSessionButton(type: FocusSessionType) -> some View {
        Button(action: { viewModel.startFocusSession(type: type) }) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.iconForFocusType(type))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(MetalTheme.ember)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(MetalTheme.chrome)

                    if type.defaultDuration > 0 {
                        Text(FocusSessionManager.formatDuration(type.defaultDuration))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(MetalTheme.steel)
                    } else {
                        Text("No time limit")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(MetalTheme.steel)
                    }
                }

                Spacer()

                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                    .foregroundColor(MetalTheme.crimson)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(MetalTheme.gunmetal)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var todayFocusSummary: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("\(viewModel.todayFocusStats.totalSessions)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(MetalTheme.chrome)
                Text("SESSIONS")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1)
                    .foregroundColor(MetalTheme.steel)
            }

            VStack(spacing: 2) {
                Text("\(viewModel.todayFocusStats.totalWordsWritten)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(MetalTheme.chrome)
                Text("WORDS")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1)
                    .foregroundColor(MetalTheme.steel)
            }

            VStack(spacing: 2) {
                Text(viewModel.formatDuration(viewModel.todayFocusStats.totalFocusTime))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(MetalTheme.chrome)
                Text("FOCUS")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1)
                    .foregroundColor(MetalTheme.steel)
            }

            Spacer()
        }
        .padding(12)
        .background(MetalTheme.obsidian)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(MetalTheme.chainLink, lineWidth: 0.5)
        )
    }

    // MARK: - War Room (Recent Documents)

    private var warRoomSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                MetalTheme.sectionTitle("War Room")
                Spacer()
                Text("\(viewModel.recentDocuments.count) recent")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(MetalTheme.steel)
            }

            VStack(spacing: 8) {
                if viewModel.recentDocuments.isEmpty {
                    emptyWarRoom
                } else {
                    ForEach(viewModel.recentDocuments) { doc in
                        documentRow(doc)
                    }
                }
            }
            .metalCard()
        }
    }

    private var emptyWarRoom: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(MetalTheme.chainLink)

            Text("No documents yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MetalTheme.steel)

            Text("Hit The Forge to start writing")
                .font(.system(size: 12))
                .foregroundColor(MetalTheme.chainLink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func documentRow(_ document: Document) -> some View {
        Button(action: { viewModel.selectDocument(document) }) {
            HStack(spacing: 12) {
                // Category icon
                Image(systemName: viewModel.iconForCategory(document.category))
                    .font(.system(size: 14))
                    .foregroundColor(MetalTheme.crimson)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(MetalTheme.chrome)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(document.category.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(MetalTheme.steel)

                        Text("\u{2022}")
                            .foregroundColor(MetalTheme.chainLink)

                        Text("\(document.wordCount) words")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(MetalTheme.steel)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(MetalTheme.chainLink)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(MetalTheme.gunmetal)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - The Gauntlet (Goals)

    private var gauntletSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                MetalTheme.sectionTitle("The Gauntlet")
                Spacer()

                if viewModel.goalsSummary.achievedGoals > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 10))
                            .foregroundColor(MetalTheme.gold)
                        Text("\(viewModel.goalsSummary.achievedGoals) conquered")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(MetalTheme.gold)
                    }
                }
            }

            VStack(spacing: 10) {
                if viewModel.activeGoals.isEmpty {
                    emptyGauntlet
                } else {
                    ForEach(viewModel.activeGoals) { goal in
                        goalRow(goal)
                    }
                }

                // Streak indicator
                streakIndicator
            }
            .metalCard()
        }
    }

    private var emptyGauntlet: some View {
        VStack(spacing: 10) {
            Image(systemName: "target")
                .font(.system(size: 28))
                .foregroundColor(MetalTheme.chainLink)

            Text("No active goals")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MetalTheme.steel)

            Text("Set a daily word count target to run the gauntlet")
                .font(.system(size: 12))
                .foregroundColor(MetalTheme.chainLink)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func goalRow(_ goal: WritingGoal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(MetalTheme.chrome)

                Spacer()

                Text("\(goal.progressPercentage)%")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(goal.isAchieved ? MetalTheme.gold : MetalTheme.ember)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MetalTheme.gunmetal)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(goal.isAchieved ? MetalTheme.conquestGradient : MetalTheme.forgeGradient)
                        .frame(width: geo.size.width * goal.progress, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(goal.current) / \(goal.target) \(goal.unit.displayName.lowercased())")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(MetalTheme.steel)

                Spacer()

                if let days = goal.daysRemaining, days > 0 {
                    Text("\(days)d remaining")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(MetalTheme.steel)
                }
            }
        }
        .padding(10)
        .background(MetalTheme.gunmetal.opacity(0.5))
        .cornerRadius(8)
    }

    private var streakIndicator: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16))
                .foregroundColor(
                    viewModel.writingStreak.isStreakActive ? MetalTheme.ember : MetalTheme.chainLink
                )

            VStack(alignment: .leading, spacing: 2) {
                if viewModel.writingStreak.currentStreak > 0 {
                    Text("\(viewModel.writingStreak.currentStreak)-day streak")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(MetalTheme.chrome)
                } else {
                    Text("No active streak")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(MetalTheme.steel)
                }

                if viewModel.writingStreak.longestStreak > 0 {
                    Text("Longest: \(viewModel.writingStreak.longestStreak) days \u{2022} Total: \(viewModel.writingStreak.totalDaysWritten) days")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(MetalTheme.steel)
                }
            }

            Spacer()

            if viewModel.writingStreak.wroteToday {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(MetalTheme.toxicGreen)
            }
        }
        .padding(10)
        .background(MetalTheme.gunmetal.opacity(0.5))
        .cornerRadius(8)
    }

    // MARK: - The Forge (Quick Actions)

    private var forgeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MetalTheme.sectionTitle("The Forge")

            VStack(spacing: 10) {
                // New blank document
                forgeActionButton(
                    title: "New Blank Document",
                    subtitle: "Start from nothing. Pure aggression.",
                    icon: "doc.badge.plus",
                    accentColor: MetalTheme.crimson,
                    action: { viewModel.showNewDocumentSheet = true }
                )

                // Browse templates
                forgeActionButton(
                    title: "Browse Templates",
                    subtitle: "\(viewModel.totalTemplates) templates ready to deploy",
                    icon: "rectangle.stack.fill",
                    accentColor: MetalTheme.ember,
                    action: { viewModel.showTemplateSheet = true }
                )

                // Set a goal
                forgeActionButton(
                    title: "Set a Writing Goal",
                    subtitle: "Run the gauntlet. Set your target.",
                    icon: "target",
                    accentColor: MetalTheme.gold,
                    action: { viewModel.showGoalSheet = true }
                )
            }
            .metalCard()

            // Category breakdown
            if !viewModel.documentsByCategory.isEmpty {
                categoryBreakdown
            }
        }
    }

    private func forgeActionButton(title: String, subtitle: String, icon: String, accentColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(MetalTheme.chrome)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(MetalTheme.steel)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(accentColor)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(MetalTheme.gunmetal)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            let sortedCategories = viewModel.documentsByCategory.sorted { $0.value > $1.value }

            ForEach(sortedCategories.prefix(5), id: \.key) { category, count in
                HStack(spacing: 10) {
                    Image(systemName: viewModel.iconForCategory(category))
                        .font(.system(size: 12))
                        .foregroundColor(MetalTheme.crimson)
                        .frame(width: 20)

                    Text(category.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MetalTheme.chrome)

                    Spacer()

                    Text("\(count)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(MetalTheme.steel)
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
}

// MARK: - Preview

@available(iOS 16.0, macOS 13.0, *)
struct MetalDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        MetalDashboardView()
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

#endif
