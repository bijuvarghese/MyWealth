//
//  HomeView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/8/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "person")
                }
            
            
            DashboardView()
                .tabItem {
                    Label("Story", systemImage: "book")
                }
            
        }
    }
}

#Preview {
    HomeView()
}
