# CLI Status App - 零决策实施计划

## 确认的技术决策

| 决策点 | 选择 | 理由 |
|-------|------|------|
| 技术栈 | Swift + SwiftUI | 用户选择，原生性能最佳 |
| 最低版本 | macOS 14 (Sonoma) | 可使用 @Observable 宏 |
| App Sandbox | 禁用 | 需要执行外部 CLI 工具 |
| 菜单样式 | `.menuBarExtraStyle(.window)` | 支持富交互 UI |
| 状态管理 | @Observable (Observation framework) | macOS 14+ 最佳实践 |
| 版本检查 | 启动时 + 每小时定时 + 手动刷新 | 用户选择 |
| 系统通知 | 启用 (UNUserNotificationCenter) | 用户选择 |

## 项目结构

```
CLIStatusApp/
├── CLIStatusApp.swift                 # @main 入口
├── Info.plist                         # 应用配置
├── CLIStatusApp.entitlements         # 权限配置（禁用沙盒）
├── Assets.xcassets/                   # 图标资源
│   └── AppIcon.appiconset/
├── Models/
│   ├── CLITool.swift                 # CLI 工具定义（枚举 + 协议）
│   ├── VersionInfo.swift             # 版本信息模型
│   └── ToolStatus.swift              # 工具状态模型
├── ViewModels/
│   ├── AppState.swift                # 全局应用状态 (@Observable)
│   └── ToolViewModel.swift           # 单个工具视图模型
├── Views/
│   ├── MenuBarView.swift             # 菜单栏主视图
│   ├── ToolRowView.swift             # 工具行组件
│   ├── HeaderView.swift              # 顶部操作栏
│   ├── FooterView.swift              # 底部设置/退出
│   └── SettingsView.swift            # 设置窗口
├── Services/
│   ├── ShellExecutor.swift           # Shell 命令执行器
│   ├── VersionChecker.swift          # 版本检查服务
│   ├── UpdateService.swift           # 更新/安装服务
│   ├── NotificationService.swift     # 系统通知服务
│   └── SchedulerService.swift        # 定时检查调度器
└── Utilities/
    ├── VersionParser.swift           # 版本解析工具
    └── Constants.swift               # 常量定义
```

---

## 实施任务序列

### Phase 1: 项目基础设施 (P1)

#### P1-T1: 创建 Xcode 项目
**输入**: 无
**输出**: 可编译的空 macOS 项目

```
操作步骤:
1. 创建 macOS App 项目
   - Product Name: CLIStatusApp
   - Team: None (个人使用)
   - Organization Identifier: com.local
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: macOS 14.0

2. 配置为菜单栏应用
   - Info.plist 添加: LSUIElement = YES (隐藏 Dock 图标)

3. 禁用 App Sandbox
   - CLIStatusApp.entitlements:
     - com.apple.security.app-sandbox = NO

4. 添加网络权限（用于 npm registry 查询）
   - com.apple.security.network.client = YES
```

**验证**: 项目可编译运行，无 Dock 图标

---

#### P1-T2: 实现基础菜单栏框架
**输入**: P1-T1
**输出**: 显示静态菜单的菜单栏应用

**文件**: `CLIStatusApp.swift`
```swift
import SwiftUI

@main
struct CLIStatusApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("CLI Status", systemImage: "terminal.fill") {
            MenuBarView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
```

**验证**: 菜单栏显示终端图标，点击显示空白弹窗

---

### Phase 2: 数据模型层 (P2)

#### P2-T1: 定义 CLI 工具模型
**输入**: P1-T2
**输出**: 完整的工具定义和状态模型

