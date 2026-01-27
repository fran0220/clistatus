//
//  Card.swift
//  CLIStatusApp
//
//  卡片容器组件
//  提供统一的圆角、阴影、背景样式
//

import SwiftUI

// MARK: - 卡片样式

/// 卡片样式枚举
enum CardStyle {
    case plain         // 普通卡片 - 无背景
    case filled        // 填充卡片 - 有背景色
    case bordered      // 边框卡片 - 有边框
    case elevated      // 浮起卡片 - 有阴影
    
    /// 是否显示背景
    var hasBackground: Bool {
        switch self {
        case .plain: return false
        case .filled, .bordered, .elevated: return true
        }
    }
    
    /// 是否显示边框
    var hasBorder: Bool {
        switch self {
        case .bordered: return true
        default: return false
        }
    }
    
    /// 是否显示阴影
    var hasShadow: Bool {
        switch self {
        case .elevated: return true
        default: return false
        }
    }
}

// MARK: - Card 组件

/// 卡片容器组件
/// 用于包裹内容，提供统一的视觉风格
struct Card<Content: View>: View {
    let style: CardStyle
    let cornerRadius: CGFloat
    let padding: CGFloat
    let backgroundColor: Color
    @ViewBuilder let content: () -> Content
    
    /// 初始化方法
    /// - Parameters:
    ///   - style: 卡片样式，默认 filled
    ///   - cornerRadius: 圆角大小，默认使用设计规范
    ///   - padding: 内边距，默认使用设计规范
    ///   - backgroundColor: 背景色，默认使用设计规范
    ///   - content: 卡片内容
    init(
        style: CardStyle = .filled,
        cornerRadius: CGFloat = AppCornerRadius.md,
        padding: CGFloat = AppSpacing.md,
        backgroundColor: Color = .surfacePrimary,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.content = content
    }
    
    var body: some View {
        let baseContent = content()
            .padding(padding)

        switch style {
        case .plain:
            baseContent
        case .filled:
            baseContent
                .glassPanel(
                    cornerRadius: cornerRadius,
                    material: .ultraThinMaterial,
                    strokeOpacity: 0.18,
                    highlightOpacity: 0.22,
                    shadow: AppShadow.sm
                )
        case .bordered:
            baseContent
                .glassPanel(
                    cornerRadius: cornerRadius,
                    material: .thinMaterial,
                    strokeOpacity: 0.28,
                    highlightOpacity: 0.18,
                    shadow: AppShadow.sm
                )
        case .elevated:
            baseContent
                .glassPanel(
                    cornerRadius: cornerRadius,
                    material: .regularMaterial,
                    strokeOpacity: 0.2,
                    highlightOpacity: 0.25,
                    shadow: AppShadow.lg
                )
        }
    }
}

// MARK: - 状态卡片

/// 带状态指示的卡片
struct StatusCard<Content: View>: View {
    let statusType: StatusType?
    let cornerRadius: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(
        statusType: StatusType? = nil,
        cornerRadius: CGFloat = AppCornerRadius.md,
        padding: CGFloat = AppSpacing.md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.statusType = statusType
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(padding)
            .glassPanel(
                cornerRadius: cornerRadius,
                material: .ultraThinMaterial,
                strokeOpacity: statusType != nil ? 0.28 : 0.18,
                highlightOpacity: 0.22,
                shadow: AppShadow.sm
            )
            .overlay(alignment: .leading) {
                if let status = statusType {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(status.color.opacity(0.35))
                        .frame(width: 3)
                        .padding(.vertical, 6)
                }
            }
    }
    
}

// MARK: - 列表项卡片

/// 专用于列表项的卡片样式
struct ListItemCard<Content: View>: View {
    let isHovered: Bool
    let statusType: StatusType?
    @ViewBuilder let content: () -> Content
    
    @State private var isHovering = false
    
    init(
        isHovered: Bool = false,
        statusType: StatusType? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isHovered = isHovered
        self.statusType = statusType
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .glassPanel(
                cornerRadius: AppCornerRadius.lg,
                material: .ultraThinMaterial,
                strokeOpacity: isHovering ? 0.32 : 0.2,
                highlightOpacity: isHovering ? 0.3 : 0.2,
                shadow: isHovering ? AppShadow.md : AppShadow.sm
            )
            .overlay(alignment: .leading) {
                if let status = statusType {
                    RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous)
                        .fill(status.color.opacity(0.35))
                        .frame(width: 3)
                        .padding(.vertical, 6)
                }
            }
            .scaleEffect(isHovering ? 1.01 : 1.0)
            .onHover { hovering in
                isHovering = hovering
            }
            .animation(.easeInOut(duration: 0.18), value: isHovering)
    }
    
}

// MARK: - View 条件修饰器扩展

extension View {
    /// 条件性应用修饰器
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - 预览

#Preview("Cards") {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            // 不同样式的卡片
            Group {
                Card(style: .plain) {
                    Text("Plain Card - 无背景")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Card(style: .filled) {
                    Text("Filled Card - 有背景")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Card(style: .bordered) {
                    Text("Bordered Card - 有边框")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Card(style: .elevated) {
                    Text("Elevated Card - 有阴影")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Divider()
            
            // 状态卡片
            Group {
                StatusCard(statusType: .success) {
                    HStack {
                        Text("成功状态卡片")
                        Spacer()
                        StatusBadge.success()
                    }
                }
                
                StatusCard(statusType: .warning) {
                    HStack {
                        Text("警告状态卡片")
                        Spacer()
                        StatusBadge.warning()
                    }
                }
                
                StatusCard(statusType: .error) {
                    HStack {
                        Text("错误状态卡片")
                        Spacer()
                        StatusBadge.error()
                    }
                }
            }
            
            Divider()
            
            // 列表项卡片
            Group {
                ListItemCard {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.toolClaudeCode)
                        Text("Claude Code")
                            .font(.itemTitle)
                        Spacer()
                        Text("v0.2.3")
                            .font(.version)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                ListItemCard(statusType: .updateAvailable) {
                    HStack {
                        Image(systemName: "diamond.fill")
                            .foregroundStyle(Color.toolGeminiCLI)
                        Text("Gemini CLI")
                            .font(.itemTitle)
                        Spacer()
                        StatusBadge.updateAvailable()
                    }
                }
            }
        }
        .padding()
    }
}
