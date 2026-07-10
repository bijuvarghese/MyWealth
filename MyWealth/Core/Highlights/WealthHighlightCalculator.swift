import Foundation

struct WealthHighlightAllocation: Equatable {
    let name: String
    let fraction: Double
    let systemImage: String
}

struct WealthHighlightBaseline: Equatable {
    let recordedAt: Date
    let assetTotal: Double
    let liabilityTotal: Double

    var netWorth: Double {
        assetTotal - liabilityTotal
    }
}

struct WealthHighlightInsight: Identifiable, Equatable {
    enum Kind: Equatable {
        case progress
        case liability
        case debtRatio
        case allocation
        case context
    }

    enum Sentiment: Equatable {
        case positive
        case neutral
        case warning
    }

    let kind: Kind
    let systemImage: String
    let message: String
    let sentiment: Sentiment

    var id: String {
        "\(kind)-\(systemImage)-\(message)"
    }
}

struct WealthHighlightSummary {
    enum Availability: Equatable {
        case full
        case currentOnly
        case unavailable
        case empty
    }

    let period: WealthHighlightPeriod
    let currencyCode: String
    let currentAssetTotal: Double?
    let currentLiabilityTotal: Double?
    let currentNetWorth: Double?
    let baseline: WealthHighlightBaseline?
    let assetChange: Double?
    let liabilityChange: Double?
    let netWorthChange: Double?
    let netWorthChangeFraction: Double?
    let insights: [WealthHighlightInsight]
    let ratesAreStale: Bool
    let availability: Availability
}

@MainActor
struct WealthHighlightCalculator {
    func summary(
        period: WealthHighlightPeriod,
        currencyCode: String,
        currentAssetTotal: Double?,
        currentLiabilityTotal: Double?,
        snapshots: [PortfolioSnapshot],
        historyScopeStartedAt: Date,
        hasPortfolioData: Bool,
        ratesAreStale: Bool,
        allocations: [WealthHighlightAllocation] = []
    ) -> WealthHighlightSummary {
        guard hasPortfolioData else {
            return WealthHighlightSummary(
                period: period,
                currencyCode: currencyCode,
                currentAssetTotal: nil,
                currentLiabilityTotal: nil,
                currentNetWorth: nil,
                baseline: nil,
                assetChange: nil,
                liabilityChange: nil,
                netWorthChange: nil,
                netWorthChangeFraction: nil,
                insights: [],
                ratesAreStale: ratesAreStale,
                availability: .empty
            )
        }

        guard
            let assetTotal = finite(currentAssetTotal),
            let liabilityTotal = finite(currentLiabilityTotal)
        else {
            return WealthHighlightSummary(
                period: period,
                currencyCode: currencyCode,
                currentAssetTotal: nil,
                currentLiabilityTotal: nil,
                currentNetWorth: nil,
                baseline: nil,
                assetChange: nil,
                liabilityChange: nil,
                netWorthChange: nil,
                netWorthChangeFraction: nil,
                insights: [],
                ratesAreStale: ratesAreStale,
                availability: .unavailable
            )
        }

        let currentNetWorth = assetTotal - liabilityTotal
        let baseline = baseline(
            for: period,
            currencyCode: currencyCode,
            snapshots: snapshots,
            historyScopeStartedAt: historyScopeStartedAt
        )
        let assetChange = baseline.map { assetTotal - $0.assetTotal }
        let liabilityChange = baseline.map { liabilityTotal - $0.liabilityTotal }
        let netWorthChange = baseline.map { currentNetWorth - $0.netWorth }
        let netWorthChangeFraction: Double?
        if let netWorthChange, let baseline, baseline.netWorth != 0 {
            let fraction = netWorthChange / abs(baseline.netWorth)
            netWorthChangeFraction = fraction.isFinite ? fraction : nil
        } else {
            netWorthChangeFraction = nil
        }
        let insights = insights(
            period: period,
            currencyCode: currencyCode,
            currentAssetTotal: assetTotal,
            currentLiabilityTotal: liabilityTotal,
            netWorthChange: netWorthChange,
            liabilityChange: liabilityChange,
            allocations: allocations
        )

        return WealthHighlightSummary(
            period: period,
            currencyCode: currencyCode,
            currentAssetTotal: assetTotal,
            currentLiabilityTotal: liabilityTotal,
            currentNetWorth: currentNetWorth,
            baseline: baseline,
            assetChange: assetChange,
            liabilityChange: liabilityChange,
            netWorthChange: netWorthChange,
            netWorthChangeFraction: netWorthChangeFraction,
            insights: insights,
            ratesAreStale: ratesAreStale,
            availability: baseline == nil ? .currentOnly : .full
        )
    }

