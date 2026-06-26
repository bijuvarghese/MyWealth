//
//  NetWorthHistoryView.swift
//  MyWealth
//

import SwiftUI
import SwiftData
import Charts

struct NetWorthHistoryView: View {
    @Query private var portfolioSnapshots: [PortfolioSnapshot]
    @Query private var netWorthSnapshots: [NetWorthSnapshot]
    @Bindable var settings: AppSettings

    @State private var selectedRange: HistoryTimeRange = .all

    // MARK: - Filtered data

    private var filteredPortfolioRows: [PortfolioTrendRow] {
        let cutoff = selectedRange.cutoffDate
        return portfolioSnapshots
            .filter {
                $0.displayCurrencyCode == settings.baseCurrency.rawValue &&
                $0.displayRecordedAt >= cutoff
            }
            .sorted { $0.displayRecordedAt < $1.displayRecordedAt }
            .enumerated()
            .map { offset, s in
                PortfolioTrendRow(
                    id: "\(s.persistentModelID)-\(offset)",
                    recordedAt: s.displayRecordedAt,
                    assetTotal: s.displayAssetTotal,
                    liabilityTotal: s.displayLiabilityTotal,
                    currencyCode: s.displayCurrencyCode
                )
            }
    }

    private var filteredNetWorthRows: [NetWorthTrendRow] {
        let cutoff = selectedRange.cutoffDate
        return netWorthSnapshots
            .filter {
                $0.displayCurrencyCode == settings.baseCurrency.rawValue &&
                $0.displayRecordedAt >= cutoff
            }
            .sorted { $0.displayRecordedAt < $1.displayRecordedAt }
            .enumerated()
            .map { offset, s in
                NetWorthTrendRow(
                    id: "\(s.persistentModelID)-\(offset)",
                    recordedAt: s.displayRecordedAt,
                    amount: s.displayAmount,
                    currencyCode: s.displayCurrencyCode
                )
            }
    }

    private var useSplitData: Bool { !filteredPortfolioRows.isEmpty }

    private var currentNetWorth: Double? {
        filteredPortfolioRows.last.map { $0.assetTotal - $0.liabilityTotal }
        ?? filteredNetWorthRows.last?.amount
    }

    private var firstNetWorth: Double? {
        filteredPortfolioRows.first.map { $0.assetTotal - $0.liabilityTotal }
        ?? filteredNetWorthRows.first?.amount
    }

    private var netWorthChange: Double? {
        guard let current = currentNetWorth, let first = firstNetWorth else { return nil }
        return current - first
    }

    private var netWorthChangePercent: Double? {
        guard let change = netWorthChange, let first = firstNetWorth, first != 0 else { return nil }
        return change / abs(first)
    }

    private var peakNetWorth: Double? {
        let values = useSplitData
            ? filteredPortfolioRows.map { $0.assetTotal - $0.liabilityTotal }
            : filteredNetWorthRows.map(\.amount)
        return values.max()
    }

