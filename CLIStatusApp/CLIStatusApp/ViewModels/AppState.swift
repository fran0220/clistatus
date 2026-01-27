import Foundation
import SwiftUI

@Observable
@MainActor
final class AppState {
    var tools: [ToolStatus]
    var npmPackages: [NpmPackageStatus] = []
    var brewPackages: [BrewPackageStatus] = []
    var npxPackages: [NpxPackageStatus] = []
    var isChecking = false
    var isCheckingNpm = false
    var isCheckingBrew = false
    var isCheckingNpx = false
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
    private let brewService = BrewPackageService()
    private let npxService = NpxPackageService()
    private var checkTimer: Timer?
    private let autoCheckKey = "autoCheckMarket"
    private let checkIntervalKey = "checkIntervalMinutes"
    private let npxStorageKey = "npx_tracked_packages"

    init() {
        let defaults = UserDefaults.standard
        let storedInterval = defaults.integer(forKey: checkIntervalKey)
        self.checkIntervalMinutes = storedInterval == 0 ? 60 : storedInterval
        self.autoCheckEnabled = defaults.object(forKey: autoCheckKey) as? Bool ?? true

        self.tools = CLITool.allCases.map { ToolStatus(tool: $0) }
        self.checkInterval = TimeInterval(self.checkIntervalMinutes * 60)
        loadNpxPackages()

        Task {
            await NotificationService.shared.requestAuthorization()
            if autoCheckEnabled {
                await checkAll()
                await checkNpmPackages()
                await checkBrewPackages()
                await checkNpxPackages()
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

    // MARK: - NPX Packages

    private struct NpxTrackedPackage: Codable {
        let name: String
        let currentVersion: String?
    }

    private func loadNpxPackages() {
        guard let data = UserDefaults.standard.data(forKey: npxStorageKey),
              let decoded = try? JSONDecoder().decode([NpxTrackedPackage].self, from: data) else {
            npxPackages = []
            return
        }
        npxPackages = decoded.map { NpxPackageStatus(name: $0.name, current: $0.currentVersion) }
    }

    private func saveNpxPackages() {
        let items = npxPackages.map { NpxTrackedPackage(name: $0.name, currentVersion: $0.currentVersion) }
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: npxStorageKey)
        }
    }

    func checkNpxPackages() async {
        guard !isCheckingNpx else { return }
        isCheckingNpx = true

        for pkg in npxPackages {
            pkg.state = .checking
        }

        await withTaskGroup(of: (String, String?).self) { group in
            for pkg in npxPackages {
                group.addTask {
                    let latest = await self.npxService.fetchLatestVersion(name: pkg.name)
                    return (pkg.name, latest)
                }
            }

            for await (name, latest) in group {
                guard let pkg = npxPackages.first(where: { $0.name == name }) else { continue }
                guard let latest = latest else {
                    pkg.state = .error(message: "获取版本失败")
                    continue
                }

                if let current = pkg.currentVersion, current != latest {
                    pkg.state = .updateAvailable(current: current, latest: latest)
                } else {
                    pkg.currentVersion = latest
                    pkg.state = .upToDate(current: latest)
                }
            }
        }

        saveNpxPackages()
        isCheckingNpx = false
    }

    func addNpxPackage(name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if npxPackages.contains(where: { $0.name == trimmed }) { return }

        let pkg = NpxPackageStatus(name: trimmed)
        pkg.state = .checking
        npxPackages.insert(pkg, at: 0)

        let latest = await npxService.fetchLatestVersion(name: trimmed)
        if let latest = latest {
            pkg.currentVersion = latest
            pkg.state = .upToDate(current: latest)
        } else {
            pkg.state = .error(message: "获取版本失败")
        }

        saveNpxPackages()
    }

    func applyNpxUpdate(name: String) {
        guard let pkg = npxPackages.first(where: { $0.name == name }) else { return }
        if case .updateAvailable(_, let latest) = pkg.state {
            pkg.currentVersion = latest
            pkg.state = .upToDate(current: latest)
            saveNpxPackages()
        }
    }

    func removeNpxPackage(name: String) {
        npxPackages.removeAll { $0.name == name }
        saveNpxPackages()
    }

    // MARK: - Homebrew Packages

    func checkBrewPackages() async {
        guard !isCheckingBrew else { return }
        isCheckingBrew = true

        do {
            let packages = try await brewService.listInstalled()
            brewPackages = packages.map { pkg in
                BrewPackageStatus(name: pkg.name, current: pkg.version, kind: pkg.kind)
            }

            for pkg in brewPackages {
                pkg.state = .checking
            }

            let outdated = await brewService.fetchOutdated()
            for pkg in brewPackages {
                guard let current = pkg.currentVersion else {
                    pkg.state = .error(message: "Unknown version")
                    continue
                }
                let latest: String?
                switch pkg.kind {
                case .formula:
                    latest = outdated.formulae[pkg.name]
                case .cask:
                    latest = outdated.casks[pkg.name]
                }

                if let latest = latest, latest != current {
                    pkg.state = .updateAvailable(current: current, latest: latest)
                } else {
                    pkg.state = .upToDate(current: current)
                }
            }
        } catch {
            for pkg in brewPackages {
                pkg.state = .error(message: error.localizedDescription)
            }
        }

        isCheckingBrew = false
    }

    func installBrewPackage(spec: String) async {
        let (kind, name) = parseBrewSpec(spec)
        let tempStatus = BrewPackageStatus(name: name, kind: kind)
        tempStatus.state = .updating
        brewPackages.insert(tempStatus, at: 0)

        do {
            try await brewService.install(spec: name, kind: kind)
            await checkBrewPackages()
        } catch {
            tempStatus.state = .error(message: error.localizedDescription)
        }
    }

    func upgradeBrewPackage(name: String) async {
        guard let pkg = brewPackages.first(where: { $0.name == name }) else { return }
        pkg.state = .updating

        do {
            try await brewService.upgrade(name: name, kind: pkg.kind)
            await checkBrewPackages()
        } catch {
            pkg.state = .error(message: error.localizedDescription)
        }
    }

    func uninstallBrewPackage(name: String) async {
        guard let pkg = brewPackages.first(where: { $0.name == name }) else { return }
        pkg.state = .uninstalling

        do {
            try await brewService.uninstall(name: name, kind: pkg.kind)
            brewPackages.removeAll { $0.name == name }
        } catch {
            pkg.state = .error(message: error.localizedDescription)
        }
    }

    private func parseBrewSpec(_ spec: String) -> (BrewPackageStatus.Kind, String) {
        let trimmed = spec.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("cask:") {
            let name = trimmed.dropFirst("cask:".count)
            return (.cask, String(name))
        }
        return (.formula, trimmed)
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
                await self?.checkBrewPackages()
                await self?.checkNpxPackages()
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
                await checkBrewPackages()
                await checkNpxPackages()
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
