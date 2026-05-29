//
//  PortfolioHistoryCoordinator.swift
//  MyWealth
//
//  Created by Biju Varghese on 5/23/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct PortfolioHistoryCoordinator {
    let assets: [Asset]
    let liabilities: [Liability]
    let netWorthSnapshots: [NetWorthSnapshot]
    let assetValueSnapshots: [AssetValueSnapshot]
    let settings: AppSettings
    let viewModel: DashboardViewModel
    let modelContext: ModelContext

    var assetSnapshotSignature: String {
        assets.map { asset in
            [
                String(describing: asset.persistentModelID),
                asset.displayName,
                "\(asset.displayAmount)",
                asset.displayCurrency.rawValue,
                asset.displayCategory.rawValue,
                "\(asset.lastUpdated?.timeIntervalSince1970 ?? 0)"
            ].joined(separator: ":")
        }
        .joined(separator: "|")
    }

    var liabilitySnapshotSignature: String {
        liabilities.map { liability in
            [
                String(describing: liability.persistentModelID),
                liability.displayName,
                "\(liability.displayAmount)",
                liability.displayCurrency.rawValue,
                liability.displayCategory.rawValue,
                "\(liability.lastUpdated?.timeIntervalSince1970 ?? 0)"
            ].joined(separator: ":")
        }
        .joined(separator: "|")
    }

    var rateSnapshotSignature: String {
        viewModel.exchangeRates
            .sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value)" }
            .joined(separator: "|")
    }

    var requiredExchangeRateCurrencies: [Asset.CurrencyType] {
        [settings.baseCurrency] + settings.totalCurrencies + assets.compactMap(\.currency) + liabilities.compactMap(\.currency)
    }

    func recordPortfolioHistory() {
        viewModel.recordPortfolioHistory(
            assets: assets,
            liabilities: liabilities,
            baseCurrency: settings.baseCurrency,
            netWorthSnapshots: netWorthSnapshots,
            assetValueSnapshots: assetValueSnapshots,
            modelContext: modelContext
        )
    }

    /// Computes the current net worth and writes it to the shared App Group
    /// container so home-screen and lock-screen widgets stay up to date.
    func writeWidgetSnapshot() {
        let rates = viewModel.exchangeRates
        let base = settings.baseCurrency

        guard
            let netWorth = viewModel.netWorthTotal(assets, liabilities: liabilities, to: base, exchangeRates: rates),
            let assetTotal = viewModel.convertedTotal(assets, to: base, exchangeRates: rates),
            let liabilityTotal = viewModel.convertedLiabilityTotal(liabilities, to: base, exchangeRates: rates)
        else { return }

        // Build secondary-currency totals for the medium widget (skip base currency).
        let currencyTotals: [WidgetSnapshot.CurrencyEntry] = settings.totalCurrencies
            .filter { $0 != base && $0 != .none }
            .compactMap { currency in
                guard let amount = viewModel.netWorthTotal(
                    assets,
                    liabilities: liabilities,
                    to: currency,
                    exchangeRates: rates
                ) else { return nil }
                return WidgetSnapshot.CurrencyEntry(code: currency.rawValue, amount: amount)
            }

        WidgetDataWriter.write(
            netWorth: netWorth,
            assetTotal: assetTotal,
            liabilityTotal: liabilityTotal,
            baseCurrency: base.rawValue,
            currencyTotals: currencyTotals,
            transferRatesLastUpdated: viewModel.lastUpdated
        )
    }
}

struct PortfolioHistoryCoordinationModifier: ViewModifier {
    let coordinator: PortfolioHistoryCoordinator

    func body(content: Content) -> some View {
        content
            .task {
                await coordinator.viewModel.refreshExchangeRateIfNeeded(
                    requiredCurrencies: coordinator.requiredExchangeRateCurrencies
                )
                coordinator.recordPortfolioHistory()
                coordinator.writeWidgetSnapshot()
            }
            .onChange(of: coordinator.assetSnapshotSignature) {
                Task {
                    await coordinator.viewModel.refreshExchangeRateIfNeeded(
                        requiredCurrencies: coordinator.requiredExchangeRateCurrencies
                    )
                    coordinator.recordPortfolioHistory()
                    coordinator.writeWidgetSnapshot()
                }
            }
            .onChange(of: coordinator.liabilitySnapshotSignature) {
                Task {
                    await coordinator.viewModel.refreshExchangeRateIfNeeded(
                        requiredCurrencies: coordinator.requiredExchangeRateCurrencies
                    )
                    coordinator.recordPortfolioHistory()
                    coordinator.writeWidgetSnapshot()
                }
            }
            .onChange(of: coordinator.settings.baseCurrency) {
                Task {
                    await coordinator.viewModel.refreshExchangeRateIfNeeded(
                        requiredCurrencies: coordinator.requiredExchangeRateCurrencies
                    )
                    coordinator.recordPortfolioHistory()
                    coordinator.writeWidgetSnapshot()
                }
            }
            .onChange(of: coordinator.settings.totalCurrencies) {
                Task {
                    await coordinator.viewModel.refreshExchangeRateIfNeeded(
                        requiredCurrencies: coordinator.requiredExchangeRateCurrencies
                    )
                    coordinator.recordPortfolioHistory()
                    coordinator.writeWidgetSnapshot()
                }
            }
            .onChange(of: coordinator.rateSnapshotSignature) {
                coordinator.recordPortfolioHistory()
                coordinator.writeWidgetSnapshot()
            }
    }
}

extension View {
    func coordinatePortfolioHistory(_ coordinator: PortfolioHistoryCoordinator) -> some View {
        self.modifier(PortfolioHistoryCoordinationModifier(coordinator: coordinator))
    }
}
