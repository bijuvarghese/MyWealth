//
//  CategoryDetailView.swift
//  MyWealth
//

import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allAssets: [Asset]

    let category: Asset.CategoryType
    @Bindable var settings: AppSettings

    @State private var viewModel = DashboardViewModel(autoRefreshRate: false)
    @State private var metalViewModel = MetalPricesViewModel()

    private var categoryAssets: [Asset] {
        allAssets
            .filter { $0.displayCategory == category }
            .sorted { $0.displayName < $1.displayName }
    }

    private var calculationCategoryAssets: [Asset] {
        settings.portfolioCalculationAssets(from: categoryAssets)
    }

    private var categoryTotal: Double? {
        viewModel.convertedTotal(
            calculationCategoryAssets,
            to: settings.baseCurrency,
            exchangeRates: viewModel.exchangeRates
        )
    }

    var body: some View {
        ZStack {
            RadialDotBackground(dotRadius: 1, spacing: 20)
                .ignoresSafeArea(.all)

            if categoryAssets.isEmpty {
                ContentUnavailableView(
                    "No Assets",
                    systemImage: category.icon,
                    description: Text("No assets found in \(category.rawValue).")
                )
            } else {
                List {
                    Section {
                        HStack {
                            Text("Total (\(settings.baseCurrency.rawValue))")
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let total = categoryTotal {
                                Text(total, format: .currency(code: settings.baseCurrency.rawValue))
                                    .font(.headline)
                                    .monospacedDigit()
                            } else {
                                Text("Unavailable")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section(header: Text("\(categoryAssets.count) asset\(categoryAssets.count == 1 ? "" : "s")")) {
                        ForEach(categoryAssets) { asset in
                            NavigationLink {
                                AssetDetailView(asset: asset, settings: settings)
                            } label: {
                                AssetRowView(
                                    asset: asset,
                                    metalRates: metalViewModel.metalRates
                                )
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let forex: () = viewModel.refreshExchangeRateIfNeeded()
            async let metals: () = metalViewModel.refreshIfNeeded()
            _ = await (forex, metals)
            viewModel.enrichWithMetalRates(metalViewModel.metalRates)
        }
    }
}
