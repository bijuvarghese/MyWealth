import SwiftUI

public extension View {
    func cardBackground() -> some View {
        background {
            RoundedRectangle(cornerRadius: DesignTokens.Shape.cardRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: DesignTokens.Elevation.cardShadowColor,
                    radius: DesignTokens.Elevation.cardShadowRadius,
                    x: DesignTokens.Elevation.cardShadowX,
                    y: DesignTokens.Elevation.cardShadowY
                )
        }
    }
}
