import SwiftUI

public struct AmountText: View {
    private let amount: String
    private let isNegative: Bool
    private let font: Font

    public init(
        _ amount: String,
        isNegative: Bool = false,
        font: Font = DesignTokens.Typography.amountProminent
    ) {
        self.amount = amount
        self.isNegative = isNegative
        self.font = font
    }

    public var body: some View {
        Text(amount)
            .font(font)
            .foregroundStyle(isNegative ? DesignTokens.ColorToken.danger : DesignTokens.ColorToken.textPrimary)
            .monospacedDigit()
    }
}
