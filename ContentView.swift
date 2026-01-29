import SwiftUI
import UniformTypeIdentifiers

private extension String {
    var escapedForShell: String {
        replacingOccurrences(of: " ", with: "\\ ")
    }
}

struct ContentView: View {

    @State private var root: FSNode
    @State private var selected: FSNode?
    @State private var showHiddenFiles = false

    init() {
        let rootURL = URL(fileURLWithPath: "/")

        // Real filesystem root (lazy-loaded)
        let realRoot = FSNode(
            name: Host.current().localizedName ?? "My Mac",
            url: rootURL,
            isDirectory: true
        )

        // Optional virtual section
        let favorites = FSNode(name: "Favorites", url: nil, isDirectory: true, isVirtual: true)
        favorites.children = [
            FSNode(name: "Desktop",
                   url: URL(fileURLWithPath: NSHomeDirectory() + "/Desktop"),
                   isDirectory: true),
            FSNode(name: "Documents",
                   url: URL(fileURLWithPath: NSHomeDirectory() + "/Documents"),
                   isDirectory: true)
        ]

        // Container root (required by NSOutlineView)
        let container = FSNode(name: "Container", url: nil, isDirectory: true, isVirtual: true)
        container.children = [favorites, realRoot]

        _root = State(initialValue: container)
    }

    var body: some View {
        NavigationSplitView {
            FSOutlineView(
                root: $root,
                selected: $selected
            ) { node in
                // When the tree selects a node, update the detail panel
                selected = node
            }
            .frame(minWidth: 250)

        } detail: {
            
            if let node = selected, node.isDirectory {
               
                VStack(alignment: .leading, spacing: 0) {
                    
                    HStack {
                        Button {
                            goUpOneLevel()
                        } label: {
                            Image(systemName: "arrow.up")
                        }
                        .disabled(selected?.parent == nil)   // disabled at root
                        .help("Go up to parent folder")
                        breadcrumbText(for: node)
                            .padding(.vertical, 4)

                        Button {
                            openTerminal(at: node)
                        } label: {
                            Image(systemName: "terminal")
                        }
                        .help("Open Terminal at this folder")
                        Toggle("Show hidden files", isOn: $showHiddenFiles)
                            .padding(.leading, 8)

                        Spacer()
                    }
                    .padding([.top, .leading, .trailing])
                    
                  

                    let contents = node.loadDirectoryContents(showHidden: showHiddenFiles)

                    List(contents) { item in
                        HStack(spacing: 8) {

                            // Icon
                            Image(nsImage: icon(for: item))
                                .resizable()
                                .frame(width: 16, height: 16)

                            // Name
                            Text(item.name)

                            Spacer()

                            // Type label
                            Text(item.isDirectory ? "Folder" : "File")
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if item.isDirectory {
                                selected = item
                                FSOutlineViewCoordinatorBridge.shared.select(item)
                            }
                        }
                    }

                }
            } else if let node = selected {
                Text(node.name)
                    .font(.title)

            } else {
                Text("Select a folder")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func icon(for node: FSNode) -> NSImage {
        if node.isDirectory {
            return NSImage(named: NSImage.folderName) ?? NSImage()
        }

        guard let url = node.url else {
            return NSImage()
        }

        // Modern UTType-based icon lookup
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return NSWorkspace.shared.icon(for: type)
        }

        // Fallback for unknown types
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    private func goUpOneLevel() {
        guard let parent = selected?.parent else { return }

        // Update detail panel
        selected = parent

        // Expand + select in navigator
        FSOutlineViewCoordinatorBridge.shared.select(parent)
    }
    
    private func buildPathChain(from node: FSNode) -> [FSNode] {
        var chain: [FSNode] = []
        var current: FSNode? = node

        while let c = current {
            chain.append(c)
            current = c.parent
        }

        return chain.reversed()
    }
    
    private func copyToClipboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    @ViewBuilder
    private func breadcrumbText(for node: FSNode) -> some View {
        let chain = buildPathChain(from: node)
        let pathString = chain
            .compactMap { $0.name }
            .joined(separator: "/")
            .replacingOccurrences(of: "//", with: "/")

        HStack(spacing: 8) {
            Text("/" + pathString)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)

            Button {
                copyToClipboard("/" + pathString)
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .help("Copy path to clipboard")

            Spacer()
        }
        .padding(.horizontal)
    }

    
    private func openTerminal(at node: FSNode) {
        guard let url = node.url else { return }

        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", "Terminal", url.path]
        task.launch()
    }


}

