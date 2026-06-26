import SwiftUI

fileprivate func abbreviatedCurrency(amount: Double, currencyCode: String, locale: Locale = .current) -> String {
    let absValue = abs(amount)

    let unit: String
    let scaled: Double

    switch absValue {
    case 1_000_000_000_000...:
        unit = "T"; scaled = amount / 1_000_000_000_000
    case 1_000_000_000...:
        unit = "B"; scaled = amount / 1_000_000_000
    case 1_000_000...:
        unit = "M"; scaled = amount / 1_000_000
    case 1_000...:
        unit = "K"; scaled = amount / 1_000
    default:
        unit = ""; scaled = amount
    }

    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    numberFormatter.locale = locale
    numberFormatter.maximumFractionDigits = (abs(scaled) < 10 ? 2 : 1)

    let numberPart = numberFormatter.string(from: NSNumber(value: scaled)) ?? "\(scaled)"

    let currencyFormatter = NumberFormatter()
    currencyFormatter.numberStyle = .currency
    currencyFormatter.currencyCode = currencyCode
    currencyFormatter.locale = locale
    let symbol = currencyFormatter.currencySymbol ?? ""

    return unit.isEmpty ? "\(symbol)\(numberPart)" : "\(symbol)\(numberPart)\(unit)"
}

struct CurrencyTotalsView: View {
    let totals: [CurrencyTotal]
    var useCompactFormatting: Bool = false

    var body: some View {
        VStack(spacing: 8) {            
            ForEach(totals) { total in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(total.currency.rawValue)
                            .font(WealthMapDesignTokens.Typography.headline)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                        Text(total.currency.name)
                            .font(WealthMapDesignTokens.Typography.caption)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.inactive)
                    }
                    
                    Spacer()
                    
                    Group {
                        if useCompactFormatting {
                            Text(abbreviatedCurrency(amount: total.amount, currencyCode: total.currency.rawValue))
                        } else {
                            Text(total.amount, format: .currency(code: total.currency.rawValue))
                        }
                    }
                    .font(WealthMapDesignTokens.Typography.headline)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
