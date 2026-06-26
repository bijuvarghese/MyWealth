import SwiftUI

public struct Card<Content: View>: View {
    private let content: Content
    private let contentPadding: EdgeInsets

    public init(
        contentPadding: EdgeInsets = EdgeInsets(
            top: DesignTokens.Spacing.cardPadding,
            leading: DesignTokens.Spacing.cardPadding,
            bottom: DesignTokens.Spacing.cardPadding,
            trailing: DesignTokens.Spacing.cardPadding
        ),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.contentPadding = contentPadding
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.Shape.cardRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: DesignTokens.Elevation.cardShadowColor,
                    radius: DesignTokens.Elevation.cardShadowRadius,
                    x: DesignTokens.Elevation.cardShadowX,
                    y: DesignTokens.Elevation.cardShadowY
                )

            content
                .padding(contentPadding)
        }
        .frame(maxWidth: .infinity)
    }
}
