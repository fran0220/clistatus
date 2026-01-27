//
//  CLIToolsTabView.swift
//  CLIStatusApp
//
//  CLI 工具标签页视图
//  显示所有 CLI 工具列表，支持空状态提示
//

import SwiftUI

struct CLIToolsTabView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            sectionHeader
            
            Group {
                if appState.tools.isEmpty {
                    emptyStateView
                } else {
                    toolListView
                }
            }
        }
        .padding(AppSpacing.md)
    }
    
    // MARK: - 工具列表视图
    
    private var toolListView: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(appState.tools) { toolStatus in
                    ToolRowView(toolStatus: toolStatus)
                }
            }
            .padding(.vertical, AppSpacing.md)
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.08))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "terminal")
                    .font(.system(size: 32, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.brandPrimary)
            }
            
            // 文字说明
            VStack(spacing: AppSpacing.sm) {
                Text("暂无 CLI 工具")
                    .font(.appTitle2)
                    .foregroundStyle(Color.textPrimary)
                
                Text("当前没有配置任何 CLI 工具。\n请检查配置或稍后重试。")
                    .font(.appSubheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // 刷新按钮
            ActionButton("刷新", icon: "arrow.clockwise", style: .secondary, size: .medium) {
                Task { await appState.checkAll() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
    }

    private var sectionHeader: some View {
        HStack(spacing: AppSpacing.sm) {
            Text("CLI 工具")
                .font(.appTitle2)
                .foregroundStyle(Color.textPrimary)
            
            Spacer()
            
            if toolsWithUpdates > 0 {
                StatusBadge(type: .updateAvailable, text: "待更新 \(toolsWithUpdates)", size: .small)
            } else {
                StatusBadge(type: .installed, text: "已是最新", size: .small)
            }
        }
    }

    private var toolsWithUpdates: Int {
        appState.tools.filter { toolStatus in
            if case .updateAvailable = toolStatus.state {
                return true
            }
            return false
        }.count
    }
}

// MARK: - 预览

#Preview {
    CLIToolsTabView()
        .environment(AppState())
        .frame(width: 380, height: 400)
}
