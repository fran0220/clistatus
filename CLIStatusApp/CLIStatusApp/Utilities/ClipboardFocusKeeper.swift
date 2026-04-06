import AppKit
import Foundation

@MainActor
enum ClipboardFocusKeeper {
    /// Writing to system pasteboard can deactivate a menu bar extra window.
    /// Re-activating the app and restoring key window keeps the panel visible.
    static func performClipboardWrite(_ write: () -> Void) {
        let app = NSApplication.shared
        let targetWindow = app.keyWindow
            ?? app.mainWindow
            ?? app.windows.first(where: { $0.isVisible })

        write()

        DispatchQueue.main.async {
            app.activate(ignoringOtherApps: true)
            guard let window = targetWindow, window.isVisible else { return }
            window.makeKeyAndOrderFront(nil)
        }
    }
}
