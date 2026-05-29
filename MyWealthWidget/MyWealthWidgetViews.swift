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

private let wealthGradient = LinearGradient(
    colors: [
        Color(red: 0.62, green: 0.08, blue: 0.53),
        Color(red: 0.38, green: 0.04, blue: 0.34)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

/// Dot-grid pattern matching the app's RadialDotBackground component.
/// Drawn with Canvas so it works in widget extensions without animation.
/// On a white background, use a lower opacity so the dots are subtle.
private struct WidgetDotBackground: View {
    var dotColor: Color = Color(red: 166/255, green: 23/255, blue: 142/255).opacity(0.18)
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
private let widgetAccent = Color(red: 0.62, green: 0.08, blue: 0.53)

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: MyWealthEntry

    private var snapshot: WidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accent header strip
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption2)
                    .foregroundStyle(widgetAccent)
                Text("NET WORTH")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(widgetAccent)
                    .tracking(0.5)
            }

            Spacer()

            // Primary amount
            Text(snapshot.netWorth.compactCurrencyString(code: snapshot.baseCurrency))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(2)

            // Currency code badge
            Text(snapshot.baseCurrency)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(widgetAccent)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(widgetAccent.opacity(0.1), in: Capsule())
                .padding(.top, 4)

            Spacer()

            // Footer: transfer-rate last updated
            Text(snapshot.transferRatesUpdatedLabel)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
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
                        .font(.caption2)
                        .foregroundStyle(widgetAccent)
                    Text("NET WORTH")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(widgetAccent)
                        .tracking(0.5)
                }

                Spacer()

                Text(snapshot.netWorth.compactCurrencyString(code: snapshot.baseCurrency))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)

                AssetLiabilityMiniBadge(
                    assetTotal: snapshot.assetTotal,
                    liabilityTotal: snapshot.liabilityTotal,
                    currency: snapshot.baseCurrency
                )
                .padding(.top, 4)

                Spacer()

                Text(snapshot.transferRatesUpdatedLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxHeight: .infinity, alignment: .leading)

            // Divider
            Divider()

            // Right: secondary currency totals
            VStack(alignment: .leading, spacing: 0) {
                Text("Also in")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)

                if snapshot.currencyTotals.isEmpty {
                    Spacer()
                    Text("Add display\ncurrencies\nin Settings")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                } else {
                    ForEach(snapshot.currencyTotals.prefix(3)) { currencyEntry in
                        CurrencyTotalRow(entry: currencyEntry)
                        if currencyEntry.id != snapshot.currencyTotals.prefix(3).last?.id {
                            Divider().padding(.vertical, 4)
                        }
                    }
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
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(snapshot.netWorth.abbreviatedString)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
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
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(snapshot.netWorth.compactCurrencyString(code: snapshot.baseCurrency))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(snapshot.transferRatesUpdatedLabel)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

// MARK: - Supporting Sub-views

/// A small row showing a secondary currency total inside the medium widget.
private struct CurrencyTotalRow: View {
    let entry: WidgetSnapshot.CurrencyEntry

    var body: some View {
        HStack {
            Text(entry.code)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .leading)

            Spacer()

            Text(entry.amount.compactCurrencyString(code: entry.code))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
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
                tint: .green.opacity(0.85)
            )
            if liabilityTotal > 0 {
                MiniStatBadge(
                    icon: "arrow.down.circle.fill",
                    value: liabilityTotal.abbreviatedString,
                    tint: .red.opacity(0.75)
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
                .font(.system(size: 8))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
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
                .init(code: "USD", amount: 14_940),
                .init(code: "EUR", amount: 13_750)
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
                .init(code: "USD", amount: 14_940),
                .init(code: "EUR", amount: 13_750),
                .init(code: "GBP", amount: 11_800)
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
