import SwiftUI

struct CurrencyTotalsView: View {
    let totals: [CurrencyTotal]

    var body: some View {
        VStack(spacing: 8) {            
            ForEach(totals) { total in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(total.currency.rawValue)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(total.currency.name)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    
                    Spacer()
                    
                    Text(total.amount, format: .currency(code: total.currency.rawValue))
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
