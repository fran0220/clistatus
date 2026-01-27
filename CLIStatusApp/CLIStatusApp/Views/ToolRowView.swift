//
//  ToolRowView.swift
//  CLIStatusApp
//
//  CLI 工具行视图
//  显示工具图标、名称、状态和操作按钮
//

import SwiftUI

struct ToolRowView: View {
    @Environment(AppState.self) private var appState
    @Bindable var toolStatus: ToolStatus
    
    var body: some View {
        ListItemCard(statusType: cardStatusType) {
            HStack(spacing: AppSpacing.md) {
                // 工具图标
                toolIcon
                
                // 工具信息
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(toolStatus.tool.displayName)
                        .font(.itemTitle)
                        .foregroundStyle(Color.textPrimary)
                    
                    versionText
                }
                
                Spacer()
                
                // 状态和操作按钮
                actionContent
            }
        }
        .padding(.horizontal, AppSpacing.sm)
    }
    
    // MARK: - 工具图标
    
    /// 工具专属图标视图
    private var toolIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                .fill(.ultraThinMaterial)
                .frame(width: AppSize.Icon.toolContainer, height: AppSize.Icon.toolContainer)
                .overlay {
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                }

            if let officialIcon = toolStatus.tool.officialIconImage {
                officialIcon
                    .resizable()
                    .scaledToFit()
                    .padding(6)
                    .frame(width: AppSize.Icon.toolContainer, height: AppSize.Icon.toolContainer)
            } else {
                Image(systemName: toolStatus.tool.iconName)
                    .font(.system(size: AppSize.Icon.lg, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(toolStatus.tool.iconColor)
            }
        }
    }
    
    // MARK: - 版本文本
    
    @ViewBuilder
    private var versionText: some View {
        switch toolStatus.state {
        case .idle, .checking:
            HStack(spacing: AppSpacing.xs) {
                ProgressView()
                    .controlSize(.mini)
                Text("检查中...")
                    .font(.itemSubtitle)
                    .foregroundStyle(Color.textTertiary)
            }
            
        case .notInstalled:
            StatusBadge.notInstalled()
            
        case .upToDate(let current):
            HStack(spacing: AppSpacing.xs) {
                Text("v\(current.display)")
                    .font(.version)
                    .foregroundStyle(Color.statusSuccess)
            }
            
        case .updateAvailable(let current, let latest):
            HStack(spacing: AppSpacing.xs) {
                Text("v\(current.display)")
                    .font(.version)
                    .foregroundStyle(Color.textSecondary)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 8, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.statusWarning)
                
                Text("v\(latest.display)")
                    .font(.version)
                    .foregroundStyle(Color.statusSuccess)
            }
            
        case .updating:
            HStack(spacing: AppSpacing.xs) {
                ProgressView()
                    .controlSize(.mini)
                Text("更新中...")
                    .font(.itemSubtitle)
                    .foregroundStyle(Color.textTertiary)
            }
            
        case .installing:
            HStack(spacing: AppSpacing.xs) {
                ProgressView()
                    .controlSize(.mini)
                Text("安装中...")
                    .font(.itemSubtitle)
                    .foregroundStyle(Color.textTertiary)
            }
            
        case .error(let message):
            Text(message)
                .font(.itemSubtitle)
                .foregroundStyle(Color.statusError)
                .lineLimit(1)
        }
    }
    
    // MARK: - 操作按钮
    
    @ViewBuilder
    private var actionContent: some View {
        switch toolStatus.state {
        case .checking, .updating, .installing:
            ProgressView()
                .controlSize(.small)
                .frame(width: 70)
                
        case .notInstalled:
            ActionButton("安装", icon: "arrow.down.circle", style: .primary, size: .small) {
                Task { await appState.install(toolStatus.tool) }
            }
            
        case .updateAvailable:
            ActionButton("更新", icon: "arrow.up.circle", style: .primary, size: .small) {
                Task { await appState.update(toolStatus.tool) }
            }
            
        case .upToDate:
            StatusBadge.installed()
            
        case .error:
            ActionButton("重试", icon: "arrow.clockwise", style: .secondary, size: .small) {
                Task { await appState.checkAll() }
            }
            
        case .idle:
            EmptyView()
                .frame(width: 70)
        }
    }
    
    // MARK: - 卡片状态类型
    
    /// 根据工具状态返回卡片状态类型
    private var cardStatusType: StatusType? {
        switch toolStatus.state {
        case .updateAvailable:
            return .updateAvailable
        case .error:
            return .error
        case .notInstalled:
            return .notInstalled
        default:
            return nil
        }
    }
}

// MARK: - 预览

#Preview {
    VStack(spacing: AppSpacing.sm) {
        // 预览需要创建模拟数据
        Text("ToolRowView Preview")
            .font(.appTitle)
    }
    .padding()
    .frame(width: 380)
}
