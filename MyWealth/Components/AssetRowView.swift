//
//  AssetRowView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//
import SwiftUI

struct AssetRowView: View {

    let asset: Asset
    /// Pass the metal-price rates dictionary (symbol → units-of-metal-per-USD).
    /// Defaults to empty so existing call sites without metal-price access compile unchanged.
    var metalRates: [String: Double] = [:]

    // MARK: - Metal helpers

    private var isMetal: Bool { asset.displayCategory.isPreciousMetal }

    /// The user's chosen display unit (falls back to troy oz for legacy rows).
    private var displayUnit: WeightUnit {
        asset.weightUnit ?? .troyOz
    }

    /// Weight converted from stored troy oz into the display unit.
    private var displayWeight: Double {
        asset.displayAmount / displayUnit.troyOzPerUnit
    }

    /// Formatted weight string, e.g. "1 kg" or "5.5 troy oz".
    private var weightLabel: String {
        "\(unsafe String(format: "%g", displayWeight)) \(displayUnit.label)"
    }

    /// Estimated market value in USD, or nil when the rate is unavailable.
    private var estimatedUSD: Double? {
        guard let symbol = asset.category?.metalCurrency?.rawValue,
              let rate = metalRates[symbol],
              rate > 0 else { return nil }
        // rate = units-of-metal per 1 USD  →  price per troy oz = 1 / rate
        return asset.displayAmount / rate
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: asset.displayCategory.icon)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                .frame(width: 25)

            VStack(alignment: .leading, spacing: 3) {
                Text(asset.displayName.isEmpty ? "Unnamed Asset" : asset.displayName)
                    .font(WealthMapDesignTokens.Typography.headline)

                if !asset.participatesInPortfolioCalculations {
                    Label("Marked ignored", systemImage: "eye.slash.fill")
                        .font(WealthMapDesignTokens.Typography.caption2.weight(.semibold))
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.warning)
                }

                if isMetal {
                    metalSubtitle
                } else {
                    standardSubtitle
                }

                Text(asset.displayCategory.localizedName)
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.inactive)
            }

            Spacer(minLength: 0)

            if isMetal, let usd = estimatedUSD {
                Text(usd, format: .currency(code: "USD"))
                    .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Sub-views

    /// Weight + optional spot-value line for metal assets.
    private var metalSubtitle: some View {
        HStack(spacing: 6) {
            // Colour dot matching the metal
            if let metal = PreciousMetalSelectionView.metals.first(where: { $0.currency == asset.category?.metalCurrency }) {
                Circle()
                    .fill(metal.color)
                    .frame(width: 7, height: 7)
            }
            Text(weightLabel)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)

            if estimatedUSD == nil {
                Text("· price unavailable")
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textTertiary)
            }
        }
        .font(WealthMapDesignTokens.Typography.subheadline)
    }

    /// Standard amount + currency code line for non-metal assets.
    private var standardSubtitle: some View {
        HStack(spacing: 4) {
            Text("\(asset.displayAmount, specifier: "%.0f")")
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
            Text(asset.displayCurrency.rawValue)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
        }
        .font(WealthMapDesignTokens.Typography.subheadline)
    }
}
