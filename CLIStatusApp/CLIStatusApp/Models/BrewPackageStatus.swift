import Foundation

@Observable
final class BrewPackageStatus: Identifiable {
    enum Kind: String {
        case formula
        case cask
    }

    let name: String
    let currentVersion: String?
    let kind: Kind
    var id: String { "\(kind.rawValue):\(name)" }

    enum State: Equatable {
        case idle
        case checking
        case upToDate(current: String)
        case updateAvailable(current: String, latest: String)
        case updating
        case uninstalling
        case error(message: String)
    }

    var state: State = .idle

    init(name: String, current: String? = nil, kind: Kind = .formula) {
        self.name = name
        self.currentVersion = current
        self.kind = kind
        if let current = current {
            self.state = .upToDate(current: current)
        }
    }
}
