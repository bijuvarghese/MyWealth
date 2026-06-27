import SwiftUI
import UIKit

struct DashboardNetWorthTotalsView: View {
    let totals: [CurrencyTotal]
    let rateStatus: RateStatusModel?
    let useCompactFormatting: Bool
    var collapsedRowLimit: Int? = nil

    @State private var showsAllTotals = false

    private var visibleTotals: [CurrencyTotal] {
        guard let collapsedRowLimit, !showsAllTotals else {
            return totals
        }

        return Array(totals.prefix(collapsedRowLimit))
    }

    private var hiddenTotalCount: Int {
        guard let collapsedRowLimit else { return 0 }
        return max(totals.count - collapsedRowLimit, 0)
    }

    var body: some View {
        VStack(spacing: 10) {
            CurrencyTotalsView(
                totals: visibleTotals,
                useCompactFormatting: useCompactFormatting
            )

            if hiddenTotalCount > 0 {
                Divider()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showsAllTotals.toggle()
                    }
                } label: {
                    HStack {
                        Text(showsAllTotals ? "Show less" : "View more")
                            .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                        Spacer()
                        Text(showsAllTotals ? "\(totals.count) shown" : "+\(hiddenTotalCount)")
                            .font(WealthMapDesignTokens.Typography.compactLabel)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        Image(systemName: showsAllTotals ? "chevron.up" : "chevron.down")
                            .font(WealthMapDesignTokens.Typography.compactLabel)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    }
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            if let rateStatus {
                Divider()
                RateStatusBannerView(status: rateStatus)
            }
        }
    }
}

struct NetWorthLivingComfortView: View {
    let totals: [CurrencyTotal]
    let baseCurrency: Asset.CurrencyType
    let exchangeRates: [String: Double]
    @Binding var assumptions: LivingComfortAssumptions
    var collapsedRowLimit: Int? = nil

    @State private var showsAllRows = false

    private let comfortCalculator = LivingComfortCalculator()

    private var visibleTotals: [CurrencyTotal] {
        guard let collapsedRowLimit, !showsAllRows else {
            return totals
        }

        return Array(totals.prefix(collapsedRowLimit))
    }

    private var hiddenRowCount: Int {
        guard let collapsedRowLimit else { return 0 }
        return max(totals.count - collapsedRowLimit, 0)
    }

