//
//  ContentView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//


import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var assets: [Asset]
    
    @State private var showAddSheet = false
    @State private var showSettings = false
    @State private var viewModel = DashboardViewModel()
    @State private var settings = AppSettings()
    
    fileprivate func contentView() -> AnyView {
        return AnyView(
            VStack(spacing: 0) {
                if assets.isEmpty {
                    ContentUnavailableView(
                        "No Assets",
                        systemImage: "banknote",
                        description: Text("Tap '+' to add your first asset.")
                    )
                } else {
                    List {
                        Section {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                                CurrencyTotalsView(
                                    totals: viewModel.totalsByCurrency(assets),
                                    useCompactFormatting: settings.usesCompactCurrencyTotals
                                )
                                    .padding(12)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        } header: {
                            HStack {
                                Text("Net Worth")
                                Spacer()
                                Toggle("Compact ", isOn: $settings.usesCompactCurrencyTotals)
                                    .font(.caption)
                                    .labelsHidden()
                            }
                        }

                        Section(footer: FooterView(
                            model: viewModel.getFooterData(
                                assets,
                                baseCurrency: settings.baseCurrency,
                                displayCurrencies: settings.totalCurrencies
                            )
                        )) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                                TransferRateWidgetView(
                                    rows: viewModel.transferRateRows(
                                        baseCurrency: settings.baseCurrency,
                                        displayCurrencies: settings.totalCurrencies
                                    ),
                                    baseCurrency: settings.baseCurrency,
                                    lastUpdated: viewModel.lastUpdated
                                )
                                .padding(12)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                        Section(header: Text("Assets")) {
                            ForEach(assets) { asset in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                                    AssetRowView(asset: asset)
                                        .padding(12)
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)      // hide separators for these rows
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
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                }
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RadialDotBackground(dotRadius: 1, spacing: 20)
                    .ignoresSafeArea(.all)
                contentView()
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
