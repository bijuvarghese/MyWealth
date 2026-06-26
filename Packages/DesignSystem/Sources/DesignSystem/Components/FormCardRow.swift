import SwiftUI

public struct FormCardRow<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(DesignTokens.Spacing.standard)
            .cardBackground()
            .listRowBackground(DesignTokens.ColorToken.surfaceClear)
    }
}
