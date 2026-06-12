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

    var gradeMovementLabel: String? {
        guard let previousGrade, previousGrade != grade else { return nil }
        return "\(previousGrade.rawValue) to \(grade.rawValue)"
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
        let assetTotal = convertedTotal(assets, to: baseCurrency, exchangeRates: exchangeRates) ?? 0
        let liabilityTotal = convertedLiabilityTotal(liabilities, to: baseCurrency, exchangeRates: exchangeRates) ?? 0
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
            focusArea: focus?.title ?? "Portfolio",
            focusDetail: focus?.detail ?? "Add assets to unlock a stronger read.",
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
            netWorth: assetTotal - liabilityTotal
        )
    }

    private func categoryAllocationRows(
        assets: [Asset],
        baseCurrency: Asset.CurrencyType,
        exchangeRates: [String: Double]
    ) -> [CategoryAllocationRow] {
        let grouped = Dictionary(grouping: assets) { $0.displayCategory }
        let totals = grouped.map { category, categoryAssets in
            (category, convertedTotal(categoryAssets, to: baseCurrency, exchangeRates: exchangeRates) ?? 0)
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
                title: "Diversification",
                score: 0,
                maxScore: 25,
                detail: "No asset categories yet"
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
            ? "All assets in one category"
            : "\(allocation.count) asset categories tracked"

        return PortfolioHealthMetric(
            id: "diversification",
            title: "Diversification",
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
            detail = "Cash buffer is balanced"
        case 0.35..<0.80:
            score = 16
            detail = "High liquidity"
        case 0.80...:
            score = 14
            detail = "Very liquid, but may limit growth"
        case 0.05..<0.10:
            score = liabilities.isEmpty ? 14 : 10
            detail = "Thin cash buffer"
        default:
            score = liabilities.isEmpty ? 10 : 6
            detail = "Low liquid reserve"
        }

        return PortfolioHealthMetric(
            id: "liquidity",
            title: "Liquidity",
            score: score,
            maxScore: 20,
            detail: detail
        )
    }

    private func debtRatioMetric(assetTotal: Double, liabilityTotal: Double) -> PortfolioHealthMetric {
        guard assetTotal > 0 else {
            return PortfolioHealthMetric(
                id: "debtRatio",
                title: "Debt Ratio",
                score: liabilityTotal > 0 ? 0 : 20,
                maxScore: 20,
                detail: liabilityTotal > 0 ? "Debt with no assets recorded" : "No debt recorded"
            )
        }

        let ratio = liabilityTotal / assetTotal
        let score: Int
        let detail: String
        switch ratio {
        case ..<0.01:
            score = 20
            detail = "No meaningful debt"
        case ..<0.20:
            score = 18
            detail = "Low debt load"
        case ..<0.40:
            score = 12
            detail = "Manageable debt load"
        case ..<0.65:
            score = 7
            detail = "Elevated debt load"
        default:
            score = 3
            detail = "High debt load"
        }

        return PortfolioHealthMetric(
            id: "debtRatio",
            title: "Debt Ratio",
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
                title: "Growth",
                score: 10,
                maxScore: 20,
                detail: "More history needed"
            )
        }

        guard abs(first.displayAmount) > 0.01 else {
            return PortfolioHealthMetric(
                id: "growth",
                title: "Growth",
                score: 10,
                maxScore: 20,
                detail: "Baseline history started"
            )
        }

        let change = (last.displayAmount - first.displayAmount) / abs(first.displayAmount)
        let score: Int
        let detail: String
        switch change {
        case 0.15...:
            score = 20
            detail = "Strong positive trend"
        case 0.03..<0.15:
            score = 16
            detail = "Positive trend"
        case -0.03..<0.03:
            score = 10
            detail = "Flat trend"
        case -0.10..<(-0.03):
            score = 6
            detail = "Slight decline"
        default:
            score = 2
            detail = "Declining trend"
        }

        return PortfolioHealthMetric(
            id: "growth",
            title: "Growth",
            score: score,
            maxScore: 20,
            detail: detail
        )
    }

    private func freshnessMetric(assets: [Asset]) -> PortfolioHealthMetric {
        guard !assets.isEmpty else {
            return PortfolioHealthMetric(
                id: "freshness",
                title: "Freshness",
                score: 0,
                maxScore: 15,
                detail: "No asset updates yet"
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
            ? "All assets updated recently"
            : "\(assets.count - freshCount) asset updates are stale"

        return PortfolioHealthMetric(
            id: "freshness",
            title: "Freshness",
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
        let debtPhrase = liabilityTotal <= 0 ? "zero debt" : "recorded debt"
        let dominant = allocation.first
        let concentration = dominant.map {
            "\(($0.percentage).formatted(.percent.precision(.fractionLength(0)))) in \($0.category.rawValue)"
        } ?? "no allocation history"
        let focusPhrase = focus.map { "The main focus area is \($0.title.lowercased()): \($0.detail.lowercased())." } ?? ""

        return "Portfolio health is \(grade.rawValue.lowercased()) at \(score)/100, with \(total) in tracked assets and \(debtPhrase). Allocation is currently led by \(concentration). \(focusPhrase)"
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
                title: "Asset Concentration",
                message: "\(dominant.category.rawValue) makes up \(dominant.percentage.formatted(.percent.precision(.fractionLength(0)))) of your portfolio (\(amount)).",
                severity: .warning,
                systemImage: "exclamationmark.circle.fill"
            ))
        }

        let cashShare = allocation.first(where: { $0.category == .bank })?.percentage ?? 0
        observations.append(PortfolioObservation(
            id: "liquidity",
            title: "Liquidity",
            message: cashShare >= 0.80
                ? "The portfolio is highly liquid, with most assets available as cash or deposits."
                : "Cash and deposits represent \(cashShare.formatted(.percent.precision(.fractionLength(0)))) of assets.",
            severity: cashShare >= 0.05 ? .neutral : .warning,
            systemImage: cashShare >= 0.05 ? "minus.circle.fill" : "drop.triangle.fill"
        ))

        if assetTotal > 0 {
            let ratio = liabilityTotal / assetTotal
            observations.append(PortfolioObservation(
                id: "debt-ratio",
                title: ratio <= 0 ? "Debt Free" : "Debt Ratio",
                message: ratio <= 0
                    ? "No liabilities are currently reducing net worth."
                    : "Liabilities equal \(ratio.formatted(.percent.precision(.fractionLength(0)))) of tracked assets.",
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
                title: "Stale Values",
                message: "\(staleAssets.count) asset \(staleAssets.count == 1 ? "value needs" : "values need") a refresh.",
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
                title: "Net Worth Trend",
                message: "Net worth \(change >= 0 ? "increased" : "decreased") by \(abs(change).formatted(.currency(code: baseCurrency.rawValue).precision(.fractionLength(0)))) over recorded history.",
                severity: change >= 0 ? .positive : .warning,
                systemImage: change >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill"
            ))
        }

        if observations.isEmpty {
            observations.append(PortfolioObservation(
                id: "empty",
                title: "Add Portfolio Data",
                message: "Add assets and liabilities to unlock portfolio intelligence.",
                severity: .neutral,
                systemImage: "sparkles"
            ))
        }

        return observations
    }
}
