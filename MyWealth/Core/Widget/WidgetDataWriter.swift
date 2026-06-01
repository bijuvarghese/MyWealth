//
//  WidgetDataWriter.swift
//  MyWealth  (main app target only — do NOT add to the widget extension target)
//
//  Writes the current portfolio snapshot to the shared App Group container and
//  asks WidgetKit to reload all widget timelines so the home/lock screen widgets
//  reflect the latest data immediately after the user makes a change.
//

import Foundation
import WidgetKit

enum WidgetDataWriter {

    /// Builds a `WidgetSnapshot` from the supplied values, persists it via
    /// `WidgetDataStore`, and tells WidgetKit to reload every timeline.
    ///
    /// Call this whenever portfolio data or exchange rates change —
    /// `PortfolioHistoryCoordinator.writeWidgetSnapshot()` does this automatically.
    @MainActor
    static func write(
        netWorth: Double,
        assetTotal: Double,
        liabilityTotal: Double,
        baseCurrency: String,
        currencyTotals: [WidgetSnapshot.CurrencyEntry],
        transferRatesLastUpdated: Date?
    ) {
        let snapshot = WidgetSnapshot(
            netWorth: netWorth,
            assetTotal: assetTotal,
            liabilityTotal: liabilityTotal,
            baseCurrency: baseCurrency,
            currencyTotals: currencyTotals,
            lastUpdated: Date(),
            transferRatesLastUpdated: transferRatesLastUpdated
        )
        WidgetDataStore.save(snapshot)
        WatchSnapshotSender.shared.send(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
