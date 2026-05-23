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
                AddorEditAssetView()
            }
            .sheet(isPresented: $showAddLiabilitySheet) {
                AddOrEditLiabilityView()
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
                                AssetListCard {
                                    HStack(spacing: 12) {
                                        AssetRowView(asset: asset)

                                        Image(systemName: "chevron.right")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .assetListRow()
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteAssets)
                    }
                }

                if !liabilities.isEmpty {
                    Section(header: PillLabel("Liabilities")) {
                        ForEach(liabilities) { liability in
                            AssetListCard {
                                LiabilityRowView(liability: liability)
                            }
                            .assetListRow()
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

private struct AssetListCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

            content
                .padding(12)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension View {
    func assetListRow() -> some View {
        listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
}
