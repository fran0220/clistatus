import Foundation

@Observable
final class ToolStatus: Identifiable {
    let tool: CLITool
    var id: String { tool.id }

    enum State: Equatable {
        case idle
        case checking
        case notInstalled
        case upToDate(current: VersionInfo)
        case updateAvailable(current: VersionInfo, latest: VersionInfo)
        case updating
        case installing
        case error(message: String)
    }

    var state: State = .idle

    init(tool: CLITool) {
        self.tool = tool
    }
}
