import Foundation

@Observable
final class NpxPackageStatus: Identifiable {
    let name: String
    var currentVersion: String?
    var id: String { name }

    enum State: Equatable {
        case idle
        case checking
        case upToDate(current: String)
        case updateAvailable(current: String, latest: String)
        case error(message: String)
    }

    var state: State = .idle

    init(name: String, current: String? = nil) {
        self.name = name
        self.currentVersion = current
        if let current = current {
            self.state = .upToDate(current: current)
        }
    }
}
