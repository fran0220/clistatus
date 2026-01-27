//
//  FooterView.swift
//  CLIStatusApp
//
//  底部状态栏视图
//  显示最后检查时间、设置和退出按钮
//

import SwiftUI

struct FooterView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 最后检查时间
            lastCheckTimeView
            
            Spacer()
            
            // 操作按钮组
            HStack(spacing: AppSpacing.sm) {
                settingsButton
                
                Divider()
                    .frame(height: AppSize.Icon.md)
                
                quitButton
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .glassPanel(cornerRadius: AppCornerRadius.lg, material: .ultraThinMaterial, strokeOpacity: 0.2, highlightOpacity: 0.2, shadow: AppShadow.sm)
    }
    
    // MARK: - 子视图
    
    /// 最后检查时间视图
    @ViewBuilder
    private var lastCheckTimeView: some View {
        if let lastCheck = appState.lastCheckTime {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "clock")
                    .font(.system(size: AppSize.Icon.sm))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.textTertiary)
                
                Text("上次检查: \(lastCheck, style: .relative)")
                    .font(.appCaption2)
                    .foregroundStyle(Color.textTertiary)
            }
        } else {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "clock")
                    .font(.system(size: AppSize.Icon.sm))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.textTertiary)
                
                Text("尚未检查")
                    .font(.appCaption2)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }
    
    /// 设置按钮
    private var settingsButton: some View {
        SettingsLink {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "gear")
                    .font(.system(size: AppSize.Icon.md, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                
                Text("设置")
                    .font(.appCaption)
            }
            .foregroundStyle(Color.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.6)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    /// 退出按钮
    private var quitButton: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "power")
                    .font(.system(size: AppSize.Icon.md, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                
                Text("退出")
                    .font(.appCaption)
            }
            .foregroundStyle(Color.statusError)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .fill(Color.statusError.opacity(0.12))
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - 预览

#Preview {
    FooterView()
        .environment(AppState())
        .frame(width: 380)
}
