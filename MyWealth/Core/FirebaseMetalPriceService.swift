import Foundation

enum MetalPriceServiceError: Error, LocalizedError {
    case missingProxyURL

    var errorDescription: String? {
        switch self {
        case .missingProxyURL:
            return "Set MetalPriceProxyURL in Info.plist to your deployed Firebase Function URL."
        }
    }
}

protocol MetalPriceFetching {
    func fetchLatestMetalPrices() async throws -> RateResponse
}

final class FirebaseMetalPriceService: MetalPriceFetching {
    static let shared = FirebaseMetalPriceService()

    private init() {}

    func fetchLatestMetalPrices() async throws -> RateResponse {
        guard let url = Self.proxyURL else {
            throw MetalPriceServiceError.missingProxyURL
        }
        return try await NetworkManager.shared.getResponse(from: url)
    }

    private static var proxyURL: URL? {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "MetalPriceProxyURL") as? String,
            !value.isEmpty,
            !value.contains("YOUR_FIREBASE_PROJECT_ID")
        else {
            return nil
        }
        return URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
