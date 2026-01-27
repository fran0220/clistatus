import Foundation

actor NpxPackageService {
    private let shell = ShellExecutor()

    func fetchLatestVersion(name: String) async -> String? {
        do {
            let output = try await shell.run(["npm", "view", name, "version"], timeout: .seconds(15))
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
