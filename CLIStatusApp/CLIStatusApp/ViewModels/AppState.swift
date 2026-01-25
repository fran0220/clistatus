import Foundation
import SwiftUI

@Observable
@MainActor
final class AppState {
    var tools: [ToolStatus]
    var isChecking = false
    var lastCheckTime: Date?
    var checkInterval: TimeInterval = 3600 {
        didSet {
            if oldValue != checkInterval {
                restartScheduledChecks()
            }
        }
    }

    private let versionChecker = VersionChecker()
    private let updateService = UpdateService()
    private var checkTimer: Timer?

    init() {
        self.tools = CLITool.allCases.map { ToolStatus(tool: $0) }

        Task {
            await NotificationService.shared.requestAuthorization()
            await checkAll()
            startScheduledChecks()
        }
    }

    func checkAll() async {
        guard !isChecking else { return }
        isChecking = true

        for toolStatus in tools {
            toolStatus.state = .checking
        }

        await withTaskGroup(of: (CLITool, VersionChecker.CheckResult).self) { group in
            for tool in CLITool.allCases {
                group.addTask {
                    let result = await self.versionChecker.check(tool)
                    return (tool, result)
                }
            }

            for await (tool, result) in group {
                guard let toolStatus = tools.first(where: { $0.tool == tool }) else { continue }

                if !result.isInstalled {
                    toolStatus.state = .notInstalled
                } else if let error = result.error {
                    toolStatus.state = .error(message: error.localizedDescription)
                } else if let current = result.current {
                    if let latest = result.latest, current < latest {
                        toolStatus.state = .updateAvailable(current: current, latest: latest)
                    } else {
                        toolStatus.state = .upToDate(current: current)
                    }
                } else {
                    toolStatus.state = .error(message: "Failed to parse version")
                }
            }
        }

        isChecking = false
        lastCheckTime = Date()
    }

    func update(_ tool: CLITool) async {
        guard let toolStatus = tools.first(where: { $0.tool == tool }) else { return }

        toolStatus.state = .updating

        let result = await updateService.update(tool)

        switch result {
        case .success:
            let checkResult = await versionChecker.check(tool)
            if let version = checkResult.current {
                toolStatus.state = .upToDate(current: version)
                NotificationService.shared.sendUpdateComplete(tool: tool, newVersion: version)
            }
        case .failure(let error):
            toolStatus.state = .error(message: error.localizedDescription)
            NotificationService.shared.sendError(tool: tool, message: error.localizedDescription)
        }
    }

    func install(_ tool: CLITool) async {
        guard let toolStatus = tools.first(where: { $0.tool == tool }) else { return }

        toolStatus.state = .installing

        let result = await updateService.install(tool)

        switch result {
        case .success:
            let checkResult = await versionChecker.check(tool)
            if let version = checkResult.current {
                toolStatus.state = .upToDate(current: version)
                NotificationService.shared.sendInstallComplete(tool: tool, version: version)
            }
        case .failure(let error):
            toolStatus.state = .error(message: error.localizedDescription)
            NotificationService.shared.sendError(tool: tool, message: error.localizedDescription)
        }
    }

    private func startScheduledChecks() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAll()
            }
        }
    }

    private func restartScheduledChecks() {
        checkTimer?.invalidate()
        checkTimer = nil
        startScheduledChecks()
    }

    func stopScheduledChecks() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
}
