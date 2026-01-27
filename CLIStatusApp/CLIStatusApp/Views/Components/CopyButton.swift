//
//  CopyButton.swift
//  CLIStatusApp
//
//  一键复制按钮组件
//  点击后复制内容到剪贴板，并显示成功反馈
//

import SwiftUI
import AppKit

// MARK: - 按钮尺寸

/// 复制按钮尺寸枚举
enum CopyButtonSize {
    case small      // 小尺寸
    case medium     // 中尺寸
    case large      // 大尺寸
    
    /// 图标大小
    var iconSize: CGFloat {
        switch self {
        case .small: return AppSize.Icon.sm
        case .medium: return AppSize.Icon.md
        case .large: return AppSize.Icon.lg
        }
    }
    
    /// 按钮内边距
    var padding: CGFloat {
        switch self {
        case .small: return AppSpacing.xs
        case .medium: return AppSpacing.sm
        case .large: return AppSpacing.md
        }
    }
    
    /// 按钮尺寸
    var buttonSize: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 32
        case .large: return 40
        }
    }
}

// MARK: - 复制按钮

/// 一键复制按钮组件
/// 点击后复制内容到系统剪贴板，并显示成功反馈
struct CopyButton: View {
    
    // MARK: - 属性
    
    /// 要复制的内容
    let content: String
    
    /// 按钮尺寸
    let size: CopyButtonSize
    
    /// 自定义复制回调（提供时将跳过默认剪贴板写入）
    let onCopy: (() -> Void)?
    
    /// 是否已复制状态
    @State private var isCopied = false
    
    /// 悬浮状态
    @State private var isHovered = false
    
    // MARK: - 初始化
    
    /// 初始化复制按钮
    /// - Parameters:
    ///   - content: 要复制的内容
    ///   - size: 按钮尺寸，默认为 medium
    ///   - onCopy: 自定义复制回调（提供时将跳过默认剪贴板写入）
    init(
        content: String,
        size: CopyButtonSize = .medium,
        onCopy: (() -> Void)? = nil
    ) {
        self.content = content
        self.size = size
        self.onCopy = onCopy
    }
    
    // MARK: - 视图
    
    var body: some View {
        Button {
            copyToClipboard()
        } label: {
            ZStack {
                // 复制图标
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: size.iconSize, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(iconColor)
            }
            .frame(width: size.buttonSize, height: size.buttonSize)
            .background {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .fill(copyFillStyle)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .stroke(isCopied ? Color.statusSuccess.opacity(0.35) : Color.white.opacity(isHovered ? 0.35 : 0.2), lineWidth: 0.6)
            }
        }
        .buttonStyle(.plain)
        .help(isCopied ? "已复制" : "复制到剪贴板")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCopied)
    }
    
    // MARK: - 计算属性
    
    /// 图标颜色
    private var iconColor: Color {
        if isCopied {
            return .statusSuccess
        }
        return isHovered ? .brandPrimary : .textSecondary
    }

    private var copyFillStyle: AnyShapeStyle {
        if isCopied {
            return AnyShapeStyle(Color.statusSuccess.opacity(0.16))
        }
        return AnyShapeStyle(.ultraThinMaterial)
    }
    
    // MARK: - 方法
    
    /// 复制内容到剪贴板
    private func copyToClipboard() {
        // 设置已复制状态
        withAnimation {
            isCopied = true
        }
        
        if let onCopy = onCopy {
            onCopy()
        } else {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(content, forType: .string)
        }
        
        // 2 秒后恢复原状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

// MARK: - 带标签的复制按钮

/// 带文字标签的复制按钮
struct CopyButtonWithLabel: View {
    let content: String
    let label: String
    let size: CopyButtonSize
    let onCopy: (() -> Void)?
    
    @State private var isCopied = false
    @State private var isHovered = false
    
    init(
        content: String,
        label: String = "复制",
        size: CopyButtonSize = .medium,
        onCopy: (() -> Void)? = nil
    ) {
        self.content = content
        self.label = label
        self.size = size
        self.onCopy = onCopy
    }
    
    var body: some View {
        Button {
            copyToClipboard()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: size.iconSize, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                
                Text(isCopied ? "已复制" : label)
                    .font(.appCaption)
            }
            .foregroundStyle(isCopied ? Color.statusSuccess : (isHovered ? Color.brandPrimary : Color.textSecondary))
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, size.padding)
            .background {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .fill(copyFillStyle)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .stroke(isCopied ? Color.statusSuccess.opacity(0.35) : Color.white.opacity(isHovered ? 0.35 : 0.2), lineWidth: 0.6)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCopied)
    }
    
    private func copyToClipboard() {
        withAnimation {
            isCopied = true
        }
        
        if let onCopy = onCopy {
            onCopy()
        } else {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(content, forType: .string)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }

    private var copyFillStyle: AnyShapeStyle {
        if isCopied {
            return AnyShapeStyle(Color.statusSuccess.opacity(0.16))
        }
        return AnyShapeStyle(.ultraThinMaterial)
    }
}

// MARK: - 预览

#Preview("Copy Button Sizes") {
    VStack(spacing: AppSpacing.lg) {
        HStack(spacing: AppSpacing.lg) {
            VStack {
                CopyButton(content: "Small", size: .small)
                Text("Small").font(.appCaption)
            }
            
            VStack {
                CopyButton(content: "Medium", size: .medium)
                Text("Medium").font(.appCaption)
            }
            
            VStack {
                CopyButton(content: "Large", size: .large)
                Text("Large").font(.appCaption)
            }
        }
        
        Divider()
        
        HStack(spacing: AppSpacing.lg) {
            CopyButtonWithLabel(content: "Test content", size: .small)
            CopyButtonWithLabel(content: "Test content", size: .medium)
            CopyButtonWithLabel(content: "Test content", size: .large)
        }
    }
    .padding()
}
