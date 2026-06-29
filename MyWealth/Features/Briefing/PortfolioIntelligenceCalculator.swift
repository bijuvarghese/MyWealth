import Foundation

struct PortfolioHealthMetric: Identifiable, Equatable {
    let id: String
    let title: String
    let score: Int
    let maxScore: Int
    let detail: String

    var ratio: Double {
        guard maxScore > 0 else { return 0 }
        return min(max(Double(score) / Double(maxScore), 0), 1)
    }
}

enum PortfolioHealthGrade: String, Equatable {
    case strong = "Strong"
    case solid = "Solid"
    case watch = "Watch"
    case risk = "Risk"

    init(score: Int) {
        switch score {
        case 80...100: self = .strong
        case 55..<80: self = .solid
        case 35..<55: self = .watch
        default: self = .risk
        }
    }

    var localizedName: String {
        AppLocalization.string(rawValue, fallback: rawValue)
    }
}

struct PortfolioObservation: Identifiable, Equatable {
    enum Severity: Equatable {
        case positive
        case neutral
        case warning
    }

    let id: String
    let title: String
    let message: String
    let severity: Severity
    let systemImage: String
}

struct PortfolioIntelligenceReport {
    let generatedAt: Date
    let score: Int
    let grade: PortfolioHealthGrade
    let previousGrade: PortfolioHealthGrade?
    let metrics: [PortfolioHealthMetric]
    let focusArea: String
    let focusDetail: String
    let summary: String
    let observations: [PortfolioObservation]
    let allocation: [CategoryAllocationRow]
    let assetTotal: Double
    let liabilityTotal: Double
    let netWorth: Double
    let isConversionComplete: Bool

    var gradeMovementLabel: String? {
        guard let previousGrade, previousGrade != grade else { return nil }
        return AppLocalization.formatted(
            "%@ to %@",
            arguments: [previousGrade.localizedName, grade.localizedName],
            fallback: "\(previousGrade.localizedName) to \(grade.localizedName)"
        )
    }
}

struct PortfolioIntelligenceCalculator: AssetOperations {
    func makeReport(
        assets: [Asset],
        liabilities: [Liability],
        netWorthSnapshots: [NetWorthSnapshot],
        exchangeRates: [String: Double],
        baseCurrency: Asset.CurrencyType,
        previousGrade: PortfolioHealthGrade? = nil,
        generatedAt: Date = Date()
    ) -> PortfolioIntelligenceReport {
        guard
            let assetTotal = convertedTotal(assets, to: baseCurrency, exchangeRates: exchangeRates),
            let liabilityTotal = convertedLiabilityTotal(
                liabilities,
                to: baseCurrency,
                exchangeRates: exchangeRates
            )
        else {
            return PortfolioIntelligenceReport(
                generatedAt: generatedAt,
                score: 0,
                grade: .risk,
                previousGrade: previousGrade,
                metrics: [],
                focusArea: AppLocalization.string("Portfolio"),
                focusDetail: AppLocalization.string(
                    "Progress is unavailable until the required exchange rates are available."
                ),
                summary: AppLocalization.string(
                    "Progress is unavailable until the required exchange rates are available."
                ),
                observations: [
                    PortfolioObservation(
                        id: "conversion-unavailable",
                        title: AppLocalization.string("Unavailable"),
                        message: AppLocalization.string(
                            "Progress is unavailable until the required exchange rates are available."
                        ),
                        severity: .warning,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                ],
                allocation: [],
                assetTotal: 0,
                liabilityTotal: 0,
                netWorth: 0,
                isConversionComplete: false
            )
        }
        let allocation = categoryAllocationRows(
            assets: assets,
            baseCurrency: baseCurrency,
            exchangeRates: exchangeRates
        )

        let metrics = [
            diversificationMetric(allocation: allocation),
            liquidityMetric(allocation: allocation, liabilities: liabilities),
            debtRatioMetric(assetTotal: assetTotal, liabilityTotal: liabilityTotal),
            growthMetric(netWorthSnapshots: netWorthSnapshots, baseCurrency: baseCurrency),
            freshnessMetric(assets: assets)
        ]

        let score = metrics.reduce(0) { $0 + $1.score }
        let grade = PortfolioHealthGrade(score: score)
        let focus = metrics.min {
            if $0.ratio == $1.ratio { return $0.maxScore > $1.maxScore }
            return $0.ratio < $1.ratio
        }

        let observations = makeObservations(
            assets: assets,
            liabilities: liabilities,
            allocation: allocation,
            assetTotal: assetTotal,
            liabilityTotal: liabilityTotal,
            netWorthSnapshots: netWorthSnapshots,
            baseCurrency: baseCurrency
        )

        return PortfolioIntelligenceReport(
            generatedAt: generatedAt,
            score: score,
            grade: grade,
            previousGrade: previousGrade,
            metrics: metrics,
            focusArea: focus?.title ?? AppLocalization.string("Portfolio"),
            focusDetail: focus?.detail ?? AppLocalization.string("Add assets to unlock a stronger read."),
            summary: makeSummary(
                score: score,
                grade: grade,
                focus: focus,
                assetTotal: assetTotal,
                liabilityTotal: liabilityTotal,
                allocation: allocation,
                baseCurrency: baseCurrency
            ),
            observations: observations,
            allocation: allocation,
            assetTotal: assetTotal,
            liabilityTotal: liabilityTotal,
            netWorth: assetTotal - liabilityTotal,
            isConversionComplete: true
        )
    }

    private func categoryAllocationRows(
        assets: [Asset],
        baseCurrency: Asset.CurrencyType,
        exchangeRates: [String: Double]
    ) -> [CategoryAllocationRow] {
        let grouped = Dictionary(grouping: assets) { $0.displayCategory }
        let totals = grouped.compactMap { category, categoryAssets -> (Asset.CategoryType, Double)? in
            guard let total = convertedTotal(
                categoryAssets,
                to: baseCurrency,
                exchangeRates: exchangeRates
            ) else {
                return nil
            }
            return (category, total)
        }
        .filter { $0.1 > 0 }
        .sorted { $0.1 > $1.1 }

        let total = totals.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return [] }

        return totals.map { category, amount in
            CategoryAllocationRow(category: category, amount: amount, percentage: amount / total)
        }
    }

