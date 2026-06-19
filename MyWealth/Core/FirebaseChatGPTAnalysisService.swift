import Foundation

enum ChatGPTAnalysisServiceError: Error, LocalizedError {
    case missingProxyURL
    case analysisFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingProxyURL:
            return "Set ChatGPTAnalysisProxyURL in Info.plist to your deployed Firebase Function URL."
        case .analysisFailed(let message):
            return message
        }
    }
}

struct ChatGPTAnalysisResponse: Decodable {
    let success: Bool
    let model: String?
    let responseId: String?
    let analysis: String?
    let error: String?
}

protocol ChatGPTAnalysisFetching {
    func analyze(_ payload: ChatGPTAnalysisExportPayload) async throws -> ChatGPTAnalysisResponse
}

final class FirebaseChatGPTAnalysisService: ChatGPTAnalysisFetching {
    static let shared = FirebaseChatGPTAnalysisService()

    private init() {}

    func analyze(_ payload: ChatGPTAnalysisExportPayload) async throws -> ChatGPTAnalysisResponse {
        guard let url = Self.proxyURL else {
            throw ChatGPTAnalysisServiceError.missingProxyURL
        }

        let activityID = await AppActivityTracker.shared.begin()
        defer {
            Task { @MainActor in
                AppActivityTracker.shared.end(activityID)
            }
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(payload)

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NetworkError.requestFailed(underlying: URLError(.badServerResponse))
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(ChatGPTAnalysisResponse.self, from: data)
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ChatGPTAnalysisServiceError.analysisFailed(
                response.error ?? "AI analysis failed with status \(httpResponse.statusCode)."
            )
        }

        guard response.success, response.analysis?.isEmpty == false else {
            throw ChatGPTAnalysisServiceError.analysisFailed(
                response.error ?? "AI analysis returned an empty response."
            )
        }

        return response
    }

    private static var proxyURL: URL? {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "ChatGPTAnalysisProxyURL") as? String,
            !value.isEmpty,
            !value.contains("YOUR_FIREBASE_PROJECT_ID")
        else {
            return nil
        }

        return URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
