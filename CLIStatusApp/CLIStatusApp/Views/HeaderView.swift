//
//  HeaderView.swift
//  CLIStatusApp
//
//  顶部标题栏视图
//  显示应用标题和刷新按钮
//

import SwiftUI

struct HeaderView: View {
    @Environment(AppState.self) private var appState
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 应用图标和标题
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.18))
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: "terminal.fill")
                        .font(.system(size: AppSize.Icon.md, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.brandPrimary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("CLI Status")
                        .font(.appTitle)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("更新与版本概览")
                        .font(.appCaption2)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            Spacer()
            
            // 刷新按钮
            Button {
                Task { await appState.checkAll() }
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: AppSize.Icon.md, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .rotationEffect(.degrees(rotationAngle))
                    
                    Text(appState.isChecking ? "检查中" : "刷新")
                        .font(.appCaption)
                }
                .foregroundStyle(appState.isChecking ? Color.textTertiary : Color.brandPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background {
                    RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.6)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(appState.isChecking)
            .help("检查所有工具更新")
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .glassPanel(cornerRadius: AppCornerRadius.lg, material: .ultraThinMaterial, strokeOpacity: 0.2, highlightOpacity: 0.2, shadow: AppShadow.sm)
        .onChange(of: appState.isChecking) { _, isChecking in
            if isChecking {
                startRefreshAnimation()
            } else {
                stopRefreshAnimation()
            }
        }
    }
    
    // MARK: - 动画方法
    
    /// 开始刷新旋转动画
    private func startRefreshAnimation() {
        withAnimation(
            .linear(duration: 1.0)
            .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
    
    /// 停止刷新动画
    private func stopRefreshAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            rotationAngle = 0
        }
    }
}

// MARK: - 预览

#Preview {
    HeaderView()
        .environment(AppState())
        .frame(width: 380)
}