    private func diversificationMetric(allocation: [CategoryAllocationRow]) -> PortfolioHealthMetric {
        guard !allocation.isEmpty else {
            return PortfolioHealthMetric(
                id: "diversification",
                title: AppLocalization.string("Diversification"),
                score: 0,
                maxScore: 25,
                detail: AppLocalization.string("No asset categories yet")
            )
        }

        let categoryScore: Int
        switch allocation.count {
        case 1: categoryScore = 0
        case 2: categoryScore = 10
        case 3: categoryScore = 17
        default: categoryScore = 25
        }

        let dominant = allocation.first?.percentage ?? 0
        let concentrationCap: Int
        switch dominant {
        case 0.85...: concentrationCap = 5
        case 0.70..<0.85: concentrationCap = 10
        case 0.55..<0.70: concentrationCap = 18
        default: concentrationCap = 25
        }

        let score = min(categoryScore, concentrationCap)
        let detail = allocation.count == 1
            ? AppLocalization.string("All assets in one category")
            : AppLocalization.formatted(
                "%lld asset categories tracked",
                arguments: [allocation.count]
            )

        return PortfolioHealthMetric(
            id: "diversification",
            title: AppLocalization.string("Diversification"),
            score: score,
            maxScore: 25,
            detail: detail
        )
    }

    private func liquidityMetric(
        allocation: [CategoryAllocationRow],
        liabilities: [Liability]
    ) -> PortfolioHealthMetric {
        let cashShare = allocation.first(where: { $0.category == .bank })?.percentage ?? 0
        let score: Int
        let detail: String

        switch cashShare {
        case 0.10...0.35:
            score = 20
            detail = AppLocalization.string("Cash buffer is balanced")
        case 0.35..<0.80:
            score = 16
            detail = AppLocalization.string("High liquidity")
        case 0.80...:
            score = 14
            detail = AppLocalization.string("Very liquid, but may limit growth")
        case 0.05..<0.10:
            score = liabilities.isEmpty ? 14 : 10
            detail = AppLocalization.string("Thin cash buffer")
        default:
            score = liabilities.isEmpty ? 10 : 6
            detail = AppLocalization.string("Low liquid reserve")
        }

        return PortfolioHealthMetric(
            id: "liquidity",
            title: AppLocalization.string("Liquidity"),
            score: score,
            maxScore: 20,
            detail: detail
        )
    }

    private func debtRatioMetric(assetTotal: Double, liabilityTotal: Double) -> PortfolioHealthMetric {
        guard assetTotal > 0 else {
            return PortfolioHealthMetric(
                id: "debtRatio",
                title: AppLocalization.string("Debt Ratio"),
                score: liabilityTotal > 0 ? 0 : 20,
                maxScore: 20,
                detail: liabilityTotal > 0
                    ? AppLocalization.string("Debt with no assets recorded")
                    : AppLocalization.string("No debt recorded")
            )
        }

        let ratio = liabilityTotal / assetTotal
        let score: Int
        let detail: String
        switch ratio {
        case ..<0.01:
            score = 20
            detail = AppLocalization.string("No meaningful debt")
        case ..<0.20:
            score = 18
            detail = AppLocalization.string("Low debt load")
        case ..<0.40:
            score = 12
            detail = AppLocalization.string("Manageable debt load")
        case ..<0.65:
            score = 7
            detail = AppLocalization.string("Elevated debt load")
        default:
            score = 3
            detail = AppLocalization.string("High debt load")
        }

        return PortfolioHealthMetric(
            id: "debtRatio",
            title: AppLocalization.string("Debt Ratio"),
            score: score,
            maxScore: 20,
            detail: detail
        )
    }

