//
//  ClipboardItemRow.swift
//  CLIStatusApp
//
//  剪贴板项行视图
//  显示标题、内容预览、分类标签，支持复制和右键菜单
//

import SwiftUI

// MARK: - 剪贴板项行视图

/// 剪贴板项行视图
/// 使用 ListItemCard 作为容器，显示项目信息并支持操作
struct ClipboardItemRow: View {
    
    // MARK: - 属性
    
    /// 剪贴板项数据
    let item: ClipboardItem
    
    /// 复制回调
    let onCopy: () -> Void
    
    /// 编辑回调
    let onEdit: () -> Void
    
    /// 删除回调
    let onDelete: () -> Void
    
    /// 悬浮状态
    @State private var isHovered = false
    
    // MARK: - 视图
    
    var body: some View {
        ListItemCard {
            HStack(spacing: AppSpacing.md) {
                // 分类图标
                categoryIcon
                
                // 内容区域
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    // 标题行
                    titleRow
                    
                    // 内容预览
                    contentPreview
                }
                
                Spacer(minLength: 0)
                
                // 操作按钮
                actionButtons
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            contextMenuContent
        }
    }
    
    // MARK: - 子视图
    
    /// 分类图标
    private var categoryIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(width: AppSize.Icon.toolContainer, height: AppSize.Icon.toolContainer)
                .overlay {
                    RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                        .stroke(item.category.color.opacity(0.35), lineWidth: 1)
                }
            
            Image(systemName: item.category.iconName)
                .font(.system(size: AppSize.Icon.md, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(item.category.color)
        }
    }
    
    /// 标题行
    private var titleRow: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(item.title)
                .font(.itemTitle)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            
            // 分类标签
            categoryBadge
        }
    }
    
    /// 分类标签
    private var categoryBadge: some View {
        Text(item.category.displayName)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(item.category.color)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, 2)
            .background {
                Capsule()
                    .fill(Color.white.opacity(0.25))
            }
    }
    
    /// 内容预览
    private var contentPreview: some View {
        Text(item.contentPreview)
            .font(.appCaption)
            .foregroundStyle(Color.textSecondary)
            .lineLimit(2)
    }
    
    /// 操作按钮
    private var actionButtons: some View {
        HStack(spacing: AppSpacing.xs) {
            // 使用次数（如果大于 0）
            if item.useCount > 0 {
                Text("\(item.useCount)")
                    .font(.appCaption)
                    .foregroundStyle(Color.textTertiary)
                    .opacity(isHovered ? 1 : 0.6)
            }
            
            // 复制按钮
            CopyButton(content: item.content, size: .small) {
                onCopy()
            }
            .opacity(isHovered ? 1 : 0.6)
        }
    }
    
    /// 右键菜单内容
    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            onCopy()
        } label: {
            Label("复制", systemImage: "doc.on.doc")
        }
        
        Button {
            onEdit()
        } label: {
            Label("编辑", systemImage: "pencil")
        }
        
        Divider()
        
        Button(role: .destructive) {
            onDelete()
        } label: {
            Label("删除", systemImage: "trash")
        }
    }
}

// MARK: - 紧凑型剪贴板项行

/// 紧凑型剪贴板项行视图
/// 用于更简洁的列表显示
struct ClipboardItemRowCompact: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // 分类图标
            Image(systemName: item.category.iconName)
                .font(.system(size: AppSize.Icon.sm, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(item.category.color)
                .frame(width: 20)
            
            // 标题
            Text(item.title)
                .font(.itemTitle)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            
            Spacer(minLength: 0)
            
            // 复制按钮
            CopyButton(content: item.content, size: .small) {
                onCopy()
            }
            .opacity(isHovered ? 1 : 0.3)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background {
            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                .fill(isHovered ? Color.surfaceSecondary : Color.clear)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button { onCopy() } label: {
                Label("复制", systemImage: "doc.on.doc")
            }
            Button { onEdit() } label: {
                Label("编辑", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) { onDelete() } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// MARK: - 预览

#Preview("Clipboard Item Row") {
    VStack(spacing: AppSpacing.md) {
        ForEach(ClipboardItem.examples) { item in
            ClipboardItemRow(
                item: item,
                onCopy: { print("Copy: \(item.title)") },
                onEdit: { print("Edit: \(item.title)") },
                onDelete: { print("Delete: \(item.title)") }
            )
        }
    }
    .padding()
    .frame(width: 380)
}

#Preview("Clipboard Item Row Compact") {
    VStack(spacing: AppSpacing.xs) {
        ForEach(ClipboardItem.examples) { item in
            ClipboardItemRowCompact(
                item: item,
                onCopy: { print("Copy: \(item.title)") },
                onEdit: { print("Edit: \(item.title)") },
                onDelete: { print("Delete: \(item.title)") }
            )
        }
    }
    .padding()
    .frame(width: 380)
}
