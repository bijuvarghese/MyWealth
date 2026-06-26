import DesignSystem
import SwiftUI

enum WealthMapDesignTokens {
    enum ColorToken {
        static let brandPrimary = DesignTokens.ColorToken.brandPrimary
        static let brandPrimaryStrong = DesignTokens.ColorToken.brandPrimaryStrong
        static let brandDot = DesignTokens.ColorToken.brandDot
        static let textPrimary = DesignTokens.ColorToken.textPrimary
        static let textSecondary = DesignTokens.ColorToken.textSecondary
        static let textTertiary = DesignTokens.ColorToken.textTertiary
        static let surfaceSecondaryFill = DesignTokens.ColorToken.surfaceSecondaryFill
        static let surfaceGrouped = DesignTokens.ColorToken.surfaceGrouped
        static let surfaceClear = DesignTokens.ColorToken.surfaceClear
        static let success = DesignTokens.ColorToken.success
        static let warning = DesignTokens.ColorToken.warning
        static let danger = DesignTokens.ColorToken.danger
        static let neutral = DesignTokens.ColorToken.neutral
        static let inactive = DesignTokens.ColorToken.inactive
        static let info = DesignTokens.ColorToken.info
        static let attention = DesignTokens.ColorToken.attention
        static let scrim = DesignTokens.ColorToken.scrim
    }

    enum Typography {
        static let displayTitle = DesignTokens.Typography.displayTitle
        static let amountProminent = DesignTokens.Typography.amountProminent
        static let title = DesignTokens.Typography.title
        static let title2 = DesignTokens.Typography.title2
        static let title3 = DesignTokens.Typography.title3
        static let headline = DesignTokens.Typography.headline
        static let headlineBold = DesignTokens.Typography.headlineBold
        static let headlineMonospacedDigit = DesignTokens.Typography.headlineMonospacedDigit
        static let body = DesignTokens.Typography.body
        static let bodySemibold = DesignTokens.Typography.bodySemibold
        static let subheadline = DesignTokens.Typography.subheadline
        static let subheadlineMedium = DesignTokens.Typography.subheadlineMedium
        static let subheadlineSemibold = DesignTokens.Typography.subheadlineSemibold
        static let subheadlineMonospacedDigit = DesignTokens.Typography.subheadlineMonospacedDigit
        static let footnote = DesignTokens.Typography.footnote
        static let compactLabel = DesignTokens.Typography.compactLabel
        static let caption = DesignTokens.Typography.caption
        static let captionMonospacedDigit = DesignTokens.Typography.captionMonospacedDigit
        static let caption2 = DesignTokens.Typography.caption2
    }

    enum Spacing {
        static let compact = DesignTokens.Spacing.compact
        static let standard = DesignTokens.Spacing.standard
        static let section = DesignTokens.Spacing.section
        static let spacious = DesignTokens.Spacing.spacious
        static let cardPadding = DesignTokens.Spacing.cardPadding
        static let inlineXS = DesignTokens.Spacing.inlineXS
        static let inlineS = DesignTokens.Spacing.inlineS
        static let pillHorizontalPadding = DesignTokens.Spacing.pillHorizontalPadding
        static let pillVerticalPadding = DesignTokens.Spacing.pillVerticalPadding
    }

    enum Shape {
        static let cardRadius = DesignTokens.Shape.cardRadius
        static let controlRadius = DesignTokens.Shape.controlRadius
        static let compactRadius = DesignTokens.Shape.compactRadius
    }

    enum Elevation {
        static let cardShadowColor = DesignTokens.Elevation.cardShadowColor
        static let cardShadowRadius = DesignTokens.Elevation.cardShadowRadius
        static let cardShadowX = DesignTokens.Elevation.cardShadowX
        static let cardShadowY = DesignTokens.Elevation.cardShadowY
    }

    enum Icon {
        static let statusSize = DesignTokens.Icon.statusSize
    }
}

extension View {
    func wealthMapCardBackground() -> some View {
        cardBackground()
    }
}