    private func growthMetric(
        netWorthSnapshots: [NetWorthSnapshot],
        baseCurrency: Asset.CurrencyType
    ) -> PortfolioHealthMetric {
        let snapshots = netWorthSnapshots
            .filter { $0.displayCurrencyCode == baseCurrency.rawValue }
            .sorted { $0.displayRecordedAt < $1.displayRecordedAt }

        guard let first = snapshots.first, let last = snapshots.last, first.displayRecordedAt < last.displayRecordedAt else {
            return PortfolioHealthMetric(
                id: "growth",
                title: AppLocalization.string("Growth"),
                score: 10,
                maxScore: 20,
                detail: AppLocalization.string("More history needed")
            )
        }

        guard abs(first.displayAmount) > 0.01 else {
            return PortfolioHealthMetric(
                id: "growth",
                title: AppLocalization.string("Growth"),
                score: 10,
                maxScore: 20,
                detail: AppLocalization.string("Baseline history started")
            )
        }

        let change = (last.displayAmount - first.displayAmount) / abs(first.displayAmount)
        let score: Int
        let detail: String
        switch change {
        case 0.15...:
            score = 20
            detail = AppLocalization.string("Strong positive trend")
        case 0.03..<0.15:
            score = 16
            detail = AppLocalization.string("Positive trend")
        case -0.03..<0.03:
            score = 10
            detail = AppLocalization.string("Flat trend")
        case -0.10..<(-0.03):
            score = 6
            detail = AppLocalization.string("Slight decline")
        default:
            score = 2
            detail = AppLocalization.string("Declining trend")
        }

        return PortfolioHealthMetric(
            id: "growth",
            title: AppLocalization.string("Growth"),
            score: score,
            maxScore: 20,
            detail: detail
        )
    }

    private func freshnessMetric(assets: [Asset]) -> PortfolioHealthMetric {
        guard !assets.isEmpty else {
            return PortfolioHealthMetric(
                id: "freshness",
                title: AppLocalization.string("Freshness"),
                score: 0,
                maxScore: 15,
                detail: AppLocalization.string("No asset updates yet")
            )
        }

        let now = Date()
        let freshCount = assets.filter { asset in
            guard let lastUpdated = asset.lastUpdated else { return false }
            return now.timeIntervalSince(lastUpdated) <= 60 * 86400
        }.count
        let ratio = Double(freshCount) / Double(assets.count)
        let score = Int((ratio * 15).rounded())
        let detail = freshCount == assets.count
            ? AppLocalization.string("All assets updated recently")
            : AppLocalization.formatted(
                "%lld asset updates are stale",
                arguments: [assets.count - freshCount]
            )

        return PortfolioHealthMetric(
            id: "freshness",
            title: AppLocalization.string("Freshness"),
            score: score,
            maxScore: 15,
            detail: detail
        )
    }

    private func makeSummary(
        score: Int,
        grade: PortfolioHealthGrade,
        focus: PortfolioHealthMetric?,
        assetTotal: Double,
        liabilityTotal: Double,
        allocation: [CategoryAllocationRow],
        baseCurrency: Asset.CurrencyType
    ) -> String {
        let total = assetTotal.formatted(.currency(code: baseCurrency.rawValue).precision(.fractionLength(0)))
        let debtPhrase = liabilityTotal <= 0
            ? AppLocalization.string("zero debt")
            : AppLocalization.string("recorded debt")
        let dominant = allocation.first
        let concentration = dominant.map {
            AppLocalization.formatted(
                "%@ in %@",
                arguments: [
                    $0.percentage.formatted(.percent.precision(.fractionLength(0))),
                    $0.category.localizedName
                ]
            )
        } ?? AppLocalization.string("no allocation history")
        let focusPhrase = focus.map {
            AppLocalization.formatted(
                "The main focus area is %@: %@.",
                arguments: [$0.title.lowercased(), $0.detail.lowercased()]
            )
        } ?? ""

        return AppLocalization.formatted(
            "Portfolio health is %@ at %lld/100, with %@ in tracked assets and %@. Allocation is currently led by %@. %@",
            arguments: [
                grade.localizedName.lowercased(),
                score,
                total,
                debtPhrase,
                concentration,
                focusPhrase
            ]
        )
    }

