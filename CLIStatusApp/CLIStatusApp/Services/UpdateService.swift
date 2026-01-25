import Foundation

actor UpdateService {
    private let shell = ShellExecutor()

    enum OperationResult: Sendable {
        case success
        case failure(Error)
    }

    func update(_ tool: CLITool) async -> OperationResult {
        do {
            _ = try await shell.run(tool.updateCommand, timeout: .seconds(120))
            return .success
        } catch {
            return .failure(error)
        }
    }

    func install(_ tool: CLITool) async -> OperationResult {
        do {
            _ = try await shell.run(tool.installCommand, timeout: .seconds(180))
            return .success
        } catch {
            return .failure(error)
        }
    }
}
