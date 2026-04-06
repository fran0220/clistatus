import SwiftUI

struct ClipboardTabView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedCategory: ClipboardCategory?

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("搜索剪贴板...", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                Button {
                    ClipboardEditorWindowManager.shared.openEditor(
                        mode: .create,
                        item: nil,
                        appState: appState
                    )
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    categoryButton(nil, title: "全部")
                    ForEach(ClipboardCategory.allCases) { cat in
                        categoryButton(cat, title: cat.displayName)
                    }
                }
                .padding(.horizontal, 8)
            }

            let items = filteredItems
            if items.isEmpty {
                ContentUnavailableView(
                    emptyStateTitle,
                    systemImage: "doc.on.clipboard",
                    description: Text(emptyStateMessage)
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(items) { item in
                            ClipboardItemRow(
                                item: item,
                                onCopy: { appState.copyClipboardItem(item) },
                                onEdit: {
                                    ClipboardEditorWindowManager.shared.openEditor(
                                        mode: .edit,
                                        item: item,
                                        appState: appState
                                    )
                                },
                                onDelete: { appState.deleteClipboardItem(id: item.id) }
                            )
                        }
                    }
                    .padding(8)
                }
            }
        }
    }

    private func categoryButton(_ category: ClipboardCategory?, title: String) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            selectedCategory = category
        } label: {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(.quaternary, lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }

    private var filteredItems: [ClipboardItem] {
        appState.clipboardService.filterItems(category: selectedCategory, keyword: searchText)
    }

    private var emptyStateTitle: String {
        if !searchText.isEmpty { return "未找到匹配项" }
        else if selectedCategory != nil { return "该分类为空" }
        else { return "暂无剪贴板项" }
    }

    private var emptyStateMessage: String {
        if !searchText.isEmpty { return "尝试使用其他关键词搜索" }
        else if selectedCategory != nil { return "此分类下暂无内容" }
        else { return "保存常用代码、命令和链接" }
    }
}
