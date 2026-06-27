import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Codable transfer types

/// Top-level envelope written to / read from the backup file.
struct ExportPayload: Codable, Sendable {
    let version: Int
    let exportedAt: Date
    let assets: [AssetExport]
    let liabilities: [LiabilityExport]
    let assetValueSnapshots: [AssetValueSnapshotExport]
    let netWorthSnapshots: [NetWorthSnapshotExport]
    let portfolioSnapshots: [PortfolioSnapshotExport]
    let netWorthGoal: NetWorthGoalExport?

    static let currentVersion = 2
}

struct AssetExport: Codable, Sendable {
    let name: String
    let amount: Double
    let currency: String
    let category: String
    let lastUpdated: Date
    let historyIdentifier: String
    let weightUnit: String?
    let isIncludedInPortfolio: Bool?
}

struct LiabilityExport: Codable, Sendable {
    let name: String
    let amount: Double
    let currency: String
    let category: String
    let lastUpdated: Date
    let historyIdentifier: String
}

struct AssetValueSnapshotExport: Codable, Sendable {
    let assetIdentifier: String
    let assetName: String
    let amount: Double
    let currencyCode: String
    let categoryName: String
    let recordedAt: Date
}

struct NetWorthSnapshotExport: Codable, Sendable {
    let amount: Double
    let currencyCode: String
    let recordedAt: Date
}

struct PortfolioSnapshotExport: Codable, Sendable {
    let assetTotal: Double
    let liabilityTotal: Double
    let currencyCode: String
    let recordedAt: Date
}

struct NetWorthGoalExport: Codable, Sendable, Equatable {
    let stableIdentifier: String
    let targetAmount: Double
    let currencyCode: String
    let targetDate: Date
    let createdAt: Date
    let updatedAt: Date

    init(goal: NetWorthGoal) {
        stableIdentifier = goal.displayStableIdentifier
        targetAmount = goal.displayTargetAmount
        currencyCode = goal.displayCurrency.rawValue
        targetDate = goal.displayTargetDate
        createdAt = goal.displayCreatedAt
        updatedAt = goal.displayUpdatedAt
    }

    var isValid: Bool {
        guard let currency = Asset.CurrencyType(rawValue: currencyCode) else { return false }
        return !stableIdentifier.isEmpty
            && targetAmount.isFinite
            && targetAmount > 0
            && currency != .none
    }
}

// MARK: - UTType

extension UTType {
    static let myWealthBackup = UTType(exportedAs: "com.bv.MyWealth.backup")
}

// MARK: - Export