**文件**: `Models/CLITool.swift`
```swift
import Foundation

enum CLITool: String, CaseIterable, Identifiable {
    case claudeCode = "claude"
    case codex = "codex"
    case geminiCLI = "gemini"
    case ampCode = "amp"
    case droid = "droid"
    case openCode = "opencode"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .codex: return "Codex"
        case .geminiCLI: return "Gemini CLI"
        case .ampCode: return "Amp Code"
        case .droid: return "Droid"
        case .openCode: return "OpenCode"
        }
    }

    var versionCommand: [String] {
        [rawValue, "--version"]
    }

    var npmPackage: String? {
        switch self {
        case .claudeCode: return "@anthropic-ai/claude-code"
        case .codex: return "@openai/codex"
        case .geminiCLI: return "@google/gemini-cli"
        case .ampCode: return "@sourcegraph/amp"
        case .droid: return nil  // 无 npm 包
        case .openCode: return "opencode-ai"
        }
    }

    var updateCommand: [String] {
        switch self {
        case .ampCode:
            return ["amp", "update"]
        case .droid:
            return ["/bin/sh", "-c", "curl -fsSL https://app.factory.ai/cli | sh"]
        default:
            guard let pkg = npmPackage else { return [] }
            return ["npm", "update", "-g", pkg]
        }
    }

    var installCommand: [String] {
        switch self {
        case .ampCode:
            return ["/bin/sh", "-c", "curl -fsSL https://ampcode.com/install.sh | sh"]
        case .droid:
            return ["/bin/sh", "-c", "curl -fsSL https://app.factory.ai/cli | sh"]
        default:
            guard let pkg = npmPackage else { return [] }
            return ["npm", "install", "-g", pkg]
        }
    }

    /// 版本输出解析正则
    var versionPattern: String {
        switch self {
        case .claudeCode: return #"(\d+\.\d+\.\d+)\s*\(Claude Code\)"#
        case .codex: return #"codex-cli\s+(\d+\.\d+\.\d+)"#
        case .ampCode: return #"^(\d+\.\d+\.\d+)"#  // 只取主版本号
        default: return #"^(\d+\.\d+\.\d+)"#
        }
    }
}
```

**文件**: `Models/VersionInfo.swift`
```swift
import Foundation

struct VersionInfo: Equatable, Comparable {
    let major: Int
    let minor: Int
    let patch: Int
    let raw: String

    init?(string: String) {
        self.raw = string
        let pattern = #"(\d+)\.(\d+)\.(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let majorRange = Range(match.range(at: 1), in: string),
              let minorRange = Range(match.range(at: 2), in: string),
              let patchRange = Range(match.range(at: 3), in: string) else {
            return nil
        }
        self.major = Int(string[majorRange]) ?? 0
        self.minor = Int(string[minorRange]) ?? 0
        self.patch = Int(string[patchRange]) ?? 0
    }

    var display: String { "\(major).\(minor).\(patch)" }

    static func < (lhs: VersionInfo, rhs: VersionInfo) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}
```

**文件**: `Models/ToolStatus.swift`
```swift
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
```

**验证**: 模型可编译，版本解析测试通过

---

### Phase 3: 服务层 (P3)

#### P3-T1: Shell 命令执行器
**输入**: P2-T1
**输出**: 异步 Shell 命令执行能力

**文件**: `Services/ShellExecutor.swift`
```swift
import Foundation

actor ShellExecutor {
    enum ShellError: Error, LocalizedError {
        case commandNotFound(String)
        case executionFailed(stderr: String, exitCode: Int32)
        case timeout

        var errorDescription: String? {
            switch self {
            case .commandNotFound(let cmd): return "Command not found: \(cmd)"
            case .executionFailed(let stderr, let code): return "Exit \(code): \(stderr)"
            case .timeout: return "Command timed out"
            }
        }
    }

    func run(_ arguments: [String], timeout: Duration = .seconds(30)) async throws -> String {
        guard !arguments.isEmpty else { throw ShellError.commandNotFound("empty") }

        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        // 查找命令路径
        let executablePath = try await findExecutable(arguments[0])
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = Array(arguments.dropFirst())
        process.standardOutput = stdout
        process.standardError = stderr

        // 设置 PATH 环境变量
        var env = ProcessInfo.processInfo.environment
        let additionalPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            NSHomeDirectory() + "/.local/bin",
            NSHomeDirectory() + "/.npm-global/bin",
            NSHomeDirectory() + "/.amp/bin"
        ]
        env["PATH"] = (additionalPaths + [env["PATH"] ?? ""]).joined(separator: ":")
        process.environment = env

        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await Task.sleep(for: timeout)
                process.terminate()
                throw ShellError.timeout
            }

            group.addTask {
                try process.run()
                process.waitUntilExit()

                let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
                let output = String(decoding: outputData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
                let errorOutput = String(decoding: errorData, as: UTF8.self)

                if process.terminationStatus != 0 {
                    throw ShellError.executionFailed(stderr: errorOutput, exitCode: process.terminationStatus)
                }
                return output
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    private func findExecutable(_ name: String) async throws -> String {
        // 如果是绝对路径，直接返回
        if name.hasPrefix("/") {
            return name
        }

        let searchPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            NSHomeDirectory() + "/.local/bin",
            NSHomeDirectory() + "/.npm-global/bin",
            NSHomeDirectory() + "/.amp/bin",
            "/usr/bin"
        ]

        for path in searchPaths {
            let fullPath = "\(path)/\(name)"
            if FileManager.default.isExecutableFile(atPath: fullPath) {
                return fullPath
            }
        }

        throw ShellError.commandNotFound(name)
    }
}
```

