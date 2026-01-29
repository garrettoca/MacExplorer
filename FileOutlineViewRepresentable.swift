import SwiftUI
import AppKit

struct FileOutlineView: NSViewRepresentable {
    @Binding var rootNode: FileNode        // This is now the CONTAINER root
    @Binding var selectedNode: FileNode?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true

        let outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.delegate = context.coordinator
        outlineView.dataSource = context.coordinator

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        scrollView.documentView = outlineView
        context.coordinator.outlineView = outlineView

        // Load children for the container root
        rootNode.loadChildren()
        outlineView.reloadData()

        // Expand the FAKE root (child of container)
        DispatchQueue.main.async {
            if let fakeRoot = rootNode.children?.first {
                outlineView.expandItem(fakeRoot)
            }
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.rootContainer = rootNode
        context.coordinator.outlineView?.reloadData()
    }

    class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
        var parent: FileOutlineView
        weak var outlineView: NSOutlineView?

        // IMPORTANT: this is now the container root
        var rootContainer: FileNode

        init(_ parent: FileOutlineView) {
            self.parent = parent
            self.rootContainer = parent.rootNode
        }

        // MARK: Data Source

        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            let node = (item as? FileNode) ?? rootContainer
            node.loadChildren()
            return node.children?.count ?? 0
        }

        func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            guard let node = item as? FileNode else { return false }
            return node.isDirectory
        }

        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            let node = (item as? FileNode) ?? rootContainer
            node.loadChildren()
            return node.children![index]
        }

        func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
            guard let node = item as? FileNode else { return nil }
            return node.displayName
        }

        // MARK: Delegate

        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let node = item as? FileNode else { return nil }
            let identifier = NSUserInterfaceItemIdentifier("DataCell")
            let cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView ?? {
                let v = NSTableCellView()
                v.identifier = identifier
                let textField = NSTextField(labelWithString: "")
                textField.translatesAutoresizingMaskIntoConstraints = false
                v.addSubview(textField)
                v.textField = textField
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 4),
                    textField.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -4),
                    textField.centerYAnchor.constraint(equalTo: v.centerYAnchor)
                ])
                return v
            }()
            cell.textField?.stringValue = node.displayName
            return cell
        }

        func outlineViewSelectionDidChange(_ notification: Notification) {
            guard let outlineView = notification.object as? NSOutlineView else { return }
            let row = outlineView.selectedRow
            guard row >= 0, let node = outlineView.item(atRow: row) as? FileNode else {
                parent.selectedNode = nil
                return
            }
            parent.selectedNode = node
        }
    }
}

