import DesignSystem
import Foundation

enum WealthMapTokenValidation {
    static let requiredCategories = TokenCatalogValidation.requiredCategories
    static let requiredPlatforms = TokenCatalogValidation.requiredPlatforms

    static func validateCatalog(data: Data) throws -> WealthMapTokenValidationReport {
        let report = try TokenCatalogValidation.validateCatalog(data: data)
        return WealthMapTokenValidationReport(report)
    }
}

struct WealthMapTokenValidationReport {
    let tokenCount: Int
    let categories: Set<String>
    let duplicateNames: [String]
    let missingCategories: Set<String>
    let tokensMissingPlatformMappings: [String]
    let tokensMissingAccessibilityNotes: [String]
    let tokensWithSensitiveContent: [String]

    var isValid: Bool {
        tokenCount > 0 &&
            duplicateNames.isEmpty &&
            missingCategories.isEmpty &&
            tokensMissingPlatformMappings.isEmpty &&
            tokensMissingAccessibilityNotes.isEmpty &&
            tokensWithSensitiveContent.isEmpty
    }

    init(_ report: TokenCatalogValidationReport) {
        tokenCount = report.tokenCount
        categories = report.categories
        duplicateNames = report.duplicateNames
        missingCategories = report.missingCategories
        tokensMissingPlatformMappings = report.tokensMissingPlatformMappings
        tokensMissingAccessibilityNotes = report.tokensMissingAccessibilityNotes
        tokensWithSensitiveContent = report.tokensWithSensitiveContent
    }
}
