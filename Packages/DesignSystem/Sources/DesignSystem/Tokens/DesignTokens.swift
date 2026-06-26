import SwiftUI

public enum DesignTokens {
    public enum ColorToken {
        public static let brandPrimary = Color(red: 0.62, green: 0.08, blue: 0.53)
        public static let brandPrimaryStrong = Color(red: 0.38, green: 0.04, blue: 0.34)
        public static let brandDot = Color(red: 166 / 255, green: 23 / 255, blue: 142 / 255)
        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary
        public static let textTertiary = Color(.tertiaryLabel)
        public static let surfaceSecondaryFill = Color(.secondarySystemFill)
        public static let surfaceGrouped = Color(.systemGray6)
        public static let surfaceClear = Color.clear
        public static let success = Color.green
        public static let warning = Color.orange
        public static let danger = Color.red
        public static let neutral = Color.secondary
        public static let inactive = Color.gray
        public static let info = Color.blue
        public static let attention = Color.yellow
        public static let scrim = Color.black.opacity(0.18)
    }

    public enum Typography {
        public static let displayTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        public static let amountProminent = Font.system(.title3, design: .rounded, weight: .bold)
        public static let title = Font.title3.bold()
        public static let title2 = Font.title2
        public static let title3 = Font.title3
        public static let headline = Font.headline
        public static let headlineBold = Font.headline.weight(.bold)
        public static let headlineMonospacedDigit = Font.headline.monospacedDigit()
        public static let body = Font.body
        public static let bodySemibold = Font.body.weight(.semibold)
        public static let subheadline = Font.subheadline
        public static let subheadlineMedium = Font.subheadline.weight(.medium)
        public static let subheadlineSemibold = Font.subheadline.weight(.semibold)
        public static let subheadlineMonospacedDigit = Font.subheadline.monospacedDigit()
        public static let footnote = Font.footnote
        public static let compactLabel = Font.caption.weight(.semibold)
        public static let caption = Font.caption
        public static let captionMonospacedDigit = Font.caption.monospacedDigit()
        public static let caption2 = Font.caption2

        public static let widgetAmount = Font.title2
        public static let widgetSecondaryAmount = Font.title3
        public static let lockScreenAmount = Font.system(size: 14, weight: .bold, design: .rounded)
        public static let compactTimestamp = Font.system(size: 9)
        public static let compactValue = Font.system(size: 9, weight: .medium)
        public static let compactIcon = Font.system(size: 8)
        public static let rectangularAmount = Font.system(.title3, design: .rounded, weight: .bold)
    }

    public enum Spacing {
        public static let compact: CGFloat = 8
        public static let standard: CGFloat = 12
        public static let section: CGFloat = 16
        public static let spacious: CGFloat = 20
        public static let cardPadding: CGFloat = 12
        public static let inlineXS: CGFloat = 4
        public static let inlineS: CGFloat = 6
        public static let pillHorizontalPadding: CGFloat = 12
        public static let pillVerticalPadding: CGFloat = 7
    }

    public enum Shape {
        public static let cardRadius: CGFloat = 12
        public static let controlRadius: CGFloat = 10
        public static let compactRadius: CGFloat = 8
    }

    public enum Elevation {
        public static let cardShadowColor = Color.black.opacity(0.06)
        public static let cardShadowRadius: CGFloat = 6
        public static let cardShadowX: CGFloat = 0
        public static let cardShadowY: CGFloat = 3
    }

    public enum Icon {
        public static let statusSize: CGFloat = 12
    }

    public static let brandPrimary = ColorToken.brandPrimary
    public static let brandPrimaryStrong = ColorToken.brandPrimaryStrong
    public static let brandDot = ColorToken.brandDot
    public static let textPrimary = ColorToken.textPrimary
    public static let textSecondary = ColorToken.textSecondary
    public static let textTertiary = ColorToken.textTertiary
    public static let surfaceClear = ColorToken.surfaceClear
    public static let success = ColorToken.success
    public static let danger = ColorToken.danger
    public static let badgeOpacity = 0.1
    public static let badgeHorizontalPadding: CGFloat = 6
    public static let badgeVerticalPadding: CGFloat = 2
    public static let compactTopPadding: CGFloat = 4
}