**验证**: 可执行 `echo hello` 并获取输出

---

#### P3-T2: 版本检查服务
**输入**: P3-T1
**输出**: 检测本地版本和远程最新版本

**文件**: `Services/VersionChecker.swift`
```swift
import Foundation

actor VersionChecker {
    private let shell = ShellExecutor()

    struct CheckResult {
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
            return nil  // Droid 无公开 API
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
            // 尝试直接解析整个输出
            return VersionInfo(string: output)
        }
        return VersionInfo(string: String(output[versionRange]))
    }
}
```

**验证**: 对所有 6 个工具检查版本返回正确结果

---

#### P3-T3: 更新/安装服务
**输入**: P3-T1
**输出**: 执行更新和安装命令

**文件**: `Services/UpdateService.swift`
```swift
import Foundation

actor UpdateService {
    private let shell = ShellExecutor()

    enum OperationResult {
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
```

**验证**: 手动测试更新一个工具

---

#### P3-T4: 通知服务
**输入**: 无
**输出**: 系统通知能力

**文件**: `Services/NotificationService.swift`
```swift
import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization() async {
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            print("Notification authorization failed: \(error)")
        }
    }

    func sendUpdateComplete(tool: CLITool, newVersion: VersionInfo) {
        let content = UNMutableNotificationContent()
        content.title = "\(tool.displayName) Updated"
        content.body = "Successfully updated to v\(newVersion.display)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendInstallComplete(tool: CLITool, version: VersionInfo) {
        let content = UNMutableNotificationContent()
        content.title = "\(tool.displayName) Installed"
        content.body = "Successfully installed v\(version.display)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendError(tool: CLITool, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(tool.displayName) Error"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
```

**验证**: 可发送测试通知

---

### Phase 4: 视图模型层 (P4)

#### P4-T1: 全局应用状态
**输入**: P3-*
**输出**: 集中管理的应用状态

**文件**: `ViewModels/AppState.swift`
```swift
import Foundation
import SwiftUI

@Observable
@MainActor
final class AppState {
    var tools: [ToolStatus]
    var isChecking = false
    var lastCheckTime: Date?
    var checkInterval: TimeInterval = 3600  // 1 小时

    private let versionChecker = VersionChecker()
    private let updateService = UpdateService()
    private var checkTimer: Timer?

    init() {
        self.tools = CLITool.allCases.map { ToolStatus(tool: $0) }

        // 启动时检查
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

    deinit {
        checkTimer?.invalidate()
    }
}
```

**验证**: 应用状态正确管理所有工具状态

---

### Phase 5: UI 层 (P5)

#### P5-T1: 菜单栏主视图
**输入**: P4-T1
**输出**: 完整的菜单栏弹窗界面

**文件**: `Views/MenuBarView.swift`
```swift
import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            Divider()

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(appState.tools) { toolStatus in
                        ToolRowView(toolStatus: toolStatus)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 300)

            Divider()

            FooterView()
        }
        .frame(width: 320)
    }
}
```

**文件**: `Views/HeaderView.swift`
```swift
import SwiftUI

struct HeaderView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            Text("CLI Status")
                .font(.headline)

            Spacer()

            Button {
                Task { await appState.checkAll() }
            } label: {
                if appState.isChecking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
            .buttonStyle(.plain)
            .disabled(appState.isChecking)
            .help("Check for updates")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
```

