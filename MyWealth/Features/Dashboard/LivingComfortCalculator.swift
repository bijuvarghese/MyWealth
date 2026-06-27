import Foundation

struct LivingComfortAssumptions: Equatable {
    var householdMembers: Int
    var monthlyIncome: Double
    var expectedMonthlySpend: Double
    var monthlyIncomeWasProvided = false
    var expectedMonthlySpendWasProvided = false

    init(
        householdMembers: Int,
        monthlyIncome: Double,
        expectedMonthlySpend: Double,
        monthlyIncomeWasProvided: Bool? = nil,
        expectedMonthlySpendWasProvided: Bool? = nil
    ) {
        self.householdMembers = householdMembers
        self.monthlyIncome = max(monthlyIncome, 0)
        self.expectedMonthlySpend = max(expectedMonthlySpend, 0)
        self.monthlyIncomeWasProvided = monthlyIncomeWasProvided ?? (monthlyIncome > 0)
        self.expectedMonthlySpendWasProvided = expectedMonthlySpendWasProvided ?? (expectedMonthlySpend > 0)
    }

    var safeHouseholdMembers: Int {
        min(max(householdMembers, 1), 12)
    }
}

enum LivingComfortLevel: String, Equatable {
    case tight = "Tight"
    case stable = "Stable"
    case comfortable = "Comfortable"
    case independent = "Independent"

    var localizedName: String {
        AppLocalization.string(rawValue, fallback: rawValue)
    }
}

struct LivingComfortRow: Identifiable, Equatable {
    let currency: Asset.CurrencyType
    let countryName: String
    let netWorthAmount: Double
    let monthlySpendEstimate: Double
    let monthlySurplus: Double?
    let runwayMonths: Double
    let level: LivingComfortLevel
    let pppConversionFactor: Double?

    var id: String { currency.rawValue }
}

struct LivingComfortCalculator {
    func rows(
        totals: [CurrencyTotal],
        baseCurrency: Asset.CurrencyType,
        exchangeRates: [String: Double],
        assumptions: LivingComfortAssumptions
    ) -> [LivingComfortRow] {
        totals.map { total in
            row(
                total: total,
                baseCurrency: baseCurrency,
                exchangeRates: exchangeRates,
                assumptions: assumptions
            )
        }
    }

    func row(
        total: CurrencyTotal,
        baseCurrency: Asset.CurrencyType,
        exchangeRates: [String: Double],
        assumptions: LivingComfortAssumptions
    ) -> LivingComfortRow {
        let monthlyIncome = purchasingPowerAdjustedAmount(
            assumptions.monthlyIncome,
            from: baseCurrency,
            to: total.currency,
            exchangeRates: exchangeRates
        )
        let expectedMonthlySpend = purchasingPowerAdjustedAmount(
            assumptions.expectedMonthlySpend,
            from: baseCurrency,
            to: total.currency,
            exchangeRates: exchangeRates
        )
        let estimatedSpend = monthlySpend(
            for: total.currency,
            expectedMonthlySpend: expectedMonthlySpend,
            assumptions: assumptions
        )
        let runwayMonths = estimatedSpend > 0 ? max(total.amount, 0) / estimatedSpend : .infinity
        let surplus = assumptions.monthlyIncomeWasProvided ? monthlyIncome - estimatedSpend : nil

        return LivingComfortRow(
            currency: total.currency,
            countryName: countryName(for: total.currency),
            netWorthAmount: total.amount,
            monthlySpendEstimate: estimatedSpend,
            monthlySurplus: surplus,
            runwayMonths: runwayMonths,
            level: comfortLevel(runwayMonths: runwayMonths),
            pppConversionFactor: pppConversionFactor(for: total.currency)
        )
    }

    func monthlySpend(
        for currency: Asset.CurrencyType,
        expectedMonthlySpend: Double,
        assumptions: LivingComfortAssumptions
    ) -> Double {
        if assumptions.expectedMonthlySpendWasProvided {
            return expectedMonthlySpend * householdScale(assumptions.safeHouseholdMembers)
        }

        let baseline = pppConversionFactor(for: currency).map {
            Self.monthlyComfortBaselineInternationalDollars * $0
        } ?? Self.monthlyBaselineByCurrency[currency.rawValue] ?? fallbackBaseline(for: currency)
        return baseline * householdScale(assumptions.safeHouseholdMembers)
    }

    func countryName(for currency: Asset.CurrencyType) -> String {
        Self.countryByCurrency[currency.rawValue] ?? countryNameFromCurrencyName(currency.name)
    }

    private func householdScale(_ members: Int) -> Double {
        guard members > 1 else { return 1 }
        return 1 + (Double(members - 1) * 0.65)
    }

