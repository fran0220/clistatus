import AppKit
import Foundation

enum FileContextService {
    static let finderCutPasteboardType = NSPasteboard.PasteboardType("com.apple.finder.cut")

    /// Absolute paths joined by newlines (multi-select friendly).
    static func pathText(for urls: [URL]) -> String {
        urls
            .map { $0.standardizedFileURL.path }
            .joined(separator: "\n")
    }

    static func urls(from pasteboard: NSPasteboard) -> [URL] {
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL], !urls.isEmpty {
            return urls.map(\.standardizedFileURL)
        }

        if let paths = pasteboard.propertyList(forType: .fileURL) as? [String] {
            return paths.map { URL(fileURLWithPath: $0).standardizedFileURL }
        }

        // Legacy filenames pasteboard
        let filenamesType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        if let paths = pasteboard.propertyList(forType: filenamesType) as? [String] {
            return paths.map { URL(fileURLWithPath: $0).standardizedFileURL }
        }

        return []
    }

    @discardableResult
    static func cutFiles(_ urls: [URL]) -> Bool {
        guard !urls.isEmpty else { return false }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let written = pasteboard.writeObjects(urls as [NSURL])
        // Finder treats this marker as a cut (move-on-paste) instead of copy.
        pasteboard.setString("1", forType: finderCutPasteboardType)
        return written
    }

    @discardableResult
    static func copyPaths(_ urls: [URL]) -> Bool {
        guard !urls.isEmpty else { return false }

        let text = pathText(for: urls)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }

    /// Permanently deletes items after optional confirmation. Returns failures.
    /// Must be called on the main thread when `confirm` is true (shows NSAlert).
    @discardableResult
    static func deletePermanently(
        _ urls: [URL],
        confirm: Bool = true
    ) -> [URL: Error] {
        guard !urls.isEmpty else { return [:] }

        if confirm {
            let approved = presentDeleteConfirmation(for: urls)
            guard approved else { return [:] }
        }

        var failures: [URL: Error] = [:]
        for url in urls {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                failures[url] = error
            }
        }

        if !failures.isEmpty {
            presentDeleteFailures(failures)
        }

        return failures
    }

    private static func presentDeleteConfirmation(for urls: [URL]) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "彻底删除 \(urls.count) 项？"
        let names = urls.prefix(5).map(\.lastPathComponent).joined(separator: "、")
        let more = urls.count > 5 ? " 等" : ""
        alert.informativeText = "将永久删除「\(names)\(more)」，不会移入废纸篓，且无法恢复。"
        alert.addButton(withTitle: "彻底删除")
        alert.addButton(withTitle: "取消")
        NSApp.activate(ignoringOtherApps: true)
        return alert.runModal() == .alertFirstButtonReturn
    }

    private static func presentDeleteFailures(_ failures: [URL: Error]) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "部分项目删除失败"
        let lines = failures
            .map { "\($0.key.path)：\($0.value.localizedDescription)" }
            .sorted()
            .joined(separator: "\n")
        alert.informativeText = lines
        alert.addButton(withTitle: "好")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
