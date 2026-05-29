import SwiftUI

struct DashboardNetWorthTotalsView: View {
    let totals: [CurrencyTotal]
    let rateStatus: RateStatusModel?
    let useCompactFormatting: Bool

    var body: some View {
        VStack(spacing: 10) {
            CurrencyTotalsView(
                totals: totals,
                useCompactFormatting: useCompactFormatting
            )

            if let rateStatus {
                Divider()
                RateStatusBannerView(status: rateStatus)
            }
        }
    }
}
