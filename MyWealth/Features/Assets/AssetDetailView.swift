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
    @State private var isShowingManualValueEntry = false

    private var assetTitle: String {
        asset.displayName.isEmpty ? "Unnamed Asset" : asset.displayName
    }

    private var requiredExchangeRateCurrencies: [Asset.CurrencyType] {
        [settings.baseCurrency] + settings.totalCurrencies + calculationAssets.compactMap(\.currency) + [asset.currency].compactMap { $0 }
    }

    private var calculationAssets: [Asset] {
        settings.portfolioCalculationAssets(from: allAssets)
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
            calculationAssets,
            to: settings.baseCurrency,
            exchangeRates: viewModel.exchangeRates
        )
    }

    private var convertedCategoryAmount: Double? {
        let categoryAssets = calculationAssets.filter { $0.displayCategory == asset.displayCategory }
        return viewModel.convertedTotal(
            categoryAssets,
            to: settings.baseCurrency,
            exchangeRates: viewModel.exchangeRates
        )
    }

    private var portfolioShare: Double? {
        guard asset.participatesInPortfolioCalculations || settings.includeIgnoredAssetsInPortfolio else {
            return nil
        }
        return share(of: convertedAssetAmount, in: convertedPortfolioAmount)
    }

    private var categoryShare: Double? {
        guard asset.participatesInPortfolioCalculations || settings.includeIgnoredAssetsInPortfolio else {
            return nil
        }
        return share(of: convertedAssetAmount, in: convertedCategoryAmount)
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
                            baseCurrency: settings.baseCurrency
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
                        AssetDetailHistoryView(
                            rows: historyRows,
                            showLogButton: asset.displayCategory.supportsManualValueHistory,
                            onLogValue: { isShowingManualValueEntry = true }
                        )
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

                    if asset.displayCategory.supportsManualValueHistory {
                        Button {
                            isShowingManualValueEntry = true
                        } label: {
                            Label("Log Value", systemImage: "plus.circle")
                        }
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
        .sheet(isPresented: $isShowingManualValueEntry) {
            ManualValueEntryView(asset: asset)
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
                    .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous)
                            .strokeBorder(WealthMapDesignTokens.ColorToken.brandPrimary.opacity(0.4), lineWidth: 1)
                    )
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
            }

            if asset.displayCategory.supportsManualValueHistory {
                Button {
                    isShowingManualValueEntry = true
                } label: {
                    Label("Log Value", systemImage: "plus.circle")
                        .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous)
                                .strokeBorder(WealthMapDesignTokens.ColorToken.success.opacity(0.5), lineWidth: 1)
                        )
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.success)
                }
            }

            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous)
                            .strokeBorder(WealthMapDesignTokens.ColorToken.danger.opacity(0.4), lineWidth: 1)
                    )
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.danger)
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
                .font(WealthMapDesignTokens.Typography.amountProminent)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                .frame(width: 46, height: 46)
                .background(WealthMapDesignTokens.ColorToken.brandPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.compactRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(WealthMapDesignTokens.Typography.amountProminent)
                    .lineLimit(2)
                Text(asset.displayCategory.rawValue)
                    .font(WealthMapDesignTokens.Typography.subheadline)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)

                if !asset.participatesInPortfolioCalculations {
                    Label("Marked ignored", systemImage: "eye.slash.fill")
                        .font(WealthMapDesignTokens.Typography.compactLabel)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.warning)
                }
            }

            Spacer(minLength: 0)
        }
    }
}

private struct AssetValueSummaryView: View {
    let asset: Asset
    let convertedAmount: Double?
    let baseCurrency: Asset.CurrencyType

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
        }
    }

    @ViewBuilder
    private var baseValueText: some View {
        if let convertedAmount {
            Text(convertedAmount, format: .currency(code: baseCurrency.rawValue))
        } else {
            Text("Unavailable")
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
        }
    }

    private func metricRow(title: String, value: some View) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(WealthMapDesignTokens.Typography.subheadline)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
            Spacer(minLength: 8)
            value
                .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
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
                    .font(WealthMapDesignTokens.Typography.subheadlineMedium)
                Spacer()
                if let share {
                    Text(share, format: .percent.precision(.fractionLength(0)))
                        .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                } else {
                    Text("Unavailable")
                        .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                }
            }

            ProgressView(value: clamped(share ?? 0))
                .tint(WealthMapDesignTokens.ColorToken.brandPrimary)

            if let totalAmount {
                Text("Total: \(totalAmount.formatted(.currency(code: currencyCode)))")
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
            }
        }
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

private struct AssetDetailHistoryView: View {
    let rows: [AssetHistoryRow]
    var showLogButton: Bool = false
    var onLogValue: () -> Void = {}

    private var chartRows: [AssetHistoryRow] {
        rows.sorted { $0.recordedAt < $1.recordedAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if rows.isEmpty {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text(
                        showLogButton
                            ? "Tap \"Log Value\" to record your first valuation."
                            : "Value changes will appear here after this asset is updated."
                    )
                )
                .frame(maxWidth: .infinity)

                if showLogButton {
                    Button(action: onLogValue) {
                        Label("Log Value", systemImage: "plus.circle")
                            .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(WealthMapDesignTokens.ColorToken.success.opacity(0.10), in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.controlRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.controlRadius, style: .continuous)
                                    .strokeBorder(WealthMapDesignTokens.ColorToken.success.opacity(0.4), lineWidth: 1)
                            )
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.success)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Chart(chartRows) { row in
                    if chartRows.count == 1 {
                        PointMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Value", row.amount)
                        )
                        .symbolSize(70)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                    } else {
                        LineMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Value", row.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)

                        AreaMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Value", row.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary.opacity(0.12))
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
                        AssetHistoryRowView(row: row)
                    }
                }

                if showLogButton {
                    Button(action: onLogValue) {
                        Label("Log Value", systemImage: "plus.circle")
                            .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(WealthMapDesignTokens.ColorToken.success.opacity(0.10), in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.controlRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.controlRadius, style: .continuous)
                                    .strokeBorder(WealthMapDesignTokens.ColorToken.success.opacity(0.4), lineWidth: 1)
                            )
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.success)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct AssetHistoryRowView: View {
    let row: AssetHistoryRow

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if row.isManual {
                        Image(systemName: "pencil.circle.fill")
                            .font(WealthMapDesignTokens.Typography.caption)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.success)
                    }
                    // Manual entries show date-only (user picked a day, not a time).
                    // Auto entries show date + time for precision.
                    if row.isManual {
                        Text(row.recordedAt, format: .dateTime.month(.abbreviated).day().year())
                            .font(WealthMapDesignTokens.Typography.subheadlineMedium)
                    } else {
                        Text(row.recordedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                            .font(WealthMapDesignTokens.Typography.subheadlineMedium)
                    }
                }
                Text(row.isManual ? "Manual entry" : row.categoryName)
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                if let note = row.note, !note.isEmpty {
                    Text(note)
                        .font(WealthMapDesignTokens.Typography.caption)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(row.amount, format: .currency(code: row.currencyCode.isEmpty ? "USD" : row.currencyCode))
                .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                .monospacedDigit()
        }
    }
}

private struct AssetDetailCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(WealthMapDesignTokens.Spacing.standard)
            .wealthMapCardBackground()
        .frame(maxWidth: .infinity)
    }
}

private extension View {
    func assetDetailListRow() -> some View {
        listRowBackground(WealthMapDesignTokens.ColorToken.surfaceClear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
}
