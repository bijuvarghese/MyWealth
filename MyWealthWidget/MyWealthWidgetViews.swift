//
//  MyWealthWidgetViews.swift
//  MyWealthWidget  (widget extension target)
//
//  All widget view definitions plus the top-level Widget configuration.
//  Supports four widget families:
//
//    • systemSmall          — Net worth + base currency, full-bleed accent background
//    • systemMedium         — Net worth (left) + secondary currency breakdown (right)
//    • accessoryCircular    — Lock screen: abbreviated net worth ring
//    • accessoryRectangular — Lock screen: "NET WORTH" label + amount
//

import WidgetKit
import SwiftUI

// MARK: - Shared background

private enum WidgetDesignTokens {
    static let brandPrimary = Color(red: 0.62, green: 0.08, blue: 0.53)
    static let brandPrimaryStrong = Color(red: 0.38, green: 0.04, blue: 0.34)
    static let brandDot = Color(red: 166/255, green: 23/255, blue: 142/255)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(.tertiaryLabel)
    static let surfaceClear = Color.clear
    static let success = Color.green
    static let danger = Color.red
    static let badgeOpacity = 0.1
    static let badgeHorizontalPadding: CGFloat = 6
    static let badgeVerticalPadding: CGFloat = 2
    static let compactTopPadding: CGFloat = 4

    enum Typography {
        static let caption = Font.caption
        static let caption2 = Font.caption2
        static let headline = Font.headline
        static let widgetAmount = Font.title2
        static let widgetSecondaryAmount = Font.title3
        static let lockScreenAmount = Font.system(size: 14, weight: .bold, design: .rounded)
        static let compactTimestamp = Font.system(size: 9)
        static let compactValue = Font.system(size: 9, weight: .medium)
        static let compactIcon = Font.system(size: 8)
        static let compactLabel = Font.system(size: 9, weight: .semibold)
        static let rectangularAmount = Font.system(.title3, design: .rounded, weight: .bold)
    }
}

private let wealthGradient = LinearGradient(
    colors: [
        WidgetDesignTokens.brandPrimary,
        WidgetDesignTokens.brandPrimaryStrong
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

/// Dot-grid pattern matching the app's RadialDotBackground component.
/// Drawn with Canvas so it works in widget extensions without animation.
/// On a white background, use a lower opacity so the dots are subtle.
private struct WidgetDotBackground: View {
    var dotColor: Color = WidgetDesignTokens.brandDot.opacity(0.18)
    var dotRadius: CGFloat = 1
    var spacing: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Canvas { context, _ in
                let circle = Path(ellipseIn: CGRect(x: 0, y: 0, width: dotRadius * 2, height: dotRadius * 2))
                for y in stride(from: 0.0, through: size.height, by: spacing) {
                    for x in stride(from: 0.0, through: size.width, by: spacing) {
                        var t = context
                        t.translateBy(x: x, y: y)
                        t.fill(circle, with: .color(dotColor))
                    }
                }
            }
        }
    }
}

/// Full-bleed widget background: white + subtle dot overlay.
private struct WealthWidgetBackground: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
            WidgetDotBackground()
        }
    }
}

// MARK: - Widget Configuration

