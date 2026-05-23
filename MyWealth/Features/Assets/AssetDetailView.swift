import SwiftUI
import SwiftData
import Charts

struct AssetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allAssets: [Asset]
    @Query private var assetValueSnapshots: [AssetValueSnapshot]

    let asset: Asset
    @Bindable var settings: AppSettings

    @State private var viewModel = DashboardViewModel()
    @State private var metalViewModel = MetalPricesViewModel()
    @State private var isShowingEditSheet = false
    @State private var isShowingDeleteConfirmation = false

    private var assetTitle: String {
        asset.displayName.isEmpty ? "Unnamed Asset" : asset.displayName
    }

    private var requiredExchangeRateCurrencies: [Asset.CurrencyType] {
        [settings.baseCurrency] + settings.totalCurrencies + allAssets.compactMap(\.currency)
    }

    private var historyRows: [AssetHistoryRow] {
        viewModel.assetHistoryRows(
            for: asset,
            snapshots: assetValueSnapshots,
            limit: 20
        )
    }

    private var convertedAssetAmount: Double? {
        viewModel.convertedTotal(
            [asset],
            to: settings.baseCurrency,
            exchangeRates: viewModel.exchangeRates
        )
    }

    private var convertedPortfolioAmount: Double? {
        viewModel.convertedTotal(
            allAssets,
            to: settings.baseCurrency,
            exchangeRates: viewModel.exchangeRates
        )
    }

    private var convertedCategoryAmount: Double? {
        let categoryAssets = allAssets.filter { $0.displayCategory == asset.displayCategory }
        return viewModel.convertedTotal(
            categoryAssets,
            to: settings.baseCurrency,
            exchangeRates: viewModel.exchangeRates
        )
    }

    private var portfolioShare: Double? {
        share(of: convertedAssetAmount, in: convertedPortfolioAmount)
    }

    private var categoryShare: Double? {
        share(of: convertedAssetAmount, in: convertedCategoryAmount)
    }

    var body: some View {
        ZStack {
            RadialDotBackground(dotRadius: 1, spacing: 20)
                .ignoresSafeArea(.all)

            List {
                Section {
                    AssetDetailCard {
                        AssetDetailHeaderView(asset: asset, title: assetTitle)
                    }
                    .assetDetailListRow()
                }

                Section(header: PillLabel("Value")) {
                    AssetDetailCard {
                        AssetValueSummaryView(
                            asset: asset,
                            convertedAmount: convertedAssetAmount,
                            baseCurrency: settings.baseCurrency,
                            lastUpdated: asset.lastUpdated
                        )
                    }
                    .assetDetailListRow()
                }

                Section(header: PillLabel("Allocation")) {
                    AssetDetailCard {
                        AssetAllocationSummaryView(
                            portfolioShare: portfolioShare,
                            categoryShare: categoryShare,
                            categoryName: asset.displayCategory.rawValue,
                            categoryAmount: convertedCategoryAmount,
                            portfolioAmount: convertedPortfolioAmount,
                            currencyCode: settings.baseCurrency.rawValue
                        )
                    }
                    .assetDetailListRow()
                }

                Section(header: PillLabel("History")) {
                    AssetDetailCard {
                        AssetDetailHistoryView(rows: historyRows)
                    }
                    .assetDetailListRow()
                }
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
        .navigationTitle(assetTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isShowingEditSheet = true
                    } label: {
                        Label("Edit Asset", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label("Delete Asset", systemImage: "trash")
                    }
                } label: {
                    Label("Asset Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            AddorEditAssetView(asset: asset)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomActionBar
        }
        .confirmationDialog(
            "Delete Asset?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Asset", role: .destructive) {
                modelContext.delete(asset)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the asset from your current portfolio. Existing history snapshots are kept.")
        }
        .task {
            // Fetch forex and metal rates in parallel, then enrich the view model
            // so metal-currency assets (XAU, XAG, XPT, XPD, XRH) are valued correctly.
            async let forex: () = viewModel.refreshExchangeRateIfNeeded(
                requiredCurrencies: requiredExchangeRateCurrencies
            )
            async let metals: () = metalViewModel.refreshIfNeeded()
            _ = await (forex, metals)
            viewModel.enrichWithMetalRates(metalViewModel.metalRates)
        }
        .onChange(of: settings.baseCurrency) {
            Task {
                async let forex: () = viewModel.refreshExchangeRateIfNeeded(
                    requiredCurrencies: requiredExchangeRateCurrencies
                )
                async let metals: () = metalViewModel.refreshIfNeeded()
                _ = await (forex, metals)
                viewModel.enrichWithMetalRates(metalViewModel.metalRates)
            }
        }
    }

    private func share(of amount: Double?, in total: Double?) -> Double? {
        guard let amount, let total, total > 0 else {
            return nil
        }
        return amount / total
    }

    // MARK: - Bottom action bar

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            Button {
                isShowingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.accent.opacity(0.4), lineWidth: 1)
                    )
                    .foregroundStyle(.accent)
            }

            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.red.opacity(0.4), lineWidth: 1)
                    )
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