    private func baseline(
        for period: WealthHighlightPeriod,
        currencyCode: String,
        snapshots: [PortfolioSnapshot],
        historyScopeStartedAt: Date
    ) -> WealthHighlightBaseline? {
        let validRows = snapshots.compactMap { snapshot -> WealthHighlightBaseline? in
            guard
                snapshot.currencyCode == currencyCode,
                let recordedAt = snapshot.recordedAt,
                recordedAt >= historyScopeStartedAt,
                recordedAt <= period.referenceDate,
                let assetTotal = snapshot.assetTotal,
                assetTotal.isFinite,
                let liabilityTotal = snapshot.liabilityTotal,
                liabilityTotal.isFinite
            else {
                return nil
            }

            return WealthHighlightBaseline(
                recordedAt: recordedAt,
                assetTotal: assetTotal,
                liabilityTotal: liabilityTotal
            )
        }

        if let prior = validRows
            .filter({ $0.recordedAt <= period.interval.start })
            .max(by: { $0.recordedAt < $1.recordedAt }) {
            return prior
        }

        return validRows
            .filter {
                $0.recordedAt >= period.interval.start &&
                    $0.recordedAt < period.interval.end
            }
            .min(by: { $0.recordedAt < $1.recordedAt })
    }

    private func insights(
        period: WealthHighlightPeriod,
        currencyCode: String,
        currentAssetTotal: Double,
        currentLiabilityTotal: Double,
        netWorthChange: Double?,
        liabilityChange: Double?,
        allocations: [WealthHighlightAllocation]
    ) -> [WealthHighlightInsight] {
        var rows: [WealthHighlightInsight] = []
        let periodName = period.kind.localizedPeriodName

        if let netWorthChange {
            let formattedChange = abs(netWorthChange).formatted(
                .currency(code: currencyCode)
            )
            if netWorthChange > 0 {
                rows.append(
                    WealthHighlightInsight(
                        kind: .progress,
                        systemImage: "arrow.up.right.circle.fill",
                        message: AppLocalization.formatted(
                            "Net worth increased by %@ this %@.",
                            arguments: [formattedChange, periodName]
                        ),
                        sentiment: .positive
                    )
                )
            } else if netWorthChange < 0 {
                rows.append(
                    WealthHighlightInsight(
                        kind: .progress,
                        systemImage: "arrow.down.right.circle.fill",
                        message: AppLocalization.formatted(
                            "Net worth decreased by %@ this %@.",
                            arguments: [formattedChange, periodName]
                        ),
                        sentiment: .warning
                    )
                )
            } else {
                rows.append(
                    WealthHighlightInsight(
                        kind: .progress,
                        systemImage: "equal.circle.fill",
                        message: AppLocalization.formatted(
                            "Net worth held steady this %@.",
                            arguments: [periodName]
                        ),
                        sentiment: .neutral
                    )
                )
            }
        }

        if let liabilityChange, liabilityChange != 0 {
            let formattedChange = abs(liabilityChange).formatted(
                .currency(code: currencyCode)
            )
            rows.append(
                WealthHighlightInsight(
                    kind: .liability,
                    systemImage: liabilityChange < 0
                        ? "arrow.down.circle.fill"
                        : "arrow.up.circle.fill",
                    message: AppLocalization.formatted(
                        liabilityChange < 0
                            ? "Liabilities decreased by %@ this %@."
                            : "Liabilities increased by %@ this %@.",
                        arguments: [formattedChange, periodName]
                    ),
                    sentiment: liabilityChange < 0 ? .positive : .warning
                )
            )
        } else if currentAssetTotal > 0, currentLiabilityTotal > 0 {
            let ratio = currentLiabilityTotal / currentAssetTotal
            rows.append(
                WealthHighlightInsight(
                    kind: .debtRatio,
                    systemImage: ratio < 0.5
                        ? "checkmark.shield.fill"
                        : "exclamationmark.triangle.fill",
                    message: AppLocalization.formatted(
                        "Debt-to-asset ratio is %@.",
                        arguments: [AppLocalization.percent(ratio)]
                    ),
                    sentiment: ratio < 0.2 ? .positive : (ratio < 0.5 ? .neutral : .warning)
                )
            )
        }

        if let allocation = allocations
            .filter({ $0.fraction.isFinite && $0.fraction >= 0 })
            .max(by: { $0.fraction < $1.fraction }) {
            rows.append(
                WealthHighlightInsight(
                    kind: .allocation,
                    systemImage: allocation.systemImage,
                    message: AppLocalization.formatted(
                        "Your largest allocation is %@ at %@.",
                        arguments: [
                            allocation.name,
                            AppLocalization.percent(allocation.fraction)
                        ]
                    ),
                    sentiment: allocation.fraction > 0.6 ? .warning : .neutral
                )
            )
        }

        return Array(rows.prefix(4))
    }

    private func finite(_ value: Double?) -> Double? {
        guard let value, value.isFinite else {
            return nil
        }
        return value
    }
}
