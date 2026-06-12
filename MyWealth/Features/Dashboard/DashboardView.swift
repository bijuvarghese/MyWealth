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
    @Environment(\.scenePhase) private var scenePhase
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
    @State private var showSettings = false

    private var portfolioAssets: [Asset] {
        settings.portfolioCalculationAssets(from: assets)
    }

    private var coordinator: PortfolioHistoryCoordinator {
        PortfolioHistoryCoordinator(
            allAssets: assets,
            assets: portfolioAssets,
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
                                    portfolioAssets,
                                    to: settings.baseCurrency,
                                    exchangeRates: viewModel.exchangeRates
                                ),
                                liabilityTotal: viewModel.convertedLiabilityTotal(
                                    liabilities,
                                    to: settings.baseCurrency,
                                    exchangeRates: viewModel.exchangeRates
                                ),
                                netWorthTotal: viewModel.netWorthTotal(
                                    portfolioAssets,
                                    liabilities: liabilities,
                                    to: settings.baseCurrency,
                                    exchangeRates: viewModel.exchangeRates
                                ),
                                currencyCode: settings.baseCurrency.rawValue
                            )
                        }
                        .appListRow()
                    }

                    Section(header: PillLabel("Plan")) {
                        NavigationLink {
                            FIRECalculatorView(settings: settings)
                        } label: {
                            AppListCard {
                                HStack(spacing: 14) {
                                    Image(systemName: "flame.fill")
                                        .font(.title2)
                                        .foregroundStyle(.orange)
                                        .frame(width: 42, height: 42)
                                        .background(Color.orange.opacity(0.12), in: Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("FIRE Calculator")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("Model your financial independence target and timeline")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .appListRow()
                    }

                    let insightRows = viewModel.portfolioInsightRows(
                        assets: portfolioAssets,
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

                    if !portfolioAssets.isEmpty {
                        Section(header: PillLabel("Allocation")) {
                            AppListCard {
                                PortfolioAllocationView(
                                    rows: viewModel.categoryAllocationRows(
                                        portfolioAssets,
                                        targetCurrency: settings.baseCurrency
                                    ),
                                    portfolioTotal: viewModel.convertedTotal(
                                        portfolioAssets,
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
                                        portfolioAssets,
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle(isOn: $settings.includeIgnoredAssetsInPortfolio) {
                            Label("Include Ignored Assets", systemImage: "eye.slash")
                        }
                    } label: {
                        Image(systemName: settings.includeIgnoredAssetsInPortfolio
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle")
                    }
                }
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
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings, showsDoneButton: true)
            }
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
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await viewModel.refreshExchangeRateIfStale()
                await metalViewModel.refreshIfStale()
                viewModel.enrichWithMetalRates(metalViewModel.metalRates)
            }
        }
    }
}

struct NetWorthView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var assets: [Asset]
    @Query private var liabilities: [Liability]
    @Query private var netWorthSnapshots: [NetWorthSnapshot]
    @Query private var portfolioSnapshots: [PortfolioSnapshot]
    @Query private var assetValueSnapshots: [AssetValueSnapshot]
    @Bindable var settings: AppSettings

    @State private var viewModel = DashboardViewModel()
    @State private var metalViewModel = MetalPricesViewModel()
    @State private var showNetWorthHistory = false
    @AppStorage("netWorthComfort.householdMembers") private var comfortHouseholdMembers = 1
    @AppStorage("netWorthComfort.monthlyIncome") private var comfortMonthlyIncome = 0.0
    @AppStorage("netWorthComfort.expectedMonthlySpend") private var comfortExpectedMonthlySpend = 0.0
    @AppStorage("netWorthComfort.monthlyIncomeWasProvided") private var comfortMonthlyIncomeWasProvided = false
    @AppStorage("netWorthComfort.expectedMonthlySpendWasProvided") private var comfortExpectedMonthlySpendWasProvided = false

    private var portfolioAssets: [Asset] {
        settings.portfolioCalculationAssets(from: assets)
    }

    private var comfortAssumptions: Binding<LivingComfortAssumptions> {
        Binding {
            LivingComfortAssumptions(
                householdMembers: comfortHouseholdMembers,
                monthlyIncome: comfortMonthlyIncome,
                expectedMonthlySpend: comfortExpectedMonthlySpend,
                monthlyIncomeWasProvided: comfortMonthlyIncomeWasProvided || comfortMonthlyIncome > 0,
                expectedMonthlySpendWasProvided: comfortExpectedMonthlySpendWasProvided || comfortExpectedMonthlySpend > 0
            )
        } set: { assumptions in
            comfortHouseholdMembers = assumptions.safeHouseholdMembers
            comfortMonthlyIncome = max(assumptions.monthlyIncome, 0)
            comfortExpectedMonthlySpend = max(assumptions.expectedMonthlySpend, 0)
            comfortMonthlyIncomeWasProvided = assumptions.monthlyIncomeWasProvided
            comfortExpectedMonthlySpendWasProvided = assumptions.expectedMonthlySpendWasProvided
        }
    }

    private var coordinator: PortfolioHistoryCoordinator {
        PortfolioHistoryCoordinator(
            allAssets: assets,
            assets: portfolioAssets,
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
                        let netWorthTotals = viewModel.totalsByCurrency(
                            portfolioAssets,
                            liabilities: liabilities,
                            baseCurrency: settings.baseCurrency,
                            displayCurrencies: settings.totalCurrencies
                        )
                        Section(header: PillLabel("Country Comfort")) {
                            AppListCard {
                                NetWorthLivingComfortView(
                                    totals: netWorthTotals,
                                    baseCurrency: settings.baseCurrency,
                                    exchangeRates: viewModel.exchangeRates,
                                    assumptions: comfortAssumptions,
                                    collapsedRowLimit: 3
                                )
                            }
                            .appListRow()
                        }

                        Section {
                            AppListCard {
                                DashboardNetWorthTotalsView(
                                    totals: netWorthTotals,
                                    rateStatus: viewModel.rateStatus,
                                    useCompactFormatting: settings.usesCompactCurrencyTotals,
                                    collapsedRowLimit: 3
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
                    }
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Global Net Worth")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle(isOn: $settings.includeIgnoredAssetsInPortfolio) {
                            Label("Include Ignored Assets", systemImage: "eye.slash")
                        }
                    } label: {
                        Image(systemName: settings.includeIgnoredAssetsInPortfolio
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle")
                    }
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
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await viewModel.refreshExchangeRateIfStale()
                await metalViewModel.refreshIfStale()
                viewModel.enrichWithMetalRates(metalViewModel.metalRates)
            }
        }
    }
}