    private var hasData: Bool {
        !filteredPortfolioRows.isEmpty || !filteredNetWorthRows.isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            RadialDotBackground(dotRadius: 1, spacing: 20)
                .ignoresSafeArea(.all)

            if !hasData {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Net worth history will appear here as your portfolio data accumulates.")
                )
            } else {
                List {
                    // Range picker
                    Section {
                        Picker("Range", selection: $selectedRange) {
                            ForEach(HistoryTimeRange.allCases) { range in
                                Text(range.label).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(WealthMapDesignTokens.ColorToken.surfaceClear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }

                    // Key stats
                    Section {
                        historyCard {
                            NetWorthStatsView(
                                currentNetWorth: currentNetWorth,
                                change: netWorthChange,
                                changePercent: netWorthChangePercent,
                                peak: peakNetWorth,
                                currencyCode: settings.baseCurrency.rawValue,
                                rangeLabel: selectedRange.label
                            )
                        }
                    }
                    .listRowBackground(WealthMapDesignTokens.ColorToken.surfaceClear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                    // Main chart
                    Section(header: Text("Net Worth Over Time").font(WealthMapDesignTokens.Typography.subheadline).foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)) {
                        historyCard {
                            HistoryChartView(
                                portfolioRows: filteredPortfolioRows,
                                netWorthRows: filteredNetWorthRows,
                                currencyCode: settings.baseCurrency.rawValue
                            )
                        }
                    }
                    .listRowBackground(WealthMapDesignTokens.ColorToken.surfaceClear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                    // Data points table
                    let snapshotCount = useSplitData ? filteredPortfolioRows.count : filteredNetWorthRows.count
                    if snapshotCount > 0 {
                        Section(header: Text("\(snapshotCount) snapshot\(snapshotCount == 1 ? "" : "s")").font(WealthMapDesignTokens.Typography.subheadline).foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)) {
                            historyCard {
                                if useSplitData {
                                    PortfolioSnapshotTableView(
                                        rows: filteredPortfolioRows.reversed().prefix(20).map { $0 },
                                        currencyCode: settings.baseCurrency.rawValue
                                    )
                                } else {
                                    NetWorthSnapshotTableView(
                                        rows: filteredNetWorthRows.reversed().prefix(20).map { $0 },
                                        currencyCode: settings.baseCurrency.rawValue
                                    )
                                }
                            }
                        }
                        .listRowBackground(WealthMapDesignTokens.ColorToken.surfaceClear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Net Worth History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func historyCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: WealthMapDesignTokens.Elevation.cardShadowColor, radius: WealthMapDesignTokens.Elevation.cardShadowRadius, x: WealthMapDesignTokens.Elevation.cardShadowX, y: WealthMapDesignTokens.Elevation.cardShadowY)
            content()
                .padding(14)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(WealthMapDesignTokens.ColorToken.surfaceClear)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}

// MARK: - Time Range

enum HistoryTimeRange: String, CaseIterable, Identifiable {
    case oneWeek   = "1W"
    case oneMonth  = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear   = "1Y"
    case all       = "All"

    var id: String { rawValue }
    var label: String { rawValue }

    var cutoffDate: Date {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .oneWeek:     return cal.date(byAdding: .day,   value: -7,   to: now) ?? now
        case .oneMonth:    return cal.date(byAdding: .month, value: -1,   to: now) ?? now
        case .threeMonths: return cal.date(byAdding: .month, value: -3,   to: now) ?? now
        case .sixMonths:   return cal.date(byAdding: .month, value: -6,   to: now) ?? now
        case .oneYear:     return cal.date(byAdding: .year,  value: -1,   to: now) ?? now
        case .all:         return .distantPast
        }
    }
}

// MARK: - Stats Header

private struct NetWorthStatsView: View {
    let currentNetWorth: Double?
    let change: Double?
    let changePercent: Double?
    let peak: Double?
    let currencyCode: String
    let rangeLabel: String

    private var isPositive: Bool { (change ?? 0) >= 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Current value + change
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Worth")
                        .font(WealthMapDesignTokens.Typography.caption)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    if let current = currentNetWorth {
                        Text(current, format: .currency(code: currencyCode))
                            .font(WealthMapDesignTokens.Typography.amountProminent.weight(.bold))
                            .monospacedDigit()
                    } else {
                        Text("Unavailable")
                            .font(WealthMapDesignTokens.Typography.amountProminent.weight(.bold))
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    }
                }
                Spacer()
                if let change, let pct = changePercent {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(rangeLabel + " change")
                            .font(WealthMapDesignTokens.Typography.caption)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        HStack(spacing: 4) {
                            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                            Text(pct, format: .percent.precision(.fractionLength(1)))
                        }
                        .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                        .foregroundStyle(isPositive ? WealthMapDesignTokens.ColorToken.success : WealthMapDesignTokens.ColorToken.danger)
                        Text(change, format: .currency(code: currencyCode).sign(strategy: .always()))
                            .font(WealthMapDesignTokens.Typography.caption)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                            .monospacedDigit()
                    }
                }
            }

            Divider()

            // Peak
            if let peak = peak {
                HStack {
                    Label("Peak", systemImage: "chart.line.uptrend.xyaxis")
                        .font(WealthMapDesignTokens.Typography.caption)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    Spacer()
                    Text(peak, format: .currency(code: currencyCode))
                        .font(WealthMapDesignTokens.Typography.compactLabel)
                        .monospacedDigit()
                }
            }
        }
    }
}

// MARK: - History Chart

private struct HistoryChartView: View {
    let portfolioRows: [PortfolioTrendRow]
    let netWorthRows: [NetWorthTrendRow]
    let currencyCode: String

