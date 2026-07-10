//
//  MyWealthTests.swift
//  MyWealthTests
//
//  Created by Biju Varghese on 11/8/25.
//

import Testing
import Foundation
import SwiftData
@testable import MyWealth

struct MyWealthTests {

    @MainActor
    @Test func analyticsEventCatalogMatchesPrivacyPlan() async throws {
        let eventNames = Set(AnalyticsService.Event.allCases.map(\.rawValue))
        let parameterNames = Set(AnalyticsService.Parameter.allCases.map(\.rawValue))

        #expect(eventNames == [
            "onboarding_started",
            "onboarding_completed",
            "dashboard_viewed",
            "networth_summary_viewed",
            "asset_add_started",
            "asset_added",
            "liability_add_started",
            "liability_added",
            "goal_created",
            "goal_updated",
            "budget_created",
            "budget_updated",
            "fire_calculator_viewed",
            "fire_calculator_completed",
            "settings_viewed"
        ])
        #expect(parameterNames == [
            "source_screen",
            "asset_type",
            "liability_type",
            "goal_type",
            "budget_type",
            "calculator_mode",
            "app_version"
        ])
        #expect(parameterNames.isDisjoint(with: AnalyticsService.disallowedParameterNames))
    }

    @MainActor
    @Test func analyticsSanitizerDropsDisallowedAndUnknownPayloadKeys() async throws {
        let sanitized = AnalyticsService.sanitizedRawParameters([
            "source_screen": "dashboard",
            "asset_type": "bank_deposits",
            "amount": "100000",
            "account_name": "Checking",
            "free_text_notes": "private note",
            "email": "person@example.com",
            "unexpected": "value",
            "app_version": "v1 (1)"
        ])

        #expect(sanitized == [
            "source_screen": "dashboard",
            "asset_type": "bank_deposits",
            "app_version": "v1 (1)"
        ])
    }

    @MainActor
    @Test func analyticsValueNamesAreStableAndNonFreeText() async throws {
        #expect(AnalyticsService.valueName("Bank Deposits") == "bank_deposits")
        #expect(AnalyticsService.valueName("Line of Credit") == "line_of_credit")
        #expect(AnalyticsService.valueName("   ") == "unknown")
    }

    @MainActor
    @Test func designTokenCatalogHasRequiredCrossPlatformMappings() async throws {
        let data = try Data(contentsOf: Self.designTokenCatalogURL)
        let report = try WealthMapTokenValidation.validateCatalog(data: data)

        #expect(report.tokenCount >= WealthMapTokenValidation.requiredCategories.count)
        #expect(report.categories.isSuperset(of: WealthMapTokenValidation.requiredCategories))
        #expect(report.duplicateNames.isEmpty)
        #expect(report.missingCategories.isEmpty)
        #expect(report.tokensMissingPlatformMappings.isEmpty)
        #expect(report.tokensMissingAccessibilityNotes.isEmpty)
        #expect(report.tokensWithSensitiveContent.isEmpty)
        #expect(report.isValid)
    }

    @MainActor
    @Test func netWorthGoalDraftValidationRejectsInvalidValues() async throws {
        let today = Date(timeIntervalSince1970: 1_800_000_000)
        let invalid = NetWorthGoalDraft(
            targetAmount: 0,
            currency: .none,
            targetDate: today.addingTimeInterval(-86_400)
        )

        #expect(invalid.validationIssues(today: today) == [.targetAmount, .currency, .targetDate])
    }

    @MainActor
    @Test func netWorthGoalStoreUpsertsAndReconcilesSingleton() async throws {
        let context = try makeInMemoryModelContext()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        context.insert(NetWorthGoal(
            targetAmount: 10_000,
            currency: .usd,
            targetDate: now.addingTimeInterval(90 * 86_400),
            stableIdentifier: "older",
            createdAt: now.addingTimeInterval(-100),
            updatedAt: now.addingTimeInterval(-100)
        ))
        context.insert(NetWorthGoal(
            targetAmount: 20_000,
            currency: .eur,
            targetDate: now.addingTimeInterval(120 * 86_400),
            stableIdentifier: "newer",
            createdAt: now,
            updatedAt: now
        ))

        let result = try NetWorthGoalStore.upsert(
            NetWorthGoalDraft(
                targetAmount: 25_000,
                currency: .inr,
                targetDate: now.addingTimeInterval(180 * 86_400)
            ),
            in: context,
            now: now.addingTimeInterval(10)
        )
        let stored = try context.fetch(FetchDescriptor<NetWorthGoal>())

        #expect(stored.count == 1)
        #expect(result.displayStableIdentifier == "newer")
        #expect(result.displayTargetAmount == 25_000)
        #expect(result.displayCurrency == .inr)
    }

    @MainActor
    @Test func netWorthGoalProgressRequiresCompleteRatesAndBoundsVisualValue() async throws {
        let calculator = NetWorthGoalCalculator()
        let goal = NetWorthGoal(
            targetAmount: 1_000,
            currency: .eur,
            targetDate: Date().addingTimeInterval(365 * 86_400)
        )
        let assets = [Asset(name: "Cash", amount: 3_000, currency: .usd, category: .bank)]
        let liabilities = [Liability(name: "Loan", amount: 500, currency: .usd, category: .personalLoan)]

        let missing = calculator.progress(
            goal: goal,
            assets: assets,
            liabilities: liabilities,
            exchangeRates: ["USD": 1],
            ratesAreStale: false
        )
        let achieved = calculator.progress(
            goal: goal,
            assets: assets,
            liabilities: liabilities,
            exchangeRates: ["USD": 1, "EUR": 0.5],
            ratesAreStale: true
        )

        #expect(missing.currentAmount == nil)
        #expect(missing.rateState == .unavailable(missingCodes: ["EUR"]))
        #expect(achieved.currentAmount == 1_250)
        #expect(achieved.rawFraction == 1.25)
        #expect(achieved.visualFraction == 1)
        #expect(achieved.isAchieved)
        #expect(achieved.rateState == .stale)
    }

    @MainActor
    @Test func netWorthGoalCurrentValueUsesSelectedGoalCurrency() async throws {
        let value = NetWorthGoalCalculator().currentValue(
            currency: .eur,
            assets: [Asset(name: "Cash", amount: 2_000, currency: .usd, category: .bank)],
            liabilities: [Liability(name: "Loan", amount: 500, currency: .usd, category: .personalLoan)],
            exchangeRates: ["USD": 1, "EUR": 0.5],
            ratesAreStale: false
        )

        #expect(value.amount == 750)
        #expect(value.rateState == .available)
    }

    @MainActor
    @Test func netWorthGoalProjectionUsesThreeSnapshotsAcrossThirtyDays() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let calculator = NetWorthGoalCalculator(calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let goal = NetWorthGoal(
            targetAmount: 2_000,
            currency: .usd,
            targetDate: now.addingTimeInterval(200 * 86_400)
        )
        let progress = NetWorthGoalProgress(
            currentAmount: 1_400,
            rawFraction: 0.7,
            visualFraction: 0.7,
            isAchieved: false,
            rateState: .available
        )
        let snapshots = [
            NetWorthSnapshot(amount: 1_000, currencyCode: "USD", recordedAt: now.addingTimeInterval(-40 * 86_400)),
            NetWorthSnapshot(amount: 1_200, currencyCode: "USD", recordedAt: now.addingTimeInterval(-20 * 86_400)),
            NetWorthSnapshot(amount: 1_400, currencyCode: "USD", recordedAt: now)
        ]

        let result = calculator.outlook(
            goal: goal,
            progress: progress,
            snapshots: snapshots,
            exchangeRates: ["USD": 1],
            currentDate: now
        )

        guard case .projected(let date, let pace) = result else {
            Issue.record("Expected a projected outlook")
            return
        }
        #expect(calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: date).day == 60)
        #expect(pace == .onTrack)
    }

    @MainActor
    @Test func netWorthGoalAchievementPlanCalculatesMonthlyAndYearlyNeeds() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let calculator = NetWorthGoalCalculator(calendar: calendar)
        let now = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_800_000_000))
        let targetDate = try #require(calendar.date(byAdding: .day, value: 365, to: now))
        let goal = NetWorthGoal(
            targetAmount: 100_000,
            currency: .usd,
            targetDate: targetDate
        )
        let progress = NetWorthGoalProgress(
            currentAmount: 40_000,
            rawFraction: 0.4,
            visualFraction: 0.4,
            isAchieved: false,
            rateState: .available
        )

        let plan = calculator.achievementPlan(
            goal: goal,
            progress: progress,
            currentDate: now
        )

        #expect(plan.status == .active)
        #expect(plan.remainingAmount == 60_000)
        #expect(plan.monthsRemaining == 12)
        #expect(abs((plan.requiredMonthlyIncrease ?? 0) - 5_002) < 2)
        #expect(abs((plan.requiredYearlyIncrease ?? 0) - 60_041) < 2)
    }

    @MainActor
    @Test func netWorthGoalAchievementPlanHandlesAchievedAndOverdueGoals() async throws {
        let calculator = NetWorthGoalCalculator()
        let now = Date()
        let goal = NetWorthGoal(
            targetAmount: 100_000,
            currency: .usd,
            targetDate: now.addingTimeInterval(-86_400)
        )
        let achieved = NetWorthGoalProgress(
            currentAmount: 110_000,
            rawFraction: 1.1,
            visualFraction: 1,
            isAchieved: true,
            rateState: .available
        )
        let behind = NetWorthGoalProgress(
            currentAmount: 90_000,
            rawFraction: 0.9,
            visualFraction: 0.9,
            isAchieved: false,
            rateState: .available
        )

        #expect(calculator.achievementPlan(goal: goal, progress: achieved, currentDate: now).status == .achieved)
        #expect(calculator.achievementPlan(goal: goal, progress: behind, currentDate: now).status == .overdue)
        #expect(calculator.achievementPlan(goal: goal, progress: behind, currentDate: now).requiredMonthlyIncrease == nil)
    }

    @MainActor
    @Test func netWorthGoalProjectionExplainsInsufficientAndNonGrowingHistory() async throws {
        let calculator = NetWorthGoalCalculator()
        let now = Date()
        let goal = NetWorthGoal(
            targetAmount: 2_000,
            currency: .usd,
            targetDate: now.addingTimeInterval(365 * 86_400)
        )
        let progress = NetWorthGoalProgress(
            currentAmount: 1_000,
            rawFraction: 0.5,
            visualFraction: 0.5,
            isAchieved: false,
            rateState: .available
        )
        let shortHistory = [
            NetWorthSnapshot(amount: 800, currencyCode: "USD", recordedAt: now.addingTimeInterval(-10 * 86_400)),
            NetWorthSnapshot(amount: 900, currencyCode: "USD", recordedAt: now.addingTimeInterval(-5 * 86_400)),
            NetWorthSnapshot(amount: 1_000, currencyCode: "USD", recordedAt: now)
        ]
        let fallingHistory = [
            NetWorthSnapshot(amount: 1_200, currencyCode: "USD", recordedAt: now.addingTimeInterval(-40 * 86_400)),
            NetWorthSnapshot(amount: 1_100, currencyCode: "USD", recordedAt: now.addingTimeInterval(-20 * 86_400)),
            NetWorthSnapshot(amount: 1_000, currencyCode: "USD", recordedAt: now)
        ]

        #expect(calculator.outlook(
            goal: goal,
            progress: progress,
            snapshots: shortHistory,
            exchangeRates: ["USD": 1]
        ) == .needsHistory)
        #expect(calculator.outlook(
            goal: goal,
            progress: progress,
            snapshots: fallingHistory,
            exchangeRates: ["USD": 1]
        ) == .nonGrowing)
    }

    @MainActor
    @Test func netWorthGoalBackupRoundTripsAndRequiresConflictResolution() async throws {
        let source = try makeInMemoryModelContext()
        let target = try makeInMemoryModelContext()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        source.insert(NetWorthGoal(
            targetAmount: 100_000,
            currency: .usd,
            targetDate: now.addingTimeInterval(365 * 86_400),
            stableIdentifier: "imported-goal",
            createdAt: now,
            updatedAt: now
        ))
        target.insert(NetWorthGoal(
            targetAmount: 50_000,
            currency: .eur,
            targetDate: now.addingTimeInterval(180 * 86_400),
            stableIdentifier: "current-goal",
            createdAt: now,
            updatedAt: now
        ))
        try source.save()
        try target.save()

        let url = try DataExporter.buildExportURL(context: source)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(ExportPayload.self, from: data)
        let preview = try DataImporter.previewImport(data, into: target)

        #expect(payload.version == 2)
        #expect(payload.netWorthGoal?.stableIdentifier == "imported-goal")
        #expect(preview.hasGoalConflict)
        #expect(throws: DataImporter.ImportError.self) {
            try DataImporter.importData(data, into: target)
        }

        _ = try DataImporter.importData(
            data,
            into: target,
            goalConflictResolution: .replaceExisting
        )
        let imported = try NetWorthGoalStore.canonicalGoal(in: target)
        #expect(imported?.displayStableIdentifier == "imported-goal")
        #expect(imported?.displayTargetAmount == 100_000)
    }

    @MainActor
    @Test func netWorthGoalDeletionLeavesPortfolioRecordsUntouched() async throws {
        let context = try makeInMemoryModelContext()
        context.insert(Asset(name: "Cash", amount: 500, currency: .usd, category: .bank))
        context.insert(Liability(name: "Loan", amount: 100, currency: .usd, category: .personalLoan))
        context.insert(NetWorthSnapshot(amount: 400, currencyCode: "USD"))
        context.insert(NetWorthGoal(
            targetAmount: 1_000,
            currency: .usd,
            targetDate: Date().addingTimeInterval(365 * 86_400)
        ))
        try context.save()

        try NetWorthGoalStore.deleteAll(in: context)

        #expect(try context.fetchCount(FetchDescriptor<NetWorthGoal>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Asset>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Liability>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<NetWorthSnapshot>()) == 1)
    }

    @MainActor
    @Test func portfolioShareSummaryIncludesOnlyUserControlledProgressText() async throws {
        let goal = NetWorthGoal(
            targetAmount: 4_000_000,
            currency: .usd,
            targetDate: Date(timeIntervalSince1970: 1_814_284_800),
            stableIdentifier: "share-goal"
        )

        let summary = PortfolioShareSummaryBuilder.build(
            netWorth: 200_000,
            baseCurrency: .usd,
            goal: goal,
            goalProgressFraction: 0.05
        )

        #expect(summary.contains("Wealth Map update"))
        #expect(summary.contains("Net worth:"))
        #expect(summary.contains("200,000"))
        #expect(summary.contains("Goal progress: 5%"))
        #expect(summary.contains("Goal target:"))
        #expect(summary.contains("4,000,000"))
        #expect(summary.contains("Tracked privately with Wealth Map."))
        #expect(!summary.contains("Asset 1"))
        #expect(!summary.contains("Liability 1"))
    }

    @MainActor
    @Test func legacyVersionOneBackupWithoutGoalStillImports() async throws {
        let source = try makeInMemoryModelContext()
        let target = try makeInMemoryModelContext()
        source.insert(Asset(name: "Cash", amount: 500, currency: .usd, category: .bank))
        try source.save()
        let url = try DataExporter.buildExportURL(context: source)
        var json = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        json["version"] = 1
        json.removeValue(forKey: "netWorthGoal")
        let legacyData = try JSONSerialization.data(withJSONObject: json)

        let summary = try DataImporter.importData(legacyData, into: target)

        #expect(summary.assets == 1)
        #expect(try contextCount(Asset.self, in: target) == 1)
        #expect(try NetWorthGoalStore.canonicalGoal(in: target) == nil)
    }

    @MainActor
    @Test func backupImportDeduplicatesRepeatedRecordsWithinOnePayload() async throws {
        let source = try makeInMemoryModelContext()
        let target = try makeInMemoryModelContext()
        source.insert(Asset(name: "Cash", amount: 500, currency: .usd, category: .bank))
        try source.save()
        let url = try DataExporter.buildExportURL(context: source)
        var json = try #require(
            JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        )
        let assets = try #require(json["assets"] as? [[String: Any]])
        json["assets"] = assets + assets
        let duplicatedData = try JSONSerialization.data(withJSONObject: json)

        let summary = try DataImporter.importData(duplicatedData, into: target)

        #expect(summary.assets == 1)
        #expect(try contextCount(Asset.self, in: target) == 1)
    }

    @MainActor
    @Test func assetCurrencyTotalsConvertEveryAssetIntoEachCurrency() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5
        ]

        let assets = [
            Asset(name: "Cash", amount: 1, currency: .usd, category: .bank),
            Asset(name: "Euro Cash", amount: 2, currency: .eur, category: .bank)
        ]

        let totals = viewModel.totalsByCurrency(assets)
        let usdTotal = try #require(totals.first { $0.currency == .usd })
        let eurTotal = try #require(totals.first { $0.currency == .eur })

        #expect(usdTotal.amount == 5)
        #expect(eurTotal.amount == 2.5)
    }

    @MainActor
    @Test func conversionsRequireEveryPositiveHoldingRate() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1]
        let assets = [
            Asset(name: "Cash", amount: 1_000, currency: .usd, category: .bank),
            Asset(name: "Euro Cash", amount: 500, currency: .eur, category: .bank)
        ]
        let liabilities = [
            Liability(name: "Euro Loan", amount: 100, currency: .eur, category: .personalLoan)
        ]

        #expect(viewModel.convertedTotal(assets, to: .usd, exchangeRates: ["USD": 1]) == nil)
        #expect(viewModel.convertedLiabilityTotal(liabilities, to: .usd, exchangeRates: ["USD": 1]) == nil)
        #expect(
            viewModel.netWorthTotal(
                assets,
                liabilities: liabilities,
                to: .usd,
                exchangeRates: ["USD": 1]
            ) == nil
        )
        #expect(viewModel.categoryAllocationRows(assets, targetCurrency: .usd).isEmpty)
    }

    @MainActor
    @Test func largestAssetInsightComparesConvertedValues() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1, "INR": 80]
        let assets = [
            Asset(name: "Rupee Account", amount: 1_000_000, currency: .inr, category: .bank),
            Asset(name: "US Brokerage", amount: 50_000, currency: .usd, category: .stocks)
        ]

        let rows = viewModel.portfolioInsightRows(
            assets: assets,
            liabilities: [],
            netWorthSnapshots: [],
            baseCurrency: .usd,
            limit: 20
        )

        #expect(rows.contains { $0.message.contains("US Brokerage alone") })
        #expect(!rows.contains { $0.message.contains("Rupee Account alone") })
    }

    @MainActor
    @Test func configuredCurrencyTotalsUseBaseAndDisplayCurrencies() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5,
            "INR": 80
        ]

        let assets = [
            Asset(name: "Cash", amount: 1, currency: .usd, category: .bank),
            Asset(name: "Euro Cash", amount: 2, currency: .eur, category: .bank)
        ]

        let totals = viewModel.totalsByCurrency(
            assets,
            baseCurrency: .inr,
            displayCurrencies: [.usd, .eur]
        )

        #expect(totals.map(\.currency) == [.inr, .usd, .eur])
        #expect(totals.first { $0.currency == .inr }?.amount == 400)
        #expect(totals.first { $0.currency == .usd }?.amount == 5)
        #expect(totals.first { $0.currency == .eur }?.amount == 2.5)
    }

    @MainActor
    @Test func configuredCurrencyTotalsSubtractLiabilitiesForNetWorth() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5,
            "INR": 80
        ]

        let assets = [
            Asset(name: "Cash", amount: 1_000, currency: .usd, category: .bank),
            Asset(name: "Euro Cash", amount: 500, currency: .eur, category: .bank)
        ]
        let liabilities = [
            Liability(name: "Mortgage", amount: 200, currency: .usd, category: .mortgage)
        ]

        let totals = viewModel.totalsByCurrency(
            assets,
            liabilities: liabilities,
            baseCurrency: .usd,
            displayCurrencies: [.eur, .inr]
        )

        #expect(totals.first { $0.currency == .usd }?.amount == 1_800)
        #expect(totals.first { $0.currency == .eur }?.amount == 900)
        #expect(totals.first { $0.currency == .inr }?.amount == 144_000)
    }

    @MainActor
    @Test func portfolioInsightsDescribeAllocationAndDebt() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1]
        let assets = [
            Asset(name: "House", amount: 700, currency: .usd, category: .realEstate),
            Asset(name: "Cash", amount: 300, currency: .usd, category: .bank)
        ]
        let liabilities = [
            Liability(name: "Mortgage", amount: 250, currency: .usd, category: .mortgage)
        ]

        let rows = viewModel.portfolioInsightRows(
            assets: assets,
            liabilities: liabilities,
            netWorthSnapshots: [],
            baseCurrency: .usd
        )

        #expect(rows.map(\.message).contains("Debt-to-asset ratio is 25% — elevated."))
        #expect(rows.map(\.message).contains("70% of assets are in Real Estate. Consider diversifying."))
        #expect(rows.map(\.message).contains("70% of assets are in House alone."))
    }

    @MainActor
    @Test func portfolioInsightsDescribeNetWorthTrend() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1]
        let now = Date()
        let snapshots = [
            NetWorthSnapshot(amount: 1_000, currencyCode: "USD", recordedAt: now),
            NetWorthSnapshot(amount: 1_250, currencyCode: "USD", recordedAt: now.addingTimeInterval(60))
        ]

        let rows = viewModel.portfolioInsightRows(
            assets: [],
            liabilities: [],
            netWorthSnapshots: snapshots,
            baseCurrency: .usd
        )

        #expect(rows.first?.message == "Net worth up 25.0% over the last 0d.")
    }

    @MainActor
    @Test func portfolioIntelligenceScoresAllCashPortfolioLikeBriefingReference() async throws {
        let calculator = PortfolioIntelligenceCalculator()
        let assets = [
            Asset(name: "Cash", amount: 800_000, currency: .usd, category: .bank)
        ]

        let report = calculator.makeReport(
            assets: assets,
            liabilities: [],
            netWorthSnapshots: [],
            exchangeRates: ["USD": 1],
            baseCurrency: .usd,
            generatedAt: Date(timeIntervalSince1970: 1_779_300_000)
        )

        #expect(report.score == 59)
        #expect(report.grade == .solid)
        #expect(report.focusArea == "Diversification")
        #expect(report.metrics.map(\.score) == [0, 14, 20, 10, 15])
        #expect(report.observations.contains { $0.id == "asset-concentration" })
    }

    @MainActor
    @Test func portfolioIntelligenceIsUnavailableWhenConversionIsIncomplete() async throws {
        let report = PortfolioIntelligenceCalculator().makeReport(
            assets: [
                Asset(name: "Euro Account", amount: 1_000, currency: .eur, category: .bank)
            ],
            liabilities: [],
            netWorthSnapshots: [],
            exchangeRates: ["USD": 1],
            baseCurrency: .usd
        )

        #expect(!report.isConversionComplete)
        #expect(report.metrics.isEmpty)
        #expect(report.observations.map(\.id) == ["conversion-unavailable"])
    }

    @MainActor
    @Test func fireProjectionCalculatesTargetsLevelsAndOneMoreYear() async throws {
        let projection = FIRECalculator().project(
            currentPortfolio: 800_000,
            monthlyExpenses: 2_500,
            monthlySavings: 2_500,
            retireAtAge: 65,
            currentAge: nil,
            annualReturn: 0.07,
            currentDate: Date(timeIntervalSince1970: 1_779_300_000)
        )

        #expect(projection.fireTarget == 750_000)
        #expect(projection.isFIREReached)
        #expect(projection.savingsRate == 0.5)
        #expect(projection.levelProgress.first { $0.kind == .lean }?.isAchieved == true)
        #expect(projection.levelProgress.first { $0.kind == .standard }?.isAchieved == true)
        #expect(projection.levelProgress.first { $0.kind == .fat }?.isAchieved == false)
        #expect(projection.portfolioAfterOneYear > 880_000)
        #expect(projection.extraAnnualSpendingAfterOneYear > 3_000)
    }

    @MainActor
    @Test func livingComfortUsesCurrencyCountryAndHouseholdAssumptions() async throws {
        let calculator = LivingComfortCalculator()
        let totals = [
            CurrencyTotal(currency: .usd, amount: 120_000),
            CurrencyTotal(currency: .inr, amount: 12_000_000)
        ]
        let rows = calculator.rows(
            totals: totals,
            baseCurrency: .usd,
            exchangeRates: ["USD": 1, "INR": 80],
            assumptions: LivingComfortAssumptions(
                householdMembers: 2,
                monthlyIncome: 8_000,
                expectedMonthlySpend: 3_000,
                monthlyIncomeWasProvided: true,
                expectedMonthlySpendWasProvided: true
            )
        )

        #expect(rows.map(\.countryName) == ["United States", "India"])
        #expect(abs((rows.first?.monthlySpendEstimate ?? 0) - 4_950) < 0.01)
        #expect(abs((rows.first?.runwayMonths ?? 0) - (120_000 / 4_950)) < 0.01)
        #expect(rows.first?.level == .stable)
        #expect(abs((rows.last?.monthlySpendEstimate ?? 0) - 98_489.73248563136) < 0.01)
        #expect(abs((rows.last?.monthlySurplus ?? 0) - 60_685.592743672) < 0.01)
        #expect(abs((rows.last?.pppConversionFactor ?? 0) - 19.8969156536629) < 0.0001)
    }

    @MainActor
    @Test func livingComfortTreatsZeroAsProvidedInput() async throws {
        let calculator = LivingComfortCalculator()
        let row = calculator.row(
            total: CurrencyTotal(currency: .usd, amount: 120_000),
            baseCurrency: .usd,
            exchangeRates: ["USD": 1],
            assumptions: LivingComfortAssumptions(
                householdMembers: 1,
                monthlyIncome: 0,
                expectedMonthlySpend: 0,
                monthlyIncomeWasProvided: true,
                expectedMonthlySpendWasProvided: true
            )
        )

        #expect(row.monthlySpendEstimate == 0)
        #expect(row.monthlySurplus == 0)
        #expect(row.runwayMonths.isInfinite)
        #expect(row.level == .independent)
    }

    @MainActor
    @Test func onboardingCompletionPersistsSelectedCurrencies() async throws {
        let defaults = try makeIsolatedDefaults()
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )

        #expect(settings.hasCompletedOnboarding.isComplete == false)
        #expect(settings.hasCompletedOnboarding.missingSteps == [.baseCurrency, .displayCurrencies, .iCloudSync])

        settings.completeOnboarding(
            baseCurrency: .eur,
            displayCurrencies: [.usd, .inr]
        )

        let restoredSettings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )
        #expect(restoredSettings.hasCompletedOnboarding.isComplete == true)
        #expect(restoredSettings.hasCompletedOnboarding.missingSteps.isEmpty)
        #expect(restoredSettings.baseCurrency == .eur)
        #expect(restoredSettings.totalCurrencies == [.eur, .usd, .inr])
    }

    @MainActor
    @Test func displayCurrencyOrderCanBeRearrangedAndPersisted() async throws {
        let defaults = try makeIsolatedDefaults()
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )

        settings.completeOnboarding(
            baseCurrency: .usd,
            displayCurrencies: [.eur, .inr, .gbp]
        )

        settings.moveTotalCurrencies(fromOffsets: IndexSet(integer: 3), toOffset: 1)

        let restoredSettings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )

        #expect(settings.totalCurrencies == [.usd, .gbp, .eur, .inr])
        #expect(restoredSettings.totalCurrencies == [.usd, .gbp, .eur, .inr])
    }

    @MainActor
    @Test func displayCurrencyTogglePreservesPriorityOrderAndBaseCurrency() async throws {
        let defaults = try makeIsolatedDefaults()
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )

        settings.toggleTotalCurrency(.eur)
        settings.toggleTotalCurrency(.usd)

        #expect(settings.totalCurrencies == [.usd, .inr, .eur])
    }

    @MainActor
    @Test func ignoredAssetsAreExcludedUnlessSettingsIncludeThem() async throws {
        let defaults = try makeIsolatedDefaults()
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )
        let included = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        let ignored = Asset(
            name: "Side Account",
            amount: 50,
            currency: .usd,
            category: .bank,
            isIncludedInPortfolio: false
        )

        #expect(settings.portfolioCalculationAssets(from: [included, ignored]).map(\.displayName) == ["Cash"])

        settings.includeIgnoredAssetsInPortfolio = true

        #expect(settings.portfolioCalculationAssets(from: [included, ignored]).map(\.displayName) == ["Cash", "Side Account"])
    }

    @MainActor
    @Test func portfolioHistoryScopeStartPersistsAcrossSettingsInstances() async throws {
        let defaults = try makeIsolatedDefaults()
        let scopeStart = Date(timeIntervalSince1970: 1_800_000_000)
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )

        settings.beginNewPortfolioHistoryScope(at: scopeStart)

        let restored = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )
        #expect(restored.portfolioHistoryScopeStartedAt == scopeStart)
    }

    @MainActor
    @Test func hidingAssetChangesMembershipButNotHistorySignature() async throws {
        let defaults = try makeIsolatedDefaults()
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )
        let modelContext = try makeInMemoryModelContext()
        let asset = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        modelContext.insert(asset)

        let before = PortfolioHistoryCoordinator(
            allAssets: [asset],
            assets: settings.portfolioCalculationAssets(from: [asset]),
            liabilities: [],
            netWorthSnapshots: [],
            assetValueSnapshots: [],
            settings: settings,
            viewModel: DashboardViewModel(autoRefreshRate: false),
            modelContext: modelContext
        )

        let historySignature = before.assetSnapshotSignature
        let membershipSignature = before.portfolioMembershipSignature

        asset.isIncludedInPortfolio = false
        asset.lastUpdated = Date()

        let after = PortfolioHistoryCoordinator(
            allAssets: [asset],
            assets: settings.portfolioCalculationAssets(from: [asset]),
            liabilities: [],
            netWorthSnapshots: [],
            assetValueSnapshots: [],
            settings: settings,
            viewModel: DashboardViewModel(autoRefreshRate: false),
            modelContext: modelContext
        )

        #expect(after.assetSnapshotSignature == historySignature)
        #expect(after.portfolioMembershipSignature != membershipSignature)
    }

    @MainActor
    @Test func includeIgnoredAssetsToggleChangesMembershipButNotHistorySignature() async throws {
        let defaults = try makeIsolatedDefaults()
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )
        let modelContext = try makeInMemoryModelContext()
        let included = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        let ignored = Asset(
            name: "Side Account",
            amount: 50,
            currency: .usd,
            category: .bank,
            isIncludedInPortfolio: false
        )
        modelContext.insert(included)
        modelContext.insert(ignored)
        let allAssets = [included, ignored]

        let before = PortfolioHistoryCoordinator(
            allAssets: allAssets,
            assets: settings.portfolioCalculationAssets(from: allAssets),
            liabilities: [],
            netWorthSnapshots: [],
            assetValueSnapshots: [],
            settings: settings,
            viewModel: DashboardViewModel(autoRefreshRate: false),
            modelContext: modelContext
        )

        let historySignature = before.assetSnapshotSignature
        let membershipSignature = before.portfolioMembershipSignature

        settings.includeIgnoredAssetsInPortfolio = true

        let after = PortfolioHistoryCoordinator(
            allAssets: allAssets,
            assets: settings.portfolioCalculationAssets(from: allAssets),
            liabilities: [],
            netWorthSnapshots: [],
            assetValueSnapshots: [],
            settings: settings,
            viewModel: DashboardViewModel(autoRefreshRate: false),
            modelContext: modelContext
        )

        #expect(after.assetSnapshotSignature == historySignature)
        #expect(after.portfolioMembershipSignature != membershipSignature)
    }

    @MainActor
    @Test func portfolioScopeResetsOnlyForPolicyChangesNotAssetAdds() {
        let initial = PortfolioMembershipState(
            assetIdentifiers: ["asset-1"],
            calculationAssetIdentifiers: ["asset-1"],
            includesIgnoredAssets: false
        )
        let excluded = PortfolioMembershipState(
            assetIdentifiers: ["asset-1"],
            calculationAssetIdentifiers: [],
            includesIgnoredAssets: false
        )
        let added = PortfolioMembershipState(
            assetIdentifiers: ["asset-1", "asset-2"],
            calculationAssetIdentifiers: ["asset-1", "asset-2"],
            includesIgnoredAssets: false
        )

        #expect(excluded.isPolicyChange(from: initial))
        #expect(!added.isPolicyChange(from: initial))
    }

    @MainActor
    @Test func transferRateRowsConvertFromBaseCurrencyToDisplayCurrencies() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5,
            "INR": 80
        ]

        let rows = viewModel.transferRateRows(
            baseCurrency: .eur,
            displayCurrencies: [.eur, .usd, .inr]
        )

        #expect(rows.count == 2)
        #expect(rows.map(\.targetCurrency) == [.usd, .inr])
        #expect(rows.first { $0.targetCurrency == .usd }?.rate == 2)
        #expect(rows.first { $0.targetCurrency == .inr }?.rate == 160)
    }

    @MainActor
    @Test func transferRateRowsCanBeLimitedForDashboard() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5,
            "INR": 80,
            "GBP": 0.8,
            "CAD": 1.3
        ]

        let rows = viewModel.transferRateRows(
            baseCurrency: .usd,
            displayCurrencies: [.usd, .eur, .inr, .gbp, .cad],
            limit: 3
        )

        #expect(rows.map(\.targetCurrency) == [.eur, .inr, .gbp])
    }

    @MainActor
    @Test func rateStatusShowsMissingRefreshAndErrors() async throws {
        let viewModel = DashboardViewModel(
            autoRefreshRate: false,
            userDefaults: try makeIsolatedDefaults()
        )

        #expect(viewModel.rateStatus?.message == "Exchange rates have not been refreshed yet.")

        viewModel.rateErrorMessage = "Unable to refresh exchange rates. Showing the last saved rates."

        #expect(viewModel.rateStatus?.message == "Unable to refresh exchange rates. Showing the last saved rates.")
    }

    @MainActor
    @Test func dashboardViewModelFetchUsesInjectedServiceAndDefaults() async throws {
        let defaults = try makeIsolatedDefaults()
        let service = StubExchangeRateService(
            response: RateResponse(
                base: "USD",
                date: "2026-05-20",
                rates: ["EUR": 0.5, "INR": 80],
                success: true,
                timestamp: 1_779_264_000,
                cacheTimestamp: 1_779_300_000
            )
        )
        let viewModel = DashboardViewModel(
            autoRefreshRate: false,
            userDefaults: defaults,
            exchangeRateService: service
        )

        await viewModel.fetchExchangeRate()

        let restoredViewModel = DashboardViewModel(
            autoRefreshRate: false,
            userDefaults: defaults,
            exchangeRateService: service
        )

        #expect(viewModel.exchangeRate == 80)
        #expect(viewModel.exchangeRates["USD"] == 1)
        #expect(viewModel.exchangeRates["EUR"] == 0.5)
        #expect(restoredViewModel.exchangeRate == 80)
        #expect(restoredViewModel.exchangeRates["INR"] == 80)
        #expect(viewModel.lastUpdated == Date(timeIntervalSince1970: 1_779_300_000))
        #expect(restoredViewModel.lastUpdated == Date(timeIntervalSince1970: 1_779_300_000))
        #expect(viewModel.rateErrorMessage == nil)
    }

    @MainActor
    @Test func exchangeRateRefreshIfNeededCallsCachedBackendEvenWhenUpdatedToday() async throws {
        let defaults = try makeIsolatedDefaults()
        defaults.set(["EUR": 0.5, "USD": 1], forKey: "exchangeRate.rates")
        defaults.set(Date().timeIntervalSince1970, forKey: "exchangeRate.lastUpdated")
        let service = StubExchangeRateService(
            response: RateResponse(
                base: "USD",
                date: "2026-05-24",
                rates: ["EUR": 0.6, "INR": 83],
                success: true,
                timestamp: 1_779_609_600,
                cacheTimestamp: 1_779_620_000
            )
        )
        let viewModel = DashboardViewModel(
            autoRefreshRate: false,
            userDefaults: defaults,
            exchangeRateService: service
        )

        await viewModel.refreshExchangeRateIfNeeded(requiredCurrencies: [.eur])

        #expect(service.fetchCount == 1)
        #expect(viewModel.exchangeRates["EUR"] == 0.6)
        #expect(viewModel.exchangeRates["INR"] == 83)
        #expect(viewModel.lastUpdated == Date(timeIntervalSince1970: 1_779_620_000))
    }

    @MainActor
    @Test func metalPriceRefreshIfNeededCallsCachedBackendEvenWhenUpdatedToday() async throws {
        let defaults = try makeIsolatedDefaults()
        defaults.set(["XAU": 0.0004], forKey: "metalPrice.rates")
        defaults.set(Date().timeIntervalSince1970, forKey: "metalPrice.lastUpdated")
        let service = StubMetalPriceService(
            response: RateResponse(
                base: "USD",
                date: "2026-05-24",
                rates: ["XAU": 0.0005],
                success: true,
                timestamp: 1_779_609_600,
                cacheTimestamp: 1_779_620_000
            )
        )
        let viewModel = MetalPricesViewModel(
            userDefaults: defaults,
            metalPriceService: service
        )

        await viewModel.refreshIfNeeded()

        #expect(service.fetchCount == 1)
        #expect(viewModel.metalRates["XAU"] == 0.0005)
        #expect(viewModel.lastUpdated == Date(timeIntervalSince1970: 1_779_620_000))
    }

    @MainActor
    @Test func metalPricesDoNotMislabelUSDWhenBaseRateIsMissing() async throws {
        let viewModel = MetalPricesViewModel(
            userDefaults: try makeIsolatedDefaults(),
            metalPriceService: StubMetalPriceService(
                response: RateResponse(
                    base: "USD",
                    date: nil,
                    rates: ["XAU": 0.0005],
                    success: true,
                    timestamp: nil,
                    cacheTimestamp: nil
                )
            )
        )
        viewModel.metalRates = ["XAU": 0.0005]

        let missingRateRows = viewModel.metalPriceRows(
            baseCurrency: .inr,
            exchangeRates: ["USD": 1]
        )
        let convertedRows = viewModel.metalPriceRows(
            baseCurrency: .inr,
            exchangeRates: ["USD": 1, "INR": 80]
        )

        #expect(missingRateRows.first { $0.symbol == "XAU" }?.priceInBase == nil)
        #expect(convertedRows.first { $0.symbol == "XAU" }?.priceInBase == 160_000)
    }

    @MainActor
    @Test func dedicatedMetalRatesSurviveForexRefreshAndTakePrecedence() async throws {
        let service = StubExchangeRateService(
            response: RateResponse(
                base: "USD",
                date: nil,
                rates: ["XAU": 0.0004, "EUR": 0.9],
                success: true,
                timestamp: nil,
                cacheTimestamp: nil
            )
        )
        let viewModel = DashboardViewModel(
            autoRefreshRate: false,
            userDefaults: try makeIsolatedDefaults(),
            exchangeRateService: service
        )
        viewModel.enrichWithMetalRates(["XAU": 0.0005, "XPT": 0.001])

        await viewModel.fetchExchangeRate(requiredCurrencies: [.xau, .xpt])

        #expect(viewModel.exchangeRates["XAU"] == 0.0005)
        #expect(viewModel.exchangeRates["XPT"] == 0.001)
        #expect(viewModel.exchangeRates["EUR"] == 0.9)
    }

    @MainActor
    @Test func unsupportedRhodiumIsNotOfferedAsLivePricedMetal() {
        #expect(Asset.CategoryType.gold.supportsLiveMetalPricing)
        #expect(Asset.CategoryType.palladium.supportsLiveMetalPricing)
        #expect(!Asset.CategoryType.rhodium.supportsLiveMetalPricing)
        #expect(!PreciousMetalSelectionView.metals.contains { $0.currency == .xrh })
    }

    @MainActor
    @Test func exchangeRateFetchDoesNotRequireINRUnlessNeeded() async throws {
        let defaults = try makeIsolatedDefaults()
        let service = StubExchangeRateService(
            response: RateResponse(
                base: "USD",
                date: "2026-05-20",
                rates: ["EUR": 0.5],
                success: true,
                timestamp: 1_779_264_000,
                cacheTimestamp: nil
            )
        )
        let viewModel = DashboardViewModel(
            autoRefreshRate: false,
            userDefaults: defaults,
            exchangeRateService: service
        )

        await viewModel.fetchExchangeRate(requiredCurrencies: [.eur])

        #expect(viewModel.exchangeRates["USD"] == 1)
        #expect(viewModel.exchangeRates["EUR"] == 0.5)
        #expect(viewModel.rateErrorMessage == nil)
        #expect(defaults.object(forKey: "exchangeRate.rates") as? [String: Double] == ["EUR": 0.5, "USD": 1])
    }

    @MainActor
    @Test func exchangeRateFetchWarnsOnlyForMissingRequiredCurrencies() async throws {
        let defaults = try makeIsolatedDefaults()
        let service = StubExchangeRateService(
            response: RateResponse(
                base: "USD",
                date: "2026-05-20",
                rates: ["EUR": 0.5],
                success: true,
                timestamp: 1_779_264_000,
                cacheTimestamp: nil
            )
        )
        let viewModel = DashboardViewModel(
            autoRefreshRate: false,
            userDefaults: defaults,
            exchangeRateService: service
        )

        await viewModel.fetchExchangeRate(requiredCurrencies: [.eur, .inr])

        #expect(viewModel.exchangeRates["EUR"] == 0.5)
        #expect(viewModel.rateErrorMessage == "Exchange rates are missing INR. Totals may be incomplete.")
    }

    @MainActor
    @Test func categoryAllocationRowsCalculatePercentages() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5
        ]

        let assets = [
            Asset(name: "Cash", amount: 100, currency: .usd, category: .bank),
            Asset(name: "Stocks", amount: 100, currency: .eur, category: .stocks)
        ]

        let rows = viewModel.categoryAllocationRows(assets)
        let stocks = try #require(rows.first { $0.category == .stocks })
        let bank = try #require(rows.first { $0.category == .bank })

        #expect(stocks.amount == 200)
        #expect(stocks.percentage == 2.0 / 3.0)
        #expect(bank.amount == 100)
        #expect(bank.percentage == 1.0 / 3.0)
    }

    @MainActor
    @Test func categoryAllocationRowsCanUseSelectedCurrency() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5,
            "INR": 80
        ]

        let assets = [
            Asset(name: "Cash", amount: 100, currency: .usd, category: .bank),
            Asset(name: "Stocks", amount: 100, currency: .eur, category: .stocks)
        ]

        let rows = viewModel.categoryAllocationRows(assets, targetCurrency: .inr)
        let stocks = try #require(rows.first { $0.category == .stocks })
        let bank = try #require(rows.first { $0.category == .bank })

        #expect(stocks.amount == 16_000)
        #expect(stocks.percentage == 2.0 / 3.0)
        #expect(bank.amount == 8_000)
        #expect(bank.percentage == 1.0 / 3.0)
    }

    @MainActor
    @Test func netWorthTrendRowsSortFilterAndLimitSnapshots() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let now = Date()
        let snapshots = [
            NetWorthSnapshot(amount: 1, currencyCode: "EUR", recordedAt: now),
            NetWorthSnapshot(amount: 3, currencyCode: "USD", recordedAt: now.addingTimeInterval(30)),
            NetWorthSnapshot(amount: 1, currencyCode: "USD", recordedAt: now.addingTimeInterval(10)),
            NetWorthSnapshot(amount: 2, currencyCode: "USD", recordedAt: now.addingTimeInterval(20))
        ]

        let rows = viewModel.netWorthTrendRows(snapshots, baseCurrency: .usd, limit: 2)

        #expect(rows.map(\.amount) == [2, 3])
        #expect(rows.allSatisfy { $0.currencyCode == "USD" })
    }

    @MainActor
    @Test func historyRowsExcludeSnapshotsFromPreviousPortfolioScope() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let oldDate = Date(timeIntervalSince1970: 1_700_000_000)
        let scopeStart = Date(timeIntervalSince1970: 1_750_000_000)
        let newDate = Date(timeIntervalSince1970: 1_800_000_000)
        let netWorthSnapshots = [
            NetWorthSnapshot(amount: 100, currencyCode: "USD", recordedAt: oldDate),
            NetWorthSnapshot(amount: 40, currencyCode: "USD", recordedAt: newDate)
        ]
        let portfolioSnapshots = [
            PortfolioSnapshot(
                assetTotal: 150,
                liabilityTotal: 50,
                currencyCode: "USD",
                recordedAt: oldDate
            ),
            PortfolioSnapshot(
                assetTotal: 90,
                liabilityTotal: 50,
                currencyCode: "USD",
                recordedAt: newDate
            )
        ]

        let netWorthRows = viewModel.netWorthTrendRows(
            netWorthSnapshots,
            baseCurrency: .usd,
            since: scopeStart
        )
        let portfolioRows = viewModel.portfolioTrendRows(
            portfolioSnapshots,
            baseCurrency: .usd,
            since: scopeStart
        )

        #expect(netWorthRows.map(\.amount) == [40])
        #expect(portfolioRows.map(\.assetTotal) == [90])
    }

    @MainActor
    @Test func netWorthTrendRowsUseStableUniqueSnapshotIds() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let context = try makeInMemoryModelContext()
        let now = Date()
        let snapshots = [
            NetWorthSnapshot(amount: 100, currencyCode: "USD", recordedAt: now),
            NetWorthSnapshot(amount: 200, currencyCode: "USD", recordedAt: now)
        ]
        snapshots.forEach { context.insert($0) }

        let rows = viewModel.netWorthTrendRows(snapshots, baseCurrency: .usd)

        #expect(Set(rows.map(\.id)).count == rows.count)
    }

    @MainActor
    @Test func recentAssetHistoryRowsUseLatestSnapshotsFirst() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let now = Date()
        let snapshots = [
            AssetValueSnapshot(
                assetIdentifier: "1",
                assetName: "Old",
                amount: 1,
                currencyCode: "USD",
                categoryName: "Bank Deposits",
                recordedAt: now
            ),
            AssetValueSnapshot(
                assetIdentifier: "2",
                assetName: "New",
                amount: 2,
                currencyCode: "EUR",
                categoryName: "Stocks",
                recordedAt: now.addingTimeInterval(60)
            )
        ]

        let rows = viewModel.recentAssetHistoryRows(snapshots, limit: 1)

        #expect(rows.map(\.assetName) == ["New"])
        #expect(rows.first?.currencyCode == "EUR")
    }

    @MainActor
    @Test func recentAssetHistoryRowsUseStableUniqueSnapshotIds() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let context = try makeInMemoryModelContext()
        let now = Date()
        let snapshots = [
            AssetValueSnapshot(
                assetIdentifier: "asset-1",
                assetName: "Cash",
                amount: 100,
                currencyCode: "USD",
                categoryName: "Bank Deposits",
                recordedAt: now
            ),
            AssetValueSnapshot(
                assetIdentifier: "asset-2",
                assetName: "Cash",
                amount: 100,
                currencyCode: "USD",
                categoryName: "Bank Deposits",
                recordedAt: now
            )
        ]
        snapshots.forEach { context.insert($0) }

        let rows = viewModel.recentAssetHistoryRows(snapshots)

        #expect(Set(rows.map(\.id)).count == rows.count)
    }

    @MainActor
    @Test func assetHistoryRowsFilterToSelectedAssetNewestFirst() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let asset = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        let otherAsset = Asset(name: "Stocks", amount: 250, currency: .usd, category: .stocks)
        let now = Date()
        let snapshots = [
            AssetValueSnapshot(
                assetIdentifier: asset.stableHistoryIdentifier,
                assetName: "Cash",
                amount: 90,
                currencyCode: "USD",
                categoryName: "Bank Deposits",
                recordedAt: now
            ),
            AssetValueSnapshot(
                assetIdentifier: otherAsset.stableHistoryIdentifier,
                assetName: "Stocks",
                amount: 250,
                currencyCode: "USD",
                categoryName: "Stocks",
                recordedAt: now.addingTimeInterval(30)
            ),
            AssetValueSnapshot(
                assetIdentifier: asset.stableHistoryIdentifier,
                assetName: "Cash",
                amount: 100,
                currencyCode: "USD",
                categoryName: "Bank Deposits",
                recordedAt: now.addingTimeInterval(60)
            )
        ]

        let rows = viewModel.assetHistoryRows(for: asset, snapshots: snapshots)

        #expect(rows.map(\.amount) == [100, 90])
        #expect(rows.allSatisfy { $0.assetName == "Cash" })
    }

    @MainActor
    @Test func assetHistoryRowsIncludeLegacyPersistentModelIdentifier() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let context = try makeInMemoryModelContext()
        let asset = Asset(name: "Legacy", amount: 100, currency: .usd, category: .bank)
        context.insert(asset)
        let legacySnapshot = AssetValueSnapshot(
            assetIdentifier: String(describing: asset.persistentModelID),
            assetName: "Legacy",
            amount: 80,
            currencyCode: "USD",
            categoryName: "Bank Deposits"
        )

        let rows = viewModel.assetHistoryRows(for: asset, snapshots: [legacySnapshot])

        #expect(rows.map(\.amount) == [80])
    }

    @MainActor
    @Test func assetSnapshotRecordingIgnoresMetadataChanges() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1, "EUR": 0.5]
        let modelContext = try makeInMemoryModelContext()
        let asset = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        modelContext.insert(asset)
        let existingSnapshot = AssetValueSnapshot(
            assetIdentifier: String(describing: asset.persistentModelID),
            assetName: "Old Cash",
            amount: 100,
            currencyCode: "USD",
            categoryName: "Stocks"
        )
        modelContext.insert(existingSnapshot)

        viewModel.recordPortfolioHistory(
            assets: [asset],
            baseCurrency: .usd,
            netWorthSnapshots: [],
            assetValueSnapshots: [existingSnapshot],
            modelContext: modelContext
        )

        let snapshots = try modelContext.fetch(FetchDescriptor<AssetValueSnapshot>())
        #expect(snapshots.count == 1)
    }

    @MainActor
    @Test func assetSnapshotRecordingUsesCurrencyChanges() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1, "EUR": 0.5]
        let modelContext = try makeInMemoryModelContext()
        let asset = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        modelContext.insert(asset)
        let existingSnapshot = AssetValueSnapshot(
            assetIdentifier: String(describing: asset.persistentModelID),
            assetName: "Cash",
            amount: 100,
            currencyCode: "EUR",
            categoryName: "Bank Deposits"
        )
        modelContext.insert(existingSnapshot)

        viewModel.recordPortfolioHistory(
            assets: [asset],
            baseCurrency: .usd,
            netWorthSnapshots: [],
            assetValueSnapshots: [existingSnapshot],
            modelContext: modelContext
        )

        let snapshots = try modelContext.fetch(FetchDescriptor<AssetValueSnapshot>())
        #expect(snapshots.count == 2)
    }

    @MainActor
    @Test func assetSnapshotRecordingUsesValueChanges() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1]
        let modelContext = try makeInMemoryModelContext()
        let asset = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        modelContext.insert(asset)
        let existingSnapshot = AssetValueSnapshot(
            assetIdentifier: String(describing: asset.persistentModelID),
            assetName: "Cash",
            amount: 90,
            currencyCode: "USD",
            categoryName: "Bank Deposits"
        )
        modelContext.insert(existingSnapshot)

        viewModel.recordPortfolioHistory(
            assets: [asset],
            baseCurrency: .usd,
            netWorthSnapshots: [],
            assetValueSnapshots: [existingSnapshot],
            modelContext: modelContext
        )

        let snapshots = try modelContext.fetch(FetchDescriptor<AssetValueSnapshot>())
        #expect(snapshots.count == 2)
    }

    @MainActor
    @Test func assetSnapshotRecordingUsesStableAssetIdentifier() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1]
        let modelContext = try makeInMemoryModelContext()
        let asset = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        modelContext.insert(asset)

        viewModel.recordPortfolioHistory(
            assets: [asset],
            baseCurrency: .usd,
            netWorthSnapshots: [],
            assetValueSnapshots: [],
            modelContext: modelContext
        )

        let snapshots = try modelContext.fetch(FetchDescriptor<AssetValueSnapshot>())
        let snapshot = try #require(snapshots.first)
        #expect(snapshot.assetIdentifier == asset.stableHistoryIdentifier)
        #expect(snapshot.assetIdentifier != String(describing: asset.persistentModelID))
    }

    @MainActor
    @Test func netWorthSnapshotRecordingSubtractsLiabilities() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1]
        let modelContext = try makeInMemoryModelContext()
        let asset = Asset(name: "Cash", amount: 1_000, currency: .usd, category: .bank)
        let liability = Liability(name: "Credit Card", amount: 250, currency: .usd, category: .creditCard)
        modelContext.insert(asset)
        modelContext.insert(liability)

        viewModel.recordPortfolioHistory(
            assets: [asset],
            liabilities: [liability],
            baseCurrency: .usd,
            netWorthSnapshots: [],
            assetValueSnapshots: [],
            modelContext: modelContext
        )

        let snapshots = try modelContext.fetch(FetchDescriptor<NetWorthSnapshot>())
        let snapshot = try #require(snapshots.first)
        #expect(snapshot.displayAmount == 750)
    }

    @MainActor
    @Test func newPortfolioScopeRecordsFreshBaselineWithoutDeletingOldHistory() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1]
        let modelContext = try makeInMemoryModelContext()
        let asset = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        let oldSnapshot = NetWorthSnapshot(
            amount: 100,
            currencyCode: "USD",
            recordedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        modelContext.insert(asset)
        modelContext.insert(oldSnapshot)
        let scopeStart = Date(timeIntervalSince1970: 1_750_000_000)

        viewModel.recordPortfolioHistory(
            assets: [asset],
            baseCurrency: .usd,
            netWorthSnapshots: [oldSnapshot],
            assetValueSnapshots: [],
            scopeStartedAt: scopeStart,
            modelContext: modelContext
        )

        let snapshots = try modelContext.fetch(FetchDescriptor<NetWorthSnapshot>())
        #expect(snapshots.count == 2)
        #expect(snapshots.contains { $0.displayRecordedAt < scopeStart })
        #expect(snapshots.contains { $0.displayRecordedAt >= scopeStart })
    }

    @MainActor
    @Test func highlightPresentationStorePresentsMonthlyAndWeeklyOnce() throws {
        let defaults = try makeIsolatedDefaults()
        let calendar = Self.highlightsTestCalendar
        let store = HighlightPresentationStore(userDefaults: defaults, calendar: calendar)
        let firstOfMonth = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 1, hour: 9))
        )
        let saturday = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 4, hour: 9))
        )

        let monthly = store.automaticPeriod(on: firstOfMonth, onboardingComplete: true)
        let repeatedMonthly = store.automaticPeriod(on: firstOfMonth, onboardingComplete: true)
        if let monthly {
            store.markDismissed(monthly)
        }
        let catchUpWeekly = store.automaticPeriod(on: firstOfMonth, onboardingComplete: true)
        if let catchUpWeekly {
            store.markDismissed(catchUpWeekly)
        }
        let suppressedMonthlyAndCatchUp = store.automaticPeriod(
            on: firstOfMonth,
            onboardingComplete: true
        )
        let weekly = store.automaticPeriod(on: saturday, onboardingComplete: true)
        let repeatedWeekly = store.automaticPeriod(on: saturday, onboardingComplete: true)
        if let weekly {
            store.markDismissed(weekly)
        }
        let dismissedWeekly = store.automaticPeriod(on: saturday, onboardingComplete: true)

        #expect(monthly?.kind == .monthly)
        #expect(repeatedMonthly?.kind == .monthly)
        #expect(catchUpWeekly?.kind == .weekly)
        #expect(suppressedMonthlyAndCatchUp == nil)
        #expect(weekly?.kind == .weekly)
        #expect(repeatedWeekly?.kind == .weekly)
        #expect(dismissedWeekly == nil)
    }

    @MainActor
    @Test func highlightPresentationStoreGatesOnboardingAndHandlesOverlap() throws {
        let defaults = try makeIsolatedDefaults()
        let calendar = Self.highlightsTestCalendar
        let store = HighlightPresentationStore(userDefaults: defaults, calendar: calendar)
        let overlappingSaturday = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 1, hour: 9))
        )

        #expect(
            store.automaticPeriod(
                on: overlappingSaturday,
                onboardingComplete: false
            ) == nil
        )
        #expect(store.lastDismissedIdentifier(for: .weekly) == nil)
        #expect(store.lastDismissedIdentifier(for: .monthly) == nil)

        let monthly = store.automaticPeriod(
            on: overlappingSaturday,
            onboardingComplete: true
        )

        #expect(monthly?.kind == .monthly)
        #expect(store.lastDismissedIdentifier(for: .monthly) == nil)
        #expect(store.lastDismissedIdentifier(for: .weekly) == nil)
        store.markDismissed(try #require(monthly))

        let weekly = store.automaticPeriod(
            on: overlappingSaturday,
            onboardingComplete: true
        )
        #expect(weekly?.kind == .weekly)
        store.markDismissed(try #require(weekly))

        #expect(
            store.automaticPeriod(
                on: overlappingSaturday,
                onboardingComplete: true
            ) == nil
        )
    }

    @MainActor
    @Test func highlightPresentationCatchesUpMonthlyAndWeeklyUntilDismissed() throws {
        let defaults = try makeIsolatedDefaults()
        let calendar = Self.highlightsTestCalendar
        let store = HighlightPresentationStore(userDefaults: defaults, calendar: calendar)
        let julyTenth = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 10, hour: 9))
        )
        let julySixth = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 6, hour: 9))
        )
        let previousMonth = try #require(
            WealthHighlightPeriod(
                kind: .monthly,
                referenceDate: calendar.date(
                    from: DateComponents(year: 2026, month: 6, day: 15)
                )!,
                calendar: calendar
            )
        )

        let monthly = try #require(
            store.automaticPeriod(on: julyTenth, onboardingComplete: true)
        )
        #expect(monthly.kind == .monthly)
        #expect(monthly.identifier == previousMonth.identifier)
        store.markDismissed(monthly)

        let weekly = try #require(
            store.automaticPeriod(on: julySixth, onboardingComplete: true)
        )
        let expectedWeekly = try #require(
            WealthHighlightPeriod(
                kind: .weekly,
                referenceDate: calendar.date(
                    from: DateComponents(year: 2026, month: 7, day: 4, hour: 9)
                )!,
                calendar: calendar
            )
        )
        #expect(weekly.kind == .weekly)
        #expect(weekly.identifier == expectedWeekly.identifier)
        store.markDismissed(weekly)
        #expect(store.automaticPeriod(on: julySixth, onboardingComplete: true) == nil)
    }

    @MainActor
    @Test func highlightPresentationOverlapRestoresWeeklyAfterLateMonthlyDismissal() throws {
        let defaults = try makeIsolatedDefaults()
        let calendar = Self.highlightsTestCalendar
        let store = HighlightPresentationStore(userDefaults: defaults, calendar: calendar)
        let overlappingSaturday = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 1, hour: 9))
        )
        let followingSunday = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 2, hour: 9))
        )
        let expectedWeekly = try #require(
            WealthHighlightPeriod(
                kind: .weekly,
                referenceDate: overlappingSaturday,
                calendar: calendar
            )
        )

        let monthly = try #require(
            store.automaticPeriod(on: overlappingSaturday, onboardingComplete: true)
        )
        #expect(monthly.kind == .monthly)
        #expect(store.automaticPeriod(on: followingSunday, onboardingComplete: true) == monthly)

        store.markDismissed(monthly)
        let weekly = try #require(
            store.automaticPeriod(on: followingSunday, onboardingComplete: true)
        )
        #expect(weekly.kind == .weekly)
        #expect(weekly.identifier == expectedWeekly.identifier)
    }

    @MainActor
    @Test func highlightPresentationStateRestoresAndManualPeriodsDoNotConsumeIt() throws {
        let defaults = try makeIsolatedDefaults()
        let calendar = Self.highlightsTestCalendar
        let saturday = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 4, hour: 9))
        )
        let sunday = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 5, hour: 9))
        )
        let initialStore = HighlightPresentationStore(
            userDefaults: defaults,
            calendar: calendar
        )
        let manualPeriod = try #require(
            WealthHighlightPeriod(
                kind: .weekly,
                referenceDate: saturday,
                calendar: calendar
            )
        )

        #expect(manualPeriod.kind == .weekly)
        #expect(initialStore.lastDismissedIdentifier(for: .weekly) == nil)
        let monthlyCatchUp = try #require(
            initialStore.automaticPeriod(
                on: saturday,
                onboardingComplete: true
            )
        )
        #expect(monthlyCatchUp.kind == .monthly)
        initialStore.markDismissed(monthlyCatchUp)

        let automaticPeriod = try #require(
            initialStore.automaticPeriod(
                on: saturday,
                onboardingComplete: true
            )
        )
        #expect(automaticPeriod.kind == .weekly)

        let restoredStore = HighlightPresentationStore(
            userDefaults: defaults,
            calendar: calendar
        )
        #expect(
            restoredStore.automaticPeriod(
                on: sunday,
                onboardingComplete: true
            )?.kind == .weekly
        )

        restoredStore.markDismissed(automaticPeriod)
        #expect(
            restoredStore.automaticPeriod(
                on: sunday,
                onboardingComplete: true
            ) == nil
        )
    }

    @MainActor
    @Test func wealthHighlightSummaryCalculatesProgressAndLiabilityReduction() throws {
        let calendar = Self.highlightsTestCalendar
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 4, hour: 9))
        )
        let period = try #require(
            WealthHighlightPeriod(kind: .weekly, referenceDate: date, calendar: calendar)
        )
        let calculator = WealthHighlightCalculator()
        let summary = calculator.summary(
            period: period,
            currencyCode: "USD",
            currentAssetTotal: 1_200,
            currentLiabilityTotal: 150,
            snapshots: [
                PortfolioSnapshot(
                    assetTotal: 1_000,
                    liabilityTotal: 200,
                    currencyCode: "USD",
                    recordedAt: period.interval.start.addingTimeInterval(-60)
                )
            ],
            historyScopeStartedAt: .distantPast,
            hasPortfolioData: true,
            ratesAreStale: false,
            allocations: [
                WealthHighlightAllocation(
                    name: "Bank Deposits",
                    fraction: 0.65,
                    systemImage: "building.columns.fill"
                )
            ]
        )

        #expect(summary.availability == .full)
        #expect(summary.currentNetWorth == 1_050)
        #expect(summary.baseline?.netWorth == 800)
        #expect(summary.assetChange == 200)
        #expect(summary.liabilityChange == -50)
        #expect(summary.netWorthChange == 250)
        #expect(summary.netWorthChangeFraction == 0.3125)
        #expect(summary.insights.contains { $0.kind == .progress })
        #expect(summary.insights.contains { $0.kind == .liability })
        #expect(summary.insights.contains { $0.kind == .allocation })
        #expect(summary.insights.count <= 4)
    }

    @MainActor
    @Test func wealthHighlightBaselineUsesScopeAndEarliestInPeriodFallback() throws {
        let calendar = Self.highlightsTestCalendar
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 4, hour: 9))
        )
        let period = try #require(
            WealthHighlightPeriod(kind: .weekly, referenceDate: date, calendar: calendar)
        )
        let scopeStart = period.interval.start.addingTimeInterval(30)
        let calculator = WealthHighlightCalculator()
        let summary = calculator.summary(
            period: period,
            currencyCode: "USD",
            currentAssetTotal: 500,
            currentLiabilityTotal: 100,
            snapshots: [
                PortfolioSnapshot(
                    assetTotal: 50,
                    liabilityTotal: 10,
                    currencyCode: "USD",
                    recordedAt: period.interval.start.addingTimeInterval(-60)
                ),
                PortfolioSnapshot(
                    assetTotal: 200,
                    liabilityTotal: 60,
                    currencyCode: "EUR",
                    recordedAt: scopeStart.addingTimeInterval(10)
                ),
                PortfolioSnapshot(
                    assetTotal: 300,
                    liabilityTotal: 80,
                    currencyCode: "USD",
                    recordedAt: scopeStart.addingTimeInterval(20)
                ),
                PortfolioSnapshot(
                    assetTotal: 350,
                    liabilityTotal: 90,
                    currencyCode: "USD",
                    recordedAt: scopeStart.addingTimeInterval(40)
                )
            ],
            historyScopeStartedAt: scopeStart,
            hasPortfolioData: true,
            ratesAreStale: false
        )

        #expect(summary.baseline?.assetTotal == 300)
        #expect(summary.baseline?.liabilityTotal == 80)
        #expect(summary.netWorthChange == 180)
    }

    @MainActor
    @Test func wealthHighlightSummaryHandlesMissingZeroAndNegativeValues() throws {
        let calendar = Self.highlightsTestCalendar
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 4, hour: 9))
        )
        let period = try #require(
            WealthHighlightPeriod(kind: .weekly, referenceDate: date, calendar: calendar)
        )
        let baselineDate = period.interval.start.addingTimeInterval(-60)
        let calculator = WealthHighlightCalculator()

        let missing = calculator.summary(
            period: period,
            currencyCode: "USD",
            currentAssetTotal: nil,
            currentLiabilityTotal: 50,
            snapshots: [],
            historyScopeStartedAt: .distantPast,
            hasPortfolioData: true,
            ratesAreStale: true
        )
        let zero = calculator.summary(
            period: period,
            currencyCode: "USD",
            currentAssetTotal: 300,
            currentLiabilityTotal: 100,
            snapshots: [
                PortfolioSnapshot(
                    assetTotal: 100,
                    liabilityTotal: 100,
                    currencyCode: "USD",
                    recordedAt: baselineDate
                )
            ],
            historyScopeStartedAt: .distantPast,
            hasPortfolioData: true,
            ratesAreStale: false
        )
        let negative = calculator.summary(
            period: period,
            currencyCode: "USD",
            currentAssetTotal: 200,
            currentLiabilityTotal: 150,
            snapshots: [
                PortfolioSnapshot(
                    assetTotal: 100,
                    liabilityTotal: 200,
                    currencyCode: "USD",
                    recordedAt: baselineDate
                )
            ],
            historyScopeStartedAt: .distantPast,
            hasPortfolioData: true,
            ratesAreStale: false
        )
        let empty = calculator.summary(
            period: period,
            currencyCode: "USD",
            currentAssetTotal: 0,
            currentLiabilityTotal: 0,
            snapshots: [],
            historyScopeStartedAt: .distantPast,
            hasPortfolioData: false,
            ratesAreStale: false
        )
        let currentOnly = calculator.summary(
            period: period,
            currencyCode: "USD",
            currentAssetTotal: 100,
            currentLiabilityTotal: 0,
            snapshots: [],
            historyScopeStartedAt: .distantPast,
            hasPortfolioData: true,
            ratesAreStale: false
        )

        #expect(missing.availability == .unavailable)
        #expect(missing.currentAssetTotal == nil)
        #expect(missing.currentLiabilityTotal == nil)
        #expect(missing.currentNetWorth == nil)
        #expect(missing.ratesAreStale)
        #expect(zero.netWorthChange == 200)
        #expect(zero.netWorthChangeFraction == nil)
        #expect(negative.netWorthChange == 150)
        #expect(negative.netWorthChangeFraction == 1.5)
        #expect(empty.availability == .empty)
        #expect(currentOnly.availability == .currentOnly)
        #expect(!currentOnly.insights.contains { $0.kind == .context })
    }

    @MainActor
    @Test func chatGPTAnalysisExportAnonymizesHoldingsAndIncludesAnalysisContext() async throws {
        let defaults = try makeIsolatedDefaults()
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )
        settings.completeOnboarding(
            baseCurrency: .usd,
            displayCurrencies: [.eur]
        )
        let modelContext = try makeInMemoryModelContext()
        let asset = Asset(
            name: "Secret Condo",
            amount: 1_000,
            currency: .usd,
            category: .realEstate
        )
        let liability = Liability(
            name: "Private Mortgage",
            amount: 250,
            currency: .usd,
            category: .mortgage
        )
        modelContext.insert(asset)
        modelContext.insert(liability)
        modelContext.insert(PortfolioSnapshot(
            assetTotal: 1_000,
            liabilityTotal: 250,
            currencyCode: "USD"
        ))
        try modelContext.save()

        let url = try ChatGPTAnalysisExporter.buildAnalysisURL(
            context: modelContext,
            settings: settings,
            exchangeRates: ["USD": 1, "EUR": 0.5],
            exchangeRatesLastUpdated: Date(timeIntervalSince1970: 1_779_300_000)
        )
        let markdown = try String(contentsOf: url, encoding: .utf8)
        let payload = try ChatGPTAnalysisExporter.buildPayload(
            context: modelContext,
            settings: settings,
            exchangeRates: ["USD": 1, "EUR": 0.5],
            exchangeRatesLastUpdated: Date(timeIntervalSince1970: 1_779_300_000)
        )

        #expect(url.lastPathComponent == "Wealth-Map-ChatGPT-Analysis.md")
        #expect(markdown.contains("comfort score"))
        #expect(markdown.contains("analysisCurrencies"))
        #expect(markdown.contains("Asset 1"))
        #expect(markdown.contains("Liability 1"))
        #expect(markdown.contains("Real Estate"))
        #expect(markdown.contains("\"netWorth\" : 750"))
        #expect(payload.analysisCurrencies.map(\.code) == ["USD", "EUR"])
        #expect(payload.analysisCurrencies.first { $0.code == "USD" }?.convertedNetWorth == 750)
        #expect(payload.analysisCurrencies.first { $0.code == "EUR" }?.convertedNetWorth == 375)
        #expect(payload.analysisCurrencies.allSatisfy { !$0.countries.isEmpty })
        #expect(!markdown.contains("Secret Condo"))
        #expect(!markdown.contains("Private Mortgage"))
        #expect(!markdown.contains(asset.stableHistoryIdentifier))
        #expect(!markdown.contains(liability.historyIdentifier ?? ""))
    }

    @MainActor
    @Test func onboardingCompletionRequiresReminderChoice() async throws {
        let defaults = try makeIsolatedDefaults()
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { false }
        )

        settings.completeOnboarding(
            baseCurrency: .eur,
            displayCurrencies: [.usd, .inr]
        )

        #expect(settings.hasCompletedOnboarding.isComplete == false)
        #expect(settings.hasCompletedOnboarding.missingSteps == [.reminders])
        #expect(settings.firstMissingOnboardingStep() == .reminders)
    }

    @MainActor
    @Test func defaultReminderPreferenceHasNoRecordedChoice() async throws {
        let preference = ReminderPreference()

        #expect(preference.isEnabled == false)
        #expect(preference.hasMadeChoice == false)
    }

    @MainActor
    @Test func legacyReminderPreferenceDecodesAsRecordedChoice() async throws {
        let legacyPreference = LegacyReminderPreference(
            isEnabled: false,
            frequency: .weekly,
            reminderTime: ReminderPreference.defaultReminderTime(),
            reminderType: .reviewPortfolio,
            lastReminderDate: nil
        )

        let data = try JSONEncoder().encode(legacyPreference)
        let preference = try JSONDecoder().decode(ReminderPreference.self, from: data)

        #expect(preference.hasMadeChoice == true)
        #expect(ReminderWeekday.allCases.contains(preference.weekday))
        #expect((1...ReminderPreference.maximumMonthlyReminderDay).contains(preference.monthDay))
    }

    @MainActor
    @Test func reminderPreferencePersistsWeeklyAlertDay() async throws {
        let preference = ReminderPreference(
            isEnabled: true,
            hasMadeChoice: true,
            frequency: .weekly,
            weekday: .friday,
            reminderTime: ReminderPreference.defaultReminderTime(),
            reminderType: .reviewPortfolio,
            lastReminderDate: nil
        )

        let data = try JSONEncoder().encode(preference)
        let restoredPreference = try JSONDecoder().decode(ReminderPreference.self, from: data)

        #expect(restoredPreference.weekday == .friday)
    }

    @MainActor
    @Test func reminderPreferencePersistsMonthlyAlertDay() async throws {
        let preference = ReminderPreference(
            isEnabled: true,
            hasMadeChoice: true,
            frequency: .monthly,
            monthDay: 15,
            reminderTime: ReminderPreference.defaultReminderTime(),
            reminderType: .reviewPortfolio,
            lastReminderDate: nil
        )

        let data = try JSONEncoder().encode(preference)
        let restoredPreference = try JSONDecoder().decode(ReminderPreference.self, from: data)

        #expect(restoredPreference.monthDay == 15)
    }

    @MainActor
    @Test func reminderPreferenceNormalizesMonthlyAlertDay() async throws {
        let earlyPreference = ReminderPreference(monthDay: 0)
        let latePreference = ReminderPreference(monthDay: 40)

        #expect(earlyPreference.monthDay == 1)
        #expect(latePreference.monthDay == ReminderPreference.maximumMonthlyReminderDay)
    }

    @Test func localizationCatalogSupportsEveryMVPLocale() {
        let expected: [String: String] = [
            "en": "Net Worth",
            "hi": "नेट वर्थ",
            "es": "Valor neto",
            "pt-BR": "Patrimônio Líquido",
            "fr": "Valeur nette",
            "de": "Vermögen",
            "zh-Hans": "净资产",
            "ar": "صافي القيمة"
        ]

        #expect(Set(AppLocalization.supportedLanguageIdentifiers) == Set(expected.keys))
        for (identifier, value) in expected {
            #expect(
                AppLocalization.string(
                    "Net Worth",
                    locale: Locale(identifier: identifier)
                ) == value
            )
        }
    }

    @Test func unsupportedLocaleFallsBackToEnglish() {
        #expect(
            AppLocalization.string(
                "Net Worth",
                locale: Locale(identifier: "zu")
            ) == "Net Worth"
        )
    }

    @MainActor
    @Test func localizedDisplayLabelsPreserveStableRawValues() {
        #expect(Asset.CategoryType.realEstate.rawValue == "Real Estate")
        #expect(Liability.CategoryType.lineOfCredit.rawValue == "Line of Credit")
        #expect(ReminderFrequency.weekly.rawValue == "weekly")
        #expect(ReminderType.reviewPortfolio.rawValue == "reviewPortfolio")
        #expect(FIRELevelKind.lean.rawValue == "LeanFIRE")

        #expect(!Asset.CategoryType.realEstate.localizedName.isEmpty)
        #expect(!Liability.CategoryType.lineOfCredit.localizedName.isEmpty)
        #expect(!ReminderFrequency.weekly.displayName.isEmpty)
        #expect(!ReminderType.reviewPortfolio.randomMessage.isEmpty)
        #expect(!FIRELevelKind.lean.subtitle.isEmpty)
    }

    @Test func localizedFormattingPreservesArguments() {
        let result = AppLocalization.formatted(
            "Goal target: %@ by %@",
            arguments: ["USD 10,000", "Dec 31, 2030"],
            locale: Locale(identifier: "es")
        )

        #expect(result.contains("USD 10,000"))
        #expect(result.contains("Dec 31, 2030"))
    }

    @Test func percentageFormattingUsesRequestedLocale() {
        let locale = Locale(identifier: "ar")
        let expected = 0.25.formatted(
            .percent
                .precision(.fractionLength(0))
                .locale(locale)
        )

        #expect(AppLocalization.percent(0.25, locale: locale) == expected)
        #expect(AppLocalization.percent(.infinity, locale: locale) == AppLocalization.percent(0, locale: locale))
    }

    @MainActor
    @Test func reminderLocalizationPreservesIdentifierAndRawValues() {
        let locale = Locale(identifier: "pt-BR")
        let messages = ReminderType.reviewPortfolio.localizedNotificationMessages(locale: locale)

        #expect(NotificationScheduler.reminderNotificationIdentifier == "com.mywealth.reminder.portfolio-review")
        #expect(ReminderType.reviewPortfolio.rawValue == "reviewPortfolio")
        #expect(ReminderFrequency.weekly.rawValue == "weekly")
        #expect(ReminderFrequency.weekly.localizedDisplayName(locale: locale) != "Weekly")
        #expect(messages.count == 2)
        #expect(messages.allSatisfy { !$0.isEmpty })
        #expect(!messages.contains("Review your Wealth Map portfolio."))
    }

    @Test func localizationCatalogsHaveCompleteMVPCoverage() throws {
        for url in Self.localizationCatalogURLs {
            let data = try Data(contentsOf: url)
            let root = try #require(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            let strings = try #require(root["strings"] as? [String: Any])

            for (key, value) in strings where !key.isEmpty {
                let definition = try #require(value as? [String: Any])
                #expect(definition["extractionState"] as? String != "stale")
                #expect(!key.contains("%%"))
                #expect(key.range(of: #"\d+%"#, options: .regularExpression) == nil)
                let localizations = try #require(
                    definition["localizations"] as? [String: Any]
                )
                for identifier in AppLocalization.supportedLanguageIdentifiers where identifier != "en" {
                    let localization = try #require(
                        localizations[identifier] as? [String: Any]
                    )
                    let unit = try #require(
                        localization["stringUnit"] as? [String: Any]
                    )
                    let translated = try #require(unit["value"] as? String)

                    #expect(!translated.isEmpty)
                    #expect(translated.range(of: #"\d+%"#, options: .regularExpression) == nil)
                    #expect(Self.formatArguments(in: translated) == Self.formatArguments(in: key))
                }
            }
        }
    }

    @Test func widgetSnapshotContractRemainsStable() throws {
        let snapshot = WidgetSnapshot(
            netWorth: 750,
            assetTotal: 1_000,
            liabilityTotal: 250,
            baseCurrency: "USD",
            currencyTotals: [
                .init(code: "EUR", amount: 700, transferRate: 0.9)
            ],
            lastUpdated: Date(timeIntervalSince1970: 1_800_000_000),
            transferRatesLastUpdated: Date(timeIntervalSince1970: 1_799_000_000)
        )
        let data = try JSONEncoder().encode(snapshot)
        let json = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        #expect(WidgetDataStore.appGroupID == "group.com.bv.MyWealth")
        #expect(Set(json.keys) == [
            "netWorth",
            "assetTotal",
            "liabilityTotal",
            "baseCurrency",
            "currencyTotals",
            "lastUpdated",
            "transferRatesLastUpdated"
        ])
    }

    private func makeIsolatedDefaults() throws -> UserDefaults {
        let suiteName = "MyWealthTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private static var designTokenCatalogURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("tokens/wealth-map.tokens.json")
    }

    private static var localizationCatalogURLs: [URL] {
        let repository = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return [
            repository.appendingPathComponent("MyWealth/Resources/Localizable.xcstrings"),
            repository.appendingPathComponent("MyWealthWidget/Resources/Localizable.xcstrings")
        ]
    }

    private static var highlightsTestCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    private static func formatArguments(in value: String) -> [String] {
        let pattern = #"%(\d+\$)?(lld|ld|d|f|@|%)"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let range = NSRange(value.startIndex..., in: value)
        return expression.matches(in: value, range: range).compactMap { match in
            guard let tokenRange = Range(match.range, in: value) else { return nil }
            let token = String(value[tokenRange])
            if token == "%%" {
                return token
            }
            return token.replacingOccurrences(
                of: #"^%\d+\$"#,
                with: "%",
                options: .regularExpression
            )
        }
        .sorted()
    }

    @MainActor
    private func makeInMemoryModelContext() throws -> ModelContext {
        let schema = Schema([
            Asset.self,
            Liability.self,
            AssetValueSnapshot.self,
            NetWorthSnapshot.self,
            PortfolioSnapshot.self,
            NetWorthGoal.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @MainActor
    private func contextCount<T: PersistentModel>(
        _ type: T.Type,
        in context: ModelContext
    ) throws -> Int {
        try context.fetchCount(FetchDescriptor<T>())
    }

    private struct LegacyReminderPreference: Codable {
        var isEnabled: Bool
        var frequency: ReminderFrequency
        var reminderTime: Date
        var reminderType: ReminderType
        var lastReminderDate: Date?
    }

    private final class StubExchangeRateService: ExchangeRateFetching {
        let response: RateResponse
        private(set) var fetchCount = 0

        init(response: RateResponse) {
            self.response = response
        }

        func fetchLatestExchangeRates() async throws -> RateResponse {
            fetchCount += 1
            return response
        }
    }

    private final class StubMetalPriceService: MetalPriceFetching {
        let response: RateResponse
        private(set) var fetchCount = 0

        init(response: RateResponse) {
            self.response = response
        }

        func fetchLatestMetalPrices() async throws -> RateResponse {
            fetchCount += 1
            return response
        }
    }

}