**文件**: `Views/ToolRowView.swift`
```swift
import SwiftUI

struct ToolRowView: View {
    @Environment(AppState.self) private var appState
    @Bindable var toolStatus: ToolStatus

    var body: some View {
        HStack(spacing: 12) {
            // 工具图标和名称
            Image(systemName: "terminal")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(toolStatus.tool.displayName)
                    .font(.body.weight(.medium))

                versionText
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            actionButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
        )
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var versionText: some View {
        switch toolStatus.state {
        case .idle, .checking:
            Text("Checking...")
        case .notInstalled:
            Text("Not installed")
                .foregroundStyle(.orange)
        case .upToDate(let current):
            Text("v\(current.display)")
                .foregroundStyle(.green)
        case .updateAvailable(let current, let latest):
            HStack(spacing: 4) {
                Text("v\(current.display)")
                Image(systemName: "arrow.right")
                    .font(.caption2)
                Text("v\(latest.display)")
                    .foregroundStyle(.green)
            }
        case .updating:
            Text("Updating...")
        case .installing:
            Text("Installing...")
        case .error(let message):
            Text(message)
                .foregroundStyle(.red)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch toolStatus.state {
        case .checking, .updating, .installing:
            ProgressView()
                .controlSize(.small)
                .frame(width: 60)
        case .notInstalled:
            Button("Install") {
                Task { await appState.install(toolStatus.tool) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        case .updateAvailable:
            Button("Update") {
                Task { await appState.update(toolStatus.tool) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        case .upToDate:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .frame(width: 60)
        case .error:
            Button {
                Task { await appState.checkAll() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        case .idle:
            EmptyView()
                .frame(width: 60)
        }
    }

    private var backgroundColor: Color {
        switch toolStatus.state {
        case .updateAvailable:
            return Color.orange.opacity(0.1)
        case .error:
            return Color.red.opacity(0.1)
        default:
            return Color.clear
        }
    }
}
```

**文件**: `Views/FooterView.swift`
```swift
import SwiftUI

struct FooterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            if let lastCheck = appState.lastCheckTime {
                Text("Last check: \(lastCheck, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            SettingsLink {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 16)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
```

**验证**: UI 完整显示所有工具状态

---

#### P5-T2: 设置视图
**输入**: P5-T1
**输出**: 设置窗口

**文件**: `Views/SettingsView.swift`
```swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("checkIntervalMinutes") private var checkIntervalMinutes = 60

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                Picker("Check interval", selection: $checkIntervalMinutes) {
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("2 hours").tag(120)
                    Text("4 hours").tag(240)
                }
                .onChange(of: checkIntervalMinutes) { _, newValue in
                    appState.checkInterval = TimeInterval(newValue * 60)
                }
            }

            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 200)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }
}
```

**验证**: 设置可保存和加载

---

### Phase 6: 完善与测试 (P6)

#### P6-T1: 添加应用图标
**输入**: P5-*
**输出**: 完整的应用图标

```
操作:
1. 在 Assets.xcassets 中创建 AppIcon
2. 使用 SF Symbols "terminal.fill" 生成各尺寸图标
```

#### P6-T2: 深色模式测试
**输入**: P5-*
**输出**: 验证深色/浅色模式正常

```
验证清单:
- [ ] 浅色模式下所有文本可读
- [ ] 深色模式下所有文本可读
- [ ] 状态颜色在两种模式下都清晰
- [ ] 菜单栏图标自动适应
```

#### P6-T3: 错误处理完善
**输入**: P5-*
**输出**: 所有错误场景都有友好提示

```
测试场景:
- [ ] 工具未安装
- [ ] 网络不可用
- [ ] npm 命令不存在
- [ ] 更新命令失败
- [ ] 版本解析失败
```

---

## PBT 属性定义

| 属性 | 不变式 | 边界条件 |
|-----|-------|---------|
| 版本比较幂等性 | `a.compare(a) == .orderedSame` | 相同版本总是相等 |
| 版本比较传递性 | `if a < b && b < c then a < c` | 版本链必须有序 |
| 状态机完整性 | 每个状态都有有效转换路径 | idle → checking → (result) |
| 并发安全 | 同时多次 checkAll() 不会崩溃 | 使用 guard 防止重入 |
| 网络失败容错 | 网络失败不影响本地版本显示 | 显示缓存或 unknown |

---

## 验收清单

- [ ] 应用能在菜单栏正常显示
- [ ] 能正确检测 6 个 CLI 工具的安装状态
- [ ] 能正确显示已安装工具的当前版本
- [ ] 能正确获取 5 个工具的最新版本（Droid 除外）
- [ ] 点击 Update 按钮能正确执行更新
- [ ] 点击 Install 按钮能正确执行安装
- [ ] 更新/安装完成后发送系统通知
- [ ] 定时自动检查更新功能正常
- [ ] 设置窗口可正常打开和保存配置
- [ ] 深色/浅色模式都正常显示
