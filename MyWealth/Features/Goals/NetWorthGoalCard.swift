import SwiftUI

struct NetWorthGoalCard: View {
    let goal: NetWorthGoal
    let progress: NetWorthGoalProgress
    let outlook: NetWorthGoalOutlook
    let useCompactFormatting: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: progress.isAchieved ? "trophy.fill" : "target")
                    .font(.title2)
                    .foregroundStyle(progress.isAchieved ? .green : .accent)
                    .frame(width: 38, height: 38)
                    .background(
                        (progress.isAchieved ? Color.green : Color.accentColor).opacity(0.12),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(progress.isAchieved ? "Goal achieved" : "Net Worth Goal")
                        .font(.headline)
                    Text("Target \(formatted(goal.displayTargetAmount)) by \(goal.displayTargetDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 7) {
                ProgressView(value: progress.visualFraction)
                    .tint(progress.isAchieved ? .green : .accentColor)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: progress.visualFraction)

                HStack(alignment: .firstTextBaseline) {
                    Text(progressLabel)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                    Spacer()
                    if let fraction = progress.rawFraction {
                        Text(fraction, format: .percent.precision(.fractionLength(0...1)))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                }
            }

            Label(outlookText, systemImage: outlookSymbol)
                .font(.caption)
                .foregroundStyle(outlookColor)
                .fixedSize(horizontal: false, vertical: true)
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
        case .achieved, .projected(_, .onTrack): .green
        case .projected(_, .behind), .conversionUnavailable: .orange
        case .needsHistory, .nonGrowing, .currentValueUnavailable: .secondary
        }
    }

    private var accessibilitySummary: String {
        let percent = progress.rawFraction?.formatted(.percent.precision(.fractionLength(0...1)))
            ?? "unavailable"
        return "Net Worth Goal. \(progressLabel). Progress \(percent). \(outlookText)"
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
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 42, height: 42)
                .background(Color.accentColor.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("Set a Net Worth Goal")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Track progress toward a target amount and date")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens goal setup")
    }
}
