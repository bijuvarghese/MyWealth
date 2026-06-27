import Foundation

enum FIRELevelKind: String, CaseIterable, Identifiable {
    case lean = "LeanFIRE"
    case standard = "FIRE"
    case fat = "FatFIRE"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .lean: return 20
        case .standard: return 25
        case .fat: return 33
        }
    }

    var subtitle: String {
        switch self {
        case .lean:
            return AppLocalization.formatted(
                "Lean lifestyle · %@ withdrawal rate",
                arguments: [AppLocalization.percent(0.05)]
            )
        case .standard:
            return AppLocalization.formatted(
                "Standard FIRE · %@ withdrawal rate",
                arguments: [AppLocalization.percent(0.04)]
            )
        case .fat:
            return AppLocalization.formatted(
                "Comfortable lifestyle · %@ withdrawal rate",
                arguments: [AppLocalization.percent(0.03)]
            )
        }
    }

    var displayName: String {
        AppLocalization.string(rawValue, fallback: rawValue)
    }

    var systemImage: String {
        switch self {
        case .lean: return "figure.walk"
        case .standard: return "figure.run"
        case .fat: return "figure.hiking"
        }
    }
}

struct FIRELevelProgress: Identifiable, Equatable {
    let kind: FIRELevelKind
    let target: Double
    let progress: Double
    let estimatedYear: Int?

    var id: FIRELevelKind { kind }
    var isAchieved: Bool { progress >= 1 }
}

struct FIRETrajectoryPoint: Identifiable, Equatable {
    let yearOffset: Int
    let amount: Double

    var id: Int { yearOffset }
}

struct FIREProjection: Equatable {
    let currentPortfolio: Double
    let monthlyExpenses: Double
    let monthlySavings: Double
    let retireAtAge: Int
    let currentAge: Int?
    let annualReturn: Double
    let annualExpenses: Double
    let fireTarget: Double
    let progress: Double
    let savingsRate: Double
    let yearsToFIRE: Double?
    let monthlyTargetToRetireAtAge: Double?
    let levelProgress: [FIRELevelProgress]
    let trajectory: [FIRETrajectoryPoint]
    let portfolioAfterOneYear: Double
    let extraAnnualSpendingAfterOneYear: Double

    var isFIREReached: Bool { progress >= 1 }
}

struct FIRECalculator {
    func project(
        currentPortfolio: Double,
        monthlyExpenses: Double,
        monthlySavings: Double,
        retireAtAge: Int = 65,
        currentAge: Int? = nil,
        annualReturn: Double = 0.07,
        projectionYears: Int = 30,
        currentDate: Date = Date()
    ) -> FIREProjection {
        let safePortfolio = max(currentPortfolio, 0)
        let safeExpenses = max(monthlyExpenses, 0)
        let safeSavings = max(monthlySavings, 0)
        let annualExpenses = safeExpenses * 12
        let fireTarget = annualExpenses * 25
        let progress = fireTarget > 0 ? min(safePortfolio / fireTarget, 1) : 0
        let savingsRateDenominator = safeExpenses + safeSavings
        let savingsRate = savingsRateDenominator > 0 ? safeSavings / savingsRateDenominator : 0
        let yearsToFIRE = yearsToReachTarget(
            currentPortfolio: safePortfolio,
            monthlySavings: safeSavings,
            target: fireTarget,
            annualReturn: annualReturn
        )
        let monthlyTarget = monthlySavingsNeeded(
            currentPortfolio: safePortfolio,
            target: fireTarget,
            annualReturn: annualReturn,
            years: currentAge.map { max(retireAtAge - $0, 0) }
        )
        let year = Calendar.current.component(.year, from: currentDate)
        let levels = FIRELevelKind.allCases.map { kind in
            let target = annualExpenses * kind.multiplier
            let years = yearsToReachTarget(
                currentPortfolio: safePortfolio,
                monthlySavings: safeSavings,
                target: target,
                annualReturn: annualReturn
            )
            return FIRELevelProgress(
                kind: kind,
                target: target,
                progress: target > 0 ? min(safePortfolio / target, 1) : 0,
                estimatedYear: years.map { year + Int(ceil($0)) }
            )
        }
        let trajectory = (0...projectionYears).map { offset in
            FIRETrajectoryPoint(
                yearOffset: offset,
                amount: futureValue(
                    currentPortfolio: safePortfolio,
                    monthlySavings: safeSavings,
                    annualReturn: annualReturn,
                    years: Double(offset)
                )
            )
        }
        let afterOneYear = futureValue(
            currentPortfolio: safePortfolio,
            monthlySavings: safeSavings,
            annualReturn: annualReturn,
            years: 1
        )
        let retiringToday = safePortfolio * 0.04
        let afterOneMoreYear = afterOneYear * 0.04

        return FIREProjection(
            currentPortfolio: safePortfolio,
            monthlyExpenses: safeExpenses,
            monthlySavings: safeSavings,
            retireAtAge: retireAtAge,
            currentAge: currentAge,
            annualReturn: annualReturn,
            annualExpenses: annualExpenses,
            fireTarget: fireTarget,
            progress: progress,
            savingsRate: savingsRate,
            yearsToFIRE: yearsToFIRE,
            monthlyTargetToRetireAtAge: monthlyTarget,
            levelProgress: levels,
            trajectory: trajectory,
            portfolioAfterOneYear: afterOneYear,
            extraAnnualSpendingAfterOneYear: afterOneMoreYear - retiringToday
        )
    }

    func futureValue(
        currentPortfolio: Double,
        monthlySavings: Double,
        annualReturn: Double,
        years: Double
    ) -> Double {
        let months = max(Int((years * 12).rounded()), 0)
        let monthlyReturn = annualReturn / 12
        var value = max(currentPortfolio, 0)

        guard monthlyReturn != 0 else {
            return value + max(monthlySavings, 0) * Double(months)
        }

        for _ in 0..<months {
            value = value * (1 + monthlyReturn) + max(monthlySavings, 0)
        }
        return value
    }

    private func yearsToReachTarget(
        currentPortfolio: Double,
        monthlySavings: Double,
        target: Double,
        annualReturn: Double
    ) -> Double? {
        guard target > 0 else { return nil }
        if currentPortfolio >= target { return 0 }
        guard monthlySavings > 0 || annualReturn > 0, currentPortfolio > 0 || monthlySavings > 0 else {
            return nil
        }

        var value = max(currentPortfolio, 0)
        let monthlyReturn = annualReturn / 12
        for month in 1...(120 * 12) {
            value = value * (1 + monthlyReturn) + max(monthlySavings, 0)
            if value >= target {
                return Double(month) / 12
            }
        }
        return nil
    }

    private func monthlySavingsNeeded(
        currentPortfolio: Double,
        target: Double,
        annualReturn: Double,
        years: Int?
    ) -> Double? {
        guard let years, years > 0, target > currentPortfolio else { return nil }
        let months = years * 12
        let monthlyReturn = annualReturn / 12

        if monthlyReturn == 0 {
            return (target - currentPortfolio) / Double(months)
        }

        let compoundedCurrent = currentPortfolio * pow(1 + monthlyReturn, Double(months))
        let annuityFactor = (pow(1 + monthlyReturn, Double(months)) - 1) / monthlyReturn
        guard annuityFactor > 0 else { return nil }

        return max((target - compoundedCurrent) / annuityFactor, 0)
    }
}