    var body: some View {
        VStack(spacing: 12) {
            comfortAssumptionsView
            Divider()
            livingComfortRows

            if hiddenRowCount > 0 {
                Divider()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showsAllRows.toggle()
                    }
                } label: {
                    HStack {
                        Text(showsAllRows ? "Show less" : "View more")
                            .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                        Spacer()
                        Text(showsAllRows ? "\(totals.count) shown" : "+\(hiddenRowCount)")
                            .font(WealthMapDesignTokens.Typography.compactLabel)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        Image(systemName: showsAllRows ? "chevron.up" : "chevron.down")
                            .font(WealthMapDesignTokens.Typography.compactLabel)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    }
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var comfortAssumptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Country Comfort", systemImage: "house.and.flag.fill")
                    .font(WealthMapDesignTokens.Typography.headline)
                Spacer()
                Text("Estimates")
                    .font(WealthMapDesignTokens.Typography.compactLabel)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
            }

            Stepper(value: Binding(
                get: { assumptions.householdMembers },
                set: { assumptions.householdMembers = $0 }
            ), in: 1...12) {
                HStack {
                    Text("Household")
                    Spacer()
                    Text("\(assumptions.safeHouseholdMembers)")
                        .font(WealthMapDesignTokens.Typography.headlineMonospacedDigit)
                }
            }

            HStack(spacing: 10) {
                comfortNumberField(
                    title: "Monthly Income (\(baseCurrency.rawValue))",
                    value: Binding(
                        get: { assumptions.monthlyIncome },
                        set: { assumptions.monthlyIncome = max($0, 0) }
                    ),
                    wasProvided: Binding(
                        get: { assumptions.monthlyIncomeWasProvided },
                        set: { assumptions.monthlyIncomeWasProvided = $0 }
                    )
                )

                comfortNumberField(
                    title: "Expected Spend (\(baseCurrency.rawValue))",
                    value: Binding(
                        get: { assumptions.expectedMonthlySpend },
                        set: { assumptions.expectedMonthlySpend = max($0, 0) }
                    ),
                    wasProvided: Binding(
                        get: { assumptions.expectedMonthlySpendWasProvided },
                        set: { assumptions.expectedMonthlySpendWasProvided = $0 }
                    )
                )
            }

            Text("Income and spend are entered in \(baseCurrency.rawValue), then converted for each country. Clear spend to use the currency-country baseline.")
                .font(WealthMapDesignTokens.Typography.caption)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func comfortNumberField(
        title: String,
        value: Binding<Double>,
        wasProvided: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(WealthMapDesignTokens.Typography.compactLabel)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            KeyboardDoneTextField(
                placeholder: "Estimate",
                text: numericText(value: value, wasProvided: wasProvided)
            )
                .frame(height: 24)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(WealthMapDesignTokens.ColorToken.surfaceSecondaryFill, in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.controlRadius, style: .continuous))
        }
    }

    private func numericText(value: Binding<Double>, wasProvided: Binding<Bool>) -> Binding<String> {
        Binding {
            guard wasProvided.wrappedValue else { return "" }
            return value.wrappedValue.formatted(.number.precision(.fractionLength(0)).grouping(.never))
        } set: { text in
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else {
                wasProvided.wrappedValue = false
                value.wrappedValue = 0
                return
            }

            wasProvided.wrappedValue = true
            let normalizedText = trimmedText.replacingOccurrences(of: ",", with: "")
            value.wrappedValue = max(Double(normalizedText) ?? 0, 0)
        }
    }

    private var livingComfortRows: some View {
        VStack(spacing: 10) {
            ForEach(comfortCalculator.rows(
                totals: visibleTotals,
                baseCurrency: baseCurrency,
                exchangeRates: exchangeRates,
                assumptions: assumptions
            )) { row in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.countryName)
                                .font(WealthMapDesignTokens.Typography.headline)
                            Text(row.pppConversionFactor.map {
                                "\(row.currency.rawValue) PPP \($0.formatted(.number.precision(.fractionLength(2)))) / intl $"
                            } ?? "\(row.currency.rawValue) living estimate")
                                .font(WealthMapDesignTokens.Typography.caption)
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        }

                        Spacer()

                        Text(row.level.localizedName)
                            .font(WealthMapDesignTokens.Typography.compactLabel)
                            .foregroundStyle(comfortColor(row.level))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(comfortColor(row.level).opacity(0.12), in: Capsule())
                    }

                    HStack(alignment: .top) {
                        comfortMetric(
                            title: "Runway",
                            value: row.runwayMonths.isInfinite
                                ? "Unlimited"
                                : row.runwayMonths >= 120
                                ? "\(Int((row.runwayMonths / 12).rounded())) yrs"
                                : "\(Int(row.runwayMonths.rounded())) mo"
                        )
                        Spacer()
                        comfortMetric(
                            title: "Monthly Need",
                            value: row.monthlySpendEstimate.formatted(.currency(code: row.currency.rawValue).precision(.fractionLength(0)))
                        )
                        Spacer()
                        comfortMetric(
                            title: "Cashflow",
                            value: row.monthlySurplus.map {
                                $0.formatted(.currency(code: row.currency.rawValue).precision(.fractionLength(0)))
                            } ?? "Set income",
                            alignment: .trailing,
                            color: (row.monthlySurplus ?? 0) >= 0 ? WealthMapDesignTokens.ColorToken.success : WealthMapDesignTokens.ColorToken.danger
                        )
                    }

                    ProgressView(value: row.runwayMonths.isInfinite ? 1 : min(row.runwayMonths / 120, 1))
                        .tint(comfortColor(row.level))
                }
                .padding(WealthMapDesignTokens.Spacing.standard)
                .background(WealthMapDesignTokens.ColorToken.surfaceSecondaryFill, in: RoundedRectangle(cornerRadius: WealthMapDesignTokens.Shape.cardRadius, style: .continuous))
            }
        }
    }

    private func comfortMetric(
        title: String,
        value: String,
        alignment: HorizontalAlignment = .leading,
        color: Color = WealthMapDesignTokens.ColorToken.textPrimary
    ) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(WealthMapDesignTokens.Typography.caption2.weight(.semibold))
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                .textCase(.uppercase)
            Text(value)
                .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func comfortColor(_ level: LivingComfortLevel) -> Color {
        switch level {
        case .tight: return WealthMapDesignTokens.ColorToken.danger
        case .stable: return WealthMapDesignTokens.ColorToken.warning
        case .comfortable: return WealthMapDesignTokens.ColorToken.success
        case .independent: return WealthMapDesignTokens.ColorToken.info
        }
    }
}

private struct KeyboardDoneTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.placeholder = placeholder
        textField.keyboardType = .decimalPad
        textField.text = text
        textField.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize,
            weight: .semibold
        )
        textField.adjustsFontForContentSizeCategory = true
        textField.inputAccessoryView = context.coordinator.makeToolbar()
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        context.coordinator.textField = textField
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.text = $text
        context.coordinator.textField = textField
        textField.placeholder = placeholder
        if textField.text != text {
            textField.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject {
        var text: Binding<String>
        weak var textField: UITextField?

        init(text: Binding<String>) {
            self.text = text
        }

        func makeToolbar() -> UIToolbar {
            let toolbar = UIToolbar()
            toolbar.items = [
                UIBarButtonItem(systemItem: .flexibleSpace),
                UIBarButtonItem(
                    title: "Done",
                    style: .prominent,
                    target: self,
                    action: #selector(doneTapped)
                )
            ]
            toolbar.sizeToFit()
            return toolbar
        }

        @objc func textDidChange(_ sender: UITextField) {
            text.wrappedValue = sender.text ?? ""
        }

        @objc func doneTapped() {
            textField?.resignFirstResponder()
        }
    }
}
