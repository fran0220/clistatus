//
//  MenuBarView.swift
//  CLIStatusApp
//
//  菜单栏主视图
//  包含顶部标题、Tab 切换和内容区域
//

import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("showTabCLI") private var showTabCLI = true
    @AppStorage("showTabNpm") private var showTabNpm = true
    @AppStorage("showTabClipboard") private var showTabClipboard = true
    @AppStorage("showTabBrew") private var showTabBrew = true
    @AppStorage("showTabNpx") private var showTabNpx = true
    @State private var selectedTab: MainTab = .cli
    @Namespace private var tabSelection
    
    var body: some View {
        ZStack {
            GlassBackgroundView()
            
            VStack(spacing: AppSpacing.md) {
                // 顶部标题栏
                HeaderView()
                
                // Tab 切换器
                tabPicker
                
                // 内容区域
                tabContent
                    .frame(height: 520)
                    .glassPanel(
                        cornerRadius: AppCornerRadius.lg,
                        material: .ultraThinMaterial,
                        strokeOpacity: 0.2,
                        highlightOpacity: 0.25,
                        shadow: AppShadow.md
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
                
                // 底部状态栏
                FooterView()
            }
            .padding(AppSpacing.md)
        }
        .frame(width: 392)
        .onAppear {
            ensureSelectedTabVisible()
        }
        .onChange(of: visibleTabs) { _, _ in
            ensureSelectedTabVisible()
        }
    }
    
    // MARK: - Tab 切换器
    
    private var tabPicker: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(visibleTabs) { tab in
                tabButton(
                    title: tab.title,
                    icon: tab.icon,
                    tab: tab,
                    badgeCount: tab.badgeCount(
                        tools: toolsWithUpdates,
                        npm: packagesWithUpdates,
                        clipboard: clipboardItemCount,
                        brew: brewPackagesWithUpdates,
                        npx: npxPackagesWithUpdates
                    )
                )
            }
        }
        .padding(AppSpacing.xs)
        .glassPanel(
            cornerRadius: AppCornerRadius.full,
            material: .ultraThinMaterial,
            strokeOpacity: 0.2,
            highlightOpacity: 0.3,
            shadow: AppShadow.sm
        )
    }
    
    /// 创建单个 Tab 按钮
    private func tabButton(title: String, icon: String, tab: MainTab, badgeCount: Int) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: AppSize.Icon.sm, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .symbolVariant(isSelected ? .fill : .none)
                
                Text(title)
                    .font(.appHeadline)
                
                // 更新数量徽章
                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.appCaption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(Color.statusWarning)
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .foregroundStyle(isSelected ? Color.brandPrimary : Color.textSecondary)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: AppCornerRadius.full, style: .continuous)
                        .fill(Color.white.opacity(0.3))
                        .matchedGeometryEffect(id: "tabSelection", in: tabSelection)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tab 内容区域
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .cli:
            CLIToolsTabView()
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        case .npm:
            NpmPackagesTabView()
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        case .clipboard:
            ClipboardTabView()
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        case .brew:
            BrewPackagesTabView()
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        case .npx:
            NpxPackagesTabView()
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
    
    // MARK: - 计算属性
    
    /// 有更新的工具数量
    private var toolsWithUpdates: Int {
        appState.tools.filter { toolStatus in
            if case .updateAvailable = toolStatus.state {
                return true
            }
            return false
        }.count
    }
    
    /// 有更新的包数量
    private var packagesWithUpdates: Int {
        appState.npmPackages.filter { package in
            if case .updateAvailable = package.state {
                return true
            }
            return false
        }.count
    }
    
    /// 剪贴板项数量
    private var clipboardItemCount: Int {
        appState.clipboardService.totalCount
    }

    /// 有更新的 Brew 包数量
    private var brewPackagesWithUpdates: Int {
        appState.brewPackages.filter { package in
            if case .updateAvailable = package.state {
                return true
            }
            return false
        }.count
    }

    /// 有更新的 NPX 包数量
    private var npxPackagesWithUpdates: Int {
        appState.npxPackages.filter { package in
            if case .updateAvailable = package.state {
                return true
            }
            return false
        }.count
    }

    private var visibleTabs: [MainTab] {
        var tabs: [MainTab] = []
        if showTabCLI { tabs.append(.cli) }
        if showTabNpm { tabs.append(.npm) }
        if showTabClipboard { tabs.append(.clipboard) }
        if showTabBrew { tabs.append(.brew) }
        if showTabNpx { tabs.append(.npx) }
        return tabs.isEmpty ? [.cli] : tabs
    }

    private func ensureSelectedTabVisible() {
        guard !visibleTabs.contains(selectedTab) else { return }
        if let first = visibleTabs.first {
            selectedTab = first
        }
    }
}

private enum MainTab: Int, CaseIterable, Identifiable {
    case cli
    case npm
    case clipboard
    case brew
    case npx

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .cli: return "CLI 工具"
        case .npm: return "NPM 包"
        case .clipboard: return "剪贴板"
        case .brew: return "Brew 包"
        case .npx: return "NPX 包"
        }
    }

    var icon: String {
        switch self {
        case .cli: return "terminal"
        case .npm: return "shippingbox"
        case .clipboard: return "doc.on.clipboard"
        case .brew: return "cup.and.saucer"
        case .npx: return "terminal.fill"
        }
    }

    func badgeCount(tools: Int, npm: Int, clipboard: Int, brew: Int, npx: Int) -> Int {
        switch self {
        case .cli: return tools
        case .npm: return npm
        case .clipboard: return clipboard
        case .brew: return brew
        case .npx: return npx
        }
    }
}

// MARK: - 预览

#Preview {
    MenuBarView()
        .environment(AppState())
}
