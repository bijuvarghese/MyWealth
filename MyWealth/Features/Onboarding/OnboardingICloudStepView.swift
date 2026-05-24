//
//  OnboardingICloudStepView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//

import SwiftUI
import CloudKit

struct OnboardingICloudStepView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var iCloudSyncEnabled: Bool

    @State private var iCloudAvailable = false

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryTextColor: Color {
        primaryTextColor
    }

    var body: some View {
        Form {
            Section {
                Toggle("Enable iCloud Backup & Sync", isOn: $iCloudSyncEnabled)
                    .tint(.accentColor)
                    .disabled(!iCloudAvailable)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))

                if !iCloudAvailable {
                    Text("Sign in to iCloud in Settings to enable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 28, bottom: 6, trailing: 16))
                }
            } header: {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Back Up & Sync Your Wealth Map", systemImage: "icloud.fill")
                        .font(.title3.bold())
                        .foregroundStyle(primaryTextColor)

                    Text("Your assets and net worth history will be securely backed up to your personal iCloud account and synced across all your devices.")
                        .font(.body)
                        .foregroundStyle(primaryTextColor)

                    Text("Your data is private — only you can access it. No one else, including the app developer, can see it.")
                        .font(.footnote)
                        .foregroundStyle(secondaryTextColor)

                    Text("You can change this anytime in Settings.")
                        .font(.footnote)
                        .foregroundStyle(secondaryTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .task {
            #if targetEnvironment(simulator)
            // CKContainer always returns .noAccount in the Simulator.
            // Force-enable so the UI flow can be exercised during development.
            iCloudAvailable = true
            #else
            let status = try? await CKContainer.default().accountStatus()
            iCloudAvailable = (status == .available)
            #endif
        }
    }
}

#Preview {
    OnboardingICloudStepView(iCloudSyncEnabled: .constant(false))
}
