//
//  ClipboardItem.swift
//  CLIStatusApp
//
//  剪贴板项数据模型
//  定义剪贴板项的结构和分类
//

import Foundation
import SwiftUI

// MARK: - 剪贴板项分类

/// 剪贴板项分类枚举
enum ClipboardCategory: String, CaseIterable, Codable, Identifiable {
    case general    // 通用
    case code       // 代码
    case command    // 命令
    case link       // 链接
    case other      // 其他
    
    var id: String { rawValue }
    
    /// 分类显示名称
    var displayName: String {
        switch self {
        case .general: return "通用"
        case .code: return "代码"
        case .command: return "命令"
        case .link: return "链接"
        case .other: return "其他"
        }
    }
    
    /// 分类图标名称
    var iconName: String {
        switch self {
        case .general: return "doc.on.clipboard"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .command: return "terminal"
        case .link: return "link"
        case .other: return "ellipsis.circle"
        }
    }
    
    /// 分类颜色
    var color: Color {
        switch self {
        case .general: return .statusInfo
        case .code: return .brandPrimary
        case .command: return .statusSuccess
        case .link: return .teal
        case .other: return .secondary
        }
    }
}

// MARK: - 剪贴板项模型

/// 剪贴板项数据模型
/// 用于存储用户保存的文本片段
struct ClipboardItem: Identifiable, Codable, Equatable {
    /// 唯一标识符
    let id: UUID
    
    /// 标题
    var title: String
    
    /// 内容
    var content: String
    
    /// 分类
    var category: ClipboardCategory
    
    /// 创建时间
    let createdAt: Date
    
    /// 更新时间
    var updatedAt: Date
    
    /// 使用次数
    var useCount: Int
    
    // MARK: - 初始化方法
    
    /// 创建新的剪贴板项
    /// - Parameters:
    ///   - title: 标题
    ///   - content: 内容
    ///   - category: 分类，默认为 general
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        category: ClipboardCategory = .general,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        useCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.useCount = useCount
    }
    
    // MARK: - 计算属性
    
    /// 内容预览（截取前 100 个字符）
    var contentPreview: String {
        let maxLength = 100
        if content.count <= maxLength {
            return content
        }
        let endIndex = content.index(content.startIndex, offsetBy: maxLength)
        return String(content[..<endIndex]) + "..."
    }
    
    /// 格式化的创建时间
    var formattedCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    /// 格式化的更新时间
    var formattedUpdatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
    
    // MARK: - 辅助方法
    
    /// 判断是否匹配搜索关键词
    /// - Parameter keyword: 搜索关键词
    /// - Returns: 是否匹配
    func matches(keyword: String) -> Bool {
        guard !keyword.isEmpty else { return true }
        let lowercasedKeyword = keyword.lowercased()
        return title.lowercased().contains(lowercasedKeyword) ||
               content.lowercased().contains(lowercasedKeyword)
    }
    
    /// 创建更新后的副本
    /// - Parameters:
    ///   - title: 新标题（可选）
    ///   - content: 新内容（可选）
    ///   - category: 新分类（可选）
    /// - Returns: 更新后的剪贴板项
    func updated(
        title: String? = nil,
        content: String? = nil,
        category: ClipboardCategory? = nil
    ) -> ClipboardItem {
        ClipboardItem(
            id: self.id,
            title: title ?? self.title,
            content: content ?? self.content,
            category: category ?? self.category,
            createdAt: self.createdAt,
            updatedAt: Date(),
            useCount: self.useCount
        )
    }
    
    /// 创建使用次数增加后的副本
    /// - Returns: 使用次数增加后的剪贴板项
    func incrementedUseCount() -> ClipboardItem {
        ClipboardItem(
            id: self.id,
            title: self.title,
            content: self.content,
            category: self.category,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            useCount: self.useCount + 1
        )
    }
}

// MARK: - 示例数据

extension ClipboardItem {
    /// 示例数据（用于预览和测试）
    static let examples: [ClipboardItem] = [
        ClipboardItem(
            title: "Git 提交模板",
            content: "feat: add new feature\n\nDescription of the feature",
            category: .command
        ),
        ClipboardItem(
            title: "SwiftUI Button",
            content: "Button(\"Title\") {\n    // action\n}",
            category: .code
        ),
        ClipboardItem(
            title: "GitHub 地址",
            content: "https://github.com/username/repo",
            category: .link
        ),
        ClipboardItem(
            title: "常用命令",
            content: "npm install && npm run dev",
            category: .command
        )
    ]
}
