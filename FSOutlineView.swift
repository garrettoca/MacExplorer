
import SwiftUI
import AppKit

struct FSOutlineView: NSViewRepresentable {
    @Binding var root: FSNode
    @Binding var selected: FSNode?

    // Callback to ContentView when the tree selects a node
    var onSelectNode: ((FSNode) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        let c = Coordinator(self)
        FSOutlineViewCoordinatorBridge.shared.coordinator = c
        return c
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true

        let outline = NSOutlineView()
        outline.headerView = nil
        outline.delegate = context.coordinator
        outline.dataSource = context.coordinator
        outline.rowSizeStyle = .default

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        col.title = "Name"
        outline.addTableColumn(col)
        outline.outlineTableColumn = col

        scroll.documentView = outline
        context.coordinator.outline = outline

        DispatchQueue.main.async {
            outline.reloadData()

            // Expand top-level nodes (Favorites + My Mac)
            if let children = root.children {
                for child in children {
                    outline.expandItem(child)
                }
            }
        }

        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.outline?.reloadData()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSOutlineViewDelegate, NSOutlineViewDataSource {
        var parent: FSOutlineView
        weak var outline: NSOutlineView?

        init(_ parent: FSOutlineView) {
            self.parent = parent
        }

        // MARK: Data Source

        func outlineView(_ outlineView: NSOutlineView,
                         numberOfChildrenOfItem item: Any?) -> Int {
            let node = item as? FSNode ?? parent.root
            node.loadChildrenIfNeeded()
            return node.children?.count ?? 0
        }

        func outlineView(_ outlineView: NSOutlineView,
                         child index: Int,
                         ofItem item: Any?) -> Any {
            let node = item as? FSNode ?? parent.root
            node.loadChildrenIfNeeded()
            return node.children![index]
        }

        func outlineView(_ outlineView: NSOutlineView,
                         isItemExpandable item: Any) -> Bool {
            let node = item as! FSNode
            return node.isDirectory
        }

        // MARK: Cell View

        func outlineView(_ outlineView: NSOutlineView,
                         viewFor tableColumn: NSTableColumn?,
                         item: Any) -> NSView? {

            let node = item as! FSNode

            let text = NSTextField(labelWithString: node.name)
            text.lineBreakMode = .byTruncatingMiddle

            // BOLD the currently selected node
            if parent.selected === node {
                text.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
            } else {
                text.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            }

            return text
        }


        // MARK: Selection Handling

        func outlineViewSelectionDidChange(_ notification: Notification) {
            guard let outline = outline,
                  outline.selectedRow >= 0,
                  let node = outline.item(atRow: outline.selectedRow) as? FSNode
            else {
                parent.selected = nil
                return
            }

            parent.selected = node
            parent.onSelectNode?(node)
        }

        // MARK: Programmatic Selection

        func selectNode(_ node: FSNode) {
            guard let outline = outline else { return }

            // Expand all parents
            var current: FSNode? = node.parent
            while let c = current {
                outline.expandItem(c)
                current = c.parent
            }

            // Select the row
            let row = outline.row(forItem: node)
            if row >= 0 {
                outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                outline.scrollRowToVisible(row)
            }
        }
        
    }
}

// MARK: - Bridge for programmatic selection from ContentView

final class FSOutlineViewCoordinatorBridge {
    static let shared = FSOutlineViewCoordinatorBridge()
    weak var coordinator: FSOutlineView.Coordinator?

    func select(_ node: FSNode) {
        coordinator?.selectNode(node)
    }
}

