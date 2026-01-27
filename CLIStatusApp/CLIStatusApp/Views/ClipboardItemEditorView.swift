//
//  ClipboardItemEditorView.swift
//  CLIStatusApp
//
//  剪贴板项编辑弹窗
//  支持新增和编辑模式，包含表单验证
//

import SwiftUI

// MARK: - 编辑器模式

/// 编辑器模式枚举
enum ClipboardEditorMode {
    case create     // 新增模式
    case edit       // 编辑模式
    
    var title: String {
        switch self {
        case .create: return "新建剪贴板项"
        case .edit: return "编辑剪贴板项"
        }
    }
    
    var confirmButtonText: String {
        switch self {
        case .create: return "创建"
        case .edit: return "保存"
        }
    }
}

// MARK: - 剪贴板项编辑器视图

/// 剪贴板项编辑弹窗视图
struct ClipboardItemEditorView: View {
    
    // MARK: - 属性
    
    /// 编辑器模式
    let mode: ClipboardEditorMode
    
    /// 要编辑的项目（编辑模式时使用）
    let item: ClipboardItem?
    
    /// 保存回调
    let onSave: (ClipboardItem) -> Void
    
    /// 取消回调
    let onCancel: () -> Void
    
    /// 表单字段 - 标题
    @State private var title: String = ""
    
    /// 表单字段 - 内容
    @State private var content: String = ""
    
    /// 表单字段 - 分类
    @State private var category: ClipboardCategory = .general
    
    /// 验证错误信息
    @State private var titleError: String?
    @State private var contentError: String?
    
    // MARK: - 初始化
    
    init(
        mode: ClipboardEditorMode,
        item: ClipboardItem? = nil,
        onSave: @escaping (ClipboardItem) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.mode = mode
        self.item = item
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    // MARK: - 视图
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView
            
            // 表单内容
            ScrollView {
                formContent
                    .padding(AppSpacing.lg)
            }
            
            // 底部按钮
            footerView
        }
        .frame(width: 360, height: 420)
        .glassPanel(cornerRadius: AppCornerRadius.lg, material: .ultraThinMaterial, strokeOpacity: 0.22, highlightOpacity: 0.25, shadow: AppShadow.lg)
        .onAppear {
            loadInitialData()
        }
    }
    
    // MARK: - 子视图
    
    /// 标题栏
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(mode.title)
                    .font(.appHeadline)
                    .foregroundStyle(Color.textPrimary)
                
                Text(mode == .create ? "保存常用片段" : "更新内容与分类")
                    .font(.appCaption2)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
            
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: AppSize.Icon.sm, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
    
    /// 表单内容
    private var formContent: some View {
        VStack(spacing: AppSpacing.lg) {
            // 标题字段
            titleField
            
            // 分类选择
            categoryPicker
            
            // 内容字段
            contentField
        }
    }
    
    /// 标题字段
    private var titleField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("标题")
                .font(.itemTitle)
                .foregroundStyle(Color.textPrimary)
            
            TextField("输入标题...", text: $title)
                .textFieldStyle(.plain)
                .font(.appBody)
                .padding(AppSpacing.sm)
                .background {
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .stroke(titleError != nil ? Color.statusError : Color.white.opacity(0.25), lineWidth: 0.6)
                }
                .onChange(of: title) { _, _ in
                    validateTitle()
                }
            
            if let error = titleError {
                Text(error)
                    .font(.appCaption)
                    .foregroundStyle(Color.statusError)
            }
        }
    }
    
    /// 分类选择器
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("分类")
                .font(.itemTitle)
                .foregroundStyle(Color.textPrimary)
            
            HStack(spacing: AppSpacing.sm) {
                ForEach(ClipboardCategory.allCases) { cat in
                    categoryButton(cat)
                }
            }
        }
    }
    
    /// 分类按钮
    private func categoryButton(_ cat: ClipboardCategory) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                category = cat
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: cat.iconName)
                    .font(.system(size: AppSize.Icon.sm))
                
                Text(cat.displayName)
                    .font(.appCaption)
            }
            .foregroundStyle(category == cat ? .white : cat.color)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .fill(category == cat ? cat.color : cat.color.opacity(0.1))
            }
        }
        .buttonStyle(.plain)
    }
    
    /// 内容字段
    private var contentField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("内容")
                .font(.itemTitle)
                .foregroundStyle(Color.textPrimary)
            
            TextEditor(text: $content)
                .font(.appCode)
                .scrollContentBackground(.hidden)
                .padding(AppSpacing.sm)
                .frame(minHeight: 120, maxHeight: 180)
                .background {
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .stroke(contentError != nil ? Color.statusError : Color.white.opacity(0.25), lineWidth: 0.6)
                }
                .onChange(of: content) { _, _ in
                    validateContent()
                }
            
            if let error = contentError {
                Text(error)
                    .font(.appCaption)
                    .foregroundStyle(Color.statusError)
            }
        }
    }
    
    /// 底部按钮
    private var footerView: some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                onCancel()
            } label: {
                Text("取消")
                    .font(.appBody)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .foregroundStyle(Color.textSecondary)
                    .background {
                        RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                            .fill(.ultraThinMaterial)
                    }
            }
            .buttonStyle(.plain)
            
            Button {
                saveItem()
            } label: {
                Text(mode.confirmButtonText)
                    .font(.appBody)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .foregroundStyle(.white)
                    .background {
                        RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                            .fill(isFormValid ? Color.brandPrimary : Color.brandPrimary.opacity(0.5))
                    }
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - 验证
    
    /// 表单是否有效
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !content.trimmingCharacters(in: .whitespaces).isEmpty &&
        titleError == nil &&
        contentError == nil
    }
    
    /// 验证标题
    private func validateTitle() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty && !title.isEmpty {
            titleError = "标题不能为空"
        } else {
            titleError = nil
        }
    }
    
    /// 验证内容
    private func validateContent() {
        let trimmed = content.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty && !content.isEmpty {
            contentError = "内容不能为空"
        } else {
            contentError = nil
        }
    }
    
    // MARK: - 方法
    
    /// 加载初始数据
    private func loadInitialData() {
        if let item = item {
            title = item.title
            content = item.content
            category = item.category
        } else {
            title = ""
            content = ""
            category = .general
        }
        titleError = nil
        contentError = nil
    }
    
    /// 保存项目
    private func saveItem() {
        guard isFormValid else { return }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedContent = content.trimmingCharacters(in: .whitespaces)
        
        let newItem: ClipboardItem
        if let existingItem = item {
            // 编辑模式：更新现有项目
            newItem = existingItem.updated(
                title: trimmedTitle,
                content: trimmedContent,
                category: category
            )
        } else {
            // 新增模式：创建新项目
            newItem = ClipboardItem(
                title: trimmedTitle,
                content: trimmedContent,
                category: category
            )
        }
        
        onSave(newItem)
    }
}

// MARK: - 预览

#Preview("Create Mode") {
    ClipboardItemEditorView(
        mode: .create,
        onSave: { item in print("Save: \(item.title)") },
        onCancel: { print("Cancel") }
    )
}

#Preview("Edit Mode") {
    ClipboardItemEditorView(
        mode: .edit,
        item: ClipboardItem.examples[0],
        onSave: { item in print("Save: \(item.title)") },
        onCancel: { print("Cancel") }
    )
}
