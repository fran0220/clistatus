//
//  SettingsView.swift
//  CLIStatusApp
//
//  设置视图
//  包含通用设置和关于信息
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("checkIntervalMinutes") private var checkIntervalMinutes = 60
    @AppStorage("autoCheckMarket") private var autoCheckMarket = true
    @AppStorage("showTabCLI") private var showTabCLI = true
    @AppStorage("showTabNpm") private var showTabNpm = true
    @AppStorage("showTabClipboard") private var showTabClipboard = true
    @AppStorage("showTabBrew") private var showTabBrew = true
    @AppStorage("showTabNpx") private var showTabNpx = true
    
    var body: some View {
        Form {
            // 通用设置区域
            generalSection

            // 标签页显示
            tabVisibilitySection
            
            // 关于信息区域
            aboutSection
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 280)
    }
    
    // MARK: - 通用设置
    
    private var generalSection: some View {
        Section {
            // 自动检测
            Toggle(isOn: $autoCheckMarket) {
                HStack(spacing: AppSpacing.md) {
                    settingIcon("waveform.path.ecg", color: .brandPrimary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("自动检测市场")
                            .font(.appHeadline)
                            .foregroundStyle(Color.textPrimary)

                        Text("按时间间隔自动检查更新")
                            .font(.appCaption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .onChange(of: autoCheckMarket) { _, newValue in
                appState.updateAutoCheckEnabled(newValue)
            }

            // 开机启动
            Toggle(isOn: $launchAtLogin) {
                HStack(spacing: AppSpacing.md) {
                    settingIcon("power", color: .statusSuccess)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("开机时启动")
                            .font(.appHeadline)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text("系统启动时自动运行 CLI Status")
                            .font(.appCaption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .onChange(of: launchAtLogin) { _, newValue in
                setLaunchAtLogin(newValue)
            }
            
            // 检查间隔
            Picker(selection: $checkIntervalMinutes) {
                Text("15 分钟").tag(15)
                Text("30 分钟").tag(30)
                Text("1 小时").tag(60)
                Text("2 小时").tag(120)
                Text("4 小时").tag(240)
            } label: {
                HStack(spacing: AppSpacing.md) {
                    settingIcon("clock.arrow.circlepath", color: .brandPrimary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("检查间隔")
                            .font(.appHeadline)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text("自动检查更新的时间间隔")
                            .font(.appCaption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .onChange(of: checkIntervalMinutes) { _, newValue in
                appState.updateCheckIntervalMinutes(newValue)
            }
        } header: {
            Text("通用")
                .font(.appTitle3)
                .foregroundStyle(Color.textSecondary)
        }
    }
    
    // MARK: - 关于信息
    
    private var aboutSection: some View {
        Section {
            // 版本信息
            HStack(spacing: AppSpacing.md) {
                settingIcon("info.circle.fill", color: .statusInfo)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("版本")
                        .font(.appHeadline)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("当前应用版本")
                        .font(.appCaption)
                        .foregroundStyle(Color.textSecondary)
                }
                
                Spacer()
                
                Text(appVersion)
                    .font(.version)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background {
                        RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                            .fill(.ultraThinMaterial)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.6)
                    }
            }
            
            // 开发者信息
            HStack(spacing: AppSpacing.md) {
                settingIcon("person.fill", color: .brandSecondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("开发者")
                        .font(.appHeadline)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("CLI Status 开发团队")
                        .font(.appCaption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        } header: {
            Text("关于")
                .font(.appTitle3)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - 标签页显示

    private var tabVisibilitySection: some View {
        Section {
            Toggle("CLI 工具", isOn: $showTabCLI)
                .onChange(of: showTabCLI) { _, _ in ensureAtLeastOneTabVisible() }
            Toggle("NPM 包", isOn: $showTabNpm)
                .onChange(of: showTabNpm) { _, _ in ensureAtLeastOneTabVisible() }
            Toggle("剪贴板", isOn: $showTabClipboard)
                .onChange(of: showTabClipboard) { _, _ in ensureAtLeastOneTabVisible() }
            Toggle("Brew 包", isOn: $showTabBrew)
                .onChange(of: showTabBrew) { _, _ in ensureAtLeastOneTabVisible() }
            Toggle("NPX 包", isOn: $showTabNpx)
                .onChange(of: showTabNpx) { _, _ in ensureAtLeastOneTabVisible() }
        } header: {
            Text("标签页显示")
                .font(.appTitle3)
                .foregroundStyle(Color.textSecondary)
        } footer: {
            Text("至少保留一个标签页可见")
                .font(.appCaption2)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private func ensureAtLeastOneTabVisible() {
        if !(showTabCLI || showTabNpm || showTabClipboard || showTabBrew || showTabNpx) {
            showTabCLI = true
        }
    }
    
    // MARK: - 辅助视图
    
    /// 创建设置图标
    private func settingIcon(_ name: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                .fill(.ultraThinMaterial)
                .frame(width: 28, height: 28)
                .overlay {
                    RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                        .stroke(color.opacity(0.35), lineWidth: 1)
                }
            
            Image(systemName: name)
                .font(.system(size: AppSize.Icon.md, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
        }
    }
    
    // MARK: - 计算属性
    
    /// 应用版本号
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    // MARK: - 方法
    
    /// 设置开机启动
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

// MARK: - 预览

#Preview {
    SettingsView()
}
