import Foundation

@Observable
final class NpmPackageStatus: Identifiable {
    let name: String
    let currentVersion: VersionInfo?
    var id: String { name }
    
    enum State: Equatable {
        case idle
        case checking
        case upToDate(current: VersionInfo)
        case updateAvailable(current: VersionInfo, latest: VersionInfo)
        case updating
        case uninstalling
        case error(message: String)
    }
    
    var state: State = .idle
    
    init(name: String, current: VersionInfo? = nil) {
        self.name = name
        self.currentVersion = current
        if let current = current {
            self.state = .upToDate(current: current)
        }
    }
}
