import SwiftUI
import SwiftData
import CloudKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var navigationPath: [SettingsRoute] = []
    @State private var isConfirmingCleanup = false
    @State private var cleanupResultMessage: String? = nil
    // Export
    @State private var exportURL: URL? = nil
    @State private var chatGPTExportURL: URL? = nil
    @State private var isGeneratingChatGPTExport = false
    @State private var chatGPTExportProgressMessage = "Preparing ChatGPT report..."
    @State private var isAnalyzingWithChatGPT = false
    @State private var chatGPTAnalysisResult: ChatGPTInAppAnalysisResult? = nil
    @State private var chatGPTAnalysisProgressMessage = "Analyzing portfolio..."
    @State private var exportError: String? = nil
    // Import
    @State private var isImporting = false
    @State private var importResultMessage: String? = nil
    @State private var importError: String? = nil
    @State private var pendingGoalImportData: Data? = nil
    @State private var isConfirmingGoalReplacement = false
    @State private var didLogSettingsView = false
    @Bindable var settings: AppSettings
    var showsDoneButton = true

    var body: some View {
        NavigationStack(path: $navigationPath) {
            settingsContent
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(showsDoneButton ? .inline : .automatic)
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .reminders:
                    ReminderSettingsView()
                case .baseCurrency:
                    BaseCurrencySelectionView(settings: settings)
                case .displayCurrencies:
                    TotalCurrencySelectionView(settings: settings)
                }
            }
            .overlay {
                if isGeneratingChatGPTExport || isAnalyzingWithChatGPT {
                    ChatGPTExportProgressOverlay(
                        message: isAnalyzingWithChatGPT
                            ? chatGPTAnalysisProgressMessage
                            : chatGPTExportProgressMessage
                    )
                }
            }
            .sheet(item: $chatGPTAnalysisResult) { result in
                ChatGPTAnalysisResultView(result: result)
            }
        }
        .onAppear {
            logSettingsViewedIfNeeded()
        }
    }

    private func logSettingsViewedIfNeeded() {
        guard !didLogSettingsView else { return }
        didLogSettingsView = true
        AnalyticsService.shared.log(
            .settingsViewed,
            parameters: [.sourceScreen: AnalyticsService.SourceScreen.settings.rawValue]
        )
    }

    @ViewBuilder
    private var settingsContent: some View {
        if showsDoneButton {
            formContent
        } else {
            dashboardStyledContent
        }
    }

    private var formContent: some View {
        Form {
            Section("Features") {
                NavigationLink(value: SettingsRoute.reminders) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(WealthMapDesignTokens.ColorToken.brandPrimary)
                        Text("Reminders")
                    }
                }
            }

            Section("Totals") {
                Toggle("Compact Amounts", isOn: $settings.usesCompactCurrencyTotals)
                    .tint(WealthMapDesignTokens.ColorToken.brandPrimary)
                Toggle("Include Ignored Assets", isOn: $settings.includeIgnoredAssetsInPortfolio)
                    .tint(WealthMapDesignTokens.ColorToken.brandPrimary)
                NavigationLink(value: SettingsRoute.baseCurrency) {
                    baseCurrencyContent
                }

                NavigationLink(value: SettingsRoute.displayCurrencies) {
                    displayCurrenciesContent
                }
            }

            Section("iCloud") {
                ICloudSyncRow(settings: settings)
            }

            Section("Data Controls") {
                Text("Wealth Map keeps records on this device unless you enable iCloud sync or export a backup.")
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                cleanupButton
                exportButton
                importButton
            }
        }
        .dataPortabilityModifiers(
            exportURL: $exportURL,
            chatGPTExportURL: $chatGPTExportURL,
            isPreparingChatGPTExport: $isGeneratingChatGPTExport,
            exportError: $exportError,
            isImporting: $isImporting,
            importResultMessage: $importResultMessage,
            importError: $importError,
            pendingGoalImportData: $pendingGoalImportData,
            isConfirmingGoalReplacement: $isConfirmingGoalReplacement,
            modelContext: modelContext
        )
        .cleanupAlerts(
            isConfirming: $isConfirmingCleanup,
            resultMessage: $cleanupResultMessage,
            onConfirm: runCleanup
        )
    }

    private var dashboardStyledContent: some View {
        ZStack {
            RadialDotBackground(dotRadius: 1, spacing: 20)
                .ignoresSafeArea(.all)

            List {
                Section {
                    AppListCard {
                        Button {
                            navigationPath.append(.reminders)
                        } label: {
                            SettingsRow(
                                title: "Reminders",
                                systemImage: "bell.badge.fill",
                                showsDisclosureIndicator: true
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .appListRow()
                }
                Section {
                    AppListCard {
                        VStack(spacing: 0) {
                            Toggle(isOn: $settings.usesCompactCurrencyTotals) {
                                SettingsRow(
                                    title: "Compact Amounts",
                                    subtitle: "Shorten large totals",
                                    systemImage: "textformat.size"
                                )
                            }
                            .tint(WealthMapDesignTokens.ColorToken.brandPrimary)

                            Divider()
                                .padding(.leading, 44)
                                .padding(.vertical, 10)

                            Toggle(isOn: $settings.includeIgnoredAssetsInPortfolio) {
                                SettingsRow(
                                    title: "Include Ignored Assets",
                                    subtitle: "Count ignored assets in portfolio totals",
                                    systemImage: "eye.slash"
                                )
                            }
                            .tint(WealthMapDesignTokens.ColorToken.brandPrimary)

                            Divider()
                                .padding(.leading, 44)
                                .padding(.vertical, 10)

                            Button {
                                navigationPath.append(.baseCurrency)
                            } label: {
                                SettingsValueRow(
                                    title: "Base Currency",
                                    value: settings.baseCurrency.rawValue,
                                    subtitle: settings.baseCurrency.name,
                                    systemImage: "banknote.fill"
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 44)
                                .padding(.vertical, 10)

                            Button {
                                navigationPath.append(.displayCurrencies)
                            } label: {
                                SettingsValueRow(
                                    title: "Display Currencies",
                                    value: displayCurrencyPrimaryValue,
                                    secondaryValue: displayCurrencyMoreValue,
                                    subtitle: "Choose currencies shown in totals and widgets",
                                    systemImage: "list.bullet.rectangle.fill"
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .appListRow()
                }
                Section {
                    AppListCard {
                        VStack(spacing: 0) {
                            SettingsRow(
                                title: "Private by Default",
                                subtitle: "Records stay on this device unless you enable iCloud sync or export a backup",
                                systemImage: "lock.shield"
                            )

                            Divider()
                                .padding(.leading, 44)
                                .padding(.vertical, 10)

                            cleanupButton
                                .buttonStyle(.plain)
                            Divider()
                                .padding(.leading, 44)
                                .padding(.vertical, 10)
                            exportButton
                                .buttonStyle(.plain)
                            Divider()
                                .padding(.leading, 44)
                                .padding(.vertical, 10)
                            importButton
                                .buttonStyle(.plain)
                        }
                    }
                    .appListRow()
                }

                Section {
                    AppListCard {
                        ICloudSyncRow(settings: settings)
                    }
                    .appListRow()
                }

                Section {
                    AppListCard {
                        SettingsValueRow(
                            title: "App Version",
                            value: AppInfo.fullVersion,
                            systemImage: "info.circle",
                            hidesDisclosureIndicator: true
                        )
                    }
                    .appListRow()
                }
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
        .cleanupAlerts(
            isConfirming: $isConfirmingCleanup,
            resultMessage: $cleanupResultMessage,
            onConfirm: runCleanup
        )
        .dataPortabilityModifiers(
            exportURL: $exportURL,
            chatGPTExportURL: $chatGPTExportURL,
            isPreparingChatGPTExport: $isGeneratingChatGPTExport,
            exportError: $exportError,
            isImporting: $isImporting,
            importResultMessage: $importResultMessage,
            importError: $importError,
            pendingGoalImportData: $pendingGoalImportData,
            isConfirmingGoalReplacement: $isConfirmingGoalReplacement,
            modelContext: modelContext
        )
    }
    // MARK: - Export / Import

    private var exportButton: some View {
        Button {
            do {
                exportURL = try DataExporter.buildExportURL(context: modelContext)
            } catch {
                exportError = error.localizedDescription
            }
        } label: {
            SettingsRow(
                title: "Export Backup",
                subtitle: "Create a local backup file you choose where to share or store",
                systemImage: "square.and.arrow.up"
            )
        }
    }

    private var chatGPTAnalysisButton: some View {
        Button {
            guard !isGeneratingChatGPTExport else { return }
            chatGPTExportProgressMessage = "Preparing ChatGPT report..."
            isGeneratingChatGPTExport = true

            Task { @MainActor in
                await Task.yield()
                try? await Task.sleep(nanoseconds: 450_000_000)

                do {
                    let rateViewModel = DashboardViewModel(autoRefreshRate: false)
                    let metalViewModel = MetalPricesViewModel()
                    rateViewModel.enrichWithMetalRates(metalViewModel.metalRates)

                    let url = try ChatGPTAnalysisExporter.buildAnalysisURL(
                        context: modelContext,
                        settings: settings,
                        exchangeRates: rateViewModel.exchangeRates,
                        exchangeRatesLastUpdated: latestDate(
                            rateViewModel.lastUpdated,
                            metalViewModel.lastUpdated
                        )
                    )
                    chatGPTExportProgressMessage = "Opening share sheet..."
                    chatGPTExportURL = url
                } catch {
                    isGeneratingChatGPTExport = false
                    exportError = error.localizedDescription
                }
            }
        } label: {
            SettingsRow(
                title: "Analyze with ChatGPT",
                subtitle: isGeneratingChatGPTExport
                    ? chatGPTExportProgressMessage
                    : "Share a sanitized portfolio snapshot",
                systemImage: "sparkles",
                showsProgress: isGeneratingChatGPTExport
            )
        }
        .disabled(isGeneratingChatGPTExport)
    }

    private var inAppChatGPTAnalysisButton: some View {
        Button {
            guard !isAnalyzingWithChatGPT else { return }
            chatGPTAnalysisProgressMessage = "Analyzing portfolio..."
            isAnalyzingWithChatGPT = true

            Task { @MainActor in
                do {
                    let payload = try buildChatGPTAnalysisPayload()
                    let response = try await FirebaseChatGPTAnalysisService.shared.analyze(payload)
                    isAnalyzingWithChatGPT = false
                    chatGPTAnalysisResult = ChatGPTInAppAnalysisResult(
                        analysis: response.analysis ?? "",
                        model: response.model,
                        responseId: response.responseId
                    )
                } catch {
                    isAnalyzingWithChatGPT = false
                    exportError = error.localizedDescription
                }
            }
        } label: {
            SettingsRow(
                title: "Analyze In App",
                subtitle: isAnalyzingWithChatGPT
                    ? chatGPTAnalysisProgressMessage
                    : "Get AI insights inside Wealth Map",
                systemImage: "brain.head.profile",
                showsProgress: isAnalyzingWithChatGPT
            )
        }
        .disabled(isAnalyzingWithChatGPT)
    }

    private var importButton: some View {
        Button {
            isImporting = true
        } label: {
            SettingsRow(
                title: "Import Backup",
                subtitle: "Restore records from a Wealth Map backup file",
                systemImage: "square.and.arrow.down"
            )
        }
    }

    private func latestDate(_ lhs: Date?, _ rhs: Date?) -> Date? {
        switch (lhs, rhs) {
        case (.some(let lhs), .some(let rhs)):
            return max(lhs, rhs)
        case (.some(let lhs), .none):
            return lhs
        case (.none, .some(let rhs)):
            return rhs
        case (.none, .none):
            return nil
        }
    }

    private func buildChatGPTAnalysisPayload() throws -> ChatGPTAnalysisExportPayload {
        let rateViewModel = DashboardViewModel(autoRefreshRate: false)
        let metalViewModel = MetalPricesViewModel()
        rateViewModel.enrichWithMetalRates(metalViewModel.metalRates)

        return try ChatGPTAnalysisExporter.buildPayload(
            context: modelContext,
            settings: settings,
            exchangeRates: rateViewModel.exchangeRates,
            exchangeRatesLastUpdated: latestDate(
                rateViewModel.lastUpdated,
                metalViewModel.lastUpdated
            )
        )
    }

    // MARK: - History cleanup

    private var cleanupButton: some View {
        Button {
            isConfirmingCleanup = true
        } label: {
            SettingsRow(
                title: "Clean Up History",
                subtitle: "Remove duplicate snapshot entries",
                systemImage: "clock.badge.xmark"
            )
        }
    }

    private func runCleanup() {
        do {
            let removed = try HistorySanitizer.sanitize(modelContext: modelContext)
            cleanupResultMessage = removed > 0
                ? "Removed \(removed) duplicate \(removed == 1 ? "entry" : "entries")."
                : "No duplicates found — your history is already clean."
        } catch {
            cleanupResultMessage = "Cleanup failed: \(error.localizedDescription)"
        }
    }

    private var interestedDisplayCurrencies: [Asset.CurrencyType] {
        settings.totalCurrencies.filter { $0 != settings.baseCurrency }
    }

    private var displayCurrencyPrimaryValue: String {
        interestedDisplayCurrencies.first?.rawValue ?? "None"
    }

    private var displayCurrencyMoreValue: String? {
        let remainingCount = interestedDisplayCurrencies.dropFirst().count

        if remainingCount > 0 {
            return "+\(remainingCount) more"
        }

        return nil
    }
    
    private var baseCurrencyContent: some View {
        LabeledContent("Base Currency") {
            VStack(alignment: .trailing, spacing: 2) {
                Text(settings.baseCurrency.rawValue)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                Text(settings.baseCurrency.name)
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.inactive)
            }
        }
    }

    private var displayCurrenciesContent: some View {
        LabeledContent("Display Currencies") {
            Text(settings.totalCurrencies.map(\.rawValue).joined(separator: ", "))
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
        }
    }
}

// MARK: - iCloud Sync Row

private struct ICloudSyncRow: View {
    @Bindable var settings: AppSettings
    @State private var iCloudAvailable: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "icloud.fill")
                .font(WealthMapDesignTokens.Typography.bodySemibold)
                .foregroundStyle(iCloudAvailable ? WealthMapDesignTokens.ColorToken.brandPrimary : WealthMapDesignTokens.ColorToken.textSecondary)
                .frame(width: 32, height: 32)
                .background(
                    (iCloudAvailable ? WealthMapDesignTokens.ColorToken.brandPrimary : WealthMapDesignTokens.ColorToken.textSecondary).opacity(0.12),
                    in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.compactRadius, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Sync with iCloud")
                    .font(WealthMapDesignTokens.Typography.body.weight(.medium))
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                Text(iCloudAvailable
                     ? "Optional backup and sync through your personal iCloud account."
                     : "Sign in to iCloud in Settings to enable.")
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $settings.iCloudSyncEnabled)
                .labelsHidden()
                .tint(WealthMapDesignTokens.ColorToken.brandPrimary)
                .disabled(!iCloudAvailable)
        }
        .frame(minHeight: 40)
        .task { await checkICloudAvailability() }
    }

    private func checkICloudAvailability() async {
        #if targetEnvironment(simulator)
        iCloudAvailable = true
        #else
        do {
            let status = try await CKContainer.default().accountStatus()
            iCloudAvailable = (status == .available)
        } catch {
            iCloudAvailable = false
        }
        #endif
    }
}

private enum SettingsRoute: Hashable {
    case reminders
    case baseCurrency
    case displayCurrencies
}

private struct ChatGPTInAppAnalysisResult: Identifiable {
    let id = UUID()
    let analysis: String
    let model: String?
    let responseId: String?
}

private struct ChatGPTAnalysisResultView: View {
    @Environment(\.dismiss) private var dismiss
    let result: ChatGPTInAppAnalysisResult

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let model = result.model {
                        Label(model, systemImage: "sparkles")
                            .font(WealthMapDesignTokens.Typography.footnote.weight(.semibold))
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    }

                    Text(LocalizedStringKey(result.analysis))
                        .font(WealthMapDesignTokens.Typography.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let responseId = result.responseId {
                        Text("Response ID: \(responseId)")
                            .font(WealthMapDesignTokens.Typography.caption2)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textTertiary)
                            .textSelection(.enabled)
                    }
                }
                .padding(20)
            }
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ChatGPTExportProgressOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            WealthMapDesignTokens.ColorToken.scrim
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                Text(message)
                    .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous))
            .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 10)
        }
        .transition(.opacity)
    }
}

