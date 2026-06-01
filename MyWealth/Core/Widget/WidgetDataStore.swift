//
//  WidgetDataStore.swift
//  MyWealth
//
//  Shared between the main app target and the MyWealthWidget extension target.
//  Add this file to both targets in Xcode (Target Membership checkbox).
//
//  Data flows one way:
//    Main app  ──▶  WidgetDataStore.save()  ──▶  App Group UserDefaults
//    Widget    ──▶  WidgetDataStore.load()  ──▶  App Group UserDefaults
//

import Foundation

// MARK: - WidgetSnapshot

/// A lightweight, Codable snapshot of the current portfolio state.
/// Written by the main app after every portfolio change; read by the widget extension.
nonisolated struct WidgetSnapshot: Codable {

    /// Net worth (assets − liabilities) in the base currency.
    let netWorth: Double
    /// Total asset value in the base currency.
    let assetTotal: Double
    /// Total liability value in the base currency.
    let liabilityTotal: Double
    /// ISO currency code for the primary/base currency (e.g. "INR", "USD").
    let baseCurrency: String
    /// Additional display-currency totals (net worth in each currency), excluding the base.
    let currencyTotals: [CurrencyEntry]
    /// When this snapshot was written by the app.
    let lastUpdated: Date
    /// When transfer/exchange rates were last refreshed.
    let transferRatesLastUpdated: Date?

    struct CurrencyEntry: Codable, Identifiable {
        let code: String
        let amount: Double
        let transferRate: Double?
        var id: String { code }

        init(code: String, amount: Double, transferRate: Double? = nil) {
            self.code = code
            self.amount = amount
            self.transferRate = transferRate
        }
    }

    /// A placeholder snapshot used while no real data exists yet.
    static var placeholder: WidgetSnapshot {
        WidgetSnapshot(
            netWorth: 0,
            assetTotal: 0,
            liabilityTotal: 0,
            baseCurrency: "USD",
            currencyTotals: [],
            lastUpdated: Date(),
            transferRatesLastUpdated: nil
        )
    }
}

// MARK: - WidgetDataStore

/// Handles persistence of `WidgetSnapshot` via the shared App Group container.
///
/// **App Group ID:** `group.com.bv.MyWealth`
/// Both the main app target and the widget extension target must have this
/// App Group capability enabled in Xcode → Signing & Capabilities.
nonisolated enum WidgetDataStore {

    /// The App Group identifier. Must match exactly in both target entitlements.
    static let appGroupID = "group.com.bv.MyWealth"

    private static let snapshotKey = "widget.netWorthSnapshot"

    /// Shared `UserDefaults` backed by the App Group container.
    /// Returns `nil` if the App Group entitlement is not configured yet.
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Encodes and persists `snapshot` to the shared App Group container.
    static func save(_ snapshot: WidgetSnapshot) {
        guard
            let defaults = sharedDefaults,
            let data = try? JSONEncoder().encode(snapshot)
        else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    /// Loads and decodes the most recently saved `WidgetSnapshot`, or `nil` if none exists.
    static func load() -> WidgetSnapshot? {
        guard
            let defaults = sharedDefaults,
            let data = defaults.data(forKey: snapshotKey),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }
}
