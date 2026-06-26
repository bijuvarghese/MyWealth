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
            RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: WealthMapDesignTokens.Elevation.cardShadowColor,
                    radius: WealthMapDesignTokens.Elevation.cardShadowRadius,
                    x: WealthMapDesignTokens.Elevation.cardShadowX,
                    y: WealthMapDesignTokens.Elevation.cardShadowY
                )

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
        listRowBackground(WealthMapDesignTokens.ColorToken.surfaceClear)
            .listRowInsets(insets)
    }
}
