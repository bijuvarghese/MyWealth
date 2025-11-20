//
//  ContentView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//


import SwiftUI
import SwiftData
import Charts
enum SheetType {
    case addAsset
    case settings
}

struct SheetTypeModel: Identifiable {
    let id = UUID()
    let type: SheetType
}
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var assets: [Asset]
    
    @State private var showSheet: SheetTypeModel? = nil
    @State private var viewModel = DashboardViewModel()
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if assets.isEmpty {
                    ContentUnavailableView(
                        "No Assets",
                        systemImage: "banknote",
                        description: Text("Tap '+' to add your first asset.")
                    )
                } else {
                    List {
                        ForEach(assets) { asset in
                            AssetRowView(asset: asset)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                modelContext.delete(assets[index])
                            }
                        }
                    }
                    FooterView(model: viewModel.getFooterData(assets))
                }
            }
            .navigationTitle("My Assets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSheet = SheetTypeModel(type: .addAsset)
                    } label: {
                        Label("Add Asset", systemImage: "plus.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSheet = SheetTypeModel(type: .settings)
                    } label: {
                        Label("Add Asset", systemImage: "gear.circle.fill")
                    }
                }
                
            }
            .sheet(item: $showSheet) { sheet in
                switch sheet.type {
                case .addAsset:
                    AddAssetView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .task {
            await viewModel.refreshExchangeRateIfNeeded()
        }
    }
}

