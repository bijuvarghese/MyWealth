import SwiftUI

struct AppListCard<Content: View>: View {
    let content: Content
    let contentPadding: EdgeInsets

    init(
        contentPadding: EdgeInsets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.contentPadding = contentPadding
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

            content
                .padding(contentPadding)
        }
        .frame(maxWidth: .infinity)
    }
}

extension View {
    func appListRow(
        insets: EdgeInsets = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
    ) -> some View {
        listRowBackground(Color.clear)
            .listRowInsets(insets)
    }
}
