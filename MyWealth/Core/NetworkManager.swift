import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(underlying: Error)
    case badStatusCode(Int)
    case decodingFailed(underlying: Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .requestFailed(let underlying):
            return "The network request failed: \(underlying.localizedDescription)"
        case .badStatusCode(let code):
            return "Received an unexpected status code: \(code)"
        case .decodingFailed(let underlying):
            return "Failed to decode the response: \(underlying.localizedDescription)"
        case .noData:
            return "No data was returned by the server."
        }
    }
}

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    @discardableResult
    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String]? = nil,
        body: Data? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers?.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.requestFailed(underlying: URLError(.badServerResponse))
            }
            guard (200..<300).contains(http.statusCode) else {
                throw NetworkError.badStatusCode(http.statusCode)
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(underlying: error)
            }
        } catch {
            throw NetworkError.requestFailed(underlying: error)
        }
    }
}

extension NetworkManager {
    func getResponse<T: Decodable>(
        from url: URL,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        try await request(url: url, method: .GET, headers: headers, decoder: decoder) as T
    }
}
