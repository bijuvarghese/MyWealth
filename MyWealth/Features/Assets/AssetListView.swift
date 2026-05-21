import SwiftUI
import SwiftData

struct AssetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var assets: [Asset]

    @State private var showAddSheet = false
    @State private var selectedAsset: Asset?

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
                    Button {
                        selectedAsset = nil
                        showAddSheet = true
                    } label: {
                        Label("Add Asset", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(
                isPresented: $showAddSheet,
                onDismiss: {
                    selectedAsset = nil
                },
                content: {
                    AddorEditAssetView(asset: selectedAsset)
                }
            )
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if assets.isEmpty {
            ContentUnavailableView(
                "No Assets",
                systemImage: "banknote",
                description: Text("Tap '+' to add your first asset.")
            )
        } else {
            List {
                Section {
                    ForEach(assets) { asset in
                        AssetListCard {
                            AssetRowView(asset: asset)
                        }
                        .assetListRow()
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            selectedAsset = asset
                            showAddSheet = true
                        }
                    }
                    .onDelete(perform: deleteAssets)
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
