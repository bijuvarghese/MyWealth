import SwiftUI

struct CurrencyRowView: View {
    let currency: Asset.CurrencyType
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(currency.rawValue)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(currency.name)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.accent)
            }
        }
    }
}
