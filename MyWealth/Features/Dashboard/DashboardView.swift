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
    @Query private var netWorthGoals: [NetWorthGoal]
    @Bindable var settings: AppSettings

    @State private var showAddSheet = false
    @State private var showNetWorthHistory = false
    @State private var hasAnimatedPortfolioChart = false
    @State private var hasAnimatedLiabilityChart = false
    @State private var selectedCategory: Asset.CategoryType? = nil
    @State private var viewModel = DashboardViewModel()
    @State private var metalViewModel = MetalPricesViewModel()
    @State private var showSettings = false
    @State private var showFIRECalculator = false
    @State private var showNetWorthGoalForm = false
    @State private var shareSummaryText: String? = nil
    @State private var didLogDashboardView = false

    private var activeGoal: NetWorthGoal? {
        NetWorthGoalStore.canonicalGoal(from: netWorthGoals)
    }

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
                VStack(spacing: 20) {
                    ContentUnavailableView(
                        "No Assets or Debt",
                        systemImage: "banknote",
                        description: Text("Add assets or liabilities to start tracking net worth.")
                    )
                    Button(activeGoal == nil ? "Set a Net Worth Goal" : "Manage Net Worth Goal") {
                        showNetWorthGoalForm = true
                    }
                    .buttonStyle(.bordered)
                }
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
                        Button {
                            showNetWorthGoalForm = true
                        } label: {
                            AppListCard {
                                goalContent
                            }
                        }
                        .buttonStyle(.plain)
                        .appListRow()
                        .listRowSeparator(.hidden)

                        Button {
                            showFIRECalculator = true
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

                        Button {
                            shareSummaryText = dashboardShareSummary()
                        } label: {
                            AppListCard {
                                HStack(spacing: 14) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title2)
                                        .foregroundStyle(.accent)
                                        .frame(width: 42, height: 42)
                                        .background(Color.accentColor.opacity(0.12), in: Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Share Progress")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(shareProgressSubtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(dashboardShareSummary() == nil)
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
                    AddorEditAssetView(sourceScreen: .dashboard)
                }
            )
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings, showsDoneButton: true)
            }
            .sheet(isPresented: Binding(
                get: { shareSummaryText != nil },
                set: { if !$0 { shareSummaryText = nil } }
            )) {
                if let shareSummaryText {
                    ActivityItemsView(items: [shareSummaryText])
                        .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $showNetWorthGoalForm) {
                NetWorthGoalFormView(
                    goal: activeGoal,
                    defaultCurrency: settings.baseCurrency,
                    assets: portfolioAssets,
                    liabilities: liabilities,
                    exchangeRates: viewModel.exchangeRates,
                    ratesAreStale: viewModel.ratesAreStale,
                    useCompactFormatting: settings.usesCompactCurrencyTotals,
                    sourceScreen: .dashboard
                )
            }
            .navigationDestination(item: $selectedCategory) { category in
                CategoryDetailView(category: category, settings: settings)
            }
            .navigationDestination(isPresented: $showFIRECalculator) {
                FIRECalculatorView(settings: settings)
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
        .onAppear {
            logDashboardViewedIfNeeded()
        }
    }

    private func logDashboardViewedIfNeeded() {
        guard !didLogDashboardView else { return }
        didLogDashboardView = true
        AnalyticsService.shared.log(
            .dashboardViewed,
            parameters: [.sourceScreen: AnalyticsService.SourceScreen.dashboard.rawValue]
        )
    }

    private var shareProgressSubtitle: String {
        dashboardShareSummary() == nil
            ? "Available after totals can be calculated"
            : "Share a text milestone you control"
    }

    private func dashboardShareSummary() -> String? {
        guard let netWorth = viewModel.netWorthTotal(
            portfolioAssets,
            liabilities: liabilities,
            to: settings.baseCurrency,
            exchangeRates: viewModel.exchangeRates
        ) else {
            return nil
        }

        if let goal = activeGoal {
            let calculator = NetWorthGoalCalculator()
            let progress = calculator.progress(
                goal: goal,
                assets: portfolioAssets,
                liabilities: liabilities,
                exchangeRates: viewModel.exchangeRates,
                ratesAreStale: viewModel.ratesAreStale
            )
            return PortfolioShareSummaryBuilder.build(
                netWorth: netWorth,
                baseCurrency: settings.baseCurrency,
                goal: goal,
                goalProgressFraction: progress.rawFraction
            )
        }

        return PortfolioShareSummaryBuilder.build(
            netWorth: netWorth,
            baseCurrency: settings.baseCurrency
        )
    }

    @ViewBuilder
    private var goalContent: some View {
        if let goal = activeGoal {
            let calculator = NetWorthGoalCalculator()
            let progress = calculator.progress(
                goal: goal,
                assets: portfolioAssets,
                liabilities: liabilities,
                exchangeRates: viewModel.exchangeRates,
                ratesAreStale: viewModel.ratesAreStale
            )
            NetWorthGoalCard(
                goal: goal,
                progress: progress,
                outlook: calculator.outlook(
                    goal: goal,
                    progress: progress,
                    snapshots: netWorthSnapshots,
                    exchangeRates: viewModel.exchangeRates
                ),
                achievementPlan: calculator.achievementPlan(goal: goal, progress: progress),
                useCompactFormatting: settings.usesCompactCurrencyTotals
            )
        } else {
            NetWorthGoalInvitationCard()
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
    @Query private var netWorthGoals: [NetWorthGoal]
    @Bindable var settings: AppSettings

    @State private var viewModel = DashboardViewModel()
    @State private var metalViewModel = MetalPricesViewModel()
    @State private var showNetWorthHistory = false
    @State private var showNetWorthGoalForm = false
    @State private var didLogNetWorthView = false
    @AppStorage("netWorthComfort.householdMembers") private var comfortHouseholdMembers = 1
    @AppStorage("netWorthComfort.monthlyIncome") private var comfortMonthlyIncome = 0.0
    @AppStorage("netWorthComfort.expectedMonthlySpend") private var comfortExpectedMonthlySpend = 0.0
    @AppStorage("netWorthComfort.monthlyIncomeWasProvided") private var comfortMonthlyIncomeWasProvided = false
    @AppStorage("netWorthComfort.expectedMonthlySpendWasProvided") private var comfortExpectedMonthlySpendWasProvided = false

    private var portfolioAssets: [Asset] {
        settings.portfolioCalculationAssets(from: assets)
    }

    private var activeGoal: NetWorthGoal? {
        NetWorthGoalStore.canonicalGoal(from: netWorthGoals)
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
                    VStack(spacing: 20) {
                        ContentUnavailableView(
                            "No Net Worth Data",
                            systemImage: "banknote",
                            description: Text("Add assets or liabilities to calculate net worth.")
                        )
                        Button(activeGoal == nil ? "Set a Net Worth Goal" : "Manage Net Worth Goal") {
                            showNetWorthGoalForm = true
                        }
                        .buttonStyle(.bordered)
                    }
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

                        Section(header: PillLabel("Goal")) {
                            Button {
                                showNetWorthGoalForm = true
                            } label: {
                                AppListCard {
                                    netWorthGoalContent
                                }
                            }
                            .buttonStyle(.plain)
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
            .sheet(isPresented: $showNetWorthGoalForm) {
                NetWorthGoalFormView(
                    goal: activeGoal,
                    defaultCurrency: settings.baseCurrency,
                    assets: portfolioAssets,
                    liabilities: liabilities,
                    exchangeRates: viewModel.exchangeRates,
                    ratesAreStale: viewModel.ratesAreStale,
                    useCompactFormatting: settings.usesCompactCurrencyTotals,
                    sourceScreen: .netWorth
                )
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
        .onAppear {
            logNetWorthViewedIfNeeded()
        }
    }

    private func logNetWorthViewedIfNeeded() {
        guard !didLogNetWorthView else { return }
        didLogNetWorthView = true
        AnalyticsService.shared.log(
            .netWorthSummaryViewed,
            parameters: [.sourceScreen: AnalyticsService.SourceScreen.netWorth.rawValue]
        )
    }

    @ViewBuilder
    private var netWorthGoalContent: some View {
        if let goal = activeGoal {
            let calculator = NetWorthGoalCalculator()
            let progress = calculator.progress(
                goal: goal,
                assets: portfolioAssets,
                liabilities: liabilities,
                exchangeRates: viewModel.exchangeRates,
                ratesAreStale: viewModel.ratesAreStale
            )
            NetWorthGoalCard(
                goal: goal,
                progress: progress,
                outlook: calculator.outlook(
                    goal: goal,
                    progress: progress,
                    snapshots: netWorthSnapshots,
                    exchangeRates: viewModel.exchangeRates
                ),
                achievementPlan: calculator.achievementPlan(goal: goal, progress: progress),
                useCompactFormatting: settings.usesCompactCurrencyTotals
            )
        } else {
            NetWorthGoalInvitationCard()
        }
    }
}
