// Made by Lumaa & Claude

import Foundation

/// Manages locale-derived identifiers across multiple regional/language standards.
///
/// Supports:
/// - **ISO 3166-1 alpha-2** (e.g. `"US"`, `"GB"`) — region codes, uppercase
/// - **ISO 639-1** (e.g. `"en"`, `"fr"`) — language codes, lowercase
/// - **BCP 47** (e.g. `"en-US"`) — combined locale tag, mixed case
///
/// Usage:
/// ```swift
/// let locale = LocaleManager()
/// let region   = locale.regionCode        // "US"
/// let language = locale.languageCode      // "en"
/// let fullTag  = locale.bcp47Tag          // "en-US"
/// ```
final class LocaleManager {
	public static let shared: LocaleManager = .init()

    // MARK: - Public properties

    /// The resolved `Locale`. Defaults to `Locale.current`.
    public let locale: Locale

    // MARK: - ISO 3166-1 alpha-2 (Uppercase)

    /// Two-letter region code in **UPPERCASE** as required by ISO 3166-1 alpha-2.
    ///
    /// Use this for:
    /// - Discover Region  (`"US"`, `"GB"`, …)
    /// - Watch Providers  (`"US"`, `"GB"`, …)
    ///
    /// Falls back to `"US"` when the locale carries no region information.
    public var regionCode: String {
        resolvedRegion.uppercased()
    }

    // MARK: - ISO 639-1 (Lowercase)

    /// Two-letter language code in **lowercase** as required by ISO 639-1.
    ///
    /// Use this for:
    /// - Interface Language  (`"en"`, `"fr"`, …)
    /// - Metadata Language   (`"en"`, `"fr"`, …)
    ///
    /// Falls back to `"en"` when the locale carries no language information.
    public var languageCode: String {
        resolvedLanguage.lowercased()
    }

    // MARK: - BCP 47 (Mixed case)

    /// Full locale tag formatted as **BCP 47** (`language-REGION`).
    ///
    /// Use this for:
    /// - Full Locale lists  (`"en-US"`, `"fr-FR"`, …)
    ///
    /// The language part is lowercased and the region part is uppercased per the
    /// BCP 47 convention (RFC 5646 §2.1).
    public var bcp47Tag: String {
        "\(resolvedLanguage.lowercased())-\(resolvedRegion.uppercased())"
    }

    // MARK: - Matching helpers

    /// Returns `true` when the given ISO 3166-1 alpha-2 region string matches
    /// the device locale, ignoring case.
    ///
    /// - Parameter iso3166: e.g. `"us"`, `"US"`, `"Gb"`
    public func matchesRegion(_ iso3166: String) -> Bool {
        resolvedRegion.caseInsensitiveCompare(iso3166) == .orderedSame
    }

    /// Returns `true` when the given ISO 639-1 language string matches
    /// the device locale, ignoring case.
    ///
    /// - Parameter iso639: e.g. `"en"`, `"FR"`, `"De"`
    public func matchesLanguage(_ iso639: String) -> Bool {
        resolvedLanguage.caseInsensitiveCompare(iso639) == .orderedSame
    }

    /// Returns `true` when the given BCP 47 tag matches the device locale.
    ///
    /// Both the language component and the region component are compared
    /// case-insensitively so `"en-us"`, `"EN-US"`, and `"en-US"` all match.
    ///
    /// - Parameter bcp47: e.g. `"en-US"`, `"fr-fr"`, `"de-DE"`
    public func matchesBCP47(_ bcp47: String) -> Bool {
        let parts = bcp47.split(separator: "-", maxSplits: 1)
        guard parts.count == 2 else {
            // Treat as language-only tag if no region separator found
            return resolvedLanguage.caseInsensitiveCompare(bcp47) == .orderedSame
        }
        let lang   = String(parts[0])
        let region = String(parts[1])
        return resolvedLanguage.caseInsensitiveCompare(lang)   == .orderedSame && resolvedRegion.caseInsensitiveCompare(region) == .orderedSame
    }

    // MARK: - Filtering helpers

    /// Filters an array of BCP 47 tags, keeping only those that match the
    /// current locale's **language** component (region-agnostic).
    ///
    /// ```swift
    /// let streams = ["en-US", "en-GB", "fr-FR", "de-DE"]
    /// locale.filterBCP47ByLanguage(streams)  // ["en-US", "en-GB"] on an English device
    /// ```
    public func filterBCP47ByLanguage(_ tags: [String]) -> [String] {
        tags.filter { tag in
            let lang = tag.split(separator: "-", maxSplits: 1).first.map(String.init) ?? tag
            return resolvedLanguage.caseInsensitiveCompare(lang) == .orderedSame
        }
    }

    /// Filters an array of ISO 3166-1 alpha-2 region codes, keeping only the
    /// ones that match the device region.
    ///
    /// ```swift
    /// let releaseDates = ["US", "GB", "FR"]
    /// locale.filterRegions(releaseDates)  // ["US"] on a US device
    /// ```
    public func filterRegions(_ regions: [String]) -> [String] {
        regions.filter { matchesRegion($0) }
    }

    /// Filters an array of ISO 639-1 language codes, keeping only the ones
    /// that match the device language.
    ///
    /// ```swift
    /// let spokenLanguages = ["en", "fr", "de"]
    /// locale.filterLanguages(spokenLanguages)  // ["en"] on an English device
    /// ```
    public func filterLanguages(_ languages: [String]) -> [String] {
        languages.filter { matchesLanguage($0) }
    }

    // MARK: - Initialiser

    /// Creates a `LocaleManager` for the given locale.
    ///
    /// - Parameter locale: Defaults to `Locale.current`.
    public init(locale: Locale = .current) {
        self.locale = locale
    }

    // MARK: - Private helpers

    /// Resolved two-letter language string (pre-normalisation).
    private var resolvedLanguage: String {
        if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
            return locale.language.languageCode?.identifier ?? "en"
        } else {
            return locale.languageCode ?? "en"
        }
    }

    /// Resolved two-letter region string (pre-normalisation).
    private var resolvedRegion: String {
        if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
			return locale.region?.identifier ?? "US"
        } else {
            return locale.regionCode ?? "US"
        }
    }
}

// MARK: - CustomStringConvertible

extension LocaleManager: CustomStringConvertible {
    public var description: String {
        "LocaleManager(bcp47: \"\(bcp47Tag)\", region: \"\(regionCode)\", language: \"\(languageCode)\")"
    }
}
