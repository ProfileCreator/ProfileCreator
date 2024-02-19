// swiftlint:disable:next file_header
//  PropertyListTree.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/19/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// A by-product of the `NSOutlineView` API is that its data must be modeled with objects (reference
/// types). This presents problems because `PropertyListItem` is a value type. Rather than losing
/// the benefits of enums and value semantics by changing `PropertyListItem` into a class, we use
/// instances of `PropertyListTree` and the `PropertyListTreeNodes` it contains as object proxies
/// for our data model’s property list items.
/// 
/// Each property list tree has a root *item* and a root *tree node*. The root item represents the 
/// actual data that the tree represents, while the root tree node mirrors the item’s hierarchy in
/// object form. 
///
/// Generally speaking, a tree is only useful because it provides references to its item and nodes.
/// That is, you will typically interact with an item or a node, not the tree it See the
/// documentation for `PropertyListItem` and `PropertyListTreeNode` for more information on how to
/// work with items and tree nodes.
///
/// That a tree provides a *reference* to its item is worth emphasizing. While a property list item
/// is a value type and has value type semantics, the property list tree that contains it is a
/// reference type. Thus, if you have many references to a single property list tree instance, they
/// all share the same root item. While this may be obvious, it is the basic reason why property
/// list trees work. We use value types at the model level, but wrap them in a reference type so
/// that we can have many references to that same value.
class PropertyListTree: NSObject {
    /// The instance’s root property list item
    private(set) var rootItem: PropertyListItem

    // swiftlint:disable:next orphaned_doc_comment
    /// The instance’s root property list tree node
    // swiftlint:disable:next implicitly_unwrapped_optional
    private(set) var rootNode: PropertyListTreeNode!

    /// Initializes a new property list tree with the specified root item.
    /// - parameter rootItem: The root item that the property list tree represents.
    init(rootItem: PropertyListItem) {
        self.rootItem = rootItem
        super.init()
        rootNode = PropertyListTreeNode(tree: self)
    }

    /// Initializes a new property list tree with a an empty dictionary as the root item.
    convenience override init() {
        self.init(rootItem: .dictionary(PropertyListDictionary()))
    }

    /// Returns the property list tree node at the specified index path.
    /// - parameter indexPath: The index path. Raises an assertion if there is no item at the
    ///       specified index path.
    func node(at indexPath: IndexPath) -> PropertyListTreeNode {
        var treeNode = rootNode

        for index in indexPath {
            treeNode = treeNode?.children[index]
        }

        return treeNode!
    }

    /// Returns the item at the specified index path relative to the instance’s root item.
    /// - parameter indexPath: The index path. Raises an assertion if any element of the index path
    ///       indexes into a scalar.
    func item(at indexPath: IndexPath) -> PropertyListItem {
        rootItem.item(at: indexPath)
    }

    /// Sets the item at the specified index path relative to the instance’s root item.
    /// - parameter indexPath: The index path. Raises an assertion if any element of the index path
    ///       indexes into a scalar.
    func setItem(_ item: PropertyListItem, at indexPath: IndexPath) {
        rootItem = rootItem.setting(item, at: indexPath)
    }
}

// MARK: -

/// Instances of `PropertyListTreeNode` act as lightweight object proxies for property items in a
/// property list tree. Each node is meant to be used as an “item” (in `NSOutlineView` parlance) for
/// an outline view row.
///
/// Tree nodes are designed to mirror the structure of a property list item hierarchy without
/// duplicating its data. Each node contains some basic tree data—a reference to its parent node and
/// child nodes—and its index in its parent. Together, these are used to compute an index path,
/// which can in turn be used to access and edit the node’s corresponding item in the property list
/// item hierarchy.
///
/// For example, suppose we have a `PropertyListTree` with an item hierarchy that looks like:
///
///     - .DictionaryItem
///         - .NumberItem
///         - .ArrayItem
///             - .DictionaryItem
///                 - .StringItem
///                 - .StringItem
///             - .DictionaryItem
///                 - .StringItem
///                 - .StringItem
///         - .StringItem
///
/// The tree node hierarchy would look like this:
///
///     - <PropertyListTreeNode indexPath=/>
///         - <PropertyListTreeNode indexPath=/0>
///         - <PropertyListTreeNode indexPath=/1>
///             - <PropertyListTreeNode indexPath=/1/0>
///                 - <PropertyListTreeNode indexPath=/1/0/0>
///                 - <PropertyListTreeNode indexPath=/1/0/1>
///             - <PropertyListTreeNode indexPath=root/1/1>
///                 - <PropertyListTreeNode indexPath=/1/1/0>
///                 - <PropertyListTreeNode indexPath=/1/1/1>
///         - <PropertyListTreeNode indexPath=/2>
///
/// As this illustrates, tree nodes are little more than hierarchical index paths. They have
/// convenience methods for accessing their corresponding property list items, but don’t
/// duplicate the items’ data. 
///
/// Because `PropertyListTreeNode` instances are proxies for data in property list items, care should
/// be taken to keep the node hierarchy in sync with that of the items they represent. For the most
/// part, this is easy:
///
/// - Creating a `PropertyListTreeNode` creates child nodes for its item’s children, so a node’s
///   hierarchy is automatically in sync with its item’s when it is created.
///
/// - When a child item is added to a node’s item, invoke `insertChild(at:)` on the node.
///   This adds a corresponding child node at the appropriate index. Again, because node
///   creation creates children for you, the child item’s children are automatically created for
///   you. This means that if you add a dictionary with many children at a particular index, you
///   only need to invoke `insertChild(at:)` for the dictionary; the node hierarchy for the
///   children will be created for you automatically.
///
/// - When a child item is removed from a node’s item, invoke `removeChild(at:)` on the node.
///   This removes the corresponding child node and the entire node hierarchy underneath it.
///
/// - When all else fails, invoke `regenerateChildren()` on the node to discard its existing child
///   nodes and generate new ones based on the state of the node’s item. This should only be 
///   necessary if a large number of changes occur on a property list item at once. For example,
///   if a node’s item was a dictionary and then became a date, it might be easier to just set
///   the node’s item to the date and regenerate its children instead of removing the children
///   one-by-one. 
///
/// Note that tree nodes model item *hierarchies*, not their data, so you only need to add or
/// remove nodes when the *hierachy* changes. For example, if you change an item from a number
/// to a date, there’s no need to update its corresponding tree node, because there are no
/// additional items in the item hierarchy. The same goes for an empty array being replaced by
/// a string, or an array being replaced by a dictionary that contains the exact same elements.
/// If a non-empty array were replaced by a string however, its corresponding node tree hierarchy
/// would need to updated because the node for the array had children and the node for the string
/// does not.
class PropertyListTreeNode: NSObject {
    /// The tree that the instance is in
    unowned let tree: PropertyListTree

