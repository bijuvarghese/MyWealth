import SwiftUI

enum WealthMapDesignTokens {
    enum ColorToken {
        static let brandPrimary = Color(red: 0.62, green: 0.08, blue: 0.53)
        static let brandPrimaryStrong = Color(red: 0.38, green: 0.04, blue: 0.34)
        static let brandDot = Color(red: 166/255, green: 23/255, blue: 142/255)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(.tertiaryLabel)
        static let surfaceSecondaryFill = Color(.secondarySystemFill)
        static let surfaceGrouped = Color(.systemGray6)
        static let surfaceClear = Color.clear
        static let success = Color.green
        static let warning = Color.orange
        static let danger = Color.red
        static let neutral = Color.secondary
        static let inactive = Color.gray
        static let info = Color.blue
        static let attention = Color.yellow
        static let scrim = Color.black.opacity(0.18)
    }

    enum Typography {
        static let displayTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let amountProminent = Font.system(.title3, design: .rounded, weight: .bold)
        static let title = Font.title3.bold()
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let headlineBold = Font.headline.weight(.bold)
        static let headlineMonospacedDigit = Font.headline.monospacedDigit()
        static let body = Font.body
        static let bodySemibold = Font.body.weight(.semibold)
        static let subheadline = Font.subheadline
        static let subheadlineMedium = Font.subheadline.weight(.medium)
        static let subheadlineSemibold = Font.subheadline.weight(.semibold)
        static let subheadlineMonospacedDigit = Font.subheadline.monospacedDigit()
        static let footnote = Font.footnote
        static let compactLabel = Font.caption.weight(.semibold)
        static let caption = Font.caption
        static let captionMonospacedDigit = Font.caption.monospacedDigit()
        static let caption2 = Font.caption2
    }

    enum Spacing {
        static let compact: CGFloat = 8
        static let standard: CGFloat = 12
        static let section: CGFloat = 16
        static let spacious: CGFloat = 20
        static let cardPadding: CGFloat = 12
        static let inlineXS: CGFloat = 4
        static let inlineS: CGFloat = 6
        static let pillHorizontalPadding: CGFloat = 12
        static let pillVerticalPadding: CGFloat = 7
    }

    enum Shape {
        static let cardRadius: CGFloat = 12
        static let controlRadius: CGFloat = 10
        static let compactRadius: CGFloat = 8
    }

    enum Elevation {
        static let cardShadowColor = Color.black.opacity(0.06)
        static let cardShadowRadius: CGFloat = 6
        static let cardShadowX: CGFloat = 0
        static let cardShadowY: CGFloat = 3
    }

    enum Icon {
        static let statusSize: CGFloat = 12
    }
}

extension View {
    func wealthMapCardBackground() -> some View {
        background {
            RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: WealthMapDesignTokens.Elevation.cardShadowColor,
                    radius: WealthMapDesignTokens.Elevation.cardShadowRadius,
                    x: WealthMapDesignTokens.Elevation.cardShadowX,
                    y: WealthMapDesignTokens.Elevation.cardShadowY
                )
        }
    }
}
