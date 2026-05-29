import SwiftUI

struct DashboardHistoryLinkRow: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("View Full History")
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}