private struct SettingsRow: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    var showsDisclosureIndicator = false
    var showsProgress = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(WealthMapDesignTokens.Typography.bodySemibold)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                .frame(width: 32, height: 32)
                .background(WealthMapDesignTokens.ColorToken.brandPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.compactRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(WealthMapDesignTokens.Typography.body.weight(.medium))
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(WealthMapDesignTokens.Typography.caption)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                }
            }

            Spacer(minLength: 8)

            if showsProgress {
                ProgressView()
                    .controlSize(.small)
            } else if showsDisclosureIndicator {
                Image(systemName: "chevron.right")
                    .font(WealthMapDesignTokens.Typography.footnote.weight(.semibold))
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textTertiary)
            }
        }
        .frame(minHeight: 40)
    }
}

private struct SettingsValueRow: View {
    let title: String
    let value: String
    var secondaryValue: String? = nil
    var subtitle: String?
    let systemImage: String
    var hidesDisclosureIndicator: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            SettingsRow(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage
            )

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(value)
                        .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if let secondaryValue {
                        Text(secondaryValue)
                            .font(WealthMapDesignTokens.Typography.caption2.weight(.medium))
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textTertiary)
                            .lineLimit(1)
                    }
                }

                if !hidesDisclosureIndicator {
                    Image(systemName: "chevron.right")
                        .font(WealthMapDesignTokens.Typography.footnote.weight(.semibold))
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textTertiary)
                }
            }
        }
    }
}

