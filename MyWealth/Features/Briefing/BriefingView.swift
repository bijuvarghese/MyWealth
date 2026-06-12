import SwiftUI
import SwiftData

struct BriefingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var assets: [Asset]
    @Query private var liabilities: [Liability]
    @Query private var netWorthSnapshots: [NetWorthSnapshot]
    @Query private var assetValueSnapshots: [AssetValueSnapshot]

    @Bindable var settings: AppSettings

    @State private var viewModel = DashboardViewModel()
    @State private var metalViewModel = MetalPricesViewModel()
    @State private var reportHistory: [PortfolioIntelligenceReport] = []
    @State private var aiAnalysis: String?
    @State private var analysisError: String?
    @State private var isAnalyzing = false
    @State private var showSettings = false

    private let calculator = PortfolioIntelligenceCalculator()

    private var portfolioAssets: [Asset] {
        settings.portfolioCalculationAssets(from: assets)
    }

    private var currentReport: PortfolioIntelligenceReport {
        if let report = reportHistory.first {
            return report
        }

        return makeReport(previousGrade: nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RadialDotBackground(dotRadius: 1, spacing: 20)
                    .ignoresSafeArea(.all)

                if assets.isEmpty && liabilities.isEmpty {
                    ContentUnavailableView(
                        "No Briefing Data",
                        systemImage: "sparkles",
                        description: Text("Add assets or liabilities to generate a portfolio briefing.")
                    )
                } else {
                    List {
                        Section(header: PillLabel("Portfolio Health")) {
                            healthCard(report: currentReport)
                                .appListRow()
                        }

                        Section(header: PillLabel("AI Analysis")) {
                            aiAnalysisCard(report: currentReport)
                                .appListRow()
                        }

                        Section(header: PillLabel("Activity")) {
                            analysisHistoryCard
                                .appListRow()
                        }

                        let warnings = currentReport.observations.filter { $0.severity == .warning }
                        if !warnings.isEmpty {
                            Section(header: PillLabel("Observations")) {
                                ForEach(warnings) { observation in
                                    alertCard(observation)
                                        .appListRow()
                                }
                            }
                        }

                        Section(header: PillLabel("Return Attribution")) {
                            returnAttributionCard
                                .appListRow()
                        }

                        Section(header: PillLabel("Allocation")) {
                            allocationCard(report: currentReport)
                                .appListRow()
                        }

                        Section {
                            whatIfLink
                                .appListRow()
                        } header: {
                            PillLabel("Scenario")
                        } footer: {
                            generatedFooter
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Briefing")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refreshAnalysis() }
                    } label: {
                        Label("Refresh Analysis", systemImage: "arrow.clockwise")
                    }
                    .disabled(isAnalyzing)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings, showsDoneButton: true)
            }
        }
        .task(id: "briefingRates") {
            await metalViewModel.refreshIfNeeded()
            viewModel.enrichWithMetalRates(metalViewModel.metalRates)
            if reportHistory.isEmpty {
                reportHistory = [makeReport(previousGrade: nil)]
            }
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

    private func makeReport(previousGrade: PortfolioHealthGrade?) -> PortfolioIntelligenceReport {
        calculator.makeReport(
            assets: portfolioAssets,
            liabilities: liabilities,
            netWorthSnapshots: netWorthSnapshots,
            exchangeRates: viewModel.exchangeRates,
            baseCurrency: settings.baseCurrency,
            previousGrade: previousGrade
        )
    }

    @MainActor
    private func refreshAnalysis() async {
        let previousGrade = reportHistory.first?.grade
        let report = makeReport(previousGrade: previousGrade)
        reportHistory.insert(report, at: 0)
        reportHistory = Array(reportHistory.prefix(6))

        isAnalyzing = true
        analysisError = nil
        defer { isAnalyzing = false }

        do {
            let payload = try ChatGPTAnalysisExporter.buildPayload(
                context: modelContext,
                settings: settings,
                exchangeRates: viewModel.exchangeRates,
                exchangeRatesLastUpdated: viewModel.lastUpdated
            )
            let response = try await FirebaseChatGPTAnalysisService.shared.analyze(payload)
            aiAnalysis = response.analysis
        } catch {
            analysisError = error.localizedDescription
        }
    }

    private func healthCard(report: PortfolioIntelligenceReport) -> some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 18) {
                    scoreRing(report: report)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Portfolio Health")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(report.grade.rawValue)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(gradeColor(report.grade))
                    }

                    Spacer()
                }

                VStack(spacing: 12) {
                    ForEach(report.metrics) { metric in
                        metricRow(metric)
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Focus area: \(report.focusArea)")
                            .fontWeight(.semibold)
                        Text(report.focusDetail)
                            .foregroundStyle(.secondary)
                    }
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func scoreRing(report: PortfolioIntelligenceReport) -> some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 9)
            Circle()
                .trim(from: 0, to: Double(report.score) / 100)
                .stroke(gradeColor(report.grade), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(report.score)")
                .font(.title.weight(.bold))
                .monospacedDigit()
        }
        .frame(width: 82, height: 82)
    }

    private func metricRow(_ metric: PortfolioHealthMetric) -> some View {
        HStack(spacing: 12) {
            Text(metric.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 118, alignment: .leading)

            ProgressView(value: metric.ratio)
                .tint(metricColor(metric))

            Text("\(metric.score)/\(metric.maxScore)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .trailing)
        }
    }

    private func aiAnalysisCard(report: PortfolioIntelligenceReport) -> some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("AI Analysis", systemImage: "atom")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Text(report.grade.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(gradeColor(report.grade))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(gradeColor(report.grade).opacity(0.12), in: Capsule())

                    if let movement = report.gradeMovementLabel {
                        Label(movement, systemImage: report.grade == .strong ? "arrow.up" : "arrow.down")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1), in: Capsule())
                    }
                }

                if isAnalyzing {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Refreshing portfolio analysis...")
                            .foregroundStyle(.secondary)
                    }
                }

                Text(aiAnalysis?.trimmedForDisplay ?? report.summary)
                    .font(.body.weight(.medium))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                if let analysisError {
                    Label(analysisError, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(report.observations.prefix(2)) { observation in
                    observationCard(observation)
                }
            }
        }
    }

    private var analysisHistoryCard: some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Last analyzed \(currentReport.generatedAt.formatted(.relative(presentation: .numeric)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Button {
                    Task { await refreshAnalysis() }
                } label: {
                    Label("Refresh Analysis", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isAnalyzing)

                Divider()

                Text("Analysis History")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                ForEach(Array(reportHistory.prefix(4).enumerated()), id: \.offset) { _, report in
                    HStack {
                        Text(report.generatedAt.formatted(.relative(presentation: .numeric)))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(report.grade.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(gradeColor(report.grade))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(gradeColor(report.grade).opacity(0.12), in: Capsule())
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private func alertCard(_ observation: PortfolioObservation) -> some View {
        AppListCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: observation.systemImage)
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 42, height: 42)
                    .background(Color.orange.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(observation.title)
                        .font(.headline)
                    Text(observation.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        }
    }

    private var returnAttributionCard: some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("Return Attribution", systemImage: "chart.bar.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)

                Text("No gain/loss data yet. Add purchase prices or cost basis to see attribution.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func allocationCard(report: PortfolioIntelligenceReport) -> some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Allocation", systemImage: "chart.pie.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)

                if report.allocation.isEmpty {
                    Text("Add assets to see allocation.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    GeometryReader { proxy in
                        HStack(spacing: 2) {
                            ForEach(report.allocation) { row in
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(categoryColor(row.category))
                                    .frame(width: max(proxy.size.width * row.percentage, 3))
                            }
                        }
                    }
                    .frame(height: 14)

                    ForEach(report.allocation) { row in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(categoryColor(row.category))
                                .frame(width: 14, height: 14)
                            Text(row.category.rawValue)
                                .font(.headline)
                            Text("(\(assets.filter { $0.displayCategory == row.category }.count))")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(row.percentage, format: .percent.precision(.fractionLength(0)))
                                .font(.headline.monospacedDigit())
                            Text(row.amount, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var whatIfLink: some View {
        NavigationLink {
            WhatIfSimulatorView(
                settings: settings,
                baseReport: currentReport,
                exchangeRates: viewModel.exchangeRates
            )
        } label: {
            AppListCard {
                HStack(spacing: 14) {
                    Image(systemName: "wand.and.stars")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What If...")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Simulate selling, buying, or paying off debt")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var generatedFooter: some View {
        Text("Generated \(currentReport.generatedAt.formatted(date: .abbreviated, time: .shortened))")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }

    private func observationCard(_ observation: PortfolioObservation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: observation.systemImage)
                .foregroundStyle(observationColor(observation.severity))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(observation.title)
                    .font(.headline)
                Text(observation.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func metricColor(_ metric: PortfolioHealthMetric) -> Color {
        switch metric.ratio {
        case 0.75...: return .green
        case 0.45..<0.75: return .orange
        default: return .gray
        }
    }

    private func gradeColor(_ grade: PortfolioHealthGrade) -> Color {
        switch grade {
        case .strong: return .green
        case .solid: return .orange
        case .watch: return .yellow
        case .risk: return .red
        }
    }

    private func observationColor(_ severity: PortfolioObservation.Severity) -> Color {
        switch severity {
        case .positive: return .green
        case .neutral: return .secondary
        case .warning: return .orange
        }
    }

    private func categoryColor(_ category: Asset.CategoryType) -> Color {
        switch category {
        case .stocks: return .blue
        case .realEstate: return .purple
        case .crypto: return .orange
        case .bank: return .green
        case .mutualFunds: return .teal
        case .gold: return .yellow
        case .silver: return .gray
        case .platinum: return .mint
        case .palladium: return .indigo
        case .rhodium: return .cyan
        case .cars: return .red
        case .others: return .secondary
        }
    }
}

private struct WhatIfSimulatorView: View {
    @Bindable var settings: AppSettings
    let baseReport: PortfolioIntelligenceReport
    let exchangeRates: [String: Double]

    @State private var scenario = WhatIfScenario.buyAsset
    @State private var amount = 10_000.0

    private var simulatedAssetTotal: Double {
        switch scenario {
        case .buyAsset: return baseReport.assetTotal + amount
        case .sellAsset: return max(baseReport.assetTotal - amount, 0)
        case .payDebt: return baseReport.assetTotal
        }
    }

    private var simulatedLiabilityTotal: Double {
        switch scenario {
        case .payDebt: return max(baseReport.liabilityTotal - amount, 0)
        case .buyAsset, .sellAsset: return baseReport.liabilityTotal
        }
    }

    private var simulatedNetWorth: Double {
        simulatedAssetTotal - simulatedLiabilityTotal
    }

    var body: some View {
        ZStack {
            RadialDotBackground(dotRadius: 1, spacing: 20)
                .ignoresSafeArea(.all)

            ScrollView {
                VStack(spacing: 18) {
                    AppListCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Scenario")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            Picker("Scenario", selection: $scenario) {
                                ForEach(WhatIfScenario.allCases) { scenario in
                                    Label(scenario.title, systemImage: scenario.systemImage)
                                        .tag(scenario)
                                }
                            }
                            .pickerStyle(.segmented)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Amount")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                    Spacer()
                                    Text(amount, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(.orange)
                                }

                                Slider(value: $amount, in: 0...max(baseReport.assetTotal, 10_000), step: 1_000)
                                    .tint(.orange)
                            }
                        }
                    }

                    AppListCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Projected Result")
                                .font(.headline)

                            whatIfRow(
                                title: "Assets",
                                value: simulatedAssetTotal,
                                delta: simulatedAssetTotal - baseReport.assetTotal
                            )
                            whatIfRow(
                                title: "Debt",
                                value: simulatedLiabilityTotal,
                                delta: simulatedLiabilityTotal - baseReport.liabilityTotal
                            )
                            Divider()
                            whatIfRow(
                                title: "Net Worth",
                                value: simulatedNetWorth,
                                delta: simulatedNetWorth - baseReport.netWorth
                            )

                            Text(scenario.guidance)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 6)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("What If")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func whatIfRow(title: String, value: Double, delta: Double) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                    .font(.headline.monospacedDigit())
                Text(delta, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(delta >= 0 ? .green : .red)
            }
        }
    }
}

private enum WhatIfScenario: String, CaseIterable, Identifiable {
    case buyAsset
    case sellAsset
    case payDebt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .buyAsset: return "Buy"
        case .sellAsset: return "Sell"
        case .payDebt: return "Pay Debt"
        }
    }

    var systemImage: String {
        switch self {
        case .buyAsset: return "plus.circle"
        case .sellAsset: return "minus.circle"
        case .payDebt: return "checkmark.shield"
        }
    }

    var guidance: String {
        switch self {
        case .buyAsset:
            return "Buying adds exposure. The health impact depends on whether the new asset improves diversification or adds concentration."
        case .sellAsset:
            return "Selling reduces assets in the simulation. If the sale lowers concentration, the portfolio may become more balanced."
        case .payDebt:
            return "Paying off debt directly improves net worth and the debt-ratio component of portfolio health."
        }
    }
}

private extension String {
    var trimmedForDisplay: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
