//
//  PortfolioHistoryCoordinator.swift
//  MyWealth
//
//  Created by Biju Varghese on 5/23/26.
//

import SwiftUI
import SwiftData

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
            }
            .onChange(of: coordinator.assetSnapshotSignature) {
                Task {
                    await coordinator.viewModel.refreshExchangeRateIfNeeded(
                        requiredCurrencies: coordinator.requiredExchangeRateCurrencies
                    )
                    coordinator.recordPortfolioHistory()
                }
            }
            .onChange(of: coordinator.liabilitySnapshotSignature) {
                Task {
                    await coordinator.viewModel.refreshExchangeRateIfNeeded(
                        requiredCurrencies: coordinator.requiredExchangeRateCurrencies
                    )
                    coordinator.recordPortfolioHistory()
                }
            }
            .onChange(of: coordinator.settings.baseCurrency) {
                Task {
                    await coordinator.viewModel.refreshExchangeRateIfNeeded(
                        requiredCurrencies: coordinator.requiredExchangeRateCurrencies
                    )
                    coordinator.recordPortfolioHistory()
                }
            }
            .onChange(of: coordinator.settings.totalCurrencies) {
                Task {
                    await coordinator.viewModel.refreshExchangeRateIfNeeded(
                        requiredCurrencies: coordinator.requiredExchangeRateCurrencies
                    )
                    coordinator.recordPortfolioHistory()
                }
            }
            .onChange(of: coordinator.rateSnapshotSignature) {
                coordinator.recordPortfolioHistory()
            }
    }
}

extension View {
    func coordinatePortfolioHistory(_ coordinator: PortfolioHistoryCoordinator) -> some View {
        self.modifier(PortfolioHistoryCoordinationModifier(coordinator: coordinator))
    }
}
