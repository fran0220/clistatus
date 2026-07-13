import AppKit
import FinderSync

final class FinderSyncPrincipal: FIFinderSync {
    override init() {
        super.init()
        refreshMonitoredDirectories()
    }

    private func refreshMonitoredDirectories() {
        var roots: Set<URL> = [URL(fileURLWithPath: "/", isDirectory: true)]
        if let volumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nil,
            options: [.skipHiddenVolumes]
        ) {
            roots.formUnion(volumes)
        }
        FIFinderSyncController.default().directoryURLs = roots
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "cliadmin")

        switch menuKind {
        case .contextualMenuForItems, .contextualMenuForContainer, .contextualMenuForSidebar:
            break
        @unknown default:
            return menu
        }

        menu.addItem(makeItem(title: "cliadmin 剪切", action: #selector(cutSelectedItems(_:))))
        menu.addItem(makeItem(title: "cliadmin 拷贝路径", action: #selector(copySelectedPaths(_:))))
        menu.addItem(makeItem(title: "cliadmin 彻底删除", action: #selector(deleteSelectedItems(_:))))
        return menu
    }

    private func makeItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private var selectedURLs: [URL] {
        FIFinderSyncController.default().selectedItemURLs() ?? []
    }

    @objc private func cutSelectedItems(_ sender: Any?) {
        let urls = selectedURLs
        guard !urls.isEmpty else { return }
        _ = FileContextService.cutFiles(urls)
    }

    @objc private func copySelectedPaths(_ sender: Any?) {
        let urls = selectedURLs
        guard !urls.isEmpty else { return }
        _ = FileContextService.copyPaths(urls)
    }

    @objc private func deleteSelectedItems(_ sender: Any?) {
        let urls = selectedURLs
        guard !urls.isEmpty else { return }

        let work = {
            _ = FileContextService.deletePermanently(urls, confirm: true)
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }
}
