//
//  Untitled.swift
//  MacExplorer
//
//  Created by Garrett O'Carroll on 28/01/2026.
//

import Foundation

class FileNode: NSObject {
    let url: URL
    weak var parent: FileNode?
    var children: [FileNode]? = nil
    var customName: String?   // ← NEW
    
    var isFakeRoot: Bool = false // for handing the root node

    var isDirectory: Bool {
        if isFakeRoot { return true }
        return (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }


    var displayName: String {
        customName ?? (url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)
    }

    init(url: URL, parent: FileNode? = nil, customName: String? = nil) {
        self.url = url
        self.parent = parent
        self.customName = customName
    }
 
    func setChildren(_ newChildren: [FileNode]) {
        self.children = newChildren
        for child in newChildren {
            child.parent = self
        }
    }

    func loadChildren() {
        print("loadChildren:", url.path, "fake:", isFakeRoot)

        // Fake root: show contents of "/"
        if isFakeRoot {
            let fm = FileManager.default
            let rootURL = URL(fileURLWithPath: "/")

            guard let urls = try? fm.contentsOfDirectory(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                children = []
                return
            }

            children = urls
                .map { FileNode(url: $0, parent: self) }
                .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }

            return
        }

        // Normal directory behaviour
        guard isDirectory, children == nil else { return }

        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            children = []
            return
        }

        children = urls
            .map { FileNode(url: $0, parent: self) }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }


}
