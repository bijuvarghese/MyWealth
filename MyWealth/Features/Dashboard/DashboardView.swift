//
//  ContentView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//


import SwiftUI
import SwiftData
import Charts

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
                        DashboardCard(
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
                        .dashboardListRow()
                    }

                    let insightRows = viewModel.portfolioInsightRows(
                        assets: assets,
                        liabilities: liabilities,
                        netWorthSnapshots: netWorthSnapshots,
                        baseCurrency: settings.baseCurrency
                    )
                    if !insightRows.isEmpty {
                        Section(header: PillLabel("Insights")) {
                            DashboardCard {
                                PortfolioInsightsView(rows: insightRows)
                            }
                            .dashboardListRow()
                        }
                    }

                    if !assets.isEmpty {
                        Section(header: PillLabel("Allocation")) {
                            DashboardCard {
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
                            .dashboardListRow()
                        }
                    }

                    let liabilityAllocationRows = viewModel.liabilityAllocationRows(
                        liabilities,
                        targetCurrency: settings.baseCurrency
                    )
                    if !liabilityAllocationRows.isEmpty {
                        Section(header: PillLabel("Liabilities")) {
                            DashboardCard {
                                LiabilityAllocationView(
                                    rows: liabilityAllocationRows,
                                    currencyCode: settings.baseCurrency.rawValue,
                                    hasAnimatedEntrance: $hasAnimatedLiabilityChart
                                )
                            }
                            .dashboardListRow()
                        }
                    }

                    Section {
                        DashboardCard {
                            VStack(spacing: 10) {
                                CurrencyTotalsView(
                                    totals: Array(
                                        viewModel.totalsByCurrency(
                                            assets,
                                            liabilities: liabilities,
                                            baseCurrency: settings.baseCurrency,
                                            displayCurrencies: settings.totalCurrencies
                                        )
                                        .prefix(3)
                                    ),
                                    useCompactFormatting: settings.usesCompactCurrencyTotals
                                )

                                if let rateStatus = viewModel.rateStatus {
                                    Divider()
                                    RateStatusBannerView(status: rateStatus)
                                }
                            }
                        }
                        .dashboardListRow()
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
                        DashboardCard {
                            TransferRateWidgetView(
                                rows: viewModel.transferRateRows(
                                    baseCurrency: settings.baseCurrency,
                                    displayCurrencies: settings.totalCurrencies,
                                    limit: 3
                                ),
                                baseCurrency: settings.baseCurrency
                            )
                        }
                        .dashboardListRow()
                    }

                    Section(header: PillLabel("Trend")) {
                        DashboardCard {
                            AssetVsLiabilityTrendChartView(
                                portfolioRows: viewModel.portfolioTrendRows(
                                    portfolioSnapshots,
                                    baseCurrency: settings.baseCurrency
                                ),
                                netWorthRows: viewModel.netWorthTrendRows(
                                    netWorthSnapshots,
                                    baseCurrency: settings.baseCurrency
                                ),
                                currencyCode: settings.baseCurrency.rawValue
                            )
                        }
                        .dashboardListRow()

                        Button {
                            showNetWorthHistory = true
                        } label: {
                            HStack {
                                Text("View Full History")
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    }

                    let historyRows = viewModel.recentAssetHistoryRows(assetValueSnapshots)
                    if !historyRows.isEmpty {
                        Section(header: PillLabel("History")) {
                            DashboardCard {
                                AssetHistoryListView(rows: historyRows)
                            }
                            .dashboardListRow()
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
                            DashboardCard {
                                VStack(spacing: 10) {
                                    CurrencyTotalsView(
                                        totals: viewModel.totalsByCurrency(
                                            assets,
                                            liabilities: liabilities,
                                            baseCurrency: settings.baseCurrency,
                                            displayCurrencies: settings.totalCurrencies
                                        ),
                                        useCompactFormatting: settings.usesCompactCurrencyTotals
                                    )

                                    if let rateStatus = viewModel.rateStatus {
                                        Divider()
                                        RateStatusBannerView(status: rateStatus)
                                    }
                                }
                            }
                            .dashboardListRow()
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
                            DashboardCard {
                                AssetVsLiabilityTrendChartView(
                                    portfolioRows: viewModel.portfolioTrendRows(
                                        portfolioSnapshots,
                                        baseCurrency: settings.baseCurrency
                                    ),
                                    netWorthRows: viewModel.netWorthTrendRows(
                                        netWorthSnapshots,
                                        baseCurrency: settings.baseCurrency
                                    ),
                                    currencyCode: settings.baseCurrency.rawValue
                                )
                            }
                            .dashboardListRow()

                            Button {
                                showNetWorthHistory = true
                            } label: {
                                HStack {
                                    Text("View Full History")
                                        .font(.subheadline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .foregroundStyle(.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        }

                        let historyRows = viewModel.recentAssetHistoryRows(assetValueSnapshots)
                        if !historyRows.isEmpty {
                            Section(header: PillLabel("History")) {
                                DashboardCard {
                                    AssetHistoryListView(rows: historyRows)
                                }
                                .dashboardListRow()
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

private struct DashboardCard<Content: View>: View {
    let content: Content
    let contentPadding: EdgeInsets

    init(
        contentPadding: EdgeInsets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.contentPadding = contentPadding
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

            content
                .padding(contentPadding)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension View {
    func dashboardListRow() -> some View {
        listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
}

private struct AssetVsLiabilityTrendChartView: View {
    let portfolioRows: [PortfolioTrendRow]
    let netWorthRows: [NetWorthTrendRow]
    let currencyCode: String

    private var useSplitData: Bool { !portfolioRows.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Net Worth")
                    .font(.headline)
                Spacer()
                if useSplitData, let latest = portfolioRows.last {
                    Text(latest.assetTotal - latest.liabilityTotal,
                         format: .currency(code: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else if let latest = netWorthRows.last {
                    Text(latest.amount, format: .currency(code: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if useSplitData {
                Chart {
                    ForEach(portfolioRows) { row in
                        LineMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Amount", row.assetTotal),
                            series: .value("Series", "Assets")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.green)

                        AreaMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Amount", row.assetTotal),
                            series: .value("Series", "Assets")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.green.opacity(0.10))

                        if portfolioRows.count == 1 {
                            PointMark(
                                x: .value("Date", row.recordedAt),
                                y: .value("Amount", row.assetTotal)
                            )
                            .symbolSize(70)
                            .foregroundStyle(.green)
                        }

                        LineMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Amount", row.liabilityTotal),
                            series: .value("Series", "Liabilities")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.red)

                        AreaMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Amount", row.liabilityTotal),
                            series: .value("Series", "Liabilities")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.red.opacity(0.10))

                        if portfolioRows.count == 1 {
                            PointMark(
                                x: .value("Date", row.recordedAt),
                                y: .value("Amount", row.liabilityTotal)
                            )
                            .symbolSize(70)
                            .foregroundStyle(.red)
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Assets": Color.green,
                    "Liabilities": Color.red
                ])
                .frame(height: 150)
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                .chartYAxis { AxisMarks(position: .leading) }
            } else {
                // Fallback: single net-worth line for users with no PortfolioSnapshot history yet.
                Chart(netWorthRows) { row in
                    if netWorthRows.count == 1 {
                        PointMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Net Worth", row.amount)
                        )
                        .symbolSize(70)
                        .foregroundStyle(.blue)
                    } else {
                        LineMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Net Worth", row.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.blue)

                        AreaMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Net Worth", row.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.blue.opacity(0.12))
                    }
                }
                .frame(height: 150)
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                .chartYAxis { AxisMarks(position: .leading) }
            }
        }
    }
}

private struct AssetLiabilitySummaryView: View {
    let assetTotal: Double?
    let liabilityTotal: Double?
    let netWorthTotal: Double?
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                SummaryMetricView(
                    title: "Assets",
                    systemImage: "plus.circle.fill",
                    amount: assetTotal,
                    currencyCode: currencyCode,
                    tint: .green
                )

                Divider()
                    .frame(height: 42)

                SummaryMetricView(
                    title: "Liabilities",
                    systemImage: "minus.circle.fill",
                    amount: liabilityTotal,
                    currencyCode: currencyCode,
                    tint: .red
                )
            }
            .padding(.horizontal, 12)

            HStack(alignment: .center, spacing: 2) {
                Text("Net Worth")
                Spacer()
                amountText(netWorthTotal)
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.yellow)
            .clipShape(.rect(bottomLeadingRadius: 12, bottomTrailingRadius: 12))
        }
    }

    @ViewBuilder
    private func amountText(_ amount: Double?) -> some View {
        if let amount {
            Text(amount, format: .currency(code: currencyCode))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        } else {
            Text("Unavailable")
                .foregroundStyle(.secondary)
        }
    }
}

private struct PortfolioInsightsView: View {
    let rows: [PortfolioInsightRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio Insights")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(rows) { row in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: row.systemImage)
                            .foregroundStyle(sentimentColor(row.sentiment))
                            .frame(width: 22)

                        Text(row.message)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(sentimentColor(row.sentiment).opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func sentimentColor(_ sentiment: PortfolioInsightRow.Sentiment) -> Color {
        switch sentiment {
        case .positive: return .green
        case .warning:  return .orange
        case .neutral:  return .accent
        }
    }
}

private struct SummaryMetricView: View {
    let title: String
    let systemImage: String
    let amount: Double?
    let currencyCode: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let amount {
                    Text(amount, format: .currency(code: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                } else {
                    Text("Unavailable")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PortfolioAllocationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chartProgress = 0.0

    let rows: [CategoryAllocationRow]
    let portfolioTotal: Double?
    let currencyCode: String
    let totalCurrencyCode: String
    @Binding var hasAnimatedEntrance: Bool
    var onCategoryTap: ((Asset.CategoryType) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Portfolio")
                    .font(.headline)

                Spacer()
            }

            Chart(rows) { row in
                SectorMark(
                    angle: .value("Amount", row.amount * chartProgress),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Category", row.category.rawValue))
            }
            .frame(height: 180)
            .chartLegend(position: .bottom, alignment: .leading)
            .onAppear {
                animateChart()
            }

            VStack(spacing: 8) {
                ForEach(rows) { row in
                    Button {
                        onCategoryTap?(row.category)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: row.category.icon)
                                .frame(width: 22)
                                .foregroundStyle(.secondary)
                            Text(row.category.rawValue)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(row.percentage, format: .percent.precision(.fractionLength(0)))
                                .foregroundStyle(.secondary)
                            Text(row.amount, format: .currency(code: currencyCode))
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .disabled(onCategoryTap == nil)
                }
            }
        }
    }

    private func animateChart() {
        guard !hasAnimatedEntrance else {
            chartProgress = 1
            return
        }

        hasAnimatedEntrance = true
        chartProgress = reduceMotion ? 1 : 0

        guard !reduceMotion else {
            return
        }

        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.85)) {
                chartProgress = 1
            }
        }
    }
}

private struct LiabilityAllocationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chartProgress = 0.0

    let rows: [LiabilityAllocationRow]
    let currencyCode: String
    @Binding var hasAnimatedEntrance: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Debt Breakdown")
                .font(.headline)

            Chart(rows) { row in
                SectorMark(
                    angle: .value("Amount", row.amount * chartProgress),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Category", row.category.rawValue))
            }
            .frame(height: 180)
            .chartLegend(position: .bottom, alignment: .leading)
            .onAppear {
                animateChart()
            }

            VStack(spacing: 8) {
                ForEach(rows) { row in
                    HStack(spacing: 10) {
                        Image(systemName: row.category.icon)
                            .frame(width: 22)
                            .foregroundStyle(.secondary)
                        Text(row.category.rawValue)
                        Spacer()
                        Text(row.percentage, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(.secondary)
                        Text(row.amount, format: .currency(code: currencyCode))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private func animateChart() {
        guard !hasAnimatedEntrance else {
            chartProgress = 1
            return
        }

        hasAnimatedEntrance = true
        chartProgress = reduceMotion ? 1 : 0

        guard !reduceMotion else {
            return
        }

        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.85)) {
                chartProgress = 1
            }
        }
    }
}

private struct AssetHistoryListView: View {
    let rows: [AssetHistoryRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Values")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(rows) { row in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.assetName.isEmpty ? "Unnamed Asset" : row.assetName)
                                .font(.subheadline.weight(.medium))
                            Text(row.recordedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(row.amount, format: .currency(code: row.currencyCode.isEmpty ? "USD" : row.currencyCode))
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                            Text(row.categoryName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