    private func makeObservations(
        assets: [Asset],
        liabilities: [Liability],
        allocation: [CategoryAllocationRow],
        assetTotal: Double,
        liabilityTotal: Double,
        netWorthSnapshots: [NetWorthSnapshot],
        baseCurrency: Asset.CurrencyType
    ) -> [PortfolioObservation] {
        var observations: [PortfolioObservation] = []

        if let dominant = allocation.first, dominant.percentage >= 0.60 {
            let amount = dominant.amount.formatted(.currency(code: baseCurrency.rawValue).precision(.fractionLength(0)))
            observations.append(PortfolioObservation(
                id: "asset-concentration",
                title: AppLocalization.string("Asset Concentration"),
                message: AppLocalization.formatted(
                    "%@ makes up %@ of your portfolio (%@).",
                    arguments: [
                        dominant.category.localizedName,
                        dominant.percentage.formatted(.percent.precision(.fractionLength(0))),
                        amount
                    ]
                ),
                severity: .warning,
                systemImage: "exclamationmark.circle.fill"
            ))
        }

        let cashShare = allocation.first(where: { $0.category == .bank })?.percentage ?? 0
        observations.append(PortfolioObservation(
            id: "liquidity",
            title: AppLocalization.string("Liquidity"),
            message: cashShare >= 0.80
                ? AppLocalization.string("The portfolio is highly liquid, with most assets available as cash or deposits.")
                : AppLocalization.formatted(
                    "Cash and deposits represent %@ of assets.",
                    arguments: [cashShare.formatted(.percent.precision(.fractionLength(0)))]
                ),
            severity: cashShare >= 0.05 ? .neutral : .warning,
            systemImage: cashShare >= 0.05 ? "minus.circle.fill" : "drop.triangle.fill"
        ))

        if assetTotal > 0 {
            let ratio = liabilityTotal / assetTotal
            observations.append(PortfolioObservation(
                id: "debt-ratio",
                title: ratio <= 0
                    ? AppLocalization.string("Debt Free")
                    : AppLocalization.string("Debt Ratio"),
                message: ratio <= 0
                    ? AppLocalization.string("No liabilities are currently reducing net worth.")
                    : AppLocalization.formatted(
                        "Liabilities equal %@ of tracked assets.",
                        arguments: [ratio.formatted(.percent.precision(.fractionLength(0)))]
                    ),
                severity: ratio < 0.25 ? .positive : .warning,
                systemImage: ratio <= 0 ? "checkmark.shield.fill" : "exclamationmark.triangle.fill"
            ))
        }

        let staleAssets = assets.filter { asset in
            guard let lastUpdated = asset.lastUpdated else { return true }
            return Date().timeIntervalSince(lastUpdated) > 60 * 86400
        }
        if !staleAssets.isEmpty {
            observations.append(PortfolioObservation(
                id: "freshness",
                title: AppLocalization.string("Stale Values"),
                message: AppLocalization.formatted(
                    staleAssets.count == 1
                        ? "%lld asset value needs a refresh."
                        : "%lld asset values need a refresh.",
                    arguments: [staleAssets.count]
                ),
                severity: .warning,
                systemImage: "clock.badge.exclamationmark.fill"
            ))
        }

        let snapshots = netWorthSnapshots
            .filter { $0.displayCurrencyCode == baseCurrency.rawValue }
            .sorted { $0.displayRecordedAt < $1.displayRecordedAt }
        if let first = snapshots.first, let last = snapshots.last, first.displayRecordedAt < last.displayRecordedAt {
            let change = last.displayAmount - first.displayAmount
            observations.append(PortfolioObservation(
                id: "net-worth-trend",
                title: AppLocalization.string("Net Worth Trend"),
                message: AppLocalization.formatted(
                    change >= 0
                        ? "Net worth increased by %@ over recorded history."
                        : "Net worth decreased by %@ over recorded history.",
                    arguments: [
                        abs(change).formatted(
                            .currency(code: baseCurrency.rawValue)
                                .precision(.fractionLength(0))
                        )
                    ]
                ),
                severity: change >= 0 ? .positive : .warning,
                systemImage: change >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill"
            ))
        }

        if observations.isEmpty {
            observations.append(PortfolioObservation(
                id: "empty",
                title: AppLocalization.string("Add Portfolio Data"),
                message: AppLocalization.string("Add assets and liabilities to unlock portfolio intelligence."),
                severity: .neutral,
                systemImage: "sparkles"
            ))
        }

        return observations
    }
}
