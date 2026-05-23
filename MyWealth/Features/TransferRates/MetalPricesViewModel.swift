import SwiftUI

// MARK: - Group

enum MetalGroup: String, CaseIterable {
    case precious  = "Precious Metals"
    case base      = "Base Metals"
    case specialty = "Specialty Metals"
}

// MARK: - Display model

struct MetalPriceRow: Identifiable {
    let symbol: String
    let name: String
    let unit: String
    let color: Color
    let group: MetalGroup
    let priceInBase: Double?
    let baseCurrencyCode: String

    var id: String { symbol }
}

// MARK: - ViewModel

@Observable
@MainActor
final class MetalPricesViewModel {

    private enum DefaultsKeys {
        static let rates      = "metalPrice.rates"
        static let lastUpdated = "metalPrice.lastUpdated"
    }

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let metalPriceService: any MetalPriceFetching

    var metalRates: [String: Double] = [:]
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?

    init(
        userDefaults: UserDefaults = .standard,
        metalPriceService: any MetalPriceFetching = FirebaseMetalPriceService.shared
    ) {
        self.userDefaults = userDefaults
        self.metalPriceService = metalPriceService

        if let saved = userDefaults.object(forKey: DefaultsKeys.rates) as? [String: Double] {
            self.metalRates = saved
        }
        if let savedInterval = userDefaults.object(forKey: DefaultsKeys.lastUpdated) as? TimeInterval {
            self.lastUpdated = Date(timeIntervalSince1970: savedInterval)
        }
    }

    // MARK: - Fetch

