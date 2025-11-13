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
                        showAddSheet = true
                    } label: {
                        Label("Add Asset", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddAssetView()
            }
        }
        .task {
            await viewModel.refreshExchangeRateIfNeeded()
        }
    }
}
