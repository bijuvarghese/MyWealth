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
    
    @ViewBuilder
    private var contentView: some View {
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
                        DashboardCard {
                            VStack(spacing: 10) {
                                CurrencyTotalsView(
                                    totals: viewModel.totalsByCurrency(
                                        assets,
                                        baseCurrency: settings.baseCurrency,
                                        displayCurrencies: settings.totalCurrencies
                                    ),
                                    useCompactFormatting: settings.usesCompactCurrencyTotals
                                )

                                if let rateStatus = viewModel.rateStatus {
                                    Divider()
                                    RateStatusBannerView(status: rateStatus)
                                }
                            }
                        }
                        .dashboardListRow()
                    } header: {
                        HStack {
                            Text("Net Worth")
                            Spacer()
                            HStack(spacing: 6) {
                                Text("Compact")
                                    .font(.caption)
                                Toggle("Compact", isOn: $settings.usesCompactCurrencyTotals)
                                    .labelsHidden()
                            }
                        }
                    }

                    Section(footer: FooterView(
                        model: viewModel.getFooterData(
                            assets,
                            baseCurrency: settings.baseCurrency,
                            displayCurrencies: settings.totalCurrencies
                        )
                    )) {
                        DashboardCard {
                            TransferRateWidgetView(
                                rows: viewModel.transferRateRows(
                                    baseCurrency: settings.baseCurrency,
                                    displayCurrencies: settings.totalCurrencies
                                ),
                                baseCurrency: settings.baseCurrency,
                                lastUpdated: viewModel.lastUpdated
                            )
                        }
                        .dashboardListRow()
                    }

                    Section(header: Text("Assets")) {
                        ForEach(assets) { asset in
                            DashboardCard {
                                AssetRowView(asset: asset)
                            }
                            .dashboardListRow()
                            .listRowSeparator(.hidden)
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
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RadialDotBackground(dotRadius: 1, spacing: 20)
                    .ignoresSafeArea(.all)
                contentView
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

private struct DashboardCard<Content: View>: View {
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
    func dashboardListRow() -> some View {
        listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
}
