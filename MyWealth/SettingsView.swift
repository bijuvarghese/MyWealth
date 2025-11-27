//
//  SettingsView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/14/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var currencies: Currencies

    let viewModel = SettingsViewModel()
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
    
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("Currency")) {
                        HStack {
                            Text("USD")
                            Spacer()
                            Button {
                                
                            } label: {
                                Label("", systemImage: "arrow.left.arrow.right")
                            }
                            Spacer()
                            Text("INR")
                        }
                    }
                }
                Spacer()
                HStack {
                    Text("Version")
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await viewModel.refreshDataIfNeeded()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

    }
}

@Observable
final class SettingsViewModel {
    var isLoadingRate: Bool = false
    
    func refreshDataIfNeeded() async {
        guard let symbols = await getAllSymbols() else { return }
        
        
    }
    
    func getAllSymbols() async -> [String: String]? {
        guard let url = URL(string: "https://api.apilayer.com/exchangerates_data/symbols") else {
            return nil
        }
        isLoadingRate = true
        defer { isLoadingRate = false }
        do {
            let decoded: SymbolsResponse = try await NetworkManager.shared.getResponse(
                from: url,
                headers: ["apikey": "cualLc86jPPqWwxNk6H1KRwHPqI9doH6"]
            )
            if let symbols = decoded.symbols {
                let now = Date()
                return symbols
            }
        } catch {
            print("⚠️ Error fetching rate:", error)
        }
        return nil
    }
}
