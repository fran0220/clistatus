//
//  ClipboardService.swift
//  CLIStatusApp
//
//  剪贴板服务
//  管理剪贴板项的 CRUD 操作和持久化存储
//

import Foundation
import AppKit

// MARK: - 剪贴板服务

/// 剪贴板服务类
/// 使用 @Observable 支持 SwiftUI 状态绑定
@Observable
@MainActor
final class ClipboardService {
    
    // MARK: - 属性
    
    /// 剪贴板项列表
    private(set) var items: [ClipboardItem] = []
    
    /// UserDefaults 存储键
    private let storageKey = "clipboard_items"
    
    /// 保存队列（串行，避免覆盖顺序错乱）
    private let saveQueue = DispatchQueue(label: "clipboard.save.queue", qos: .utility)
    
    // MARK: - 初始化
    
    init() {
        loadItems()
    }
    
    // MARK: - 持久化操作
    
    /// 从 UserDefaults 加载数据
    func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            items = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            items = try decoder.decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to decode clipboard items: \(error)")
            items = []
        }
    }
    
    /// 保存数据到 UserDefaults
    func saveItems() {
        let itemsSnapshot = items
        let key = storageKey
        saveQueue.async {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(itemsSnapshot)
                UserDefaults.standard.set(data, forKey: key)
            } catch {
                print("Failed to encode clipboard items: \(error)")
            }
        }
    }
    
    // MARK: - CRUD 操作
    
    /// 添加新的剪贴板项
    /// - Parameter item: 要添加的剪贴板项
    func addItem(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        saveItems()
    }
    
    /// 添加新的剪贴板项（便捷方法）
    /// - Parameters:
    ///   - title: 标题
    ///   - content: 内容
    ///   - category: 分类
    func addItem(title: String, content: String, category: ClipboardCategory = .general) {
        let item = ClipboardItem(title: title, content: content, category: category)
        addItem(item)
    }
    
    /// 更新剪贴板项
    /// - Parameter item: 更新后的剪贴板项
    func updateItem(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        saveItems()
    }
    
    /// 删除剪贴板项
    /// - Parameter id: 要删除的剪贴板项 ID
    func deleteItem(id: UUID) {
        items.removeAll { $0.id == id }
        saveItems()
    }
    
    /// 删除多个剪贴板项
    /// - Parameter ids: 要删除的剪贴板项 ID 集合
    func deleteItems(ids: Set<UUID>) {
        items.removeAll { ids.contains($0.id) }
        saveItems()
    }
    
    /// 清空所有剪贴板项
    func clearAll() {
        items.removeAll()
        saveItems()
    }
    
    // MARK: - 查询操作
    
    /// 根据分类获取剪贴板项
    /// - Parameter category: 分类
    /// - Returns: 该分类下的所有剪贴板项
    func getItemsByCategory(_ category: ClipboardCategory) -> [ClipboardItem] {
        items.filter { $0.category == category }
    }
    
    /// 搜索剪贴板项
    /// - Parameter keyword: 搜索关键词
    /// - Returns: 匹配的剪贴板项列表
    func searchItems(keyword: String) -> [ClipboardItem] {
        guard !keyword.isEmpty else { return items }
        return items.filter { $0.matches(keyword: keyword) }
    }
    
    /// 根据分类和关键词筛选剪贴板项
    /// - Parameters:
    ///   - category: 分类（nil 表示全部）
    ///   - keyword: 搜索关键词
    /// - Returns: 筛选后的剪贴板项列表
    func filterItems(category: ClipboardCategory?, keyword: String) -> [ClipboardItem] {
        var result = items
        
        if let category = category {
            result = result.filter { $0.category == category }
        }
        
        if !keyword.isEmpty {
            result = result.filter { $0.matches(keyword: keyword) }
        }
        
        return result
    }
    
    /// 根据 ID 获取剪贴板项
    /// - Parameter id: 剪贴板项 ID
    /// - Returns: 找到的剪贴板项（如果存在）
    func getItem(by id: UUID) -> ClipboardItem? {
        items.first { $0.id == id }
    }
    
    // MARK: - 使用统计
    
    /// 增加使用次数
    /// - Parameter id: 剪贴板项 ID
    func incrementUseCount(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index] = items[index].incrementedUseCount()
        saveItems()
    }
    
    // MARK: - 系统剪贴板操作
    
    /// 复制内容到系统剪贴板
    /// - Parameter content: 要复制的内容
    func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
    
    /// 复制剪贴板项到系统剪贴板并增加使用次数
    /// - Parameter item: 剪贴板项
    func copyItem(_ item: ClipboardItem) {
        copyToClipboard(item.content)
        incrementUseCount(id: item.id)
    }
    
    /// 从系统剪贴板获取内容
    /// - Returns: 剪贴板内容（如果有）
    func getFromClipboard() -> String? {
        NSPasteboard.general.string(forType: .string)
    }
    
    // MARK: - 统计信息
    
    /// 剪贴板项总数
    var totalCount: Int {
        items.count
    }
    
    /// 各分类的数量
    var countByCategory: [ClipboardCategory: Int] {
        Dictionary(grouping: items, by: { $0.category })
            .mapValues { $0.count }
    }
    
    /// 最常使用的剪贴板项
    /// - Parameter limit: 返回数量限制
    /// - Returns: 按使用次数排序的剪贴板项列表
    func mostUsedItems(limit: Int = 5) -> [ClipboardItem] {
        Array(items.sorted { $0.useCount > $1.useCount }.prefix(limit))
    }
}
