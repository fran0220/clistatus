import AppKit
import SwiftUI

@MainActor
final class ClipboardEditorWindowManager {
    static let shared = ClipboardEditorWindowManager()

    private var window: NSWindow?
    private var windowDelegate: WindowDelegate?

    private init() {}

    func openEditor(mode: ClipboardEditorMode, item: ClipboardItem?, appState: AppState) {
        let editorView = ClipboardItemEditorView(
            mode: mode,
            item: item,
            onSave: { [weak self] savedItem in
                if mode == .create {
                    appState.addClipboardItem(savedItem)
                } else {
                    appState.updateClipboardItem(savedItem)
                }
                self?.closeEditor()
            },
            onCancel: { [weak self] in
                self?.closeEditor()
            }
        )

        let hostingController = NSHostingController(rootView: editorView)

        if let window {
            window.contentViewController = hostingController
            window.title = mode.title
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = mode.title
        newWindow.styleMask = [.titled, .closable]
        newWindow.setContentSize(NSSize(width: 380, height: 420))
        newWindow.isReleasedWhenClosed = false
        newWindow.level = .floating
        newWindow.center()

        let delegate = WindowDelegate { [weak self] in
            self?.window = nil
            self?.windowDelegate = nil
        }
        newWindow.delegate = delegate
        self.windowDelegate = delegate
        self.window = newWindow

        newWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func closeEditor() {
        window?.close()
    }
}

private final class WindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
