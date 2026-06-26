import Foundation

public enum TokenCatalogValidation {
    public static let requiredCategories: Set<String> = [
        "brandColor",
        "semanticColor",
        "typography",
        "spacing",
        "shape",
        "elevation",
        "iconSizing",
        "chartStatusColor",
        "motionIntent"
    ]

    public static let requiredPlatforms: Set<String> = ["ios", "android", "web"]

    public static func validateCatalog(data: Data) throws -> TokenCatalogValidationReport {
        let catalog = try JSONDecoder().decode(TokenCatalog.self, from: data)
        let tokenNames = catalog.tokens.map(\.name)
        let duplicateNames = duplicates(in: tokenNames)
        let categories = Set(catalog.tokens.map(\.category))
        let missingCategories = requiredCategories.subtracting(categories)
        let tokensMissingPlatformMappings = catalog.tokens
            .filter { !requiredPlatforms.isSubset(of: Set($0.platformValues.keys)) }
            .map(\.name)
        let tokensMissingAccessibilityNotes = catalog.tokens
            .filter { $0.accessibilityNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map(\.name)
        let tokensWithSensitiveContent = catalog.tokens
            .filter { containsSensitiveContent($0.searchableContent) }
            .map(\.name)

        return TokenCatalogValidationReport(
            tokenCount: catalog.tokens.count,
            categories: categories,
            duplicateNames: duplicateNames,
            missingCategories: missingCategories,
            tokensMissingPlatformMappings: tokensMissingPlatformMappings,
            tokensMissingAccessibilityNotes: tokensMissingAccessibilityNotes,
            tokensWithSensitiveContent: tokensWithSensitiveContent
        )
    }

    private static func duplicates(in values: [String]) -> [String] {
        var seen: Set<String> = []
        var duplicateValues: Set<String> = []

        for value in values {
            if !seen.insert(value).inserted {
                duplicateValues.insert(value)
            }
        }

        return duplicateValues.sorted()
    }

    private static func containsSensitiveContent(_ content: String) -> Bool {
        let lowered = content.lowercased()
        let blockedTerms = [
            "api_key",
            "apikey",
            "secret",
            "password",
            "token=",
            "account_name",
            "institution",
            "balance",
            "net worth:",
            "email",
            "phone"
        ]

        return blockedTerms.contains { lowered.contains($0) }
    }
}

public struct TokenCatalogValidationReport {
    public let tokenCount: Int
    public let categories: Set<String>
    public let duplicateNames: [String]
    public let missingCategories: Set<String>
    public let tokensMissingPlatformMappings: [String]
    public let tokensMissingAccessibilityNotes: [String]
    public let tokensWithSensitiveContent: [String]

    public var isValid: Bool {
        tokenCount > 0 &&
            duplicateNames.isEmpty &&
            missingCategories.isEmpty &&
            tokensMissingPlatformMappings.isEmpty &&
            tokensMissingAccessibilityNotes.isEmpty &&
            tokensWithSensitiveContent.isEmpty
    }
}

private struct TokenCatalog: Decodable {
    let tokens: [DesignToken]
}

private struct DesignToken: Decodable {
    let name: String
    let category: String
    let description: String
    let value: JSONValue
    let platformValues: [String: String]
    let accessibilityNotes: String

    var searchableContent: String {
        ([name, category, description, accessibilityNotes] + platformValues.values + [value.searchableContent])
            .joined(separator: " ")
    }
}

private enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case object([String: JSONValue])
    case array([JSONValue])
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported token value"
            )
        }
    }

    var searchableContent: String {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return String(value)
        case .object(let values):
            return values.map { "\($0.key) \($0.value.searchableContent)" }.joined(separator: " ")
        case .array(let values):
            return values.map(\.searchableContent).joined(separator: " ")
        case .bool(let value):
            return String(value)
        case .null:
            return ""
        }
    }
}
