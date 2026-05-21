import SwiftUI

struct TransferRatesView: View {
    @Bindable var settings: AppSettings

    @State private var viewModel = DashboardViewModel()
    @State private var showSettings = false

    private var rows: [TransferRateRow] {
        viewModel.transferRateRows(
            baseCurrency: settings.baseCurrency,
            displayCurrencies: settings.totalCurrencies
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RadialDotBackground(dotRadius: 1, spacing: 20)
                    .ignoresSafeArea(.all)

                List {
                    Section {
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.fetchExchangeRate()
                        }
                    } label: {
                        Label("Refresh Rates", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoadingRate)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings)
            }
        }
        .task {
            await viewModel.refreshExchangeRateIfNeeded()
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
