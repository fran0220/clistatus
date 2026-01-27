//
//  ActionButton.swift
//  CLIStatusApp
//
//  统一的操作按钮组件
//  支持 primary/secondary/destructive/ghost 样式
//

import SwiftUI

// MARK: - 按钮样式类型

/// 按钮样式枚举
enum ActionButtonStyle {
    case primary       // 主要按钮 - 品牌色填充
    case secondary     // 次要按钮 - 边框样式
    case destructive   // 危险按钮 - 红色
    case ghost         // 幽灵按钮 - 透明背景
    case success       // 成功按钮 - 绿色
    
    /// 背景样式
    var backgroundStyle: AnyShapeStyle {
        switch self {
        case .primary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.brandPrimary, .brandSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .secondary:
            return AnyShapeStyle(.ultraThinMaterial)
        case .destructive:
            return AnyShapeStyle(Color.statusError.opacity(0.9))
        case .ghost:
            return AnyShapeStyle(Color.clear)
        case .success:
            return AnyShapeStyle(Color.statusSuccess.opacity(0.9))
        }
    }
    
    /// 前景颜色
    var foregroundColor: Color {
        switch self {
        case .primary, .destructive, .success:
            return .white
        case .secondary:
            return .brandPrimary
        case .ghost:
            return .textSecondary
        }
    }
    
    /// 边框颜色
    var borderColor: Color? {
        switch self {
        case .secondary:
            return .white.opacity(0.35)
        case .ghost:
            return nil
        default:
            return nil
        }
    }
    
    /// 按压时的背景样式
    var pressedBackgroundStyle: AnyShapeStyle {
        switch self {
        case .primary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.brandPrimary.opacity(0.8), .brandSecondary.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .secondary:
            return AnyShapeStyle(.thinMaterial)
        case .destructive:
            return AnyShapeStyle(Color.statusError.opacity(0.75))
        case .ghost:
            return AnyShapeStyle(Color.white.opacity(0.08))
        case .success:
            return AnyShapeStyle(Color.statusSuccess.opacity(0.75))
        }
    }
}

// MARK: - 按钮尺寸

/// 按钮尺寸枚举
enum ActionButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return AppSize.Button.heightSm
        case .medium: return AppSize.Button.heightMd
        case .large: return AppSize.Button.heightLg
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return AppSpacing.sm
        case .medium: return AppSpacing.md
        case .large: return AppSpacing.lg
        }
    }
    
    var font: Font {
        switch self {
        case .small: return .appCaption
        case .medium: return .itemTitle
        case .large: return .appHeadline
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 14
        case .large: return 16
        }
    }
}

// MARK: - ActionButton 组件

/// 统一的操作按钮组件
struct ActionButton: View {
    let title: String
    let icon: String?
    let style: ActionButtonStyle
    let size: ActionButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    /// 初始化方法
    /// - Parameters:
    ///   - title: 按钮文本
    ///   - icon: SF Symbol 图标名称（可选）
    ///   - style: 按钮样式，默认 primary
    ///   - size: 按钮尺寸，默认 medium
    ///   - isLoading: 是否显示加载状态
    ///   - isDisabled: 是否禁用
    ///   - action: 点击回调
    init(
        _ title: String,
        icon: String? = nil,
        style: ActionButtonStyle = .primary,
        size: ActionButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: size.iconSize, height: size.iconSize)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                }
                
                Text(title)
                    .font(size.font)
                    .fontWeight(.medium)
            }
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .foregroundStyle(isDisabled ? style.foregroundColor.opacity(0.5) : style.foregroundColor)
            .background {
                RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                    .fill(isDisabled ? AnyShapeStyle(Color.white.opacity(0.08)) : style.backgroundStyle)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous))
            .overlay {
                if let borderColor = style.borderColor {
                    RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                        .stroke(isDisabled ? borderColor.opacity(0.5) : borderColor, lineWidth: 1)
                }
            }
        }
        .buttonStyle(GlassPressButtonStyle(pressedBackgroundStyle: style.pressedBackgroundStyle))
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - 自定义按钮样式

/// 缩放按钮样式 - 按压时轻微缩放
struct GlassPressButtonStyle: ButtonStyle {
    let pressedBackgroundStyle: AnyShapeStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                if configuration.isPressed {
                    RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                        .fill(pressedBackgroundStyle)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// 轻微缩放按钮样式 - 用于普通按钮和链接
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - 图标按钮组件

/// 纯图标按钮
struct IconButton: View {
    let icon: String
    let style: ActionButtonStyle
    let size: ActionButtonSize
    let action: () -> Void
    
    init(
        icon: String,
        style: ActionButtonStyle = .ghost,
        size: ActionButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .frame(width: size.height, height: size.height)
                .foregroundStyle(style.foregroundColor)
                .background {
                    RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                        .fill(style == .ghost ? AnyShapeStyle(.ultraThinMaterial) : style.backgroundStyle)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous))
                .overlay {
                    if style == .ghost {
                        RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.6)
                    }
                }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - 便捷构造器

extension ActionButton {
    /// 主要操作按钮
    static func primary(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(title, icon: icon, style: .primary, isLoading: isLoading, action: action)
    }
    
    /// 次要操作按钮
    static func secondary(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(title, icon: icon, style: .secondary, action: action)
    }
    
    /// 危险操作按钮
    static func destructive(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(title, icon: icon, style: .destructive, action: action)
    }
}

// MARK: - 预览

#Preview("Action Buttons") {
    VStack(spacing: AppSpacing.lg) {
        // 不同样式
        HStack(spacing: AppSpacing.md) {
            ActionButton.primary("更新") { }
            ActionButton.secondary("取消") { }
            ActionButton.destructive("删除") { }
        }
        
        // 带图标
        HStack(spacing: AppSpacing.md) {
            ActionButton("刷新", icon: "arrow.clockwise", style: .primary) { }
            ActionButton("复制", icon: "doc.on.doc", style: .secondary) { }
        }
        
        // 不同尺寸
        VStack(spacing: AppSpacing.sm) {
            ActionButton("Small", style: .primary, size: .small) { }
            ActionButton("Medium", style: .primary, size: .medium) { }
            ActionButton("Large", style: .primary, size: .large) { }
        }
        
        // 加载和禁用状态
        HStack(spacing: AppSpacing.md) {
            ActionButton("加载中", style: .primary, isLoading: true) { }
            ActionButton("禁用", style: .primary, isDisabled: true) { }
        }
        
        // 图标按钮
        HStack(spacing: AppSpacing.md) {
            IconButton(icon: "plus", style: .primary) { }
            IconButton(icon: "trash", style: .destructive) { }
            IconButton(icon: "gear") { }
        }
    }
    .padding()
}
