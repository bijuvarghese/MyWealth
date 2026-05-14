import SwiftUI

struct CurrencySummaryView: View {
    let currency: Asset.CurrencyType

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(currency.rawValue)
                .foregroundStyle(.primary)
            Text(currency.name)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}
