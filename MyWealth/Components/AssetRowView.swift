//
//  AssetRowView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//
import SwiftUI
struct AssetRowView: View {
    
    let asset: Asset
    
    var body: some View {
        HStack {
            Image(systemName: asset.displayCategory.icon)
                .foregroundStyle(.accent)
                .frame(width: 25)
            VStack(alignment: .leading) {
                Text(asset.displayName)
                    .font(.headline)
                HStack {
                    Text("\(asset.displayAmount, specifier: "%.0f")")
                        .foregroundStyle(.secondary)
                    Text(asset.displayCurrency.rawValue)
                        .foregroundStyle(.primary)
                }
                Text(asset.displayCategory.rawValue)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
    }
}