private extension View {
    /// Attaches the share sheet (export), file importer (import), and result alerts.
    func dataPortabilityModifiers(
        exportURL: Binding<URL?>,
        chatGPTExportURL: Binding<URL?>,
        isPreparingChatGPTExport: Binding<Bool>,
        exportError: Binding<String?>,
        isImporting: Binding<Bool>,
        importResultMessage: Binding<String?>,
        importError: Binding<String?>,
        pendingGoalImportData: Binding<Data?>,
        isConfirmingGoalReplacement: Binding<Bool>,
        modelContext: ModelContext
    ) -> some View {
        self
            // Export: standard iOS share sheet via UIActivityViewController.
            .sheet(isPresented: Binding(
                get: { exportURL.wrappedValue != nil },
                set: { if !$0 { exportURL.wrappedValue = nil } }
            )) {
                if let url = exportURL.wrappedValue {
                    ActivityView(url: url)
                        .ignoresSafeArea()
                }
            }
            // ChatGPT analysis: sanitized Markdown snapshot shared through iOS.
            .sheet(isPresented: Binding(
                get: { chatGPTExportURL.wrappedValue != nil },
                set: {
                    if !$0 {
                        chatGPTExportURL.wrappedValue = nil
                        isPreparingChatGPTExport.wrappedValue = false
                    }
                }
            )) {
                if let url = chatGPTExportURL.wrappedValue {
                    ActivityView(url: url)
                        .ignoresSafeArea()
                }
            }
            // Import: file picker — decode directly from the security-scoped URL.
            .fileImporter(
                isPresented: isImporting,
                allowedContentTypes: [.myWealthBackup, .json]
            ) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let url):
                        do {
                            guard url.startAccessingSecurityScopedResource() else { return }
                            defer { url.stopAccessingSecurityScopedResource() }
                            let data = try Data(contentsOf: url)
                            let preview = try DataImporter.previewImport(data, into: modelContext)
                            if preview.hasGoalConflict {
                                pendingGoalImportData.wrappedValue = data
                                isConfirmingGoalReplacement.wrappedValue = true
                            } else {
                                let summary = try DataImporter.importData(data, into: modelContext)
                                importResultMessage.wrappedValue = summary.description
                            }
                        } catch {
                            importError.wrappedValue = error.localizedDescription
                        }
                    case .failure(let error):
                        importError.wrappedValue = error.localizedDescription
                    }
                }
            }
            .alert("Export Failed", isPresented: Binding(
                get: { exportError.wrappedValue != nil },
                set: { if !$0 { exportError.wrappedValue = nil } }
            )) {
                Button("OK") { exportError.wrappedValue = nil }
            } message: {
                Text(exportError.wrappedValue ?? "")
            }
            .alert("Import Complete", isPresented: Binding(
                get: { importResultMessage.wrappedValue != nil },
                set: { if !$0 { importResultMessage.wrappedValue = nil } }
            )) {
                Button("OK") { importResultMessage.wrappedValue = nil }
            } message: {
                Text(importResultMessage.wrappedValue ?? "")
            }
            .alert("Import Failed", isPresented: Binding(
                get: { importError.wrappedValue != nil },
                set: { if !$0 { importError.wrappedValue = nil } }
            )) {
                Button("OK") { importError.wrappedValue = nil }
            } message: {
                Text(importError.wrappedValue ?? "")
            }
            .confirmationDialog(
                "Replace Net Worth Goal?",
                isPresented: isConfirmingGoalReplacement,
                titleVisibility: .visible
            ) {
                Button("Keep Current Goal") {
                    applyPendingImport(
                        resolution: .keepExisting,
                        data: pendingGoalImportData,
                        resultMessage: importResultMessage,
                        errorMessage: importError,
                        context: modelContext
                    )
                }
                Button("Replace Goal", role: .destructive) {
                    applyPendingImport(
                        resolution: .replaceExisting,
                        data: pendingGoalImportData,
                        resultMessage: importResultMessage,
                        errorMessage: importError,
                        context: modelContext
                    )
                }
                Button("Cancel", role: .cancel) {
                    pendingGoalImportData.wrappedValue = nil
                }
            } message: {
                Text("This backup contains a different goal. Other backup records remain additive.")
            }
    }

    @MainActor
    private func applyPendingImport(
        resolution: DataImporter.GoalConflictResolution,
        data: Binding<Data?>,
        resultMessage: Binding<String?>,
        errorMessage: Binding<String?>,
        context: ModelContext
    ) {
        guard let pendingData = data.wrappedValue else { return }
        defer { data.wrappedValue = nil }
        do {
            let summary = try DataImporter.importData(
                pendingData,
                into: context,
                goalConflictResolution: resolution
            )
            resultMessage.wrappedValue = summary.description
        } catch {
            errorMessage.wrappedValue = error.localizedDescription
        }
    }

    /// Attaches the confirmation dialog and result alert for the history cleanup action.
    func cleanupAlerts(
        isConfirming: Binding<Bool>,
        resultMessage: Binding<String?>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self
            .confirmationDialog(
                "Clean Up History?",
                isPresented: isConfirming,
                titleVisibility: .visible
            ) {
                Button("Remove Duplicates") { onConfirm() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Scans your history for duplicate entries recorded by an older bug and removes them. This cannot be undone.")
            }
            .alert(
                "History Cleanup",
                isPresented: Binding(
                    get: { resultMessage.wrappedValue != nil },
                    set: { if !$0 { resultMessage.wrappedValue = nil } }
                )
            ) {
                Button("OK") { resultMessage.wrappedValue = nil }
            } message: {
                Text(resultMessage.wrappedValue ?? "")
            }
    }
}

