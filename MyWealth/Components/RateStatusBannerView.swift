import SwiftUI

struct RateStatusBannerView: View {
    let status: RateStatusModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(iconColor)

            Text(status.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var iconColor: Color {
        switch status.style {
        case .loading:
            .accentColor
        case .neutral:
            .secondary
        case .warning:
            .orange
        }
    }
}
