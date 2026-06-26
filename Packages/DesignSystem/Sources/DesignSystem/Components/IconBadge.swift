import SwiftUI

public struct IconBadge: View {
    private let systemImage: String
    private let tint: Color

    public init(
        systemImage: String,
        tint: Color = DesignTokens.ColorToken.brandPrimary
    ) {
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        Image(systemName: systemImage)
            .font(DesignTokens.Typography.bodySemibold)
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: DesignTokens.Shape.compactRadius, style: .continuous))
    }
}
