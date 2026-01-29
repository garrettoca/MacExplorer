import Foundation
import SwiftUI

let machineName = Host.current().localizedName ?? "My Mac"

struct ContentView: View {

    @State private var fakeRoot: FileNode
    @State private var rootContainer: FileNode
    @State private var selectedNode: FileNode?

    init() {
        // Create fake visible root
        let fake = FileNode(
            url: URL(fileURLWithPath: "/FAKE_ROOT_DO_NOT_USE"),
            customName: machineName
        )
        fake.isFakeRoot = true

        // Create invisible container root
        let container = FileNode(url: URL(fileURLWithPath: "/CONTAINER_NODE"))

        // Attach fake root immediately (NOT in onAppear)
        container.setChildren([fake])

        // Assign to @State wrappers
        _fakeRoot = State(initialValue: fake)
        _rootContainer = State(initialValue: container)
    }

    var body: some View {
        NavigationSplitView {
            FileOutlineView(rootNode: $rootContainer, selectedNode: $selectedNode)
                .frame(minWidth: 250)
        } detail: {
            Group {
                if let node = selectedNode, !node.isDirectory {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(node.displayName)
                            .font(.headline)
                        Text(node.url.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Divider()
                        QuickLookPreview(url: node.url)
                            .background(Color(NSColor.windowBackgroundColor))
                    }
                    .padding()
                } else if let node = selectedNode {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(node.displayName)
                            .font(.headline)
                        Text("Folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    Text("Select a file or folder")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

