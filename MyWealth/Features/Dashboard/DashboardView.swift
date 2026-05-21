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
    @Query private var netWorthSnapshots: [NetWorthSnapshot]
    @Query private var assetValueSnapshots: [AssetValueSnapshot]
    @Bindable var settings: AppSettings
    
    @State private var showAddSheet = false
    @State private var hasAnimatedPortfolioChart = false
    @State private var viewModel = DashboardViewModel()

    private var assetSnapshotSignature: String {
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

    private var rateSnapshotSignature: String {
        viewModel.exchangeRates
            .sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value)" }
            .joined(separator: "|")
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            if assets.isEmpty {
                ContentUnavailableView(
                    "No Assets",
                    systemImage: "banknote",
                    description: Text("Tap '+' to add your first asset.")
                )
            } else {
                List {
                    Section(header: PillLabel("Allocation")) {
                        DashboardCard {
                            PortfolioAllocationView(
                                rows: viewModel.categoryAllocationRows(assets),
                                portfolioTotal: viewModel.convertedTotal(
                                    assets,
                                    to: settings.baseCurrency,
                                    exchangeRates: viewModel.exchangeRates
                                ),
                                currencyCode: Asset.CurrencyType.usd.rawValue,
                                totalCurrencyCode: settings.baseCurrency.rawValue,
                                hasAnimatedEntrance: $hasAnimatedPortfolioChart
                            )
                        }
                        .dashboardListRow()
                    }
                    Section {
                        DashboardCard {
                            VStack(spacing: 10) {
                                CurrencyTotalsView(
                                    totals: viewModel.totalsByCurrency(
                                        assets,
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

                    Section(footer: FooterView(
                        model: viewModel.getFooterData(
                            assets,
                            baseCurrency: settings.baseCurrency,
                            displayCurrencies: settings.totalCurrencies
                        )
                    )) {
                        DashboardCard {
                            TransferRateWidgetView(
                                rows: viewModel.transferRateRows(
                                    baseCurrency: settings.baseCurrency,
                                    displayCurrencies: settings.totalCurrencies
                                ),
                                baseCurrency: settings.baseCurrency,
                                lastUpdated: viewModel.lastUpdated
                            )
                        }
                        .dashboardListRow()
                    }

                    Section(header: PillLabel("Trend")) {
                        DashboardCard {
                            NetWorthTrendChartView(
                                rows: viewModel.netWorthTrendRows(
                                    netWorthSnapshots,
                                    baseCurrency: settings.baseCurrency
                                ),
                                currencyCode: settings.baseCurrency.rawValue
                            )
                        }
                        .dashboardListRow()
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
        }
        .task {
            await viewModel.refreshExchangeRateIfNeeded()
            recordPortfolioHistory()
        }
        .onChange(of: assetSnapshotSignature) {
            recordPortfolioHistory()
        }
        .onChange(of: settings.baseCurrency) {
            recordPortfolioHistory()
        }
        .onChange(of: rateSnapshotSignature) {
            recordPortfolioHistory()
        }
    }

    private func recordPortfolioHistory() {
        viewModel.recordPortfolioHistory(
            assets: assets,
            baseCurrency: settings.baseCurrency,
            netWorthSnapshots: netWorthSnapshots,
            assetValueSnapshots: assetValueSnapshots,
            modelContext: modelContext
        )
    }
}

private struct DashboardCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

            content
                .padding(12)
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

private struct NetWorthTrendChartView: View {
    let rows: [NetWorthTrendRow]
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Net Worth")
                    .font(.headline)
                Spacer()
                if let latest = rows.last {
                    Text(latest.amount, format: .currency(code: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Chart(rows) { row in
                if rows.count == 1 {
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
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Portfolio")
                    .font(.headline)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let portfolioTotal {
                        Text(portfolioTotal, format: .currency(code: totalCurrencyCode))
                            .font(.headline.weight(.semibold))
                            .monospacedDigit()
                    } else {
                        Text("Unavailable")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
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
