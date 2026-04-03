import Foundation
import SwiftUI

@Observable
@MainActor
final class AppState {
    var tools: [ToolStatus]
    var npmPackages: [NpmPackageStatus] = []
    var isChecking = false
    var isCheckingNpm = false
    var autoCheckEnabled: Bool
    var checkIntervalMinutes: Int
    var lastCheckTime: Date?
    var checkInterval: TimeInterval = 3600 {
        didSet {
            if oldValue != checkInterval, autoCheckEnabled {
                restartScheduledChecks()
            }
        }
    }
    
    // MARK: - 剪贴板服务
    
    /// 剪贴板服务实例
    let clipboardService = ClipboardService()

    private let versionChecker = VersionChecker()
    private let updateService = UpdateService()
    private let npmService = NpmPackageService()
    private var checkTimer: Timer?
    private let autoCheckKey = "autoCheckMarket"
    private let checkIntervalKey = "checkIntervalMinutes"

    init() {
        let defaults = UserDefaults.standard
        let storedInterval = defaults.integer(forKey: checkIntervalKey)
        self.checkIntervalMinutes = storedInterval == 0 ? 60 : storedInterval
        self.autoCheckEnabled = defaults.object(forKey: autoCheckKey) as? Bool ?? true

        self.tools = CLITool.allCases.map { ToolStatus(tool: $0) }
        self.checkInterval = TimeInterval(self.checkIntervalMinutes * 60)

        Task {
            await NotificationService.shared.requestAuthorization()
            if autoCheckEnabled {
                await checkAll()
                await checkNpmPackages()
                startScheduledChecks()
            }
        }
    }

    // MARK: - CLI Tools
    
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
            try? await Task.sleep(for: .seconds(1))
            let checkResult = await versionChecker.check(tool)
            if let version = checkResult.current {
                toolStatus.state = .upToDate(current: version)
                NotificationService.shared.sendUpdateComplete(tool: tool, newVersion: version)
            } else {
                toolStatus.state = .error(message: "Update completed but version check failed")
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
            try? await Task.sleep(for: .seconds(1))
            let checkResult = await versionChecker.check(tool)
            if let version = checkResult.current {
                toolStatus.state = .upToDate(current: version)
                NotificationService.shared.sendInstallComplete(tool: tool, version: version)
            } else {
                toolStatus.state = .error(message: "Install completed but version check failed")
            }
        case .failure(let error):
            toolStatus.state = .error(message: error.localizedDescription)
            NotificationService.shared.sendError(tool: tool, message: error.localizedDescription)
        }
    }

    // MARK: - NPM Packages
    
    func checkNpmPackages() async {
        guard !isCheckingNpm else { return }
        isCheckingNpm = true
        
        do {
            let packages = try await npmService.listGlobals()
            
            npmPackages = packages.map { pkg in
                NpmPackageStatus(name: pkg.name, current: pkg.current)
            }
            
            for pkg in npmPackages {
                pkg.state = .checking
            }
            
            await withTaskGroup(of: (String, VersionInfo?).self) { group in
                for pkg in npmPackages {
                    group.addTask {
                        let latest = await self.npmService.fetchLatestVersion(name: pkg.name)
                        return (pkg.name, latest)
                    }
                }
                
                for await (name, latest) in group {
                    guard let pkg = npmPackages.first(where: { $0.name == name }) else { continue }
                    
                    if let current = pkg.currentVersion {
                        if let latest = latest, current < latest {
                            pkg.state = .updateAvailable(current: current, latest: latest)
                        } else {
                            pkg.state = .upToDate(current: current)
                        }
                    } else {
                        pkg.state = .error(message: "Failed to parse version")
                    }
                }
            }
        } catch {
            for pkg in npmPackages {
                pkg.state = .error(message: error.localizedDescription)
            }
        }
        
        isCheckingNpm = false
    }

    func installNpmPackage(spec: String) async {
        let tempStatus = NpmPackageStatus(name: spec)
        tempStatus.state = .updating
        npmPackages.insert(tempStatus, at: 0)
        
        do {
            try await npmService.install(spec: spec)
            await checkNpmPackages()
        } catch {
            tempStatus.state = .error(message: error.localizedDescription)
        }
    }
    
    func upgradeNpmPackage(name: String) async {
        guard let pkg = npmPackages.first(where: { $0.name == name }) else { return }
        
        pkg.state = .updating
        
        do {
            try await npmService.upgrade(name: name)
            try? await Task.sleep(for: .seconds(1))
            
            if let latest = await npmService.fetchLatestVersion(name: name) {
                pkg.state = .upToDate(current: latest)
            } else {
                pkg.state = .error(message: "Upgrade completed but version check failed")
            }
        } catch {
            pkg.state = .error(message: error.localizedDescription)
        }
    }
    
    func uninstallNpmPackage(name: String) async {
        guard let pkg = npmPackages.first(where: { $0.name == name }) else { return }
        
        pkg.state = .uninstalling
        
        do {
            try await npmService.uninstall(name: name)
            npmPackages.removeAll { $0.name == name }
        } catch {
            pkg.state = .error(message: error.localizedDescription)
        }
    }

    // MARK: - Timer
    
    private func startScheduledChecks() {
        guard autoCheckEnabled else { return }
        checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAll()
                await self?.checkNpmPackages()
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

    func updateAutoCheckEnabled(_ enabled: Bool) {
        autoCheckEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: autoCheckKey)
        if enabled {
            Task {
                await checkAll()
                await checkNpmPackages()
                startScheduledChecks()
            }
        } else {
            stopScheduledChecks()
        }
    }

    func updateCheckIntervalMinutes(_ minutes: Int) {
        checkIntervalMinutes = minutes
        UserDefaults.standard.set(minutes, forKey: checkIntervalKey)
        checkInterval = TimeInterval(minutes * 60)
    }
    
    // MARK: - Clipboard Operations
    
    /// 添加剪贴板项
    /// - Parameter item: 要添加的剪贴板项
    func addClipboardItem(_ item: ClipboardItem) {
        clipboardService.addItem(item)
    }
    
    /// 添加剪贴板项（便捷方法）
    /// - Parameters:
    ///   - title: 标题
    ///   - content: 内容
    ///   - category: 分类
    func addClipboardItem(title: String, content: String, category: ClipboardCategory = .general) {
        clipboardService.addItem(title: title, content: content, category: category)
    }
    
    /// 更新剪贴板项
    /// - Parameter item: 更新后的剪贴板项
    func updateClipboardItem(_ item: ClipboardItem) {
        clipboardService.updateItem(item)
    }
    
    /// 删除剪贴板项
    /// - Parameter id: 要删除的剪贴板项 ID
    func deleteClipboardItem(id: UUID) {
        clipboardService.deleteItem(id: id)
    }
    
    /// 复制剪贴板项到系统剪贴板
    /// - Parameter item: 要复制的剪贴板项
    func copyClipboardItem(_ item: ClipboardItem) {
        clipboardService.copyItem(item)
    }
}