struct MyWealthWidget: Widget {
    let kind: String = "MyWealthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MyWealthWidgetProvider()) { entry in
            MyWealthWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Net Worth")
        .description("See your total net worth at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Root Entry View (dispatches by family)

struct MyWealthWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MyWealthEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Accent color (matches app AccentColor asset)
private let widgetAccent = WidgetDesignTokens.brandPrimary

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: MyWealthEntry

    private var snapshot: WidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accent header strip
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(WidgetDesignTokens.Typography.caption2)
                    .foregroundStyle(widgetAccent)
                Text("NET WORTH")
                    .font(WidgetDesignTokens.Typography.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(widgetAccent)
                    .tracking(0.5)
            }

            Spacer()

            // Primary amount
            Text(snapshot.netWorth.compactCurrencyString(code: snapshot.baseCurrency))
                .font(WidgetDesignTokens.Typography.widgetAmount)
                .fontWeight(.bold)
                .foregroundStyle(WidgetDesignTokens.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(2)

            // Currency code badge
            Text(snapshot.baseCurrency)
                .font(WidgetDesignTokens.Typography.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(widgetAccent)
                .padding(.horizontal, WidgetDesignTokens.badgeHorizontalPadding)
                .padding(.vertical, WidgetDesignTokens.badgeVerticalPadding)
                .background(widgetAccent.opacity(WidgetDesignTokens.badgeOpacity), in: Capsule())
                .padding(.top, WidgetDesignTokens.compactTopPadding)

            Spacer()

            // Footer: transfer-rate last updated
            Text(snapshot.transferRatesUpdatedLabel)
                .font(WidgetDesignTokens.Typography.compactTimestamp)
                .foregroundStyle(WidgetDesignTokens.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { WealthWidgetBackground() }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: MyWealthEntry

    private var snapshot: WidgetSnapshot { entry.snapshot }

    var body: some View {
        HStack(spacing: 16) {
            // Left: primary net worth
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(WidgetDesignTokens.Typography.caption2)
                        .foregroundStyle(widgetAccent)
                    Text("NET WORTH")
                        .font(WidgetDesignTokens.Typography.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(widgetAccent)
                        .tracking(0.5)
                }

                Spacer()

                Text(snapshot.netWorth.compactCurrencyString(code: snapshot.baseCurrency))
                    .font(WidgetDesignTokens.Typography.widgetSecondaryAmount)
                    .fontWeight(.bold)
                    .foregroundStyle(WidgetDesignTokens.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)

                AssetLiabilityMiniBadge(
                    assetTotal: snapshot.assetTotal,
                    liabilityTotal: snapshot.liabilityTotal,
                    currency: snapshot.baseCurrency
                )
                .padding(.top, WidgetDesignTokens.compactTopPadding)

                Spacer()

                Text(snapshot.transferRatesUpdatedLabel)
                    .font(WidgetDesignTokens.Typography.compactTimestamp)
                    .foregroundStyle(WidgetDesignTokens.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxHeight: .infinity, alignment: .leading)

            // Divider
            Divider()

            // Right: first interested currency total and transfer rate
            VStack(alignment: .leading, spacing: 0) {
                if let preferredCurrency = snapshot.currencyTotals.first {
                    PreferredCurrencySummary(
                        entry: preferredCurrency,
                        baseCurrency: snapshot.baseCurrency
                    )
                } else {
                    Spacer()
                    Text("Add display\ncurrencies\nin Settings")
                        .font(WidgetDesignTokens.Typography.caption2)
                        .foregroundStyle(WidgetDesignTokens.textTertiary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            .frame(maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { WealthWidgetBackground() }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

// MARK: - Lock Screen: Circular

/// A compact circular lock-screen widget showing an abbreviated net worth.
struct CircularLockScreenView: View {
    let entry: MyWealthEntry

    private var snapshot: WidgetSnapshot { entry.snapshot }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 1) {
                Text(snapshot.baseCurrency)
                    .font(WidgetDesignTokens.Typography.compactLabel)
                    .foregroundStyle(WidgetDesignTokens.textSecondary)

                Text(snapshot.netWorth.abbreviatedString)
                    .font(WidgetDesignTokens.Typography.lockScreenAmount)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        }
        .containerBackground(for: .widget) { WidgetDesignTokens.surfaceClear }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

// MARK: - Lock Screen: Rectangular

/// A wider lock-screen widget showing a labelled net worth figure.
struct RectangularLockScreenView: View {
    let entry: MyWealthEntry

    private var snapshot: WidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Net Worth", systemImage: "chart.line.uptrend.xyaxis")
                .font(WidgetDesignTokens.Typography.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(WidgetDesignTokens.textSecondary)

            Text(snapshot.netWorth.compactCurrencyString(code: snapshot.baseCurrency))
                .font(WidgetDesignTokens.Typography.rectangularAmount)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(snapshot.transferRatesUpdatedLabel)
                .font(WidgetDesignTokens.Typography.compactTimestamp)
                .foregroundStyle(WidgetDesignTokens.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { WidgetDesignTokens.surfaceClear }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

// MARK: - Supporting Sub-views

/// Medium-widget summary for the first display currency selected by the user.
private struct PreferredCurrencySummary: View {
    let entry: WidgetSnapshot.CurrencyEntry
    let baseCurrency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Also in")
                .font(WidgetDesignTokens.Typography.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(WidgetDesignTokens.textSecondary)

            Text(entry.amount.compactCurrencyString(code: entry.code))
                .font(WidgetDesignTokens.Typography.headline)
                .fontWeight(.bold)
                .foregroundStyle(WidgetDesignTokens.textPrimary)
                .minimumScaleFactor(0.55)
                .lineLimit(1)

            Divider()

            VStack(alignment: .leading, spacing: 3) {
                Text("Transfer rate")
                    .font(WidgetDesignTokens.Typography.caption2)
                    .foregroundStyle(WidgetDesignTokens.textSecondary)

                if let transferRate = entry.transferRate {
                    Text("1 \(baseCurrency) = \(transferRate, format: .number.precision(.significantDigits(4...6))) \(entry.code)")
                        .font(WidgetDesignTokens.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(WidgetDesignTokens.textPrimary)
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                } else {
                    Text("Unavailable")
                        .font(WidgetDesignTokens.Typography.caption)
                        .foregroundStyle(WidgetDesignTokens.textTertiary)
                }
            }

            Spacer()

            Text(entry.code)
                .font(WidgetDesignTokens.Typography.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(widgetAccent)
                .padding(.horizontal, WidgetDesignTokens.badgeHorizontalPadding)
                .padding(.vertical, WidgetDesignTokens.badgeVerticalPadding)
                .background(widgetAccent.opacity(WidgetDesignTokens.badgeOpacity), in: Capsule())
                .lineLimit(1)
        }
    }
}

/// Small asset/liability mini-badges for the medium widget left column.
private struct AssetLiabilityMiniBadge: View {
    let assetTotal: Double
    let liabilityTotal: Double
    let currency: String

    var body: some View {
        HStack(spacing: 6) {
            MiniStatBadge(
                icon: "arrow.up.circle.fill",
                value: assetTotal.abbreviatedString,
                tint: WidgetDesignTokens.success.opacity(0.85)
            )
            if liabilityTotal > 0 {
                MiniStatBadge(
                    icon: "arrow.down.circle.fill",
                    value: liabilityTotal.abbreviatedString,
                    tint: WidgetDesignTokens.danger.opacity(0.75)
                )
            }
        }
    }
}

private struct MiniStatBadge: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(WidgetDesignTokens.Typography.compactIcon)
                .foregroundStyle(tint)
            Text(value)
                .font(WidgetDesignTokens.Typography.compactValue)
                .foregroundStyle(WidgetDesignTokens.textSecondary)
        }
    }
}

// MARK: - Formatting Helpers

extension Double {
    /// Formats the value as an abbreviated compact string (e.g. "1.2M", "45.3K").
    var abbreviatedString: String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""

        switch absValue {
        case 1_000_000_000...:
            return "\(sign)\((absValue / 1_000_000_000).formatted(.number.precision(.fractionLength(1))))B"
        case 1_000_000...:
            return "\(sign)\((absValue / 1_000_000).formatted(.number.precision(.fractionLength(1))))M"
        case 1_000...:
            return "\(sign)\((absValue / 1_000).formatted(.number.precision(.fractionLength(1))))K"
        default:
            return "\(sign)\(absValue.formatted(.number.precision(.fractionLength(0))))"
        }
    }

    /// Formats the value as a compact currency string using the given ISO code.
    /// For large numbers the amount is abbreviated and the currency code is appended.
    func compactCurrencyString(code: String) -> String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        let suffix: String

        switch absValue {
        case 1_000_000_000...:
            suffix = "\((absValue / 1_000_000_000).formatted(.number.precision(.fractionLength(2))))B"
        case 1_000_000...:
            suffix = "\((absValue / 1_000_000).formatted(.number.precision(.fractionLength(2))))M"
        case 1_000...:
            suffix = "\((absValue / 1_000).formatted(.number.precision(.fractionLength(1))))K"
        default:
            suffix = absValue.formatted(.number.precision(.fractionLength(0)))
        }

        let symbol = Locale.current.currencySymbol(for: code) ?? code
        return "\(sign)\(symbol)\(suffix)"
    }
}

extension Locale {
    /// Returns the currency symbol for the given ISO 4217 code, or `nil` if unknown.
    func currencySymbol(for isoCode: String) -> String? {
        let locale = Locale.availableIdentifiers
            .lazy
            .map { Locale(identifier: $0) }
            .first { $0.currency?.identifier == isoCode }
        return locale?.currencySymbol
    }
}

extension Date {
    var rateUpdatedLabel: String {
        "Rates: \(formatted(date: .abbreviated, time: .shortened))"
    }
}

extension WidgetSnapshot {
    var transferRatesUpdatedLabel: String {
        (transferRatesLastUpdated ?? lastUpdated).rateUpdatedLabel
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    MyWealthWidget()
} timeline: {
    MyWealthEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            netWorth: 1_250_000,
            assetTotal: 1_500_000,
            liabilityTotal: 250_000,
            baseCurrency: "INR",
            currencyTotals: [
                .init(code: "USD", amount: 14_940, transferRate: 0.012),
                .init(code: "EUR", amount: 13_750, transferRate: 0.011)
            ],
            lastUpdated: .now,
            transferRatesLastUpdated: .now
        ),
        isPlaceholder: false
    )
}

#Preview("Medium", as: .systemMedium) {
    MyWealthWidget()
} timeline: {
    MyWealthEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            netWorth: 1_250_000,
            assetTotal: 1_500_000,
            liabilityTotal: 250_000,
            baseCurrency: "INR",
            currencyTotals: [
                .init(code: "USD", amount: 14_940, transferRate: 0.012),
                .init(code: "EUR", amount: 13_750, transferRate: 0.011),
                .init(code: "GBP", amount: 11_800, transferRate: 0.0094)
            ],
            lastUpdated: .now,
            transferRatesLastUpdated: .now
        ),
        isPlaceholder: false
    )
}

#Preview("Lock Screen Circular", as: .accessoryCircular) {
    MyWealthWidget()
} timeline: {
    MyWealthEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            netWorth: 1_250_000,
            assetTotal: 1_500_000,
            liabilityTotal: 250_000,
            baseCurrency: "INR",
            currencyTotals: [],
            lastUpdated: .now,
            transferRatesLastUpdated: .now
        ),
        isPlaceholder: false
    )
}

#Preview("Lock Screen Rectangular", as: .accessoryRectangular) {
    MyWealthWidget()
} timeline: {
    MyWealthEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            netWorth: 1_250_000,
            assetTotal: 1_500_000,
            liabilityTotal: 250_000,
            baseCurrency: "INR",
            currencyTotals: [],
            lastUpdated: .now,
            transferRatesLastUpdated: .now
        ),
        isPlaceholder: false
    )
}
