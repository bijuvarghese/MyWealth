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
    @State private var didLogViewed = false
    @State private var didLogCompleted = false
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
        .onAppear {
            logViewedIfNeeded()
            logCompletedIfReady()
        }
        .onChange(of: monthlyExpenses) { _, _ in
            logCompletedIfReady()
        }
        .onChange(of: monthlySavings) { _, _ in
            logCompletedIfReady()
        }
    }

    private func logViewedIfNeeded() {
        guard !didLogViewed else { return }
        didLogViewed = true
        AnalyticsService.shared.log(
            .fireCalculatorViewed,
            parameters: [
                .sourceScreen: AnalyticsService.SourceScreen.fireCalculator.rawValue,
                .calculatorMode: "standard_fire"
            ]
        )
    }

    private func logCompletedIfReady() {
        guard !didLogCompleted, monthlyExpenses > 0, monthlySavings > 0 else { return }
        didLogCompleted = true
        AnalyticsService.shared.log(
            .fireCalculatorCompleted,
            parameters: [
                .sourceScreen: AnalyticsService.SourceScreen.fireCalculator.rawValue,
                .calculatorMode: "standard_fire"
            ]
        )
    }

    private var numbersCard: some View {
        AppListCard(contentPadding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.warning)
                    Text("Your numbers")
                        .font(WealthMapDesignTokens.Typography.headline)
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
                                .font(WealthMapDesignTokens.Typography.compactLabel)
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                                .textCase(.uppercase)
                            Text("Target retirement")
                                .font(WealthMapDesignTokens.Typography.subheadline)
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        }

                        Spacer()

                        HStack(spacing: 12) {
                            Button {
                                retireAtAge = max(retireAtAge - 1, 35)
                            } label: {
                                Image(systemName: "minus")
                                    .font(WealthMapDesignTokens.Typography.headlineBold)
                                    .frame(width: 44, height: 44)
                                    .background(WealthMapDesignTokens.ColorToken.surfaceSecondaryFill, in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous))
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
                                    .font(WealthMapDesignTokens.Typography.headlineBold)
                                    .frame(width: 44, height: 44)
                                    .background(WealthMapDesignTokens.ColorToken.surfaceSecondaryFill, in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Increase retirement age")
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Expected Annual Return")
                            .font(WealthMapDesignTokens.Typography.compactLabel)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                            .textCase(.uppercase)

                        HStack(spacing: 10) {
                            returnButton(subtitle: "Conservative", value: 0.05)
                            returnButton(subtitle: "Moderate", value: 0.07)
                            returnButton(subtitle: "Optimistic", value: 0.09)
                        }

                        Text(
                            AppLocalization.formatted(
                                "Real return after inflation. %@ is the long-term stock market average.",
                                arguments: [AppLocalization.percent(0.07)]
                            )
                        )
                            .font(WealthMapDesignTokens.Typography.footnote)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    }
                }
                .padding(18)
            }
        }
    }

    private func currencyField(title: String, value: Binding<Double>, focus: FIREInputField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLocalization.string(title, fallback: title))
                .font(WealthMapDesignTokens.Typography.compactLabel)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                .textCase(.uppercase)

            HStack {
                Text(currencySymbol)
                    .font(WealthMapDesignTokens.Typography.amountProminent)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    .frame(width: 36)

                TextField("0", value: value, format: .number.precision(.fractionLength(0)))
                    .keyboardType(.decimalPad)
                    .focused($focusedInput, equals: focus)
                    .font(.title.weight(.semibold))
                    .monospacedDigit()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(WealthMapDesignTokens.ColorToken.surfaceSecondaryFill, in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous))
        }
    }

    private func returnButton(subtitle: String, value: Double) -> some View {
        Button {
            annualReturn = value
        } label: {
            VStack(spacing: 4) {
                Text(AppLocalization.percent(value))
                    .font(WealthMapDesignTokens.Typography.amountProminent.weight(.bold))
                Text(AppLocalization.string(subtitle, fallback: subtitle))
                    .font(WealthMapDesignTokens.Typography.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(abs(annualReturn - value) < 0.001 ? WealthMapDesignTokens.ColorToken.warning : WealthMapDesignTokens.ColorToken.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous)
                    .fill(abs(annualReturn - value) < 0.001 ? WealthMapDesignTokens.ColorToken.warning.opacity(0.12) : WealthMapDesignTokens.ColorToken.surfaceSecondaryFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous)
                    .stroke(abs(annualReturn - value) < 0.001 ? WealthMapDesignTokens.ColorToken.warning.opacity(0.55) : WealthMapDesignTokens.ColorToken.surfaceClear, lineWidth: 1)
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
                            .font(WealthMapDesignTokens.Typography.compactLabel)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                            .textCase(.uppercase)
                        Text(
                            AppLocalization.formatted(
                                "25x annual spending · %@ rule",
                                arguments: [AppLocalization.percent(0.04)]
                            )
                        )
                            .font(WealthMapDesignTokens.Typography.subheadline)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    }
                    Spacer()
                    if projection.isFIREReached {
                        Label("FIRE Reached", systemImage: "figure.run")
                            .font(WealthMapDesignTokens.Typography.compactLabel)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.success)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(WealthMapDesignTokens.ColorToken.success.opacity(0.12), in: Capsule())
                    }
                }

                Text(projection.fireTarget, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)

                ProgressView(value: projection.progress)
                    .tint(WealthMapDesignTokens.ColorToken.success)

                HStack {
                    Text("\(projection.progress.formatted(.percent.precision(.fractionLength(0)))) of FIRE target")
                    Spacer()
                    Text("\(currentPortfolio.formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))) saved")
                }
                .font(WealthMapDesignTokens.Typography.subheadline)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)

                Label("Spending \(projection.annualExpenses.formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0))))/yr - cutting expenses shrinks both your target and the time it takes to get there.", systemImage: "info.circle")
                    .font(WealthMapDesignTokens.Typography.footnote)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var firePaceCard: some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("FIRE Pace")
                    .font(WealthMapDesignTokens.Typography.compactLabel)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    .textCase(.uppercase)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Savings Rate")
                            .font(WealthMapDesignTokens.Typography.compactLabel)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                            .textCase(.uppercase)
                        Text(projection.savingsRate, format: .percent.precision(.fractionLength(0)))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.success)
                            .monospacedDigit()
                        Text(savingsRateLabel)
                            .font(WealthMapDesignTokens.Typography.footnote)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    }

                    Divider()
                        .frame(height: 80)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly Target")
                            .font(WealthMapDesignTokens.Typography.compactLabel)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
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
                            .font(WealthMapDesignTokens.Typography.footnote)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    }
                }

                ProgressView(value: min(projection.savingsRate, 1))
                    .tint(WealthMapDesignTokens.ColorToken.success)

                Text(
                    AppLocalization.formatted(
                        "Savings rate is the single strongest predictor of FIRE speed. At %@ or higher you typically reach FI in under 17 years from scratch.",
                        arguments: [AppLocalization.percent(0.50)]
                    )
                )
                    .font(WealthMapDesignTokens.Typography.subheadline)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Stepper(value: $currentAge, in: 0...85) {
                    Text(currentAge > 0 ? "Current age: \(currentAge)" : "Current age: not set")
                        .font(WealthMapDesignTokens.Typography.footnote)
                }
            }
        }
    }

    private var savingsRateLabel: String {
        if let years = projection.yearsToFIRE {
            if years == 0 { return AppLocalization.string("Already FI") }
            return AppLocalization.formatted(
                "%@ yrs to FI",
                arguments: [years.formatted(.number.precision(.fractionLength(1)))]
            )
        }
        return AppLocalization.string("Add savings to estimate FI")
    }

    private var trajectoryCard: some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Portfolio Trajectory")
                        .font(WealthMapDesignTokens.Typography.compactLabel)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text(
                        AppLocalization.formatted(
                            "%@ return / yr",
                            arguments: [AppLocalization.percent(annualReturn)]
                        )
                    )
                        .font(WealthMapDesignTokens.Typography.subheadline)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                }

                Chart {
                    ForEach(projection.trajectory) { point in
                        AreaMark(
                            x: .value("Year", point.yearOffset),
                            y: .value("Portfolio", point.amount)
                        )
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.warning.opacity(0.18))

                        LineMark(
                            x: .value("Year", point.yearOffset),
                            y: .value("Portfolio", point.amount)
                        )
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.warning)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    }

                    RuleMark(y: .value("FIRE Target", projection.fireTarget))
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary.opacity(0.45))
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
                        .font(WealthMapDesignTokens.Typography.compactLabel)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text("Based on \(projection.annualExpenses.formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0))))/yr")
                        .font(WealthMapDesignTokens.Typography.subheadline)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                }

                ForEach(projection.levelProgress) { level in
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: level.kind.systemImage)
                                .foregroundStyle(level.isAchieved ? WealthMapDesignTokens.ColorToken.success : WealthMapDesignTokens.ColorToken.warning)
                                .frame(width: 34, height: 34)
                                .background((level.isAchieved ? WealthMapDesignTokens.ColorToken.success : WealthMapDesignTokens.ColorToken.warning).opacity(0.12), in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.kind.displayName)
                                    .font(WealthMapDesignTokens.Typography.headline)
                                Text(level.kind.subtitle)
                                    .font(WealthMapDesignTokens.Typography.subheadline)
                                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                            }
                            Spacer()
                            if level.isAchieved {
                                Label("Achieved", systemImage: "checkmark.circle.fill")
                                    .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                                    .foregroundStyle(WealthMapDesignTokens.ColorToken.success)
                            } else if let estimatedYear = level.estimatedYear {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Est. \(estimatedYear)")
                                        .font(WealthMapDesignTokens.Typography.subheadline.weight(.bold))
                                        .foregroundStyle(WealthMapDesignTokens.ColorToken.warning)
                                    Text(level.target, format: .currency(code: settings.baseCurrency.rawValue).notation(.compactName).precision(.fractionLength(1)))
                                        .font(WealthMapDesignTokens.Typography.caption)
                                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                                }
                            }
                        }

                        ProgressView(value: level.progress)
                            .tint(level.isAchieved ? WealthMapDesignTokens.ColorToken.success : WealthMapDesignTokens.ColorToken.warning)
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
                        .font(WealthMapDesignTokens.Typography.title2)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.warning)
                    Text("Savings Explorer")
                        .font(WealthMapDesignTokens.Typography.headline)
                    Spacer()
                }

                Divider()

                HStack(alignment: .firstTextBaseline) {
                    Text("If I saved")
                        .font(WealthMapDesignTokens.Typography.compactLabel)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text(savingsExplorer, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                        .font(.title.weight(.bold))
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.warning)
                    Text("/mo")
                        .font(WealthMapDesignTokens.Typography.headline)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.warning)
                }

                Slider(value: $savingsExplorer, in: 0...max(monthlyExpenses, 5_000), step: 100)
                    .tint(WealthMapDesignTokens.ColorToken.warning)

                HStack {
                    Text("Actual: \(monthlySavings.formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0))))/mo")
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    Spacer()
                    Button("Reset") {
                        savingsExplorer = 0
                    }
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.warning)
                }
                .font(WealthMapDesignTokens.Typography.subheadline)
            }
        }
    }

    private var oneMoreYearCard: some View {
        AppListCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("One More Year", systemImage: "calendar.badge.plus")
                    .font(WealthMapDesignTokens.Typography.headline)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)

                Text("What one extra year of saving and growth is worth in real spending power.")
                    .font(WealthMapDesignTokens.Typography.subheadline)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Portfolio After 1 Year")
                            .font(WealthMapDesignTokens.Typography.compactLabel)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                            .textCase(.uppercase)
                        Text(projection.portfolioAfterOneYear, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                            .font(WealthMapDesignTokens.Typography.amountProminent.weight(.bold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Extra Spending/Year")
                            .font(WealthMapDesignTokens.Typography.compactLabel)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                            .textCase(.uppercase)
                        Text(projection.extraAnnualSpendingAfterOneYear, format: .currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0)))
                            .font(WealthMapDesignTokens.Typography.amountProminent.weight(.bold))
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.success)
                    }
                }

                Divider()

                Text("Retiring today: \((currentPortfolio * 0.04).formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0))))/yr")
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                Text("After one more year: \((projection.portfolioAfterOneYear * 0.04).formatted(.currency(code: settings.baseCurrency.rawValue).precision(.fractionLength(0))))/yr")
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
            }
            .font(WealthMapDesignTokens.Typography.subheadline)
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
                        title: AppLocalization.formatted(
                            "The %@ Rule",
                            arguments: [AppLocalization.percent(0.04)]
                        ),
                        body: AppLocalization.formatted(
                            "A classic FIRE target is 25x your annual expenses. Spending %@/yr implies a target of %@.",
                            arguments: [
                                projection.annualExpenses.formatted(
                                    .currency(code: settings.baseCurrency.rawValue)
                                        .precision(.fractionLength(0))
                                ),
                                projection.fireTarget.formatted(
                                    .currency(code: settings.baseCurrency.rawValue)
                                        .precision(.fractionLength(0))
                                )
                            ]
                        )
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
                    .font(WealthMapDesignTokens.Typography.headline)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
            }
            .tint(WealthMapDesignTokens.ColorToken.warning)
        }
    }

    private func explainerSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(AppLocalization.string(title, fallback: title))
                .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.warning)
            Text(AppLocalization.string(body, fallback: body))
                .font(WealthMapDesignTokens.Typography.subheadline)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
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