private struct BaseCurrencySelectionView: View {
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private let commonCurrencies: [Asset.CurrencyType] = [
        .usd,
        .inr,
        .eur,
        .gbp,
        .cad,
        .aud
    ]

    private var filteredCurrencies: [Asset.CurrencyType] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return Asset.CurrencyType.selectableCases
        }

        return Asset.CurrencyType.selectableCases.filter { currency in
            currency.rawValue.localizedCaseInsensitiveContains(query) ||
            currency.name.localizedCaseInsensitiveContains(query)
        }
    }

    private var groupedCurrencies: [(String, [Asset.CurrencyType])] {
        let currencies = searchText.isEmpty
            ? filteredCurrencies.filter { !commonCurrencies.contains($0) }
            : filteredCurrencies

        let grouped = Dictionary(grouping: currencies) { currency in
            String(currency.rawValue.prefix(1))
        }

        return grouped
            .map { ($0.key, $0.value.sorted { $0.rawValue < $1.rawValue }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        List {
            if searchText.isEmpty {
                Section("Common") {
                    ForEach(commonCurrencies) { currency in
                        currencyButton(for: currency)
                    }
                }
            }

            ForEach(groupedCurrencies, id: \.0) { letter, currencies in
                Section(letter) {
                    ForEach(currencies) { currency in
                        currencyButton(for: currency)
                    }
                }
            }
        }
        .navigationTitle("Base Currency")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }

    private func currencyButton(for currency: Asset.CurrencyType) -> some View {
        Button {
            settings.setBaseCurrency(currency)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(currency.rawValue)
                        .font(WealthMapDesignTokens.Typography.headline)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                    Text(currency.name)
                        .font(WealthMapDesignTokens.Typography.caption)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.inactive)
                }

                Spacer()

                if settings.baseCurrency == currency {
                    Image(systemName: "checkmark")
                        .font(WealthMapDesignTokens.Typography.bodySemibold)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                }
            }
        }
    }
}

