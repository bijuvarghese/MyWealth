import Foundation

enum AppLocalization {
    static let supportedLanguageIdentifiers = [
        "en", "hi", "es", "pt-BR", "fr", "de", "zh-Hans", "ar"
    ]

    nonisolated static func string(
        _ key: String,
        table: String? = nil,
        bundle: Bundle = .main,
        locale: Locale = .current,
        fallback: String? = nil
    ) -> String {
        let localizedBundle = bundle.localizedBundle(for: locale)
        let value = localizedBundle.localizedString(forKey: key, value: nil, table: table)

        if value != key {
            return value
        }

        let englishBundle = bundle.localizedBundle(forLanguage: "en") ?? bundle
        let english = englishBundle.localizedString(forKey: key, value: nil, table: table)
        return english == key ? (fallback ?? key) : english
    }

    nonisolated static func formatted(
        _ key: String,
        arguments: [CVarArg],
        bundle: Bundle = .main,
        locale: Locale = .current,
        fallback: String? = nil
    ) -> String {
        let format = string(
            key,
            bundle: bundle,
            locale: locale,
            fallback: fallback
        )
        return String(format: format, locale: locale, arguments: arguments)
    }
}

extension Bundle {
    nonisolated fileprivate func localizedBundle(for locale: Locale) -> Bundle {
        for identifier in localeLocalizationCandidates(for: locale) {
            if let localizedBundle = localizedBundle(forLanguage: identifier) {
                return localizedBundle
            }
        }
        return localizedBundle(forLanguage: "en") ?? self
    }

    nonisolated fileprivate func localizedBundle(forLanguage language: String) -> Bundle? {
        guard
            let path = path(forResource: language, ofType: "lproj"),
            let localizedBundle = Bundle(path: path)
        else {
            return nil
        }
        return localizedBundle
    }

    nonisolated private func localeLocalizationCandidates(for locale: Locale) -> [String] {
        let canonical = Locale.canonicalLanguageIdentifier(from: locale.identifier)
        var candidates = [canonical]

        if let languageCode = locale.language.languageCode?.identifier {
            if let script = locale.language.script?.identifier {
                candidates.append("\(languageCode)-\(script)")
            }
            candidates.append(languageCode)
        }

        return candidates
    }
}
