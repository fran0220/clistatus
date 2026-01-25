import Foundation

actor VersionChecker {
    private let shell = ShellExecutor()

    struct CheckResult: Sendable {
        let tool: CLITool
        let current: VersionInfo?
        let latest: VersionInfo?
        let isInstalled: Bool
        let error: Error?
    }

    func check(_ tool: CLITool) async -> CheckResult {
        async let currentVersion = getCurrentVersion(tool)
        async let latestVersion = getLatestVersion(tool)

        let current = await currentVersion
        let latest = await latestVersion

        return CheckResult(
            tool: tool,
            current: current.version,
            latest: latest,
            isInstalled: current.installed,
            error: current.error
        )
    }

    private func getCurrentVersion(_ tool: CLITool) async -> (version: VersionInfo?, installed: Bool, error: Error?) {
        do {
            let output = try await shell.run(tool.versionCommand, timeout: .seconds(10))
            let version = parseVersion(output, pattern: tool.versionPattern)
            return (version, true, nil)
        } catch let error as ShellExecutor.ShellError {
            if case .commandNotFound = error {
                return (nil, false, nil)
            }
            return (nil, false, error)
        } catch {
            return (nil, false, error)
        }
    }

    private func getLatestVersion(_ tool: CLITool) async -> VersionInfo? {
        guard let npmPackage = tool.npmPackage else {
            return nil
        }

        do {
            let output = try await shell.run(["npm", "view", npmPackage, "version"], timeout: .seconds(15))
            return VersionInfo(string: output)
        } catch {
            return nil
        }
    }

    private func parseVersion(_ output: String, pattern: String) -> VersionInfo? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let versionRange = Range(match.range(at: 1), in: output) else {
            return VersionInfo(string: output)
        }
        return VersionInfo(string: String(output[versionRange]))
    }
}
