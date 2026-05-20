import SwiftUI

struct TransferRateWidgetView: View {
    let rows: [TransferRateRow]
    let baseCurrency: Asset.CurrencyType
    let lastUpdated: Date?

    var body: some View {
        if rows.isEmpty {
            unavailableState
        } else {
            VStack(alignment: .leading, spacing: 12) {
                header

                ForEach(rows) { row in
                    TransferRateRowView(row: row)

                    if row.id != rows.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .foregroundStyle(.accent)
            Text("Transfer Rates")
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()            
            if let lastUpdated {
                Text(lastUpdated, format: .relative(presentation: .numeric))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var unavailableState: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.left.arrow.right")
                .foregroundStyle(.accent)
                .frame(width: 25)

            VStack(alignment: .leading, spacing: 3) {
                Text("Transfer Rates")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Add display currencies in Settings")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct TransferRateRowView: View {
    let row: TransferRateRow

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(row.baseCurrency.rawValue)
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                    Text(row.targetCurrency.rawValue)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                Text(row.targetCurrency.name)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("1 \(row.baseCurrency.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                if let rate = row.rate {
                    Text("\(rate, format: .number.precision(.significantDigits(4...6))) \(row.targetCurrency.rawValue)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                } else {
                    Text("Unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