private struct AssetDetailHeaderView: View {
    let asset: Asset
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: asset.displayCategory.icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.accent)
                .frame(width: 46, height: 46)
                .background(.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                Text(asset.displayCategory.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct AssetValueSummaryView: View {
    let asset: Asset
    let convertedAmount: Double?
    let baseCurrency: Asset.CurrencyType
    let lastUpdated: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            metricRow(
                title: "Current Value",
                value: Text(asset.displayAmount, format: .currency(code: asset.displayCurrency.rawValue.isEmpty ? "USD" : asset.displayCurrency.rawValue))
            )

            metricRow(
                title: "Base Value",
                value: baseValueText
            )

            metricRow(
                title: "Currency",
                value: Text(asset.displayCurrency.displayText)
            )

            metricRow(
                title: "Last Updated",
                value: lastUpdatedText
            )
        }
    }

    @ViewBuilder
    private var baseValueText: some View {
        if let convertedAmount {
            Text(convertedAmount, format: .currency(code: baseCurrency.rawValue))
        } else {
            Text("Unavailable")
                .foregroundStyle(.secondary)
        }
    }

    private var lastUpdatedText: Text {
        if let lastUpdated {
            Text(lastUpdated, format: .dateTime.month(.abbreviated).day().year().hour().minute())
        } else {
            Text("Not recorded")
        }
    }

    private func metricRow(title: String, value: some View) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            value
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct AssetAllocationSummaryView: View {
    let portfolioShare: Double?
    let categoryShare: Double?
    let categoryName: String
    let categoryAmount: Double?
    let portfolioAmount: Double?
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            allocationRow(
                title: "Portfolio Share",
                share: portfolioShare,
                totalAmount: portfolioAmount
            )

            allocationRow(
                title: "\(categoryName) Share",
                share: categoryShare,
                totalAmount: categoryAmount
            )
        }
    }

    private func allocationRow(title: String, share: Double?, totalAmount: Double?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                if let share {
                    Text(share, format: .percent.precision(.fractionLength(0)))
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text("Unavailable")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: clamped(share ?? 0))
                .tint(.accent)

            if let totalAmount {
                Text("Total: \(totalAmount.formatted(.currency(code: currencyCode)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

private struct AssetDetailHistoryView: View {
    let rows: [AssetHistoryRow]

    private var chartRows: [AssetHistoryRow] {
        rows.sorted { $0.recordedAt < $1.recordedAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if rows.isEmpty {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Value changes will appear here after this asset is updated.")
                )
                .frame(maxWidth: .infinity)
            } else {
                Chart(chartRows) { row in
                    if chartRows.count == 1 {
                        PointMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Value", row.amount)
                        )
                        .symbolSize(70)
                        .foregroundStyle(.accent)
                    } else {
                        LineMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Value", row.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.accent)

                        AreaMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Value", row.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.accent.opacity(0.12))
                    }
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }

                VStack(spacing: 10) {
                    ForEach(rows.prefix(6)) { row in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.recordedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(.subheadline.weight(.medium))
                                Text(row.categoryName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(row.amount, format: .currency(code: row.currencyCode.isEmpty ? "USD" : row.currencyCode))
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
    }
}

private struct AssetDetailCard<Content: View>: View {
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
    func assetDetailListRow() -> some View {
        listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
}
