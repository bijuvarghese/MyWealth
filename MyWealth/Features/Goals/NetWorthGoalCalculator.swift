import Foundation

struct NetWorthGoalProgress: Equatable {
    let currentAmount: Double?
    let rawFraction: Double?
    let visualFraction: Double
    let isAchieved: Bool
    let rateState: NetWorthGoalRateState
}

struct NetWorthGoalCurrentValue: Equatable {
    let amount: Double?
    let rateState: NetWorthGoalRateState
}

enum NetWorthGoalRateState: Equatable {
    case available
    case stale
    case unavailable(missingCodes: [String])
}

enum NetWorthGoalPace: Equatable {
    case onTrack
    case behind
}

enum NetWorthGoalOutlook: Equatable {
    case achieved
    case projected(date: Date, pace: NetWorthGoalPace)
    case needsHistory
    case nonGrowing
    case conversionUnavailable
    case currentValueUnavailable
}

struct NetWorthGoalCalculator {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func progress(
        goal: NetWorthGoal,
        assets: [Asset],
        liabilities: [Liability],
        exchangeRates: [String: Double],
        ratesAreStale: Bool
    ) -> NetWorthGoalProgress {
        let currentValue = currentValue(
            currency: goal.displayCurrency,
            assets: assets,
            liabilities: liabilities,
            exchangeRates: exchangeRates,
            ratesAreStale: ratesAreStale
        )
        guard goal.hasValidStoredValues,
              let currentAmount = currentValue.amount
        else {
            return NetWorthGoalProgress(
                currentAmount: nil,
                rawFraction: nil,
                visualFraction: 0,
                isAchieved: false,
                rateState: currentValue.rateState
            )
        }

        let rawFraction = currentAmount / goal.displayTargetAmount
        return NetWorthGoalProgress(
            currentAmount: currentAmount,
            rawFraction: rawFraction,
            visualFraction: min(max(rawFraction, 0), 1),
            isAchieved: currentAmount >= goal.displayTargetAmount,
            rateState: currentValue.rateState
        )
    }

    func currentValue(
        currency: Asset.CurrencyType,
        assets: [Asset],
        liabilities: [Liability],
        exchangeRates: [String: Double],
        ratesAreStale: Bool
    ) -> NetWorthGoalCurrentValue {
        guard !assets.isEmpty || !liabilities.isEmpty else {
            return NetWorthGoalCurrentValue(amount: nil, rateState: .available)
        }

        let currencies = requiredCurrencies(
            targetCurrency: currency,
            assets: assets,
            liabilities: liabilities
        )
        let missingCodes = currencies
            .filter { validRate(for: $0, rates: exchangeRates) == nil }
            .map(\.rawValue)
            .sorted()

        guard missingCodes.isEmpty,
              currency != .none,
              let targetRate = validRate(for: currency, rates: exchangeRates)
        else {
            return NetWorthGoalCurrentValue(
                amount: nil,
                rateState: .unavailable(missingCodes: missingCodes)
            )
        }

        let assetUSD = assets.reduce(0.0) { total, asset in
            guard asset.participatesInPortfolioCalculations,
                  asset.displayAmount > 0,
                  asset.displayAmount.isFinite,
                  let sourceRate = validRate(for: asset.displayCurrency, rates: exchangeRates)
            else { return total }
            return total + asset.displayAmount / sourceRate
        }
        let liabilityUSD = liabilities.reduce(0.0) { total, liability in
            guard liability.displayAmount > 0,
                  liability.displayAmount.isFinite,
                  let sourceRate = validRate(for: liability.displayCurrency, rates: exchangeRates)
            else { return total }
            return total + liability.displayAmount / sourceRate
        }
        let currentAmount = (assetUSD - liabilityUSD) * targetRate
        guard currentAmount.isFinite else {
            return NetWorthGoalCurrentValue(
                amount: nil,
                rateState: .unavailable(missingCodes: [])
            )
        }

        return NetWorthGoalCurrentValue(
            amount: currentAmount,
            rateState: ratesAreStale ? .stale : .available
        )
    }