enum DataExporter {
    /// Serialises all SwiftData records to JSON, writes to a temp file, and
    /// returns the URL. The caller can hand this URL to UIActivityViewController.
    @MainActor
    static func buildExportURL(context: ModelContext) throws -> URL {
        let assets             = try context.fetch(FetchDescriptor<Asset>())
        let liabilities        = try context.fetch(FetchDescriptor<Liability>())
        let assetSnapshots     = try context.fetch(FetchDescriptor<AssetValueSnapshot>())
        let netWorthSnapshots  = try context.fetch(FetchDescriptor<NetWorthSnapshot>())
        let portfolioSnapshots = try context.fetch(FetchDescriptor<PortfolioSnapshot>())
        let netWorthGoal = try NetWorthGoalStore.canonicalGoal(in: context)

        let payload = ExportPayload(
            version: ExportPayload.currentVersion,
            exportedAt: Date(),
            assets: assets.map {
                AssetExport(
                    name: $0.name ?? "",
                    amount: $0.amount ?? 0,
                    currency: $0.currency?.rawValue ?? "",
                    category: $0.category?.rawValue ?? "",
                    lastUpdated: $0.lastUpdated ?? Date(),
                    historyIdentifier: $0.historyIdentifier ?? UUID().uuidString,
                    weightUnit: $0.weightUnit?.rawValue,
                    isIncludedInPortfolio: $0.participatesInPortfolioCalculations
                )
            },
            liabilities: liabilities.map {
                LiabilityExport(
                    name: $0.name ?? "",
                    amount: $0.amount ?? 0,
                    currency: $0.currency?.rawValue ?? "",
                    category: $0.category?.rawValue ?? "",
                    lastUpdated: $0.lastUpdated ?? Date(),
                    historyIdentifier: $0.historyIdentifier ?? UUID().uuidString
                )
            },
            assetValueSnapshots: assetSnapshots.map {
                AssetValueSnapshotExport(
                    assetIdentifier: $0.assetIdentifier ?? "",
                    assetName: $0.assetName ?? "",
                    amount: $0.amount ?? 0,
                    currencyCode: $0.currencyCode ?? "",
                    categoryName: $0.categoryName ?? "",
                    recordedAt: $0.recordedAt ?? Date()
                )
            },
            netWorthSnapshots: netWorthSnapshots.map {
                NetWorthSnapshotExport(
                    amount: $0.amount ?? 0,
                    currencyCode: $0.currencyCode ?? "",
                    recordedAt: $0.recordedAt ?? Date()
                )
            },
            portfolioSnapshots: portfolioSnapshots.map {
                PortfolioSnapshotExport(
                    assetTotal: $0.assetTotal ?? 0,
                    liabilityTotal: $0.liabilityTotal ?? 0,
                    currencyCode: $0.currencyCode ?? "",
                    recordedAt: $0.recordedAt ?? Date()
                )
            },
            netWorthGoal: netWorthGoal.map(NetWorthGoalExport.init(goal:))
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)

        let filename = "WealthMap-\(formattedExportDate()).backup"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func formattedExportDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

// MARK: - Import

enum DataImporter {
    enum GoalConflictResolution: Equatable {
        case requireDecision
        case keepExisting
        case replaceExisting
    }

    struct ImportPreview {
        let hasGoalConflict: Bool
        let importedGoal: NetWorthGoalExport?
    }

    enum ImportError: LocalizedError {
        case unsupportedVersion(Int)
        case invalidGoal
        case goalConflict
        var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let v):
                return AppLocalization.formatted(
                    "Backup version %lld is not supported by this app version.",
                    arguments: [v]
                )
            case .invalidGoal:
                return AppLocalization.string("The backup contains an invalid net worth goal.")
            case .goalConflict:
                return AppLocalization.string(
                    "The backup contains a different net worth goal. Choose whether to keep or replace your current goal."
                )
            }
        }
    }

    @MainActor
    static func previewImport(_ data: Data, into context: ModelContext) throws -> ImportPreview {
        let payload = try decodePayload(data)
        if let goal = payload.netWorthGoal, !goal.isValid {
            throw ImportError.invalidGoal
        }
        let existing = try NetWorthGoalStore.canonicalGoal(in: context).map(NetWorthGoalExport.init(goal:))
        let hasConflict = if let imported = payload.netWorthGoal, let existing {
            !goalsAreMateriallyEqual(imported, existing)
        } else {
            false
        }
        return ImportPreview(hasGoalConflict: hasConflict, importedGoal: payload.netWorthGoal)
    }

    /// Reads `url`, decodes the JSON payload, and inserts any records not
    /// already present in `context`. Existing records are skipped (additive).
    @MainActor
    static func importFromURL(
        _ url: URL,
        into context: ModelContext,
        goalConflictResolution: GoalConflictResolution = .requireDecision
    ) throws -> ImportSummary {
        let data = try Data(contentsOf: url)
        return try importData(
            data,
            into: context,
            goalConflictResolution: goalConflictResolution
        )
    }

    @MainActor
    static func importData(
        _ data: Data,
        into context: ModelContext,
        goalConflictResolution: GoalConflictResolution = .requireDecision
    ) throws -> ImportSummary {
        let payload = try decodePayload(data)
        if let goal = payload.netWorthGoal, !goal.isValid {
            throw ImportError.invalidGoal
        }
        let existingGoal = try NetWorthGoalStore.canonicalGoal(in: context)
        let hasGoalConflict = if let imported = payload.netWorthGoal, let existingGoal {
            !goalsAreMateriallyEqual(imported, NetWorthGoalExport(goal: existingGoal))
        } else {
            false
        }
        if hasGoalConflict, goalConflictResolution == .requireDecision {
            throw ImportError.goalConflict
        }

        return try apply(
            payload,
            into: context,
            existingGoal: existingGoal,
            goalConflictResolution: goalConflictResolution
        )
    }

    private static func decodePayload(_ data: Data) throws -> ExportPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(ExportPayload.self, from: data)

        guard payload.version <= ExportPayload.currentVersion else {
            throw ImportError.unsupportedVersion(payload.version)
        }
        return payload
    }

    @MainActor
    private static func apply(
        _ payload: ExportPayload,
        into context: ModelContext,
        existingGoal: NetWorthGoal?,
        goalConflictResolution: GoalConflictResolution
    ) throws -> ImportSummary {
        let existingAssetIDs = Set(
            (try context.fetch(FetchDescriptor<Asset>())).compactMap(\.historyIdentifier)
        )
        let existingLiabilityIDs = Set(
            (try context.fetch(FetchDescriptor<Liability>())).compactMap(\.historyIdentifier)
        )

        var summary = ImportSummary()

        for a in payload.assets where !existingAssetIDs.contains(a.historyIdentifier) {
            let asset = Asset(
                name: a.name,
                amount: a.amount,
                currency: Asset.CurrencyType(rawValue: a.currency) ?? .none,
                category: Asset.CategoryType(rawValue: a.category) ?? .others,
                lastUpdated: a.lastUpdated,
                weightUnit: a.weightUnit.flatMap(WeightUnit.init(rawValue:)),
                isIncludedInPortfolio: a.isIncludedInPortfolio ?? true
            )
            asset.historyIdentifier = a.historyIdentifier
            context.insert(asset)
            summary.assets += 1
        }

        for l in payload.liabilities where !existingLiabilityIDs.contains(l.historyIdentifier) {
            let liability = Liability(
                name: l.name,
                amount: l.amount,
                currency: Asset.CurrencyType(rawValue: l.currency) ?? .none,
                category: Liability.CategoryType(rawValue: l.category) ?? .other,
                lastUpdated: l.lastUpdated
            )
            liability.historyIdentifier = l.historyIdentifier
            context.insert(liability)
            summary.liabilities += 1
        }

        let existingSnapKeys = Set(
            (try context.fetch(FetchDescriptor<AssetValueSnapshot>())).map {
                "\($0.assetIdentifier ?? "")|\($0.recordedAt?.timeIntervalSince1970 ?? 0)"
            }
        )
        for s in payload.assetValueSnapshots {
            let key = "\(s.assetIdentifier)|\(s.recordedAt.timeIntervalSince1970)"
            guard !existingSnapKeys.contains(key) else { continue }
            context.insert(AssetValueSnapshot(
                assetIdentifier: s.assetIdentifier,
                assetName: s.assetName,
                amount: s.amount,
                currencyCode: s.currencyCode,
                categoryName: s.categoryName,
                recordedAt: s.recordedAt
            ))
            summary.assetSnapshots += 1
        }

        let existingNWKeys = Set(
            (try context.fetch(FetchDescriptor<NetWorthSnapshot>())).map {
                "\($0.currencyCode ?? "")|\($0.recordedAt?.timeIntervalSince1970 ?? 0)"
            }
        )
        for s in payload.netWorthSnapshots {
            let key = "\(s.currencyCode)|\(s.recordedAt.timeIntervalSince1970)"
            guard !existingNWKeys.contains(key) else { continue }
            context.insert(NetWorthSnapshot(
                amount: s.amount,
                currencyCode: s.currencyCode,
                recordedAt: s.recordedAt
            ))
            summary.netWorthSnapshots += 1
        }

        let existingPFKeys = Set(
            (try context.fetch(FetchDescriptor<PortfolioSnapshot>())).map {
                "\($0.currencyCode ?? "")|\($0.recordedAt?.timeIntervalSince1970 ?? 0)"
            }
        )
        for s in payload.portfolioSnapshots {
            let key = "\(s.currencyCode)|\(s.recordedAt.timeIntervalSince1970)"
            guard !existingPFKeys.contains(key) else { continue }
            context.insert(PortfolioSnapshot(
                assetTotal: s.assetTotal,
                liabilityTotal: s.liabilityTotal,
                currencyCode: s.currencyCode,
                recordedAt: s.recordedAt
            ))
            summary.portfolioSnapshots += 1
        }

        if let importedGoal = payload.netWorthGoal {
            let shouldApply = existingGoal == nil || goalConflictResolution == .replaceExisting
            if shouldApply {
                for goal in try context.fetch(FetchDescriptor<NetWorthGoal>()) {
                    context.delete(goal)
                }
                let currency = Asset.CurrencyType(rawValue: importedGoal.currencyCode) ?? .none
                context.insert(NetWorthGoal(
                    targetAmount: importedGoal.targetAmount,
                    currency: currency,
                    targetDate: importedGoal.targetDate,
                    stableIdentifier: importedGoal.stableIdentifier,
                    createdAt: importedGoal.createdAt,
                    updatedAt: importedGoal.updatedAt
                ))
                summary.netWorthGoals = 1
            }
        }

        try context.save()
        return summary
    }

    private static func goalsAreMateriallyEqual(
        _ lhs: NetWorthGoalExport,
        _ rhs: NetWorthGoalExport
    ) -> Bool {
        lhs.stableIdentifier == rhs.stableIdentifier
            && lhs.targetAmount == rhs.targetAmount
            && lhs.currencyCode == rhs.currencyCode
            && lhs.targetDate == rhs.targetDate
    }
}

