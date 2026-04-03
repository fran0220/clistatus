import SwiftUI

enum ClipboardEditorMode {
    case create
    case edit

    var title: String {
        switch self {
        case .create: return "新建剪贴板项"
        case .edit: return "编辑剪贴板项"
        }
    }
}

struct ClipboardItemEditorView: View {
    let mode: ClipboardEditorMode
    let item: ClipboardItem?
    let onSave: (ClipboardItem) -> Void
    let onCancel: () -> Void

    @State private var title = ""
    @State private var content = ""
    @State private var category: ClipboardCategory = .general

    var body: some View {
        VStack(spacing: 0) {
            Text(mode.title)
                .font(.headline)
                .padding()

            Form {
                TextField("标题", text: $title)
                Picker("分类", selection: $category) {
                    ForEach(ClipboardCategory.allCases) { cat in
                        Label(cat.displayName, systemImage: cat.iconName).tag(cat)
                    }
                }
                TextEditor(text: $content)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(minHeight: 120)
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            HStack {
                Button("取消") { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(mode == .create ? "创建" : "保存") { saveItem() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || content.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 360, height: 380)
        .onAppear {
            if let item {
                title = item.title
                content = item.content
                category = item.category
            }
        }
    }

    private func saveItem() {
        let t = title.trimmingCharacters(in: .whitespaces)
        let c = content.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !c.isEmpty else { return }

        if let existing = item {
            onSave(existing.updated(title: t, content: c, category: category))
        } else {
            onSave(ClipboardItem(title: t, content: c, category: category))
        }
    }
}
