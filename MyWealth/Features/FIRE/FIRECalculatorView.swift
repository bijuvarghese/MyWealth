import SwiftUI
import SwiftData
import Charts

struct FIRECalculatorView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var assets: [Asset]
    @Query private var liabilities: [Liability]

    @Bindable var settings: AppSettings

    @AppStorage("fire.monthlyExpenses") private var monthlyExpenses = 0.0
    @AppStorage("fire.monthlySavings") private var monthlySavings = 0.0
    @AppStorage("fire.retireAtAge") private var retireAtAge = 65
    @AppStorage("fire.currentAge") private var currentAge = 0
    @AppStorage("fire.annualReturn") private var annualReturn = 0.07
    @State private var viewModel = DashboardViewModel()
    @State private var metalViewModel = MetalPricesViewModel()
    @State private var savingsExplorer = 0.0
    @State private var fireExplainerIsExpanded = true
    @FocusState private var focusedInput: FIREInputField?

    private let calculator = FIRECalculator()
    private enum FIREInputField: Hashable {
        case monthlyExpenses
        case monthlySavings
    }

    private var portfolioAssets: [Asset] {
        settings.portfolioCalculationAssets(from: assets)
    }

    private var currentPortfolio: Double {
        viewModel.netWorthTotal(
            portfolioAssets,
            liabilities: liabilities,
            to: settings.baseCurrency,
            exchangeRates: viewModel.exchangeRates
        ) ?? 0
    }

    private var projection: FIREProjection {
        calculator.project(
            currentPortfolio: currentPortfolio,
            monthlyExpenses: monthlyExpenses,
            monthlySavings: monthlySavings + savingsExplorer,
            retireAtAge: retireAtAge,
            currentAge: currentAge > 0 ? currentAge : nil,
            annualReturn: annualReturn
        )
    }

    var body: some View {
        ZStack {
            RadialDotBackground(dotRadius: 1, spacing: 20)
                .ignoresSafeArea(.all)

            ScrollView {
                VStack(spacing: 18) {
                    numbersCard
                    fireTargetCard
                    firePaceCard
                    trajectoryCard
                    fireLevelsCard
                    savingsExplorerCard
                    oneMoreYearCard
                    fireExplainerCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("FIRE Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedInput = nil
                }
            }
        }
        .task(id: "fireRates") {
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

    private var numbersCard: some View {
        AppListCard(contentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text("Your numbers")
                        .font(.headline)
                    Spacer()
                }
                .padding(18)

                Divider()

                VStack(spacing: 16) {
                    currencyField(title: "Monthly Expenses", value: $monthlyExpenses, focus: .monthlyExpenses)
                    currencyField(title: "Monthly Savings", value: $monthlySavings, focus: .monthlySavings)

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Retire At Age")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text("Target retirement")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 12) {
                            Button {
                                retireAtAge = max(retireAtAge - 1, 35)
                            } label: {
                                Image(systemName: "minus")
                                    .font(.headline.weight(.bold))
                                    .frame(width: 44, height: 44)
                                    .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Decrease retirement age")

                            Text("\(retireAtAge)")
                                .font(.largeTitle.weight(.bold))
                                .monospacedDigit()
                                .frame(minWidth: 64)
                                .contentTransition(.numericText())

                            Button {
                                retireAtAge = min(retireAtAge + 1, 85)
                            } label: {
                                Image(systemName: "plus")
                                    .font(.headline.weight(.bold))
                                    .frame(width: 44, height: 44)
                                    .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Increase retirement age")
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Expected Annual Return")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        HStack(spacing: 10) {
                            returnButton(label: "5%", subtitle: "Conservative", value: 0.05)
                            returnButton(label: "7%", subtitle: "Moderate", value: 0.07)
                            returnButton(label: "9%", subtitle: "Optimistic", value: 0.09)
                        }

                        Text("Real return after inflation. 7% is the long-term stock market average.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(18)
            }
        }
    }

    private func currencyField(title: String, value: Binding<Double>, focus: FIREInputField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack {
                Text(currencySymbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36)

                TextField("0", value: value, format: .number.precision(.fractionLength(0)))
                    .keyboardType(.decimalPad)
                    .focused($focusedInput, equals: focus)
                    .font(.title.weight(.semibold))
                    .monospacedDigit()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func returnButton(label: String, subtitle: String, value: Double) -> some View {
        Button {
            annualReturn = value
        } label: {
            VStack(spacing: 4) {
                Text(label)
                    .font(.title2.weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(abs(annualReturn - value) < 0.001 ? .orange : .primary)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(abs(annualReturn - value) < 0.001 ? Color.orange.opacity(0.12) : Color(.secondarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(abs(annualReturn - value) < 0.001 ? Color.orange.opacity(0.55) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var fireTargetCard: some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FIRE Target")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text("25x annual spending · 4% rule")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if projection.isFIREReached {
                        Label("FIRE Reached", systemImage: "figure.run")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.12), in: Capsule())
                    }
                }

                Text(projection.fireTarget, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)

                ProgressView(value: projection.progress)
                    .tint(.green)

                HStack {
                    Text("\(projection.progress.formatted(.percent.precision(.fractionLength(0)))) of FIRE target")
                    Spacer()
                    Text("\(currentPortfolio.formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))) saved")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Label("Spending \(projection.annualExpenses.formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0))))/yr - cutting expenses shrinks both your target and the time it takes to get there.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var firePaceCard: some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("FIRE Pace")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Savings Rate")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(projection.savingsRate, format: .percent.precision(.fractionLength(0)))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                            .monospacedDigit()
                        Text(savingsRateLabel)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .frame(height: 80)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly Target")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        if let target = projection.monthlyTargetToRetireAtAge {
                            Text(target, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                                .font(.title.weight(.bold))
                                .monospacedDigit()
                        } else {
                            Text("-")
                                .font(.title.weight(.bold))
                        }
                        Text(currentAge > 0 ? "For age \(retireAtAge)" : "Set current age")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                ProgressView(value: min(projection.savingsRate, 1))
                    .tint(.green)

                Text("Savings rate is the single strongest predictor of FIRE speed. At 50%+ you typically reach FI in under 17 years from scratch.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Stepper(value: $currentAge, in: 0...85) {
                    Text(currentAge > 0 ? "Current age: \(currentAge)" : "Current age: not set")
                        .font(.footnote)
                }
            }
        }
    }

    private var savingsRateLabel: String {
        if let years = projection.yearsToFIRE {
            if years == 0 { return "Already FI" }
            return "\(years.formatted(.number.precision(.fractionLength(1)))) yrs to FI"
        }
        return "Add savings to estimate FI"
    }

    private var trajectoryCard: some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Portfolio Trajectory")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text("\(Int(annualReturn * 100))% return / yr")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Chart {
                    ForEach(projection.trajectory) { point in
                        AreaMark(
                            x: .value("Year", point.yearOffset),
                            y: .value("Portfolio", point.amount)
                        )
                        .foregroundStyle(Color.orange.opacity(0.18))

                        LineMark(
                            x: .value("Year", point.yearOffset),
                            y: .value("Portfolio", point.amount)
                        )
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    }

                    RuleMark(y: .value("FIRE Target", projection.fireTarget))
                        .foregroundStyle(.secondary.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(amount, format: .currency(code: settings.baseCurrency.rawValue).notation(.compactName).precision(.fractionLength(1)))
                            }
                        }
                    }
                }
                .chartXAxisLabel("Years")
                .frame(height: 230)
            }
        }
    }

    private var fireLevelsCard: some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("FI Levels")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text("Based on \(projection.annualExpenses.formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0))))/yr")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(projection.levelProgress) { level in
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: level.kind.systemImage)
                                .foregroundStyle(level.isAchieved ? .green : .orange)
                                .frame(width: 34, height: 34)
                                .background((level.isAchieved ? Color.green : Color.orange).opacity(0.12), in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.kind.rawValue)
                                    .font(.headline)
                                Text(level.kind.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if level.isAchieved {
                                Label("Achieved", systemImage: "checkmark.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.green)
                            } else if let estimatedYear = level.estimatedYear {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Est. \(estimatedYear)")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.orange)
                                    Text(level.target, format: .currency(code: settings.baseCurrency.rawValue).notation(.compactName).precision(.fractionLength(1)))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        ProgressView(value: level.progress)
                            .tint(level.isAchieved ? .green : .orange)
                    }
                    if level.kind != projection.levelProgress.last?.kind {
                        Divider()
                    }
                }
            }
        }
    }

    private var savingsExplorerCard: some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text("Savings Explorer")
                        .font(.headline)
                    Spacer()
                }

                Divider()

                HStack(alignment: .firstTextBaseline) {
                    Text("If I saved")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text(savingsExplorer, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                        .font(.title.weight(.bold))
                        .foregroundStyle(.orange)
                    Text("/mo")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }

                Slider(value: $savingsExplorer, in: 0...max(monthlyExpenses, 5_000), step: 100)
                    .tint(.orange)

                HStack {
                    Text("Actual: \(monthlySavings.formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0))))/mo")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Reset") {
                        savingsExplorer = 0
                    }
                    .foregroundStyle(.orange)
                }
                .font(.subheadline)
            }
        }
    }

    private var oneMoreYearCard: some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("One More Year", systemImage: "calendar.badge.plus")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("What one extra year of saving and growth is worth in real spending power.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Portfolio After 1 Year")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(projection.portfolioAfterOneYear, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                            .font(.title2.weight(.bold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Extra Spending/Year")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(projection.extraAnnualSpendingAfterOneYear, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.green)
                    }
                }

                Divider()

                Text("Retiring today: \((currentPortfolio * 0.04).formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0))))/yr")
                    .foregroundStyle(.secondary)
                Text("After one more year: \((projection.portfolioAfterOneYear * 0.04).formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0))))/yr")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }

    private var fireExplainerCard: some View {
        AppListCard {
            DisclosureGroup(isExpanded: $fireExplainerIsExpanded) {
                VStack(alignment: .leading, spacing: 16) {
                    explainerSection(
                        title: "The Concept",
                        body: "FIRE stands for Financially Independent, Retire Early. The goal is to build a portfolio large enough that investment returns alone cover living expenses, making work optional."
                    )
                    Divider()
                    explainerSection(
                        title: "The 4% Rule",
                        body: "A classic FIRE target is 25x your annual expenses. Spending \(projection.annualExpenses.formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0))))/yr implies a target of \(projection.fireTarget.formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0))))."
                    )
                    Divider()
                    explainerSection(
                        title: "Why Expenses Matter",
                        body: "Cutting expenses lowers the target and frees up more cash to invest, creating a double impact on the timeline."
                    )
                }
                .padding(.top, 16)
            } label: {
                Label("What is FIRE?", systemImage: "questionmark.circle")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .tint(.orange)
        }
    }

    private func explainerSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var currencySymbol: String {
        Locale.current.localizedString(forCurrencyCode: settings.baseCurrency.rawValue)
            .flatMap { _ in
                Locale.current.currencySymbol
            } ?? settings.baseCurrency.rawValue
    }
}
