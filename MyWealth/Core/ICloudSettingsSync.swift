import Foundation

/// Syncs lightweight user preferences via iCloud Key-Value Store.
/// Only active when iCloud sync is enabled and the user is signed in to iCloud.
/// Syncs: baseCurrency, totalCurrencies, usesCompactCurrencyTotals.
/// Does NOT sync: reminder preferences, onboarding state (per-device by nature).
final class ICloudSettingsSync {

    static let shared = ICloudSettingsSync()

    private let store = NSUbiquitousKeyValueStore.default

    private enum Keys {
        static let baseCurrency    = "kv.baseCurrency"
        static let totalCurrencies = "kv.totalCurrencies"
        static let compactTotals   = "kv.compactTotals"
    }

    private init() {}

    // MARK: - Push local → iCloud

    func push(settings: AppSettings) {
        store.set(settings.baseCurrency.rawValue, forKey: Keys.baseCurrency)
        store.set(settings.totalCurrencies.map(\.rawValue), forKey: Keys.totalCurrencies)
        store.set(settings.usesCompactCurrencyTotals, forKey: Keys.compactTotals)
        store.synchronize()
    }

    // MARK: - Pull iCloud → local

    /// Applies any iCloud KV values that differ from the current local settings.
    func pull(into settings: AppSettings) {
        if let raw = store.string(forKey: Keys.baseCurrency),
           let currency = Asset.CurrencyType(rawValue: raw),
           currency != .none {
            settings.baseCurrency = currency
        }
        if let rawArray = store.array(forKey: Keys.totalCurrencies) as? [String] {
            let currencies = rawArray.compactMap(Asset.CurrencyType.init(rawValue:))
                .filter { $0 != .none }
            if !currencies.isEmpty {
                settings.totalCurrencies = currencies
            }
        }
        settings.usesCompactCurrencyTotals = store.bool(forKey: Keys.compactTotals)
    }

    // MARK: - Observe remote changes

    /// Registers a handler called whenever another device pushes a change to iCloud KV.
    func startObserving(onChange: @Sendable @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { _ in onChange() }
        store.synchronize()
    }

    func stopObserving() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }
}
