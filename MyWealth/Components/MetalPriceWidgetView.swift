import SwiftUI

struct MetalPriceWidgetView: View {
    /// Rows pre-bucketed by group, in display order.
    let groups: [(group: MetalGroup, rows: [MetalPriceRow])]
    let isLoading: Bool
    let lastUpdated: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if groups.isEmpty {
                unavailableState
            } else {
                ForEach(groups, id: \.group) { item in
                    MetalGroupSection(group: item.group, rows: item.rows)

                    if item.group != groups.last?.group {
                        Divider()
                            .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.bar.fill")
                .foregroundStyle(.accent)
            Text("Metal Prices")
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            if isLoading {
                ProgressView()
                    .scaleEffect(0.75)
            } else if let lastUpdated {
                Text(lastUpdated, format: .relative(presentation: .numeric))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Empty state

    private var unavailableState: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .foregroundStyle(.secondary)
                .frame(width: 25)

            VStack(alignment: .leading, spacing: 3) {
                Text("Prices unavailable")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Text("Pull to refresh or check back later")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Group section

private struct MetalGroupSection: View {
    let group: MetalGroup
    let rows: [MetalPriceRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(group.rawValue.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)

            ForEach(rows) { row in
                MetalPriceRowView(row: row)

                if row.id != rows.last?.id {
                    Divider()
                        .padding(.leading, 32)
                }
            }
        }
    }
}

// MARK: - Row view

private struct MetalPriceRowView: View {
    let row: MetalPriceRow

    var body: some View {
        HStack(spacing: 12) {
            // Colour dot
            Circle()
                .fill(row.color)
                .frame(width: 10, height: 10)
                .frame(width: 20)

            // Name + symbol
            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(row.symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Price
            VStack(alignment: .trailing, spacing: 2) {
                if let price = row.priceInBase {
                    Text(price, format: .currency(code: row.baseCurrencyCode))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                } else {
                    Text("—")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("/ \(row.unit)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