private struct TotalCurrencySelectionView: View {
    @Bindable var settings: AppSettings
    @State private var searchText = ""

    private let commonCurrencies: [Asset.CurrencyType] = [
        .usd,
        .inr,
        .eur,
        .gbp,
        .cad,
        .aud
    ]

    private var filteredCurrencies: [Asset.CurrencyType] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return Asset.CurrencyType.selectableCases
        }

        return Asset.CurrencyType.selectableCases.filter { currency in
            currency.rawValue.localizedCaseInsensitiveContains(query) ||
            currency.name.localizedCaseInsensitiveContains(query)
        }
    }

    private var groupedCurrencies: [(String, [Asset.CurrencyType])] {
        let currencies = searchText.isEmpty
            ? filteredCurrencies.filter { !commonCurrencies.contains($0) }
            : filteredCurrencies

        let grouped = Dictionary(grouping: currencies) { currency in
            String(currency.rawValue.prefix(1))
        }

        return grouped
            .map { ($0.key, $0.value.sorted { $0.rawValue < $1.rawValue }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        List {
            if searchText.isEmpty {
                Section {
                    NavigationLink {
                        DisplayCurrencyArrangementView(
                            currencies: $settings.totalCurrencies,
                            requiredCurrency: settings.baseCurrency
                        )
                    } label: {
                        HStack(spacing: 12) {
                            Label("Arrange Selected", systemImage: "arrow.up.arrow.down")
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)

                            Spacer(minLength: 8)

                            Text(selectedCurrencySummary)
                                .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
            }

            if searchText.isEmpty {
                Section("Common") {
                    ForEach(commonCurrencies) { currency in
                        currencyButton(for: currency)
                    }
                }
            }

            ForEach(groupedCurrencies, id: \.0) { letter, currencies in
                Section(letter) {
                    ForEach(currencies) { currency in
                        currencyButton(for: currency)
                    }
                }
            }
        }
        .navigationTitle("Display Currencies")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }

    private var selectedCurrencySummary: String {
        settings.totalCurrencies.map(\.rawValue).joined(separator: ", ")
    }

    private func currencyButton(for currency: Asset.CurrencyType) -> some View {
        Button {
            settings.toggleTotalCurrency(currency)
        } label: {
            CurrencyRowView(currency: currency, isSelected: settings.totalCurrencies.contains(currency))
        }
    }
}
