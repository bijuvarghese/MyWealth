//
//  MyWealthApp.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//

import SwiftUI
import SwiftData

@main
struct MyWealthApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Asset.self,
            Currencies.self            
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: ModelConfiguration.GroupContainer.automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .modelContainer(sharedModelContainer)
    }
}
