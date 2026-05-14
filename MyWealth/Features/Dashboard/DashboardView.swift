//
//  ContentView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//


import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var assets: [Asset]
    
    @State private var showAddSheet = false
    @State private var showSettings = false
    @State private var viewModel = DashboardViewModel()
    @State private var settings = AppSettings()
    
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
                        Section("Net Worth") {
                            CurrencyTotalsView(totals: viewModel.totalsByCurrency(assets))
                        }
                        Section(header: Text("Assets"), footer: FooterView(
                            model: viewModel.getFooterData(
                                assets,
                                baseCurrency: settings.baseCurrency,
                                displayCurrencies: settings.totalCurrencies
                            )
                        )
                        ) {
                            ForEach(assets) { asset in
                                AssetRowView(asset: asset)
                                    .onTapGesture {
                                        viewModel.selectedAsset = asset
                                        showAddSheet = true
                                    }
                                
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    modelContext.delete(assets[index])
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Assets")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Add Asset", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(
                isPresented: $showAddSheet,
                onDismiss: {
                    viewModel.selectedAsset = nil
                },
                content: {
                    AddorEditAssetView(asset: viewModel.selectedAsset)
                }
            )
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings)
            }
        }
        .task {
            await viewModel.refreshExchangeRateIfNeeded()
        }
    }
}
