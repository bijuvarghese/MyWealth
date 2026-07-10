import SwiftData
import SwiftUI

struct WealthHighlightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var assets: [Asset]
    @Query private var liabilities: [Liability]
    @Query private var portfolioSnapshots: [PortfolioSnapshot]

    let period: WealthHighlightPeriod
    @Bindable var settings: AppSettings

    @State private var viewModel = DashboardViewModel()

    private var portfolioAssets: [Asset] {
        settings.portfolioCalculationAssets(from: assets)
    }

    private var currentAssetTotal: Double? {
        viewModel.convertedTotal(
            portfolioAssets,
            to: settings.baseCurrency,
            exchangeRates: viewModel.exchangeRates
        )
    }

    private var currentLiabilityTotal: Double? {
        viewModel.convertedLiabilityTotal(
            liabilities,
            to: settings.baseCurrency,
            exchangeRates: viewModel.exchangeRates
        )
    }

    private var summary: WealthHighlightSummary {
        let allocations = viewModel.categoryAllocationRows(
            portfolioAssets,
            targetCurrency: settings.baseCurrency
        )
        .map {
            WealthHighlightAllocation(
                name: $0.category.localizedName,
                fraction: $0.percentage,
                systemImage: $0.category.icon
            )
        }

        return WealthHighlightCalculator().summary(
            period: period,
            currencyCode: settings.baseCurrency.rawValue,
            currentAssetTotal: currentAssetTotal,
            currentLiabilityTotal: currentLiabilityTotal,
            snapshots: portfolioSnapshots,
            historyScopeStartedAt: settings.portfolioHistoryScopeStartedAt,
            hasPortfolioData: !portfolioAssets.isEmpty || !liabilities.isEmpty,
            ratesAreStale: viewModel.ratesAreStale,
            allocations: allocations
        )
    }

    private var requiredCurrencies: [Asset.CurrencyType] {
        [settings.baseCurrency]
            + portfolioAssets.compactMap(\.currency)
            + liabilities.compactMap(\.currency)
    }

    private var rateRefreshSignature: String {
        requiredCurrencies.map(\.rawValue).sorted().joined(separator: ":")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RadialDotBackground(dotRadius: 1, spacing: 20)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: WealthMapDesignTokens.Spacing.section) {
                        header

                        switch summary.availability {
                        case .empty:
                            emptyState
                        case .unavailable:
                            unavailableState
                        case .currentOnly, .full:
                            currentPortfolioCard
                            progressCard
                            insightsCard
                            contextCards
                        }
                    }
                    .frame(maxWidth: 720)
                    .padding(.horizontal, WealthMapDesignTokens.Spacing.standard)
                    .padding(.vertical, WealthMapDesignTokens.Spacing.section)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(period.kind.localizedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task(id: rateRefreshSignature) {
            await viewModel.refreshExchangeRateIfNeeded(
                requiredCurrencies: requiredCurrencies
            )
        }
    }

    private var header: some View {
        AppListCard {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: period.kind == .monthly
                    ? "calendar.badge.checkmark"
                    : "calendar.badge.clock")
                    .font(WealthMapDesignTokens.Typography.title)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                    .frame(width: 52, height: 52)
                    .background(
                        WealthMapDesignTokens.ColorToken.brandPrimary.opacity(0.12),
                        in: Circle()
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(period.kind.localizedTitle)
                        .font(WealthMapDesignTokens.Typography.title2)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)

                    Text(periodDateRange)
                        .font(WealthMapDesignTokens.Typography.subheadline)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)

                    Text("Based on your recorded Wealth Map data.")
                        .font(WealthMapDesignTokens.Typography.caption)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textTertiary)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var currentPortfolioCard: some View {
        VStack(alignment: .leading, spacing: WealthMapDesignTokens.Spacing.compact) {
            PillLabel(AppLocalization.string("Current Portfolio"))
            AppListCard(
                contentPadding: EdgeInsets(top: 12, leading: 0, bottom: 0, trailing: 0)
            ) {
                AssetLiabilitySummaryView(
                    assetTotal: summary.currentAssetTotal,
                    liabilityTotal: summary.currentLiabilityTotal,
                    netWorthTotal: summary.currentNetWorth,
                    currencyCode: summary.currencyCode
                )
            }
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: WealthMapDesignTokens.Spacing.compact) {
            PillLabel(AppLocalization.string("Period Progress"))
            AppListCard {
                if summary.availability == .full {
                    VStack(spacing: 0) {
                        HighlightChangeRow(
                            title: AppLocalization.string("Net Worth Change"),
                            systemImage: "chart.line.uptrend.xyaxis",
                            value: summary.netWorthChange,
                            fraction: summary.netWorthChangeFraction,
                            currencyCode: summary.currencyCode
                        )

                        Divider().padding(.leading, 38)

                        HighlightChangeRow(
                            title: AppLocalization.string("Asset Change"),
                            systemImage: "plus.circle.fill",
                            value: summary.assetChange,
                            currencyCode: summary.currencyCode
                        )

                        Divider().padding(.leading, 38)

                        HighlightChangeRow(
                            title: AppLocalization.string("Liability Change"),
                            systemImage: "minus.circle.fill",
                            value: summary.liabilityChange,
                            currencyCode: summary.currencyCode,
                            lowerIsPositive: true
                        )

                        if let baseline = summary.baseline {
                            Divider().padding(.leading, 38)
                            Label {
                                Text(
                                    AppLocalization.formatted(
                                        "Compared with %@",
                                        arguments: [
                                            baseline.recordedAt.formatted(
                                                date: .abbreviated,
                                                time: .omitted
                                            )
                                        ]
                                    )
                                )
                            } icon: {
                                Image(systemName: "clock.arrow.circlepath")
                            }
                            .font(WealthMapDesignTokens.Typography.caption)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                        }
                    }
                } else {
                    HighlightContextRow(
                        systemImage: "clock.badge.checkmark",
                        title: AppLocalization.string("More history needed"),
                        message: AppLocalization.formatted(
                            "Keep updating your portfolio to unlock %@ comparisons.",
                            arguments: [period.kind.localizedPeriodName]
                        )
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var insightsCard: some View {
        if !summary.insights.isEmpty {
            VStack(alignment: .leading, spacing: WealthMapDesignTokens.Spacing.compact) {
                PillLabel(AppLocalization.string("Insights"))
                AppListCard {
                    PortfolioInsightsView(
                        rows: summary.insights.map { insight in
                            PortfolioInsightRow(
                                systemImage: insight.systemImage,
                                message: insight.message,
                                sentiment: portfolioSentiment(insight.sentiment)
                            )
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var contextCards: some View {
        if summary.ratesAreStale {
            AppListCard {
                HighlightContextRow(
                    systemImage: "clock.badge.exclamationmark",
                    title: AppLocalization.string("Saved Rates"),
                    message: AppLocalization.string(
                        "Using saved exchange rates that may be stale."
                    )
                )
            }
        }
    }

    private var emptyState: some View {
        AppListCard {
            ContentUnavailableView(
                "No Portfolio Yet",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text(
                    "Add assets or liabilities to start seeing weekly and monthly progress."
                )
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, WealthMapDesignTokens.Spacing.spacious)
        }
    }

    private var unavailableState: some View {
        AppListCard {
            ContentUnavailableView(
                "Highlights Unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(
                    "Complete exchange rates are needed to calculate this highlight."
                )
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, WealthMapDesignTokens.Spacing.spacious)
        }
    }

    private var periodDateRange: String {
        let calendar = Calendar.current
        let displayedEnd = calendar.date(
            byAdding: .day,
            value: -1,
            to: period.interval.end
        ) ?? period.interval.end
        let start = period.interval.start.formatted(date: .abbreviated, time: .omitted)
        let end = displayedEnd.formatted(date: .abbreviated, time: .omitted)
        return "\(start) – \(end)"
    }

    private func portfolioSentiment(
        _ sentiment: WealthHighlightInsight.Sentiment
    ) -> PortfolioInsightRow.Sentiment {
        switch sentiment {
        case .positive:
            .positive
        case .neutral:
            .neutral
        case .warning:
            .warning
        }
    }
}

private struct HighlightChangeRow: View {
    let title: String
    let systemImage: String
    let value: Double?
    var fraction: Double? = nil
    let currencyCode: String
    var lowerIsPositive = false

    private var isPositive: Bool {
        guard let value else {
            return false
        }
        return lowerIsPositive ? value < 0 : value > 0
    }

    private var tint: Color {
        guard let value, value != 0 else {
            return WealthMapDesignTokens.ColorToken.neutral
        }
        return isPositive
            ? WealthMapDesignTokens.ColorToken.success
            : WealthMapDesignTokens.ColorToken.warning
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 26)
                .accessibilityHidden(true)

            Text(title)
                .font(WealthMapDesignTokens.Typography.subheadline)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text(signedCurrency)
                    .font(WealthMapDesignTokens.Typography.headlineMonospacedDigit)
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let fraction {
                    Text(fraction, format: .percent.precision(.fractionLength(1)))
                        .font(WealthMapDesignTokens.Typography.captionMonospacedDigit)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                }
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private var signedCurrency: String {
        guard let value, value.isFinite else {
            return AppLocalization.string("Unavailable")
        }
        let amount = abs(value).formatted(.currency(code: currencyCode))
        if value > 0 {
            return "+\(amount)"
        }
        if value < 0 {
            return "−\(amount)"
        }
        return amount
    }
}

private struct HighlightContextRow: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                .frame(width: 26)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(WealthMapDesignTokens.Typography.headline)
                Text(message)
                    .font(WealthMapDesignTokens.Typography.subheadline)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
