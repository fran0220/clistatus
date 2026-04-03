import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("checkIntervalMinutes") private var checkIntervalMinutes = 60
    @AppStorage("autoCheckMarket") private var autoCheckMarket = true

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

            Section("关于") {
                LabeledContent("版本", value: appVersion)
                LabeledContent("开发者", value: "CLI Status")
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 240)
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
}