    private var useSplitData: Bool { !portfolioRows.isEmpty }

    var body: some View {
        if useSplitData {
            Chart {
                ForEach(portfolioRows) { row in
                    LineMark(
                        x: .value("Date", row.recordedAt),
                        y: .value("Amount", row.assetTotal),
                        series: .value("Series", "Assets")
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.success)

                    AreaMark(
                        x: .value("Date", row.recordedAt),
                        y: .value("Amount", row.assetTotal),
                        series: .value("Series", "Assets")
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.success.opacity(0.10))

                    LineMark(
                        x: .value("Date", row.recordedAt),
                        y: .value("Amount", row.liabilityTotal),
                        series: .value("Series", "Liabilities")
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.danger)

                    AreaMark(
                        x: .value("Date", row.recordedAt),
                        y: .value("Amount", row.liabilityTotal),
                        series: .value("Series", "Liabilities")
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.danger.opacity(0.10))
                }
            }
            .chartForegroundStyleScale([
                "Assets": WealthMapDesignTokens.ColorToken.success,
                "Liabilities": WealthMapDesignTokens.ColorToken.danger
            ])
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 220)
        } else {
            Chart(netWorthRows) { row in
                if netWorthRows.count == 1 {
                    PointMark(
                        x: .value("Date", row.recordedAt),
                        y: .value("Net Worth", row.amount)
                    )
                    .symbolSize(80)
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
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 220)
        }
    }
}

// MARK: - Snapshot Table

private struct PortfolioSnapshotTableView: View {
    let rows: [PortfolioTrendRow]
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Date")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Assets")
                    .frame(width: 90, alignment: .trailing)
                Text("Net Worth")
                    .frame(width: 90, alignment: .trailing)
            }
            .font(WealthMapDesignTokens.Typography.caption)
            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)

            Divider()

            ForEach(rows) { row in
                snapshotRow(for: row)
            }
        }
    }

    @ViewBuilder
    private func snapshotRow(for row: PortfolioTrendRow) -> some View {
        let netWorth = row.assetTotal - row.liabilityTotal
        HStack {
            Text(row.recordedAt, format: .dateTime.month(.abbreviated).day().year())
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(row.assetTotal, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .frame(width: 90, alignment: .trailing)
                .monospacedDigit()
            Text(netWorth, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .frame(width: 90, alignment: .trailing)
                .monospacedDigit()
                .foregroundStyle(netWorth >= 0 ? WealthMapDesignTokens.ColorToken.textPrimary : WealthMapDesignTokens.ColorToken.danger)
        }
        .font(WealthMapDesignTokens.Typography.caption)
    }
}

// MARK: - Net Worth Snapshot Table (fallback for pre-PortfolioSnapshot history)

private struct NetWorthSnapshotTableView: View {
    let rows: [NetWorthTrendRow]
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Date")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Net Worth")
                    .frame(width: 120, alignment: .trailing)
            }
            .font(WealthMapDesignTokens.Typography.caption)
            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)

            Divider()

            ForEach(rows) { row in
                HStack {
                    Text(row.recordedAt, format: .dateTime.month(.abbreviated).day().year())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(row.amount, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                        .frame(width: 120, alignment: .trailing)
                        .monospacedDigit()
                        .foregroundStyle(row.amount >= 0 ? WealthMapDesignTokens.ColorToken.textPrimary : WealthMapDesignTokens.ColorToken.danger)
                }
                .font(WealthMapDesignTokens.Typography.caption)
            }
        }
    }
}