    /// The instance’s parent node. This is `nil` when the instance is the root node.
    private(set) weak var parent: PropertyListTreeNode?

    /// The instance’s child nodes.
    var children: [PropertyListTreeNode] = []

    /// A cached version of the instance’s calculated index path. This is only calculated once
    /// provided that the instance’s index (or one of its ancestors’) doesn’t change.
    private var cachedIndexPath: IndexPath?

    /// The instance’s index.
    private(set) var index: Int? {
        didSet {
            invalidateCachedIndexPath()
        }
    }

    /// Initializes a new root tree node with the specified tree. Automatically generates child
    /// nodes for its item’s children.
    /// - parameter tree: The tree the node is in.
    init(tree: PropertyListTree) {
        self.tree = tree
        super.init()
        regenerateChildren()
    }

    /// Initializes a new tree node with the specified tree, parent node, and index. Automatically
    /// generates child nodes for its item’s children.
    ///
    /// - parameter parent: The node’s parent.
    /// - parameter index: The index of the node in its parent’s children array.
    init(parent: PropertyListTreeNode, index: Int) {
        tree = parent.tree
        self.parent = parent
        self.index = index
        super.init()
        regenerateChildren()
    }

    /// Returns the instance’s index path. 
    var indexPath: IndexPath {
        if cachedIndexPath == nil {
            if let parent = parent {
                // If we have a parent, we have an index
                cachedIndexPath = parent.indexPath.appending(index!)
            } else {
                cachedIndexPath = IndexPath()
            }
        }

        return cachedIndexPath!
    }

    /// Convenience accessors for the instance’s item. In reality, this is getting and setting the
    /// item via the instance’s tree.
    var item: PropertyListItem {
        get {
            tree.item(at: indexPath)
        }

        set(item) {
            tree.setItem(item, at: indexPath)
        }
    }

    /// Whether the instance is the root node of its tree. This returns true if the instance has no
    /// parent.
    var isRootNode: Bool {
        parent == nil
    }

    override var description: String {
        let indexDescriptions = indexPath.map { $0.description }
        let indexPathString = indexDescriptions.joined(separator: "/")
        return "<PropertyListTreeNode indexPath=/\(indexPathString)>"
    }

    override var hash: Int {
        indexPath.hashValue
    }

    // MARK: - 

    /// Whether the instance is expandable, i.e., whether it can have children.
    var isExpandable: Bool {
        item.isCollection
    }

    /// The number of child nodes the instance has.
    var numberOfChildren: Int {
        children.count
    }

    /// Returns the instance’s child node with the specified index.
    /// - parameter index: The index of the child.
    func child(at index: Int) -> PropertyListTreeNode {
        children[index]
    }

    // MARK: - 

    /// Regenerates the instance’s child nodes, replacing the existing child nodes with newly
    /// created ones.
    func regenerateChildren() {
        let elementCount: Int
        switch item {
        case let .array(array):
            elementCount = array.count
        case let .dictionary(dictionary):
            elementCount = dictionary.count
        default:
            elementCount = 0
        }

        children = (0 ..< elementCount).map { PropertyListTreeNode(parent: self, index: $0) }
    }

    /// Returns the instance’s last child or `nil` if the instance has no children.
    var lastChild: PropertyListTreeNode? {
        children.last
    }

    /// Inserts a new child node at the specified index.
    /// - note: This method should only be invoked *after* the instance’s item has had a child
    ///         added at the specified index. That is, update the item first, then the node.
    /// - parameter index: The index at which to insert the new child node.
    func insertChild(at index: Int) {
        children.insert(PropertyListTreeNode(parent: self, index: index), at: index)
        updateIndexesForChildren(in: index ..< numberOfChildren)
    }

    /// Removes the child node at the specified index.
    /// - note: This method should only be invoked *after* the instance’s item has had a child
    ///         removed from the specified index. That is, update the item first, then the node.
    /// - parameter index: The index from which to remove the child node.
    func removeChild(at index: Int) {
        children.remove(at: index)
        updateIndexesForChildren(in: index ..< numberOfChildren)
    }

    // MARK: - 

    /// Recursively invalidates the instance’s cached index path and those of its children.
    private func invalidateCachedIndexPath() {
        cachedIndexPath = nil
        for child in children {
            child.invalidateCachedIndexPath()
        }
    }

    /// Updates the indexes for the instance’s children with indexes is in the specified range.
    /// - parameter indexRange: The range of child node indexes whose children need updated indexes.
    private func updateIndexesForChildren(in indexRange: CountableRange<Int>) {
        for i in indexRange {
            children[i].index = i
        }
    }
}
