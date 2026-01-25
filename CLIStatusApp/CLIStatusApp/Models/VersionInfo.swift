import Foundation

struct VersionInfo: Equatable, Comparable, Sendable {
    let major: Int
    let minor: Int
    let patch: Int
    let raw: String

    init?(string: String) {
        self.raw = string
        let pattern = #"(\d+)\.(\d+)\.(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let majorRange = Range(match.range(at: 1), in: string),
              let minorRange = Range(match.range(at: 2), in: string),
              let patchRange = Range(match.range(at: 3), in: string) else {
            return nil
        }
        self.major = Int(string[majorRange]) ?? 0
        self.minor = Int(string[minorRange]) ?? 0
        self.patch = Int(string[patchRange]) ?? 0
    }

    var display: String { "\(major).\(minor).\(patch)" }

    static func < (lhs: VersionInfo, rhs: VersionInfo) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}
