import SwiftUI

struct NetWorthGoalCard: View {
    let goal: NetWorthGoal
    let progress: NetWorthGoalProgress
    let outlook: NetWorthGoalOutlook
    let achievementPlan: NetWorthGoalAchievementPlan
    let useCompactFormatting: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: progress.isAchieved ? "trophy.fill" : "target")
                    .font(WealthMapDesignTokens.Typography.title2)
                    .foregroundStyle(progress.isAchieved ? WealthMapDesignTokens.ColorToken.success : WealthMapDesignTokens.ColorToken.brandPrimary)
                    .frame(width: 38, height: 38)
                    .background(
                        (progress.isAchieved ? WealthMapDesignTokens.ColorToken.success : WealthMapDesignTokens.ColorToken.brandPrimary).opacity(0.12),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(progress.isAchieved ? "Goal achieved" : "Net Worth Goal")
                        .font(WealthMapDesignTokens.Typography.headline)
                    Text("Target \(formatted(goal.displayTargetAmount)) by \(goal.displayTargetDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(WealthMapDesignTokens.Typography.subheadline)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(WealthMapDesignTokens.Typography.footnote.weight(.semibold))
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textTertiary)
            }

            VStack(alignment: .leading, spacing: 7) {
                ProgressView(value: progress.visualFraction)
                    .tint(progress.isAchieved ? WealthMapDesignTokens.ColorToken.success : WealthMapDesignTokens.ColorToken.brandPrimary)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: progress.visualFraction)

                HStack(alignment: .firstTextBaseline) {
                    Text(progressLabel)
                        .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                        .monospacedDigit()
                    Spacer()
                    if let fraction = progress.rawFraction {
                        Text(fraction, format: .percent.precision(.fractionLength(0...1)))
                            .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                            .monospacedDigit()
                    }
                }
            }

            Label(outlookText, systemImage: outlookSymbol)
                .font(WealthMapDesignTokens.Typography.caption)
                .foregroundStyle(outlookColor)
                .fixedSize(horizontal: false, vertical: true)

            achievementInsights
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens goal settings")
    }

    private var progressLabel: String {
        guard let current = progress.currentAmount else { return "Current value unavailable" }
        return "\(formatted(current)) of \(formatted(goal.displayTargetAmount))"
    }

    private var outlookText: String {
        switch outlook {
        case .achieved:
            return "You have reached this goal."
        case .projected(let date, .onTrack):
            return "On track. Indicative date: \(date.formatted(date: .abbreviated, time: .omitted))."
        case .projected(let date, .behind):
            return "Behind pace. Indicative date: \(date.formatted(date: .abbreviated, time: .omitted))."
        case .needsHistory:
            return "More history is needed for a projection."
        case .nonGrowing:
            return "Current history does not support an achievement estimate."
        case .conversionUnavailable:
            return "Progress is unavailable until the required exchange rates are available."
        case .currentValueUnavailable:
            return "Add portfolio data to calculate progress."
        }
    }

    private var outlookSymbol: String {
        switch outlook {
        case .achieved: "checkmark.circle.fill"
        case .projected(_, .onTrack): "arrow.up.right.circle.fill"
        case .projected(_, .behind): "clock.badge.exclamationmark"
        case .needsHistory: "chart.line.uptrend.xyaxis"
        case .nonGrowing: "equal.circle"
        case .conversionUnavailable, .currentValueUnavailable: "exclamationmark.triangle"
        }
    }

    private var outlookColor: Color {
        switch outlook {
        case .achieved, .projected(_, .onTrack): WealthMapDesignTokens.ColorToken.success
        case .projected(_, .behind), .conversionUnavailable: WealthMapDesignTokens.ColorToken.warning
        case .needsHistory, .nonGrowing, .currentValueUnavailable: WealthMapDesignTokens.ColorToken.textSecondary
        }
    }

    private var accessibilitySummary: String {
        let percent = progress.rawFraction?.formatted(.percent.precision(.fractionLength(0...1)))
            ?? "unavailable"
        return "Net Worth Goal. \(progressLabel). Progress \(percent). \(outlookText) \(achievementAccessibilitySummary)"
    }

    @ViewBuilder
    private var achievementInsights: some View {
        switch achievementPlan.status {
        case .active:
            VStack(alignment: .leading, spacing: 9) {
                Text("Goal Insights")
                    .font(WealthMapDesignTokens.Typography.compactLabel)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    alignment: .leading,
                    spacing: 10
                ) {
                    insightMetric("Remaining", value: formatted(achievementPlan.remainingAmount ?? 0))
                    insightMetric("Time Left", value: monthsLabel)
                    insightMetric("Needed / Month", value: formatted(achievementPlan.requiredMonthlyIncrease ?? 0))
                    insightMetric("Needed / Year", value: formatted(achievementPlan.requiredYearlyIncrease ?? 0))
                }

                Text("Average net worth increase needed if progress is spread evenly to the target date.")
                    .font(WealthMapDesignTokens.Typography.caption2)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .dueToday:
            Label("The target is due today with \(formatted(achievementPlan.remainingAmount ?? 0)) remaining.", systemImage: "calendar.badge.exclamationmark")
                .font(WealthMapDesignTokens.Typography.caption)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.warning)
        case .overdue:
            Label("The target date has passed with \(formatted(achievementPlan.remainingAmount ?? 0)) remaining.", systemImage: "calendar.badge.exclamationmark")
                .font(WealthMapDesignTokens.Typography.caption)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.warning)
        case .unavailable, .achieved:
            EmptyView()
        }
    }

    private func insightMetric(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(WealthMapDesignTokens.Typography.caption2)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
            Text(value)
                .font(WealthMapDesignTokens.Typography.compactLabel)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }

    private var monthsLabel: String {
        guard let months = achievementPlan.monthsRemaining else { return "Unavailable" }
        return months == 1 ? "1 month" : "\(months) months"
    }

    private var achievementAccessibilitySummary: String {
        switch achievementPlan.status {
        case .active:
            return "\(monthsLabel) left. \(formatted(achievementPlan.remainingAmount ?? 0)) remaining. Average needed per month \(formatted(achievementPlan.requiredMonthlyIncrease ?? 0)); per year \(formatted(achievementPlan.requiredYearlyIncrease ?? 0))."
        case .dueToday:
            return "Target is due today."
        case .overdue:
            return "Target date has passed."
        case .unavailable, .achieved:
            return ""
        }
    }

    private func formatted(_ amount: Double) -> String {
        if useCompactFormatting {
            return amount.formatted(
                .currency(code: goal.displayCurrency.rawValue)
                    .notation(.compactName)
                    .precision(.fractionLength(0...1))
            )
        }
        return amount.formatted(
            .currency(code: goal.displayCurrency.rawValue)
                .precision(.fractionLength(0...2))
        )
    }
}

struct NetWorthGoalInvitationCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "target")
                .font(WealthMapDesignTokens.Typography.title2)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                .frame(width: 42, height: 42)
                .background(WealthMapDesignTokens.ColorToken.brandPrimary.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("Set a Net Worth Goal")
                    .font(WealthMapDesignTokens.Typography.headline)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                Text("Track progress toward a target amount and date")
                    .font(WealthMapDesignTokens.Typography.subheadline)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(WealthMapDesignTokens.Typography.footnote.weight(.semibold))
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textTertiary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens goal setup")
    }
}
