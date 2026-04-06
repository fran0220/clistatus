import AppKit
import Foundation

@MainActor
enum ClipboardFocusKeeper {
    /// Keep the menu bar window focused after clipboard writes.
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
