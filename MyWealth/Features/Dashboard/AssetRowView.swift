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
                .foregroundStyle(.blue)
                .frame(width: 25)
            VStack(alignment: .leading) {
                Text(asset.name ?? "")
                    .font(.headline)
                Text("\(asset.amount ?? 0, specifier: "%.2f") \(asset.currency?.rawValue ?? "")")
                    .foregroundStyle(.secondary)
                Text(asset.category?.rawValue ?? "")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
    }
}
