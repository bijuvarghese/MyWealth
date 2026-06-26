import SwiftUI

struct IPadRootView: View {
    @Bindable var settings: AppSettings
    @State private var selection: IPadSection = .dashboard

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(IPadSection.allCases) { section in
                    Button {
                        selection = section
                    } label: {
                        Label(section.title, systemImage: section.systemImage)
                            .font(.body.weight(selection == section ? .semibold : .regular))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selection == section ? WealthMapDesignTokens.ColorToken.brandPrimary : WealthMapDesignTokens.ColorToken.textPrimary)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.compactRadius, style: .continuous)
                            .fill(selection == section ? WealthMapDesignTokens.ColorToken.brandPrimary.opacity(0.14) : WealthMapDesignTokens.ColorToken.surfaceClear)
                    )
                }
            }
            .navigationTitle("Wealth Map")
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            detailView(for: selection)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func detailView(for section: IPadSection) -> some View {
        switch section {
        case .dashboard:
            DashboardView(settings: settings)
        case .assets:
            AssetListView(settings: settings)
        case .netWorth:
            NetWorthView(settings: settings)
        case .rates:
            TransferRatesView(settings: settings)
        case .briefing:
            BriefingView(settings: settings)
        }
    }
}

private enum IPadSection: String, CaseIterable, Hashable, Identifiable {
    case dashboard
    case assets
    case netWorth
    case rates
    case briefing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .assets:
            return "Assets"
        case .netWorth:
            return "Net Worth"
        case .rates:
            return "Rates"
        case .briefing:
            return "Briefing"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            return "chart.pie.fill"
        case .assets:
            return "list.bullet.rectangle"
        case .netWorth:
            return "chart.line.uptrend.xyaxis"
        case .rates:
            return "arrow.left.arrow.right.circle.fill"
        case .briefing:
            return "sparkles"
        }
    }
}
