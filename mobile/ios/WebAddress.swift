import Foundation

enum WebAddress {
    private static let domain = "^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z]{2,63}$"
    private static let blockedSuffixes = [".localhost", ".local", ".internal", ".test", ".lan", ".onion", ".arpa"]

    static func parse(_ text: String) -> URL? {
        let address = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = address.contains("://") ? address : "https://" + address
        guard candidate.utf8.count <= 2000, let url = URL(string: candidate), allows(url) else { return nil }
        return url
    }

    static func allows(_ url: URL) -> Bool {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme?.lowercased() == "https",
              parts.user == nil, parts.password == nil,
              parts.port == nil || parts.port == 443,
              let host = parts.percentEncodedHost?.lowercased(), host.utf8.count <= 253,
              host.range(of: domain, options: .regularExpression) != nil else { return false }
        return !blockedSuffixes.contains { host.hasSuffix($0) }
    }
}
