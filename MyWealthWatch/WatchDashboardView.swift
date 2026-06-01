import SwiftUI

struct WatchDashboardView: View {
    @ObservedObject var store: WatchPortfolioStore

    private var snapshot: WatchPortfolioSnapshot {
        store.snapshot
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                netWorthCard
                totalsCard
                preferredCurrencyCard
                footer
            }
            .padding(.vertical, 4)
        }
        .containerBackground(.black, for: .navigation)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Wealth Map")
                .font(.headline)
            Text(store.connectionStatus)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var netWorthCard: some View {
        WatchCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("Net Worth")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(snapshot.netWorth.watchCurrencyString(code: snapshot.baseCurrency))
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)

                Text(snapshot.baseCurrency)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.yellow)
            }
        }
    }

    private var totalsCard: some View {
        WatchCard {
            VStack(spacing: 8) {
                WatchTotalRow(
                    title: "Assets",
                    amount: snapshot.assetTotal,
                    currencyCode: snapshot.baseCurrency,
                    tint: .green
                )

                Divider()

                WatchTotalRow(
                    title: "Liabilities",
                    amount: snapshot.liabilityTotal,
                    currencyCode: snapshot.baseCurrency,
                    tint: .red
                )
            }
        }
    }

    @ViewBuilder
    private var preferredCurrencyCard: some View {
        if let preferredCurrency = snapshot.preferredCurrency {
            WatchCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Also in \(preferredCurrency.code)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(preferredCurrency.amount.watchCurrencyString(code: preferredCurrency.code))
                        .font(.headline.weight(.semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)

                    if let rate = preferredCurrency.transferRate {
                        Text("1 \(snapshot.baseCurrency) = \(rate.formatted(.number.precision(.significantDigits(4...6)))) \(preferredCurrency.code)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                }
            }
        }
    }

    private var footer: some View {
        Text("Rates \(snapshot.ratesUpdatedAt.formatted(date: .abbreviated, time: .shortened))")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

private struct WatchCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct WatchTotalRow: View {
    let title: String
    let amount: Double
    let currencyCode: String
    let tint: Color

    var body: some View {
        HStack {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 6)

            Text(amount.watchCurrencyString(code: currencyCode))
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

private extension Double {
    func watchCurrencyString(code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = abs(self) >= 1_000 ? 0 : 2
        return formatter.string(from: NSNumber(value: self)) ?? "\(self.formatted()) \(code)"
    }
}
