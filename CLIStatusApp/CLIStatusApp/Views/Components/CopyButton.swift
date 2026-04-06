import SwiftUI
import AppKit

struct CopyButton: View {
    let content: String
    let onCopy: (() -> Void)?
    @State private var isCopied = false

    init(content: String, size: CopyButtonSize = .medium, onCopy: (() -> Void)? = nil) {
        self.content = content
        self.onCopy = onCopy
    }

    var body: some View {
        Button {
            if let onCopy {
                onCopy()
            } else {
                ClipboardFocusKeeper.performClipboardWrite {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                }
            }
            isCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopied = false }
        } label: {
            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 12))
                .foregroundStyle(isCopied ? .green : .secondary)
        }
        .buttonStyle(.plain)
        .help(isCopied ? "已复制" : "复制到剪贴板")
    }
}

enum CopyButtonSize { case small, medium, large }
