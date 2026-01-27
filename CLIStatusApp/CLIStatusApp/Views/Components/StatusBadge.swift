//
//  StatusBadge.swift
//  CLIStatusApp
//
//  统一的状态标签组件
//  支持 success/warning/error/loading/info 状态
//

import SwiftUI

// MARK: - 状态类型

/// 状态类型枚举
enum StatusType: Equatable {
    case success
    case warning
    case error
    case loading
    case info
    case installed
    case notInstalled
    case updateAvailable
    
    /// 状态颜色
    var color: Color {
        switch self {
        case .success, .installed:
            return .statusSuccess
        case .warning, .updateAvailable:
            return .statusWarning
        case .error, .notInstalled:
            return .statusError
        case .loading:
            return .statusChecking
        case .info:
            return .statusInfo
        }
    }
    
    /// 状态背景色
    var backgroundColor: Color {
        color.opacity(0.12)
    }
    
    /// 状态图标
    var iconName: String {
        switch self {
        case .success, .installed:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        case .loading:
            return "arrow.triangle.2.circlepath"
        case .info:
            return "info.circle.fill"
        case .updateAvailable:
            return "arrow.up.circle.fill"
        case .notInstalled:
            return "minus.circle.fill"
        }
    }
    
    /// 默认显示文本
    var defaultText: String {
        switch self {
        case .success:
            return "成功"
        case .warning:
            return "警告"
        case .error:
            return "错误"
        case .loading:
            return "检查中"
        case .info:
            return "信息"
        case .installed:
            return "已安装"
        case .updateAvailable:
            return "有更新"
        case .notInstalled:
            return "未安装"
        }
    }
}

// MARK: - StatusBadge 组件

/// 状态标签组件
/// 用于显示各种状态信息，支持自定义文本和样式
struct StatusBadge: View {
    let type: StatusType
    let text: String?
    let showIcon: Bool
    let size: BadgeSize
    
    /// 徽章尺寸
    enum BadgeSize {
        case small
        case medium
        case large
        
        var fontSize: Font {
            switch self {
            case .small: return .appCaption
            case .medium: return .itemSubtitle
            case .large: return .itemTitle
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return AppSpacing.xs
            case .medium: return AppSpacing.sm
            case .large: return AppSpacing.md
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return AppSpacing.xs
            case .large: return AppSpacing.sm
            }
        }
    }
    
    /// 初始化方法
    /// - Parameters:
    ///   - type: 状态类型
    ///   - text: 自定义文本，不传则使用默认文本
    ///   - showIcon: 是否显示图标，默认 true
    ///   - size: 徽章尺寸，默认 medium
    init(
        type: StatusType,
        text: String? = nil,
        showIcon: Bool = true,
        size: BadgeSize = .medium
    ) {
        self.type = type
        self.text = text
        self.showIcon = showIcon
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            if showIcon {
                iconView
            }
            
            Text(text ?? type.defaultText)
                .font(size.fontSize)
                .fontWeight(.medium)
        }
        .foregroundStyle(type.color)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background {
            RoundedRectangle(cornerRadius: AppCornerRadius.sm, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm, style: .continuous)
                        .fill(type.color.opacity(0.12))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppCornerRadius.sm, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.6)
        }
    }
    
    @ViewBuilder
    private var iconView: some View {
        if type == .loading {
            Image(systemName: type.iconName)
                .font(.system(size: size.iconSize))
                .symbolRenderingMode(.hierarchical)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear { isAnimating = true }
        } else {
            Image(systemName: type.iconName)
                .font(.system(size: size.iconSize))
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    @State private var isAnimating = false
}

// MARK: - 便捷构造器

extension StatusBadge {
    /// 成功状态徽章
    static func success(_ text: String? = nil) -> StatusBadge {
        StatusBadge(type: .success, text: text)
    }
    
    /// 警告状态徽章
    static func warning(_ text: String? = nil) -> StatusBadge {
        StatusBadge(type: .warning, text: text)
    }
    
    /// 错误状态徽章
    static func error(_ text: String? = nil) -> StatusBadge {
        StatusBadge(type: .error, text: text)
    }
    
    /// 加载中状态徽章
    static func loading(_ text: String? = nil) -> StatusBadge {
        StatusBadge(type: .loading, text: text)
    }
    
    /// 已安装状态徽章
    static func installed() -> StatusBadge {
        StatusBadge(type: .installed)
    }
    
    /// 有更新状态徽章
    static func updateAvailable() -> StatusBadge {
        StatusBadge(type: .updateAvailable)
    }
    
    /// 未安装状态徽章
    static func notInstalled() -> StatusBadge {
        StatusBadge(type: .notInstalled)
    }
}

// MARK: - 预览

#Preview("Status Badges") {
    VStack(spacing: AppSpacing.lg) {
        HStack(spacing: AppSpacing.md) {
            StatusBadge.success()
            StatusBadge.warning()
            StatusBadge.error()
        }
        
        HStack(spacing: AppSpacing.md) {
            StatusBadge.loading()
            StatusBadge(type: .info)
        }
        
        HStack(spacing: AppSpacing.md) {
            StatusBadge.installed()
            StatusBadge.updateAvailable()
            StatusBadge.notInstalled()
        }
        
        // 不同尺寸
        VStack(spacing: AppSpacing.sm) {
            StatusBadge(type: .success, text: "Small", size: .small)
            StatusBadge(type: .success, text: "Medium", size: .medium)
            StatusBadge(type: .success, text: "Large", size: .large)
        }
    }
    .padding()
}
