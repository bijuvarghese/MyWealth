//
//  ContentView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//


import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var assets: [Asset]
    @Query private var liabilities: [Liability]
    @Query private var netWorthSnapshots: [NetWorthSnapshot]
    @Query private var portfolioSnapshots: [PortfolioSnapshot]
    @Query private var assetValueSnapshots: [AssetValueSnapshot]
    @Bindable var settings: AppSettings

    @State private var showAddSheet = false
    @State private var showNetWorthHistory = false
    @State private var hasAnimatedPortfolioChart = false
    @State private var hasAnimatedLiabilityChart = false
    @State private var selectedCategory: Asset.CategoryType? = nil
    @State private var viewModel = DashboardViewModel()
    @State private var metalViewModel = MetalPricesViewModel()

    private var coordinator: PortfolioHistoryCoordinator {
        PortfolioHistoryCoordinator(
            assets: assets,
            liabilities: liabilities,
            netWorthSnapshots: netWorthSnapshots,
            assetValueSnapshots: assetValueSnapshots,
            settings: settings,
            viewModel: viewModel,
            modelContext: modelContext
        )
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            if assets.isEmpty && liabilities.isEmpty {
                ContentUnavailableView(
                    "No Assets or Debt",
                    systemImage: "banknote",
                    description: Text("Add assets or liabilities to start tracking net worth.")
                )
            } else {
                List {
                    Section {
                        AppListCard(
                            contentPadding: EdgeInsets(top: 12, leading: 0, bottom: 0, trailing: 0)
                        ) {
                            AssetLiabilitySummaryView(
                                assetTotal: viewModel.convertedTotal(
                                    assets,
                                    to: settings.baseCurrency,
                                    exchangeRates: viewModel.exchangeRates
                                ),
                                liabilityTotal: viewModel.convertedLiabilityTotal(
                                    liabilities,
                                    to: settings.baseCurrency,
                                    exchangeRates: viewModel.exchangeRates
                                ),
                                netWorthTotal: viewModel.netWorthTotal(
                                    assets,
                                    liabilities: liabilities,
                                    to: settings.baseCurrency,
                                    exchangeRates: viewModel.exchangeRates
                                ),
                                currencyCode: settings.baseCurrency.rawValue
                            )
                        }
                        .appListRow()
                    }

                    let insightRows = viewModel.portfolioInsightRows(
                        assets: assets,
                        liabilities: liabilities,
                        netWorthSnapshots: netWorthSnapshots,
                        baseCurrency: settings.baseCurrency
                    )
                    if !insightRows.isEmpty {
                        Section(header: PillLabel("Insights")) {
                            AppListCard {
                                PortfolioInsightsView(rows: insightRows)
                            }
                            .appListRow()
                        }
                    }

                    if !assets.isEmpty {
                        Section(header: PillLabel("Allocation")) {
                            AppListCard {
                                PortfolioAllocationView(
                                    rows: viewModel.categoryAllocationRows(
                                        assets,
                                        targetCurrency: settings.baseCurrency
                                    ),
                                    portfolioTotal: viewModel.convertedTotal(
                                        assets,
                                        to: settings.baseCurrency,
                                        exchangeRates: viewModel.exchangeRates
                                    ),
                                    currencyCode: settings.baseCurrency.rawValue,
                                    totalCurrencyCode: settings.baseCurrency.rawValue,
                                    hasAnimatedEntrance: $hasAnimatedPortfolioChart,
                                    onCategoryTap: { category in
                                        selectedCategory = category
                                    }
                                )
                            }
                            .appListRow()
                        }
                    }

                    let liabilityAllocationRows = viewModel.liabilityAllocationRows(
                        liabilities,
                        targetCurrency: settings.baseCurrency
                    )
                    if !liabilityAllocationRows.isEmpty {
                        Section(header: PillLabel("Liabilities")) {
                            AppListCard {
                                LiabilityAllocationView(
                                    rows: liabilityAllocationRows,
                                    currencyCode: settings.baseCurrency.rawValue,
                                    hasAnimatedEntrance: $hasAnimatedLiabilityChart
                                )
                            }
                            .appListRow()
                        }
                    }

                    Section {
                        AppListCard {
                            DashboardNetWorthTotalsView(
                                totals: Array(
                                    viewModel.totalsByCurrency(
                                        assets,
                                        liabilities: liabilities,
                                        baseCurrency: settings.baseCurrency,
                                        displayCurrencies: settings.totalCurrencies
                                    )
                                    .prefix(3)
                                ),
                                rateStatus: viewModel.rateStatus,
                                useCompactFormatting: settings.usesCompactCurrencyTotals
                            )
                        }
                        .appListRow()
                    } header: {
                        HStack {
                            PillLabel("Global Net Worth")
                            Spacer()
                            HStack(spacing: 6) {
                                Text("Compact")
                                    .font(.footnote)
                                Toggle("Compact", isOn: $settings.usesCompactCurrencyTotals)
                                    .tint(.accentColor)
                                    .labelsHidden()
                            }
                        }
                    }

                    Section {
                        AppListCard {
                            TransferRateWidgetView(
                                rows: viewModel.transferRateRows(
                                    baseCurrency: settings.baseCurrency,
                                    displayCurrencies: settings.totalCurrencies,
                                    limit: 3
                                ),
                                baseCurrency: settings.baseCurrency
                            )
                        }
                        .appListRow()
                    }

                    Section(header: PillLabel("Trend")) {
                        AppListCard {
                            DashboardTrendView(
                                portfolioRows: viewModel.portfolioTrendRows(
                                    portfolioSnapshots,
                                    baseCurrency: settings.baseCurrency
                                ),
                                netWorthRows: viewModel.netWorthTrendRows(
                                    netWorthSnapshots,
                                    baseCurrency: settings.baseCurrency
                                ),
                                currencyCode: settings.baseCurrency.rawValue,
                                onViewFullHistory: {
                                    showNetWorthHistory = true
                                }
                            )
                        }
                        .appListRow()

                    }

                    let historyRows = viewModel.recentAssetHistoryRows(assetValueSnapshots)
                    if !historyRows.isEmpty {
                        Section(header: PillLabel("History")) {
                            AppListCard {
                                AssetHistoryListView(rows: historyRows)
                            }
                            .appListRow()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RadialDotBackground(dotRadius: 1, spacing: 20)
                    .ignoresSafeArea(.all)
                contentView
            }
            .navigationTitle("My Assets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Add Asset", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(
                isPresented: $showAddSheet,
                onDismiss: {
                    viewModel.selectedAsset = nil
                },
                content: {
                    AddorEditAssetView()
                }
            )
            .navigationDestination(item: $selectedCategory) { category in
                CategoryDetailView(category: category, settings: settings)
            }
            .navigationDestination(isPresented: $showNetWorthHistory) {
                NetWorthHistoryView(settings: settings)
            }
        }
        .coordinatePortfolioHistory(coordinator)
        .task(id: "metalRates") {
            await metalViewModel.refreshIfNeeded()
            viewModel.enrichWithMetalRates(metalViewModel.metalRates)
        }
    }
}

struct NetWorthView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var assets: [Asset]
    @Query private var liabilities: [Liability]
    @Query private var netWorthSnapshots: [NetWorthSnapshot]
    @Query private var portfolioSnapshots: [PortfolioSnapshot]
    @Query private var assetValueSnapshots: [AssetValueSnapshot]
    @Bindable var settings: AppSettings

    @State private var viewModel = DashboardViewModel()
    @State private var metalViewModel = MetalPricesViewModel()
    @State private var showNetWorthHistory = false

    private var coordinator: PortfolioHistoryCoordinator {
        PortfolioHistoryCoordinator(
            assets: assets,
            liabilities: liabilities,
            netWorthSnapshots: netWorthSnapshots,
            assetValueSnapshots: assetValueSnapshots,
            settings: settings,
            viewModel: viewModel,
            modelContext: modelContext
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RadialDotBackground(dotRadius: 1, spacing: 20)
                    .ignoresSafeArea(.all)

                if assets.isEmpty && liabilities.isEmpty {
                    ContentUnavailableView(
                        "No Net Worth Data",
                        systemImage: "banknote",
                        description: Text("Add assets or liabilities to calculate net worth.")
                    )
                } else {
                    List {
                        Section {
                            AppListCard {
                                DashboardNetWorthTotalsView(
                                    totals: viewModel.totalsByCurrency(
                                        assets,
                                        liabilities: liabilities,
                                        baseCurrency: settings.baseCurrency,
                                        displayCurrencies: settings.totalCurrencies
                                    ),
                                    rateStatus: viewModel.rateStatus,
                                    useCompactFormatting: settings.usesCompactCurrencyTotals
                                )
                            }
                            .appListRow()
                        } header: {
                            HStack {
                                PillLabel("Net Worth")
                                Spacer()
                                HStack(spacing: 6) {
                                    Text("Compact")
                                        .font(.footnote)
                                    Toggle("Compact", isOn: $settings.usesCompactCurrencyTotals)
                                        .tint(.accentColor)
                                        .labelsHidden()
                                }
                            }
                        }

                        Section(header: PillLabel("Trend")) {
                            AppListCard {
                                DashboardTrendView(
                                    portfolioRows: viewModel.portfolioTrendRows(
                                        portfolioSnapshots,
                                        baseCurrency: settings.baseCurrency
                                    ),
                                    netWorthRows: viewModel.netWorthTrendRows(
                                        netWorthSnapshots,
                                        baseCurrency: settings.baseCurrency
                                    ),
                                    currencyCode: settings.baseCurrency.rawValue,
                                    onViewFullHistory: {
                                        showNetWorthHistory = true
                                    }
                                )
                            }
                            .appListRow()
                        }

                        let historyRows = viewModel.recentAssetHistoryRows(assetValueSnapshots)
                        if !historyRows.isEmpty {
                            Section(header: PillLabel("History")) {
                                AppListCard {
                                    AssetHistoryListView(rows: historyRows)
                                }
                                .appListRow()
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Global Net Worth")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.fetchExchangeRate(
                                requiredCurrencies: coordinator.requiredExchangeRateCurrencies
                            )
                            coordinator.recordPortfolioHistory()
                        }
                    } label: {
                        Label("Refresh Rates", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoadingRate)
                }
            }
            .navigationDestination(isPresented: $showNetWorthHistory) {
                NetWorthHistoryView(settings: settings)
            }
        }
        .coordinatePortfolioHistory(coordinator)
        .task(id: "metalRates") {
            await metalViewModel.refreshIfNeeded()
            viewModel.enrichWithMetalRates(metalViewModel.metalRates)
        }
    }
}
