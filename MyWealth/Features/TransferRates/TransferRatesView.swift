import SwiftUI
import SwiftData

struct TransferRatesView: View {
    @Query private var assets: [Asset]
    @Bindable var settings: AppSettings

    @State private var viewModel = DashboardViewModel()

    private var rows: [TransferRateRow] {
        viewModel.transferRateRows(
            baseCurrency: settings.baseCurrency,
            displayCurrencies: settings.totalCurrencies
        )
    }

    private var requiredExchangeRateCurrencies: [Asset.CurrencyType] {
        [settings.baseCurrency] + settings.totalCurrencies + assets.compactMap(\.currency)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RadialDotBackground(dotRadius: 1, spacing: 20)
                    .ignoresSafeArea(.all)

                List {
                    Section(footer: FooterView(
                        model: viewModel.getFooterData(
                            assets,
                            baseCurrency: settings.baseCurrency,
                            displayCurrencies: settings.totalCurrencies
                        )
                    )) {
                        TransferRatesCard {
                            TransferRateWidgetView(
                                rows: rows,
                                baseCurrency: settings.baseCurrency,
                                lastUpdated: viewModel.lastUpdated
                            )
                        }
                        .transferRatesListRow()
                    }

                    if let rateStatus = viewModel.rateStatus {
                        Section {
                            RateStatusBannerView(status: rateStatus)
                                .transferRatesListRow()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Transfer Rates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.fetchExchangeRate(
                                requiredCurrencies: requiredExchangeRateCurrencies
                            )
                        }
                    } label: {
                        Label("Refresh Rates", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoadingRate)
                }
            }            
        }
        .task {
            await viewModel.refreshExchangeRateIfNeeded(
                requiredCurrencies: requiredExchangeRateCurrencies
            )
        }
        .onChange(of: settings.baseCurrency) {
            Task {
                await viewModel.refreshExchangeRateIfNeeded(
                    requiredCurrencies: requiredExchangeRateCurrencies
                )
            }
        }
        .onChange(of: settings.totalCurrencies) {
            Task {
                await viewModel.refreshExchangeRateIfNeeded(
                    requiredCurrencies: requiredExchangeRateCurrencies
                )
            }
        }
    }
}

private struct TransferRatesCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

            content
                .padding(12)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension View {
    func transferRatesListRow() -> some View {
        listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
}
