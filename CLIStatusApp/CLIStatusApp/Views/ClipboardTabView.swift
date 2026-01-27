//
//  ClipboardTabView.swift
//  CLIStatusApp
//
//  剪贴板 Tab 主视图
//  包含搜索栏、分类筛选器、列表和编辑功能
//

import SwiftUI

// MARK: - 剪贴板 Tab 视图

/// 剪贴板 Tab 主视图
struct ClipboardTabView: View {
    
    // MARK: - 属性
    
    @Environment(AppState.self) private var appState
    
    /// 搜索关键词
    @State private var searchText = ""
    
    /// 选中的分类（nil 表示全部）
    @State private var selectedCategory: ClipboardCategory?
    
    /// 是否显示编辑器
    @State private var showEditor = false
    
    /// 编辑器模式
    @State private var editorMode: ClipboardEditorMode = .create
    
    /// 要编辑的项目
    @State private var editingItem: ClipboardItem?
    
    // MARK: - 视图
    
    var body: some View {
        let items = filteredItems
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: AppSpacing.md) {
                    sectionHeader
                    
                    // 搜索栏和添加按钮
                    searchBar
                    
                    // 分类筛选器
                    categoryFilter
                    
                    // 列表内容
                    if items.isEmpty {
                        emptyStateView
                    } else {
                        itemsList(items)
                    }
                }
                .padding(AppSpacing.md)
            }
            
            if showEditor {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showEditor = false
                    }
                
                ClipboardItemEditorView(
                    mode: editorMode,
                    item: editingItem,
                    onSave: { item in
                        handleSave(item)
                    },
                    onCancel: {
                        showEditor = false
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
                .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 8)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showEditor)
    }
    
    // MARK: - 子视图
    
    /// 搜索栏
    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            // 搜索输入框
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: AppSize.Icon.sm))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.textTertiary)
                
                TextField("搜索剪贴板...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.appBody)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: AppSize.Icon.sm))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
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
            
            // 添加按钮
            Button {
                editorMode = .create
                editingItem = nil
                showEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: AppSize.Icon.md, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 32, height: 32)
                    .background {
                        RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                            .fill(.ultraThinMaterial)
                    }
            }
            .buttonStyle(.plain)
            .help("添加新项")
        }
    }
    
    /// 分类筛选器
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                // 全部分类
                categoryFilterButton(nil, title: "全部", count: appState.clipboardService.totalCount)
                
                // 各个分类
                ForEach(ClipboardCategory.allCases) { category in
                    categoryFilterButton(
                        category,
                        title: category.displayName,
                        count: appState.clipboardService.countByCategory[category] ?? 0
                    )
                }
            }
            .padding(.vertical, AppSpacing.xs)
        }
    }
    
    /// 分类筛选按钮
    private func categoryFilterButton(_ category: ClipboardCategory?, title: String, count: Int) -> some View {
        let isSelected = selectedCategory == category
        let buttonColor = category?.color ?? Color.brandPrimary
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if let cat = category {
                    Image(systemName: cat.iconName)
                        .font(.system(size: AppSize.Icon.sm))
                }
                
                Text(title)
                    .font(.appCaption)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background {
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : buttonColor.opacity(0.2))
                        }
                }
            }
            .foregroundStyle(isSelected ? .white : buttonColor)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background {
                Capsule()
                    .fill(isSelected ? buttonColor : Color.white.opacity(0.25))
            }
        }
        .buttonStyle(.plain)
    }
    
    /// 项目列表
    private func itemsList(_ items: [ClipboardItem]) -> some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(items) { item in
                    ClipboardItemRow(
                        item: item,
                        onCopy: {
                            appState.copyClipboardItem(item)
                        },
                        onEdit: {
                            editorMode = .edit
                            editingItem = item
                            showEditor = true
                        },
                        onDelete: {
                            appState.deleteClipboardItem(id: item.id)
                        }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(Color.textTertiary)
            
            VStack(spacing: AppSpacing.xs) {
                Text(emptyStateTitle)
                    .font(.appHeadline)
                    .foregroundStyle(Color.textPrimary)
                
                Text(emptyStateMessage)
                    .font(.appCaption)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if !hasAnyItems {
                Button {
                    editorMode = .create
                    editingItem = nil
                    showEditor = true
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "plus")
                            .symbolRenderingMode(.hierarchical)
                        Text("添加第一个项目")
                    }
                    .font(.appBody)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background {
                        RoundedRectangle(cornerRadius: AppCornerRadius.md)
                            .fill(Color.brandPrimary)
                    }
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.lg)
    }
    
    // MARK: - 计算属性
    
    /// 筛选后的项目列表
    private var filteredItems: [ClipboardItem] {
        appState.clipboardService.filterItems(category: selectedCategory, keyword: searchText)
    }
    
    /// 是否有任何项目
    private var hasAnyItems: Bool {
        appState.clipboardService.totalCount > 0
    }
    
    /// 空状态标题
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "未找到匹配项"
        } else if selectedCategory != nil {
            return "该分类为空"
        } else {
            return "暂无剪贴板项"
        }
    }
    
    /// 空状态消息
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "尝试使用其他关键词搜索"
        } else if selectedCategory != nil {
            return "此分类下暂无内容\n点击 + 按钮添加"
        } else {
            return "保存常用的代码、命令和链接\n方便随时复制使用"
        }
    }
    
    // MARK: - 方法
    
    /// 处理保存
    private func handleSave(_ item: ClipboardItem) {
        if editorMode == .create {
            appState.addClipboardItem(item)
        } else {
            appState.updateClipboardItem(item)
        }
        showEditor = false
    }

    private var sectionHeader: some View {
        HStack(spacing: AppSpacing.sm) {
            Text("剪贴板")
                .font(.appTitle2)
                .foregroundStyle(Color.textPrimary)
            
            Spacer()
            
            if hasAnyItems {
                StatusBadge(type: .info, text: "共 \(appState.clipboardService.totalCount) 项", size: .small)
            } else {
                StatusBadge(type: .notInstalled, text: "尚无内容", size: .small)
            }
        }
    }
}

// MARK: - 预览

#Preview {
    ClipboardTabView()
        .environment(AppState())
        .frame(width: 380, height: 500)
}
