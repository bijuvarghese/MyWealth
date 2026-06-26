import SwiftUI
import SwiftData

struct AssetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var assets: [Asset]
    @Query private var liabilities: [Liability]
    @Bindable var settings: AppSettings

    @State private var showAddSheet = false
    @State private var showAddLiabilitySheet = false
    @State private var selectedAsset: Asset?
    @State private var selectedLiability: Liability?
    @State private var metalViewModel = MetalPricesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                RadialDotBackground(dotRadius: 1, spacing: 20)
                    .ignoresSafeArea(.all)

                contentView
            }
            .navigationTitle("Assets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showAddSheet = true
                        } label: {
                            Label("Asset", systemImage: "plus.circle.fill")
                        }

                        Button {
                            showAddLiabilitySheet = true
                        } label: {
                            Label("Debt", systemImage: "minus.circle.fill")
                        }
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddorEditAssetView(sourceScreen: .assets)
            }
            .task {
                await metalViewModel.refreshIfNeeded()
            }
            .sheet(isPresented: $showAddLiabilitySheet) {
                AddOrEditLiabilityView(sourceScreen: .assets)
            }
            .sheet(item: $selectedLiability) { liability in
                AddOrEditLiabilityView(liability: liability)
            }
            .navigationDestination(item: $selectedAsset) { asset in
                AssetDetailView(asset: asset, settings: settings)
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if assets.isEmpty && liabilities.isEmpty {
            ContentUnavailableView(
                "No Assets or Debt",
                systemImage: "banknote",
                description: Text("Tap '+' to add your first asset or debt.")
            )
        } else {
            List {
                if !assets.isEmpty {
                    Section(header: PillLabel("Assets")) {
                        ForEach(assets) { asset in
                            Button {
                                selectedAsset = asset
                            } label: {
                                AppListCard {
                                    HStack(spacing: 12) {
                                        AssetRowView(asset: asset, metalRates: metalViewModel.metalRates)

                                        Image(systemName: "chevron.right")
                                            .font(WealthMapDesignTokens.Typography.footnote.weight(.semibold))
                                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textTertiary)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .appListRow()
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteAssets)
                    }
                }

                if !liabilities.isEmpty {
                    Section(header: PillLabel("Liabilities")) {
                        ForEach(liabilities) { liability in
                            AppListCard {
                                LiabilityRowView(liability: liability)
                            }
                            .appListRow()
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                selectedLiability = liability
                            }
                        }
                        .onDelete(perform: deleteLiabilities)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
    }

    private func deleteAssets(at indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(assets[index])
        }
    }

    private func deleteLiabilities(at indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(liabilities[index])
        }
    }
}
