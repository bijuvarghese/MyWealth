import SwiftUI
import SwiftData

struct TransferRatesView: View {
    @Query private var assets: [Asset]
    @Query private var liabilities: [Liability]
    @Bindable var settings: AppSettings

    @State private var viewModel = DashboardViewModel()
    @State private var metalViewModel = MetalPricesViewModel()

    private var rows: [TransferRateRow] {
        viewModel.transferRateRows(
            baseCurrency: settings.baseCurrency,
            displayCurrencies: settings.totalCurrencies
        )
    }

    private var metalGroups: [(group: MetalGroup, rows: [MetalPriceRow])] {
        metalViewModel.groupedRows(
            baseCurrency: settings.baseCurrency,
            exchangeRates: viewModel.exchangeRates
        )
    }

    private var requiredExchangeRateCurrencies: [Asset.CurrencyType] {
        [settings.baseCurrency] + settings.totalCurrencies + assets.compactMap(\.currency) + liabilities.compactMap(\.currency)
    }

    private var isRefreshing: Bool {
        viewModel.isLoadingRate || metalViewModel.isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RadialDotBackground(dotRadius: 1, spacing: 20)
                    .ignoresSafeArea(.all)

                List {
                    // Transfer rates
                    Section {
                        TransferRatesCard {
                            VStack(spacing: 8) {
                                TransferRateWidgetView(
                                    rows: rows,
                                    baseCurrency: settings.baseCurrency
                                )
                                if let rateStatus = viewModel.rateStatus {
                                    Divider()
                                    RateStatusBannerView(status: rateStatus)
                                        .transferRatesListRow()
                                }
                            }
                        }
                        .transferRatesListRow()
                    }

                    // Metal prices
                    Section {
                        TransferRatesCard {
                            VStack(spacing: 8) {
                                MetalPriceWidgetView(
                                    groups: metalGroups,
                                    isLoading: metalViewModel.isLoading,
                                    lastUpdated: metalViewModel.lastUpdated
                                )
                                if let metalStatus = metalViewModel.statusBanner {
                                    Divider()
                                    RateStatusBannerView(status: metalStatus)
                                        .transferRatesListRow()
                                }
                            }
                        }
                        .transferRatesListRow()
                    }

                }
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Rates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            async let exchangeRefresh: Void = viewModel.fetchExchangeRate(
                                requiredCurrencies: requiredExchangeRateCurrencies
                            )
                            async let metalRefresh: Void = metalViewModel.refresh()
                            _ = await (exchangeRefresh, metalRefresh)
                        }
                    } label: {
                        Label("Refresh Rates", systemImage: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)
                }
            }
        }
        .task {
            async let exchangeRefresh: Void = viewModel.refreshExchangeRateIfNeeded(
                requiredCurrencies: requiredExchangeRateCurrencies
            )
            async let metalRefresh: Void = metalViewModel.refreshIfNeeded()
            _ = await (exchangeRefresh, metalRefresh)
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
