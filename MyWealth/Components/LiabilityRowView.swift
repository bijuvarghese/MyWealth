import SwiftUI

struct LiabilityRowView: View {
    let liability: Liability

    var body: some View {
        HStack {
            Image(systemName: liability.displayCategory.icon)
                .foregroundStyle(.red)
                .frame(width: 25)

            VStack(alignment: .leading) {
                Text(liability.displayName)
                    .font(.headline)

                HStack {
                    Text(liability.displayAmount, format: .number.precision(.fractionLength(0)))
                        .foregroundStyle(.secondary)
                    Text(liability.displayCurrency.rawValue)
                        .foregroundStyle(.primary)
                }

                Text(liability.displayCategory.rawValue)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
    }
}
