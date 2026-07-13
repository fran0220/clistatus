import SwiftUI
import AppKit
import ServiceManagement

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("checkIntervalMinutes") private var checkIntervalMinutes = 60
    @AppStorage("autoCheckMarket") private var autoCheckMarket = true
    @AppStorage("processAutoRefreshEnabled") private var processAutoRefreshEnabled = true

    var body: some View {
        Form {
            Section("通用") {
                Toggle("自动检测更新", isOn: $autoCheckMarket)
                    .onChange(of: autoCheckMarket) { _, newValue in
                        appState.updateAutoCheckEnabled(newValue)
                    }

                Toggle("开机时启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                Picker("检查间隔", selection: $checkIntervalMinutes) {
                    Text("15 分钟").tag(15)
                    Text("30 分钟").tag(30)
                    Text("1 小时").tag(60)
                    Text("2 小时").tag(120)
                    Text("4 小时").tag(240)
                }
                .onChange(of: checkIntervalMinutes) { _, newValue in
                    appState.updateCheckIntervalMinutes(newValue)
                }
            }

            Section("性能监视") {
                Toggle("自动刷新进程", isOn: $processAutoRefreshEnabled)
                    .onChange(of: processAutoRefreshEnabled) { _, newValue in
                        appState.updateProcessAutoRefreshEnabled(newValue)
                    }
                Text("打开性能页时约每 4 秒刷新一次系统占用。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Finder 扩展") {
                Text("将 cliadmin 安装到「应用程序」并启动一次后，在 Finder 中选中文件即可在右键菜单直接使用：")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("• cliadmin 剪切\n• cliadmin 拷贝路径\n• cliadmin 彻底删除")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("若菜单未出现，请到「系统设置 → 隐私与安全性 → 扩展 → 访达扩展」中开启 cliadmin。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("打开访达扩展设置") {
                    openFinderExtensionsSettings()
                }
            }

            Section("关于") {
                LabeledContent("版本", value: appVersion)
                LabeledContent("开发者", value: "CLI Status")
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 420)
        .onAppear {
            processAutoRefreshEnabled = appState.processAutoRefreshEnabled
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("设置开机启动失败: \(error)")
        }
    }

    private func openFinderExtensionsSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.FinderSync",
            "x-apple.systempreferences:com.apple.ExtensionsPreferences",
            "x-apple.systempreferences:com.apple.preference.security?Privacy"
        ]
        for raw in candidates {
            if let url = URL(string: raw), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