    func outlook(
        goal: NetWorthGoal,
        progress: NetWorthGoalProgress,
        snapshots: [NetWorthSnapshot],
        exchangeRates: [String: Double],
        currentDate: Date = Date()
    ) -> NetWorthGoalOutlook {
        guard let currentAmount = progress.currentAmount else {
            if case .unavailable = progress.rateState { return .conversionUnavailable }
            return .currentValueUnavailable
        }
        if progress.isAchieved { return .achieved }

        let validSnapshots = snapshots.filter {
            $0.displayAmount.isFinite
                && $0.recordedAt != nil
                && Asset.CurrencyType(rawValue: $0.displayCurrencyCode) != nil
                && Asset.CurrencyType(rawValue: $0.displayCurrencyCode) != .none
        }
        let missingSnapshotRate = validSnapshots.contains { snapshot in
            guard let currency = Asset.CurrencyType(rawValue: snapshot.displayCurrencyCode) else {
                return true
            }
            return validRate(for: currency, rates: exchangeRates) == nil
        }
        guard !missingSnapshotRate,
              let targetRate = validRate(for: goal.displayCurrency, rates: exchangeRates)
        else { return .conversionUnavailable }

        var latestByDay: [Date: NetWorthSnapshot] = [:]
        for snapshot in validSnapshots {
            let day = calendar.startOfDay(for: snapshot.displayRecordedAt)
            if let current = latestByDay[day], current.displayRecordedAt >= snapshot.displayRecordedAt {
                continue
            }
            latestByDay[day] = snapshot
        }

        let observations = latestByDay.values
            .sorted { $0.displayRecordedAt < $1.displayRecordedAt }
            .suffix(365)
            .compactMap { snapshot -> (Date, Double)? in
                guard let currency = Asset.CurrencyType(rawValue: snapshot.displayCurrencyCode),
                      let sourceRate = validRate(for: currency, rates: exchangeRates)
                else { return nil }
                return (snapshot.displayRecordedAt, snapshot.displayAmount / sourceRate * targetRate)
            }

        guard observations.count >= 3,
              let oldest = observations.first,
              let newest = observations.last
        else { return .needsHistory }

        let elapsedDays = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: oldest.0),
            to: calendar.startOfDay(for: newest.0)
        ).day ?? 0
        guard elapsedDays >= 30 else { return .needsHistory }

        let dailyChange = (newest.1 - oldest.1) / Double(elapsedDays)
        guard dailyChange.isFinite, dailyChange > 0 else { return .nonGrowing }

        let remaining = max(goal.displayTargetAmount - currentAmount, 0)
        let projectedDays = Int(ceil(remaining / dailyChange))
        guard let projectedDate = calendar.date(
            byAdding: .day,
            value: projectedDays,
            to: calendar.startOfDay(for: currentDate)
        ) else { return .currentValueUnavailable }

        let pace: NetWorthGoalPace = calendar.startOfDay(for: projectedDate)
            <= calendar.startOfDay(for: goal.displayTargetDate) ? .onTrack : .behind
        return .projected(date: projectedDate, pace: pace)
    }

    private func requiredCurrencies(
        targetCurrency: Asset.CurrencyType,
        assets: [Asset],
        liabilities: [Liability]
    ) -> Set<Asset.CurrencyType> {
        var currencies: Set<Asset.CurrencyType> = [targetCurrency]
        currencies.formUnion(
            assets
                .filter { $0.participatesInPortfolioCalculations && $0.displayAmount > 0 && $0.displayAmount.isFinite }
                .map(\.displayCurrency)
        )
        currencies.formUnion(
            liabilities
                .filter { $0.displayAmount > 0 && $0.displayAmount.isFinite }
                .map(\.displayCurrency)
        )
        return currencies.filter { $0 != .none }
    }

    private func validRate(
        for currency: Asset.CurrencyType,
        rates: [String: Double]
    ) -> Double? {
        if currency == .usd { return 1 }
        guard let rate = rates[currency.rawValue], rate.isFinite, rate > 0 else { return nil }
        return rate
    }
}
