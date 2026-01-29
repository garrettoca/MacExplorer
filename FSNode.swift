import Foundation

// Global cache so FSNode instances are reused across tree + detail panel
fileprivate var fsNodeCache: [URL: FSNode] = [:]

final class FSNode: Identifiable {
    let id = UUID()
    let name: String
    let url: URL?
    let isDirectory: Bool
    let isVirtual: Bool

    weak var parent: FSNode?
    var children: [FSNode]?
    private var didLoadChildren = false

    init(name: String,
         url: URL?,
         isDirectory: Bool,
         isVirtual: Bool = false,
         parent: FSNode? = nil,
         children: [FSNode]? = nil)
    {
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.isVirtual = isVirtual
        self.parent = parent
        self.children = children

        // Register in cache so we can reuse this node later
        if let url = url {
            fsNodeCache[url] = self
        }
    }

    // MARK: - Navigation Tree Loading (Directories Only)

    func loadChildrenIfNeeded() {
        guard !didLoadChildren else { return }
        didLoadChildren = true

        // Virtual nodes define their own children
        if isVirtual {
            return
        }

        guard let url = url, isDirectory else {
            children = []
            return
        }

        let fm = FileManager.default
        let urls = (try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        // Only directories for the navigation tree
        children = urls.compactMap { url in
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            guard isDir else { return nil }

            // Reuse existing node if available
            if let existing = fsNodeCache[url] {
                existing.parent = self
                return existing
            }

            // Otherwise create and cache
            let node = FSNode(
                name: url.lastPathComponent,
                url: url,
                isDirectory: true,
                parent: self
            )
            fsNodeCache[url] = node
            return node
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Detail Panel Loading (Directories + Files)

    func loadDirectoryContents(showHidden: Bool) -> [FSNode] {
        guard let url = url, isDirectory else { return [] }

        let fm = FileManager.default
        let urls = (try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: showHidden ? [] : [.skipsHiddenFiles]
        )) ?? []

        return urls.compactMap { url in
            let name = url.lastPathComponent

            // Manual hidden-file filter (covers dot-files even if not marked hidden)
            if !showHidden && name.hasPrefix(".") {
                return nil
            }

            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false

            // Reuse existing node if available
            if let existing = fsNodeCache[url] {
                existing.parent = self
                return existing
            }

            let node = FSNode(
                name: name,
                url: url,
                isDirectory: isDir,
                parent: self
            )
            fsNodeCache[url] = node
            return node
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

}
