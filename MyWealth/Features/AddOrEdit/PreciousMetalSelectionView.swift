//
//  PreciousMetalSelectionView.swift
//  MyWealth
//

import SwiftUI

struct PreciousMetalSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: Asset.CurrencyType

    struct MetalOption: Identifiable {
        let currency: Asset.CurrencyType
        let name: String
        let symbol: String
        let unit: String
        let color: Color

        var id: String { symbol }
    }

    static let metals: [MetalOption] = [
        MetalOption(currency: .xau, name: "Gold",      symbol: "XAU", unit: "troy oz", color: Color(red: 0.85, green: 0.65, blue: 0.13)),
        MetalOption(currency: .xag, name: "Silver",    symbol: "XAG", unit: "troy oz", color: Color(.systemGray)),
        MetalOption(currency: .xpt, name: "Platinum",  symbol: "XPT", unit: "troy oz", color: Color(.systemTeal)),
        MetalOption(currency: .xpd, name: "Palladium", symbol: "XPD", unit: "troy oz", color: Color(.systemMint)),
    ]

    var body: some View {
        List {
            Section("Precious Metals") {
                ForEach(Self.metals) { metal in
                    Button {
                        selection = metal.currency
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(metal.color)
                                .frame(width: 12, height: 12)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(metal.name)
                                    .font(WealthMapDesignTokens.Typography.headline)
                                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                                Text("\(metal.symbol) · \(metal.unit)")
                                    .font(WealthMapDesignTokens.Typography.caption)
                                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                            }

                            Spacer()

                            if selection == metal.currency {
                                Image(systemName: "checkmark")
                                    .font(WealthMapDesignTokens.Typography.bodySemibold)
                                    .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Select Metal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension Asset.CurrencyType {
    /// Returns true if this currency represents a precious metal.
    var isPreciousMetal: Bool {
        PreciousMetalSelectionView.metals.map(\.currency).contains(self)
    }
}
