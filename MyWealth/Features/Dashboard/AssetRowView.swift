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
            Image(systemName: asset.category?.icon ?? "")
                .foregroundStyle(.launch)
                .frame(width: 25)
            VStack(alignment: .leading) {
                Text(asset.name ?? "")
                    .font(.headline)
                HStack {
                    Text("\(asset.amount ?? 0, specifier: "%.0f")")
                        .foregroundStyle(.secondary)
                    Text("\(asset.currency?.rawValue ?? "")")
                        .foregroundStyle(.primary)
                }
                Text(asset.category?.rawValue ?? "")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
    }
}