    func refreshIfNeeded() async {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        if let last = lastUpdated, last >= startOfToday, !metalRates.isEmpty {
            return
        }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await metalPriceService.fetchLatestMetalPrices()
            let rates = response.rates ?? [:]
            let now = Date()
            metalRates = rates
            lastUpdated = now
            errorMessage = nil
            userDefaults.set(rates, forKey: DefaultsKeys.rates)
            userDefaults.set(now.timeIntervalSince1970, forKey: DefaultsKeys.lastUpdated)
        } catch {
            errorMessage = "Unable to refresh metal prices. Showing the last saved prices."
        }
    }

    // MARK: - Row computation

    /// Returns display rows for all known metals that have a live rate,
    /// priced in the user's base currency.
    /// `exchangeRates` is the USD-based dictionary from DashboardViewModel
    /// (e.g. ["INR": 84.0, "EUR": 0.92]).
    func metalPriceRows(
        baseCurrency: Asset.CurrencyType,
        exchangeRates: [String: Double]
    ) -> [MetalPriceRow] {
        // How many units of the base currency equal 1 USD?
        let baseUnitsPerUSD: Double
        if baseCurrency == .usd {
            baseUnitsPerUSD = 1.0
        } else if let rate = exchangeRates[baseCurrency.rawValue], rate > 0 {
            baseUnitsPerUSD = rate
        } else {
            baseUnitsPerUSD = 1.0
        }

        return Self.knownMetals.compactMap { info in
            guard let metalRate = metalRates[info.symbol], metalRate > 0 else {
                return nil
            }
            // The API returns "units of metal per 1 USD".
            // → price per 1 unit of metal in USD  = 1 / metalRate
            // → price per 1 unit of metal in base = (1 / metalRate) × baseUnitsPerUSD
            let priceInBase = (1.0 / metalRate) * baseUnitsPerUSD

            return MetalPriceRow(
                symbol: info.symbol,
                name: info.name,
                unit: info.unit,
                color: info.color,
                group: info.group,
                priceInBase: priceInBase,
                baseCurrencyCode: baseCurrency.rawValue
            )
        }
    }

    /// Rows bucketed by group, preserving catalogue order within each group.
    func groupedRows(
        baseCurrency: Asset.CurrencyType,
        exchangeRates: [String: Double]
    ) -> [(group: MetalGroup, rows: [MetalPriceRow])] {
        let all = metalPriceRows(baseCurrency: baseCurrency, exchangeRates: exchangeRates)
        return MetalGroup.allCases.compactMap { group in
            let rows = all.filter { $0.group == group }
            return rows.isEmpty ? nil : (group, rows)
        }
    }

    // MARK: - Status banner

    var statusBanner: RateStatusModel? {
        if isLoading {
            return RateStatusModel(
                systemImage: "arrow.triangle.2.circlepath",
                message: "Refreshing metal prices...",
                style: .loading
            )
        }
        if let errorMessage {
            return RateStatusModel(
                systemImage: "exclamationmark.triangle",
                message: errorMessage,
                style: .warning
            )
        }
        guard let lastUpdated else {
            return RateStatusModel(
                systemImage: "clock",
                message: "Metal prices have not been loaded yet.",
                style: .neutral
            )
        }
        if !Calendar.current.isDateInToday(lastUpdated) {
            return RateStatusModel(
                systemImage: "clock.badge.exclamationmark",
                message: "Metal prices are from \(lastUpdated.formatted(date: .abbreviated, time: .shortened)).",
                style: .warning
            )
        }
        return nil
    }

    // MARK: - Metal catalogue

    private struct MetalInfo {
        let symbol: String
        let name: String
        let unit: String
        let color: Color
        let group: MetalGroup
    }

    private static let knownMetals: [MetalInfo] = [
        // ── Precious Metals ─────────────────────────────────────────────
        MetalInfo(symbol: "XAU", name: "Gold",      unit: "troy oz", color: Color(red: 0.85, green: 0.65, blue: 0.13), group: .precious),
        MetalInfo(symbol: "XAG", name: "Silver",    unit: "troy oz", color: Color(.systemGray),                         group: .precious),
        MetalInfo(symbol: "XPT", name: "Platinum",  unit: "troy oz", color: Color(.systemTeal),                         group: .precious),
        MetalInfo(symbol: "XPD", name: "Palladium", unit: "troy oz", color: Color(.systemMint),                         group: .precious),
        MetalInfo(symbol: "XRH", name: "Rhodium",   unit: "troy oz", color: Color(.systemPurple),                       group: .precious),

        // ── Base Metals ─────────────────────────────────────────────────
        MetalInfo(symbol: "XCU",  name: "Copper",    unit: "lb",  color: Color(.systemOrange),               group: .base),
        MetalInfo(symbol: "ALU",  name: "Aluminum",  unit: "MT",  color: Color(.systemBlue),                 group: .base),
        MetalInfo(symbol: "NI",   name: "Nickel",    unit: "MT",  color: Color(.systemCyan),                 group: .base),
        MetalInfo(symbol: "ZNC",  name: "Zinc",      unit: "MT",  color: Color(red: 0.6, green: 0.6, blue: 0.65), group: .base),
        MetalInfo(symbol: "XPB",  name: "Lead",      unit: "MT",  color: Color(.systemGray2),                group: .base),
        MetalInfo(symbol: "XSN",  name: "Tin",       unit: "MT",  color: Color(.systemGray3),                group: .base),
        MetalInfo(symbol: "IRON", name: "Iron Ore",  unit: "MT",  color: Color(red: 0.55, green: 0.27, blue: 0.07), group: .base),
        MetalInfo(symbol: "XCO",  name: "Cobalt",    unit: "MT",  color: Color(.systemIndigo),               group: .base),

        // ── Specialty / Rare Metals ──────────────────────────────────────
        MetalInfo(symbol: "XLI", name: "Lithium",    unit: "MT", color: Color(red: 0.9, green: 0.4, blue: 0.1),  group: .specialty),
        MetalInfo(symbol: "XMO", name: "Molybdenum", unit: "kg", color: Color(.systemGray4),                      group: .specialty),
        MetalInfo(symbol: "XND", name: "Neodymium",  unit: "kg", color: Color(.systemMint),                       group: .specialty),
        MetalInfo(symbol: "XGA", name: "Gallium",    unit: "kg", color: Color(red: 0.5, green: 0.8, blue: 0.5),  group: .specialty),
        MetalInfo(symbol: "XIN", name: "Indium",     unit: "kg", color: Color(.systemTeal),                       group: .specialty),
        MetalInfo(symbol: "XTE", name: "Tellurium",  unit: "kg", color: Color(.systemPurple),                     group: .specialty),
        MetalInfo(symbol: "XU",  name: "Uranium",    unit: "lb", color: Color(red: 0.6, green: 0.8, blue: 0.2),  group: .specialty),
    ]
}
