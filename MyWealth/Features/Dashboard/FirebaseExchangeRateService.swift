import Foundation

enum ExchangeRateServiceError: Error, LocalizedError {
    case missingProxyURL

    var errorDescription: String? {
        switch self {
        case .missingProxyURL:
            return "Set ExchangeRateProxyURL in Info.plist to your deployed Firebase Function URL."
        }
    }
}

final class FirebaseExchangeRateService {
    static let shared = FirebaseExchangeRateService()

    private init() {}

    func fetchLatestExchangeRates() async throws -> RateResponse {
        guard let url = Self.proxyURL else {
            throw ExchangeRateServiceError.missingProxyURL
        }

        return try await NetworkManager.shared.getResponse(from: url)
    }

    private static var proxyURL: URL? {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "ExchangeRateProxyURL") as? String,
            !value.contains("YOUR_FIREBASE_PROJECT_ID")
        else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: trimmedValue)
    }
}
