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
                Toggle("Enable iCloud Backup and Sync", isOn: $iCloudSyncEnabled)
                    .tint(WealthMapDesignTokens.ColorToken.brandPrimary)
                    .disabled(!iCloudAvailable)
                    .padding(WealthMapDesignTokens.Spacing.standard)
                    .background {
                        RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: WealthMapDesignTokens.Elevation.cardShadowColor, radius: WealthMapDesignTokens.Elevation.cardShadowRadius, x: WealthMapDesignTokens.Elevation.cardShadowX, y: WealthMapDesignTokens.Elevation.cardShadowY)
                    }
                    .listRowBackground(WealthMapDesignTokens.ColorToken.surfaceClear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))

                if !iCloudAvailable {
                    Text("Sign in to iCloud in Settings to enable.")
                        .font(WealthMapDesignTokens.Typography.caption)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        .listRowBackground(WealthMapDesignTokens.ColorToken.surfaceClear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 28, bottom: 6, trailing: 16))
                }
            } header: {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Choose local-only or iCloud", systemImage: "icloud.fill")
                        .font(WealthMapDesignTokens.Typography.title)
                        .foregroundStyle(primaryTextColor)

                    Text("Wealth Map keeps your financial records on this device by default.")
                        .font(WealthMapDesignTokens.Typography.body)
                        .foregroundStyle(primaryTextColor)

                    Text("Turn on iCloud only if you want Apple iCloud backup and sync through your personal account.")
                        .font(WealthMapDesignTokens.Typography.footnote)
                        .foregroundStyle(secondaryTextColor)

                    Text("Wealth Map does not require a separate account or bank login, and you can change this anytime in Settings.")
                        .font(WealthMapDesignTokens.Typography.footnote)
                        .foregroundStyle(secondaryTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(WealthMapDesignTokens.Spacing.section)
                .background {
                    RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: WealthMapDesignTokens.Elevation.cardShadowColor, radius: WealthMapDesignTokens.Elevation.cardShadowRadius, x: WealthMapDesignTokens.Elevation.cardShadowX, y: WealthMapDesignTokens.Elevation.cardShadowY)
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
