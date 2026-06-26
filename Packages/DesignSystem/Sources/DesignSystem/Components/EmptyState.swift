import SwiftUI

public struct EmptyState<Action: View>: View {
    private let title: String
    private let message: String
    private let systemImage: String
    private let action: Action

    public init(
        title: String,
        message: String,
        systemImage: String = "tray",
        @ViewBuilder action: () -> Action
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.action = action()
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.standard) {
            Image(systemName: systemImage)
                .font(DesignTokens.Typography.title2)
                .foregroundStyle(DesignTokens.ColorToken.brandPrimary)

            VStack(spacing: DesignTokens.Spacing.inlineS) {
                Text(title)
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.ColorToken.textPrimary)

                Text(message)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
            }

            action
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.spacious)
    }
}

public extension EmptyState where Action == EmptyView {
    init(title: String, message: String, systemImage: String = "tray") {
        self.init(title: title, message: message, systemImage: systemImage) {
            EmptyView()
        }
    }
}