// MARK: - Import summary

struct ImportSummary {
    var assets = 0
    var liabilities = 0
    var assetSnapshots = 0
    var netWorthSnapshots = 0
    var portfolioSnapshots = 0
    var netWorthGoals = 0

    var description: String {
        var parts: [String] = []
        if assets > 0 {
            parts.append(AppLocalization.formatted(
                assets == 1 ? "%lld asset" : "%lld assets",
                arguments: [assets]
            ))
        }
        if liabilities > 0 {
            parts.append(AppLocalization.formatted(
                liabilities == 1 ? "%lld liability" : "%lld liabilities",
                arguments: [liabilities]
            ))
        }
        if assetSnapshots > 0 {
            parts.append(AppLocalization.formatted(
                "%lld asset history entries",
                arguments: [assetSnapshots]
            ))
        }
        if netWorthSnapshots > 0 {
            parts.append(AppLocalization.formatted(
                "%lld net worth snapshots",
                arguments: [netWorthSnapshots]
            ))
        }
        if portfolioSnapshots > 0 {
            parts.append(AppLocalization.formatted(
                "%lld portfolio snapshots",
                arguments: [portfolioSnapshots]
            ))
        }
        if netWorthGoals > 0 {
            parts.append(AppLocalization.formatted(
                "%lld net worth goal",
                arguments: [netWorthGoals]
            ))
        }
        guard !parts.isEmpty else {
            return AppLocalization.string("Nothing new to import — all records already exist.")
        }
        return AppLocalization.formatted(
            "Imported: %@.",
            arguments: [parts.joined(separator: ", ")]
        )
    }
}

