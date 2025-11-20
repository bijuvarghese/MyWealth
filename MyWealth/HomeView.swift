//
//  HomeView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/8/25.
//

import SwiftUI
enum HomeViewState {
    case initial
    case currencySelection
    case dashboard
}

struct HomeView: View {
    let viewModel: HomeViewModel = HomeViewModel()
    var body: some View {
        VStack {
            switch viewModel.state {
            case .initial:
                InitalLoadingView()
            case .currencySelection:
                SettingsView()
            case .dashboard:
                DashboardView()
            }
        }
        .task {
            viewModel.loadAppData()
        }
        
    }
}

private enum DefaultsKeys {
    static let lastUpdated = "exchangeRate.lastUpdated"
    static let rate = "exchangeRate.value"
    static let baseCurrency = "baseCurrency"
    static let apikey = "cualLc86jPPqWwxNk6H1KRwHPqI9doH6"

}

@Observable
final class HomeViewModel {
    // Simple persistence key for whether the user finished initial preferences
    private let baseCurrency = "baseCurrency"
    private let otherCurrency = "otherCurrency"

    /// Returns true if the user has completed initial preferences setup.
    /// Replace this with your actual persistence mechanism if needed.
    func hasUserSetPreferences() -> Bool {
        UserDefaults.standard.bool(forKey: hasCompletedPreferencesKey)
    }

    /// Call this when the user completes preferences so future launches skip setup.
    func markUserPreferencesCompleted() {
        UserDefaults.standard.set(true, forKey: hasCompletedPreferencesKey)
    }
    
    var state: HomeViewState = .initial
    
    func loadAppData() {
        if hasUserSetPreferences() {
            self.state = .dashboard
        } else {
            self.state = .currencySelection
        }
    }
    
}