    private func purchasingPowerAdjustedAmount(
        _ amount: Double,
        from sourceCurrency: Asset.CurrencyType,
        to targetCurrency: Asset.CurrencyType,
        exchangeRates: [String: Double]
    ) -> Double {
        guard amount.isFinite else { return 0 }

        if
            let sourcePPP = pppConversionFactor(for: sourceCurrency),
            let targetPPP = pppConversionFactor(for: targetCurrency),
            sourcePPP > 0,
            targetPPP > 0 {
            return (amount / sourcePPP) * targetPPP
        }

        return marketConvertedAmount(
            amount,
            from: sourceCurrency,
            to: targetCurrency,
            exchangeRates: exchangeRates
        )
    }

    private func marketConvertedAmount(
        _ amount: Double,
        from sourceCurrency: Asset.CurrencyType,
        to targetCurrency: Asset.CurrencyType,
        exchangeRates: [String: Double]
    ) -> Double {
        guard
            amount.isFinite,
            let sourceRate = rate(for: sourceCurrency, exchangeRates: exchangeRates),
            let targetRate = rate(for: targetCurrency, exchangeRates: exchangeRates),
            sourceRate > 0,
            targetRate > 0
        else {
            return 0
        }

        return (amount / sourceRate) * targetRate
    }

    private func rate(for currency: Asset.CurrencyType, exchangeRates: [String: Double]) -> Double? {
        if currency == .usd {
            return 1
        }

        return exchangeRates[currency.rawValue]
    }

    private func pppConversionFactor(for currency: Asset.CurrencyType) -> Double? {
        Self.privateConsumptionPPPByCurrency[currency.rawValue]
    }

    private func comfortLevel(runwayMonths: Double) -> LivingComfortLevel {
        switch runwayMonths {
        case 120...: return .independent
        case 36..<120: return .comfortable
        case 12..<36: return .stable
        default: return .tight
        }
    }

    private func fallbackBaseline(for currency: Asset.CurrencyType) -> Double {
        let name = currency.name.lowercased()
        if name.contains("franc") || name.contains("pound") || name.contains("dollar") {
            return 4_000
        }
        if name.contains("rupee") || name.contains("peso") || name.contains("real") {
            return 90_000
        }
        return 3_000
    }

    private func countryNameFromCurrencyName(_ name: String) -> String {
        name
            .replacingOccurrences(of: " Dollar", with: "")
            .replacingOccurrences(of: " Dirham", with: "")
            .replacingOccurrences(of: " Rupee", with: "")
            .replacingOccurrences(of: " Peso", with: "")
            .replacingOccurrences(of: " Pound Sterling", with: "")
            .replacingOccurrences(of: " Franc", with: "")
    }

    private static let countryByCurrency: [String: String] = [
        "USD": "United States",
        "EUR": "Euro Area",
        "GBP": "United Kingdom",
        "INR": "India",
        "CAD": "Canada",
        "AUD": "Australia",
        "AED": "United Arab Emirates",
        "SGD": "Singapore",
        "CHF": "Switzerland",
        "JPY": "Japan",
        "CNY": "China",
        "HKD": "Hong Kong",
        "NZD": "New Zealand",
        "MXN": "Mexico",
        "BRL": "Brazil",
        "ZAR": "South Africa",
        "THB": "Thailand",
        "MYR": "Malaysia",
        "PHP": "Philippines",
        "IDR": "Indonesia",
        "KRW": "South Korea",
        "SEK": "Sweden",
        "NOK": "Norway",
        "DKK": "Denmark"
    ]

    private static let monthlyComfortBaselineInternationalDollars = 4_500.0

    private static let privateConsumptionPPPByCurrency: [String: Double] = [
        "USD": 1,
        "EUR": 0.6748138,
        "GBP": 0.682739,
        "INR": 19.8969156536629,
        "CAD": 1.240903,
        "AUD": 1.427398,
        "AED": 2.56310995667988,
        "SGD": 1.04202980034753,
        "CHF": 1.107209,
        "JPY": 99.384798,
        "CNY": 3.55078934957361,
        "HKD": 5.83933992666934,
        "NZD": 1.499938,
        "MXN": 10.801299,
        "BRL": 2.52449654597584,
        "ZAR": 7.70191474358185,
        "THB": 11.7121210098267,
        "MYR": 1.44922714623582,
        "PHP": 20.743505641423,
        "IDR": 5_104.98431987765,
        "KRW": 872.468736,
        "SEK": 8.577614,
        "NOK": 9.540077,
        "DKK": 6.764411
    ]

    private static let monthlyBaselineByCurrency: [String: Double] = [
        "USD": 4_500,
        "EUR": 3_800,
        "GBP": 3_700,
        "INR": 120_000,
        "CAD": 4_800,
        "AUD": 5_000,
        "AED": 16_000,
        "SGD": 6_500,
        "CHF": 6_500,
        "JPY": 420_000,
        "CNY": 18_000,
        "HKD": 45_000,
        "NZD": 5_200,
        "MXN": 55_000,
        "BRL": 12_000,
        "ZAR": 45_000,
        "THB": 85_000,
        "MYR": 10_000,
        "PHP": 140_000,
        "IDR": 32_000_000,
        "KRW": 4_500_000,
        "SEK": 42_000,
        "NOK": 48_000,
        "DKK": 31_000
    ]
}