// MARK: - Portfolio sharing

enum PortfolioShareSummaryBuilder {
    static func build(
        netWorth: Double,
        baseCurrency: Asset.CurrencyType,
        goal: NetWorthGoal? = nil,
        goalProgressFraction: Double? = nil
    ) -> String {
        var lines = [
            AppLocalization.string("Wealth Map update"),
            AppLocalization.formatted(
                "Net worth: %@",
                arguments: [formatted(netWorth, currency: baseCurrency)]
            )
        ]

        if let goal {
            if let goalProgressFraction {
                lines.append(AppLocalization.formatted(
                    "Goal progress: %@",
                    arguments: [
                        goalProgressFraction.formatted(
                            .percent.precision(.fractionLength(0...1))
                        )
                    ]
                ))
            }
            lines.append(AppLocalization.formatted(
                "Goal target: %@ by %@",
                arguments: [
                    formatted(goal.displayTargetAmount, currency: goal.displayCurrency),
                    goal.displayTargetDate.formatted(date: .abbreviated, time: .omitted)
                ]
            ))
        }

        lines.append(AppLocalization.string("Tracked privately with Wealth Map."))
        return lines.joined(separator: "\n")
    }

    private static func formatted(_ amount: Double, currency: Asset.CurrencyType) -> String {
        amount.formatted(
            .currency(code: currency.rawValue)
                .precision(.fractionLength(0...2))
        )
    }
}

// MARK: - Share sheet

/// Wraps UIActivityViewController so a backup file URL can be shared via the
/// standard iOS share sheet without requiring FileDocument or Transferable.
struct ActivityView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Wraps UIActivityViewController for lightweight share actions that are not
/// backup files, such as a user-controlled portfolio milestone summary.
struct ActivityItemsView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
