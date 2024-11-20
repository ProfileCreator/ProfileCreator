//
//  ProfileEditorOutlineViewController.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ProfileEditorOutlineViewController: NSObject {

    // MARK: -
    // MARK: Variables

    let outlineView = ProfileEditorOutlineView()
    let scrollView = OverlayScrollView(frame: NSRect.zero)

    // MARK: -
    // MARK: Private Variables

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var tree: PropertyListTree! {
        didSet {
            self.outlineView.reloadData()
        }
    }

    // MARK: -
    // MARK: Initialization

    override init() {
        self.tree = PropertyListTree()

        super.init()

        self.outlineView.dataSource = self
        self.outlineView.delegate = self
    }

    deinit {
        self.outlineView.dataSource = nil
        self.outlineView.delegate = nil
    }

    func updateSourceView(_ payloadContent: [String: Any]) {
        do {
            let propertyListData = try PropertyListSerialization.data(fromPropertyList: payloadContent, format: .xml, options: 0)
            let rootItem = try PropertyListXMLReader(XMLData: propertyListData).readData()
            self.tree = PropertyListTree(rootItem: rootItem)
            /*
            if let propertyListObject = (payloadContent as? NSDictionary) as? PropertyListItemConvertible {
                let rootItem: PropertyListItem = try propertyListObject.propertyListItem()
                self.tree = PropertyListTree(rootItem: rootItem)
            }
 */
        } catch {
            Log.shared.error(message: "Failed to convert payload to XML with error: \(error)", category: String(describing: self))
        }

        self.outlineView.reloadData()
    }
}

extension ProfileEditorOutlineViewController: NSOutlineViewDataSource {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        // Swift.print("numberOfChildrenOfItem")
        if let treeNode = item as? PropertyListTreeNode {
            // Swift.print("treeNode.numberOfChildren: \(treeNode.numberOfChildren)")
            return treeNode.numberOfChildren
        } else {
            return 1
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let treeNode = item as? PropertyListTreeNode {
            return treeNode.isExpandable
        } else {
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let treeNode = item as? PropertyListTreeNode {
            return treeNode.child(at: index)
        } else {
            return tree.rootNode!
        }
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {

        guard
            let treeNode = item as? PropertyListTreeNode,
            let tableColumnIdentifier = tableColumn?.identifier else { return nil }

        switch tableColumnIdentifier {
        case .tableColumnPropertyListKey:
            return key(of: treeNode)
        case .tableColumnPropertyListKeyEnabled:
            return nil
        case .tableColumnPropertyListType:
            return typePopUpMenuItemIndex(of: treeNode)
        case .tableColumnPropertyListValue:
            if let valueString = value(of: treeNode) as? String, valueString.contains("Example:") {
                let myMutableString = NSMutableAttributedString(string: valueString)
                myMutableString.addAttribute(NSAttributedString.Key.foregroundColor, value: NSColor.red, range: NSRange(location: 0, length: 7))
                return myMutableString
            }
            return value(of: treeNode)
        default:
            return nil
        }
    }

    func outlineView(_ outlineView: NSOutlineView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, byItem item: Any?) {

        guard
            let treeNode = item as? PropertyListTreeNode,
            let tableColumnIdentifier = tableColumn?.identifier,
            let propertyListObject = object as? PropertyListItemConvertible else { return }

        switch tableColumnIdentifier {
        case .tableColumnPropertyListKey:
            if let string = object as? String {
                setKey(string, of: treeNode)
            }
        case .tableColumnPropertyListKeyEnabled:
            Swift.print("Here")
        case .tableColumnPropertyListType:
            if let index = object as? Int, let type = PropertyListType(typePopUpMenuItemIndex: index) {
                setType(type, of: treeNode)
            }
        case .tableColumnPropertyListValue:
            let item: PropertyListItem

            do {
                // The two cases here are the value being set by a pop-up button or the value being returned directly
                if case let nodeItem = treeNode.item,
                    let valueConstraint = nodeItem.valueConstraint,
                    case let .valueArray(valueArray) = valueConstraint,
                    let popUpButtonMenuItemIndex = object as? Int {
                    item = try valueArray[popUpButtonMenuItemIndex].value.propertyListItem()
                } else {
                    // Otherwise, just create a property list item
                    item = try propertyListObject.propertyListItem()
                }

                setValue(item, of: treeNode)
            } catch {
                Log.shared.error(message: "Failed with error: \(error)", category: String(describing: self))
            }
        default:
            Swift.print("Default")
        }
    }
}

extension ProfileEditorOutlineViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, dataCellFor tableColumn: NSTableColumn?, item: Any) -> NSCell? {

        guard
            let treeNode = item as? PropertyListTreeNode,
            let tableColumnIdentifier = tableColumn?.identifier else {
                return nil
        }

        switch tableColumnIdentifier {
        case .tableColumnPropertyListValue:
            return valueCell(for: treeNode)
        default:
            return tableColumn?.dataCell as? NSCell
        }
    }

    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {

        guard
            let treeNode = item as? PropertyListTreeNode,
            let tableColumnIdentifier = tableColumn?.identifier else {
                return false
        }

        switch tableColumnIdentifier {
        case .tableColumnPropertyListKey:
            return treeNode.parent?.item.propertyListType == .dictionary
        case .tableColumnPropertyListKeyEnabled:
            return false
        case .tableColumnPropertyListType:
            return true
        case .tableColumnPropertyListValue:
            return !treeNode.item.isCollection
        default:
            return false
        }
    }
}

extension ProfileEditorOutlineViewController {
    private func editTreeNode(_ treeNode: PropertyListTreeNode) {
        let rowIndex = self.outlineView.row(forItem: treeNode)

        let tableColumnIdentifier: NSUserInterfaceItemIdentifier
        if treeNode.isRootNode {
            tableColumnIdentifier = .tableColumnPropertyListValue
        } else {
            tableColumnIdentifier = treeNode.parent!.item.propertyListType == .dictionary ? .tableColumnPropertyListKey : .tableColumnPropertyListValue
        }

        if let columnIndex = self.outlineView.tableColumns.firstIndex(where: { $0.identifier == tableColumnIdentifier }) {
            self.outlineView.selectRowIndexes(IndexSet(integer: rowIndex), byExtendingSelection: false)
            self.outlineView.editColumn(columnIndex, row: rowIndex, with: nil, select: true)
        }
    }

    // MARK: - Accessing Tree Node Item Data

    /// Returns the string to display in the Key column for the specified tree node.
    /// - parameter treeNode: The tree node whose key is being returned.
    private func key(of treeNode: PropertyListTreeNode) -> NSString {
        guard let index = treeNode.index else {
            return NSLocalizedString("PropertyListDocument.RootNodeKey", comment: "Key for root node") as NSString
        }

        // Parent node will be non-nil if index is non-nil
        switch treeNode.parent!.item {
        case .array:
            let formatString = NSLocalizedString("PropertyListDocument.ArrayItemKeyFormat", comment: "Format string for array item node key")
            return NSString.localizedStringWithFormat(formatString as NSString, index)
        case let .dictionary(dictionary):
            return dictionary[index].key as NSString
        default:
            fatalError("Impossible state: all nodes must be the root node or the child of a dictionary/array")
        }
    }

    /// Sets the key for the specified tree node. Due to the implementation of other data source
    /// methods, the tree node can be assumed to have a dictionary item as its parent.
    ///
    /// This method works by getting the parent of the specified tree node, getting its
    /// (dictionary) item, and editing it by replacing the tree node’s corresponding key with
    /// the new key. The parent node’s (dictionary) item is then replaced with the edited
    /// version using `setItem(_:ofTreeNodeAt:nodeOperation:)`. That method handles
    /// making actual model changes and registering an appropriate undo action.
    ///
    /// - parameter key: The key being set. If the dictionary already contains this key, has no
    ///       effect. This should not be possible because of our implementation of
    ///        `control(_:textShouldEndEditing:)`.
    /// - parameter treeNode: The tree node whose key is being set.
    private func setKey(_ key: String, of treeNode: PropertyListTreeNode) {
        guard let parent = treeNode.parent, let index = treeNode.index else {
            return
        }

        if case var .dictionary(dictionary) = parent.item {
            guard !dictionary.containsKey(key) else {
                return
            }

            dictionary.setKey(key, at: index)
            setItem(.dictionary(dictionary), ofTreeNodeAt: parent.indexPath)
        }
    }

    /// Returns the index corresponding to the tree node’s type in the type pop-up menu.
    /// - parameter treeNode: The tree node whose type pop-up menu index is being returned.
    private func typePopUpMenuItemIndex(of treeNode: PropertyListTreeNode) -> Int {
        treeNode.item.propertyListType.typePopUpMenuItemIndex
    }

    /// Sets the type for the specified tree node.
    ///
    /// This method works by first converting the existing property list item of the tree node
    /// to the new type and then invoking `setValue(_:of:needsChildRegeneration:)` with the
    /// new value. Child regeneration is needed when the type of the given tree goes from
    /// being a scalar to a collection or vice versa.
    ///
    /// - parameter type: The type being set.
    /// - parameter treeNode: The tree node whose type is being set.
    private func setType(_ type: PropertyListType, of treeNode: PropertyListTreeNode) {
        let wasCollection = treeNode.item.isCollection
        let newValue = treeNode.item.converting(to: type)
        let isCollection = newValue.isCollection

        // We only need child regeneration if we changed from being a scalar to a collection or
        // vice versa.  If we changed types from one collection to another, we keep our children
        // as part of type conversion, so the node hierarchy doesn’t change at all.
        setValue(newValue, of: treeNode, needsChildRegeneration: wasCollection != isCollection)
    }

    /// Returns the object value to display in the Value column for the specified tree node.
    /// - parameter treeNode: The tree node whose object value is being returned.
    private func value(of treeNode: PropertyListTreeNode) -> Any {
        switch treeNode.item {
        case .array:
            let formatString = NSLocalizedString("PropertyListDocument.ArrayValueFormat", comment: "Format string for values of arrays")
            return NSString.localizedStringWithFormat(formatString as NSString, treeNode.numberOfChildren)
        case .dictionary:
            let formatString = NSLocalizedString("PropertyListDocument.DictionaryValueFormat", comment: "Format string for values of dictionaries")
            return NSString.localizedStringWithFormat(formatString as NSString, treeNode.numberOfChildren)
        default:
            return treeNode.item.propertyListObjectValue
        }
    }

    /// Sets the value for the specified tree node. If the node’s parent item is not a
    /// dictionary, this simply means replacing the node’s item with the one specified. For
    /// nodes that represent a key-value pair in a dictionary, this method sets the pair’s value
    /// to the one specified.
    ///
    /// This method works by getting the parent of the specified tree node, getting its item,
    /// and editing it by replacing the tree node’s corresponding value with the new one. The
    /// parent node’s item is then replaced with the edited version using
    /// `setItem(_:ofTreeNodeAt:nodeOperation:)`. That method handles making actual model
    /// changes and registering an appropriate undo action.
    ///
    /// - parameter newValue: The value being set.
    /// - parameter treeNode: The tree node for which the value is being set.
    /// - parameter needsChildRegeneration: Whether setting the new value should result in the
    ///       node’s child nodes being regenerated. This is `false` by default. Child
    ///       regeneration is appropriate when the effect of the edit changes the property list
    ///       item hierarchy.
    private func setValue(_ newValue: PropertyListItem, of treeNode: PropertyListTreeNode, needsChildRegeneration: Bool = false) {
        guard let parent = treeNode.parent else {
            let nodeOperation: TreeNodeOperation? = needsChildRegeneration ? .regenerateChildren : nil
            setItem(newValue, ofTreeNodeAt: tree.rootNode.indexPath as IndexPath, nodeOperation: nodeOperation)
            return
        }

        // index is not nil because parent is not nil
        let index = treeNode.index!
        let item: PropertyListItem

        switch parent.item {
        case var .array(array):
            array[index] = newValue
            item = .array(array)
        case var .dictionary(dictionary):
            dictionary.setValue(newValue, at: index)
            item = .dictionary(dictionary)
        default:
            item = newValue
        }

        let nodeOperation: TreeNodeOperation? = needsChildRegeneration ? .regenerateChildrenForChildAt(index) : nil
        setItem(item, ofTreeNodeAt: parent.indexPath as IndexPath, nodeOperation: nodeOperation)
    }

    /// Inserts the specified item as a child of `treeNode`’s item at the specified index.
    ///
    /// This method works by replacing `treeNode`’s item with an edited version that has the new
    /// item added to it. It then invokes `setItem(_:ofTreeNodeAt:nodeOperation:)`, which
    /// handles making actual model changes and registering an appropriate undo action.
    ///
    /// - parameter item: The item being added.
    /// - parameter index: The index in `treeNode`’s item at which to add the new item.
    /// - parameter treeNode: The tree node that is having a child added to it. Raises an
    ///       assertion if `treeNode`’s item is not a collection.
    private func insert(_ item: PropertyListItem, at index: Int, in treeNode: PropertyListTreeNode) {
        let newItem: PropertyListItem

        switch treeNode.item {
        case var .array(array):
            array.insert(item, at: index)
            newItem = .array(array)
        case var .dictionary(dictionary):
            dictionary.insertKey(dictionary.unusedKey(), value: item, at: index)
            newItem = .dictionary(dictionary)
        default:
            fatalError("Attempt to insert child at index \(index) in scalar tree node \(treeNode)")
        }

        setItem(newItem, ofTreeNodeAt: treeNode.indexPath as IndexPath, nodeOperation: .insertChildAt(index))
    }

    /// Removes the child item at the specified index from `treeNode`’s item.
    ///
    /// This method works by replacing `treeNode`’s item with an edited version that removes the
    /// child item at the specified index. It then invokes
    /// `setItem(_:ofTreeNodeAt:nodeOperation:)`, which handles making actual model
    /// changes and registering an appropriate undo action.
    ///
    /// - parameter index: The index of the child to remove in `treeNode`’s item.
    /// - parameter treeNode: The tree node that is having a child removed from it. Raises an
    ///       assertion if `treeNode`’s item is not a collection.
    private func remove(at index: Int, in treeNode: PropertyListTreeNode) {
        let newItem: PropertyListItem

        switch treeNode.item {
        case var .array(array):
            array.remove(at: index)
            newItem = .array(array)
        case var .dictionary(dictionary):
            dictionary.remove(at: index)
            newItem = .dictionary(dictionary)
        default:
            fatalError("Attempt to remove child at index \(index) in scalar tree node \(treeNode)")
        }

        setItem(newItem, ofTreeNodeAt: treeNode.indexPath as IndexPath, nodeOperation: .removeChildAt(index))
    }

    /// Sets the item of the tree node at the specified index path to the one specified and then
    /// performs the specified tree node operation.
    ///
    /// This method also registers an appropriate undo operation that sets the item of the tree
    /// node back to the original value and undoes the node operation.
    ///
    /// This is the only method in this class that makes direct changes to instance’s backing
    /// data model. All other methods ultimately funnel through this method. This is primarily to
    /// make undo/redo easier to reason about.
    ///
    /// - parameter newItem: The new item that is being set.
    /// - parameter indexPath: The index path of the tree node whose item is being set. This is
    ///       used instead of the tree node itself because an undo/redo operation might occur on
    ///       a different tree node than the one that was in the tree at the time of the original
    ///       edit.
    /// - parameter nodeOperation: An optional tree node operation to perform to keep the tree node
    ///       hierarchy in sync with the property list item hierarchy. `nil` by default. If this
    ///       is non-`nil` and not `.RemoveChildAtIndex(index)`, the tree node that was inserted
    ///       or had children regenerated for it will be expanded.
    private func setItem(_ newItem: PropertyListItem, ofTreeNodeAt indexPath: IndexPath, nodeOperation: TreeNodeOperation? = nil) {
        let treeNode = tree.node(at: indexPath)
        // let oldItem = treeNode.item

        treeNode.item = newItem
        nodeOperation?.performOperation(on: treeNode)

        self.outlineView.reloadItem(treeNode, reloadChildren: true)

        if let nodeOperation = nodeOperation {
            switch nodeOperation {
            case let .insertChildAt(index):
                self.outlineView.expandItem(treeNode.child(at: index))
            case let .regenerateChildrenForChildAt(index):
                self.outlineView.expandItem(treeNode.child(at: index))
            case .regenerateChildren:
                self.outlineView.expandItem(treeNode)
            default:
                break
            }
        }
    }

    /// Returns the default item to add to our backing property list when a new row is added to
    /// the outline view.
    private func itemForAdding() -> PropertyListItem {
        PropertyListItem(propertyListType: .string)
    }

    private func valueCell(for treeNode: PropertyListTreeNode) -> NSCell {
        let item = treeNode.item
        let tableColumn = self.outlineView.tableColumn(withIdentifier: .tableColumnPropertyListKey)!

        // If we’re a collection, just use a copy of the prototype cell with the disabled text color
        if item.isCollection, let cellCopy = (tableColumn.dataCell as? NSCopying)?.copy() as? NSTextFieldCell {
            let cell = cellCopy
            cell.textColor = NSColor.tertiaryLabelColor
            return cell
        }

        // If we don’t have a value constraint, just use the normal text cell
        guard let valueConstraint = item.valueConstraint else {
            // swiftlint:disable:next force_cast
            return tableColumn.dataCell as! NSTextFieldCell
        }

        switch valueConstraint {
        case let .formatter(formatter):
            // If our value constraint is a formatter, make a copy of the prototype cell and add the
            // formatter to it.
            // swiftlint:disable:next force_cast
            let cell = (tableColumn.dataCell as! NSCopying).copy() as! NSTextFieldCell
            cell.formatter = formatter
            return cell
        case let .valueArray(validValues):
            // Otherwise, generate a pop-up button with the array of valid values
            return popUpButtonCell(withValidValues: validValues)
        }
    }

    private func popUpButtonCell(withValidValues validValues: [PropertyListValidValue]) -> NSPopUpButtonCell {
        let cell = NSPopUpButtonCell()
        cell.isBordered = false
        cell.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small))

        for validValue in validValues {
            cell.addItem(withTitle: validValue.localizedDescription)
            cell.menu!.items.last!.representedObject = validValue.value
        }

        return cell
    }

    // MARK: - UI Validation
    /*
     override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
     let selectors: Set<Selector> = [#selector(PropertyListDocument.addChild(_:)),
     #selector(PropertyListDocument.addSibling(_:)),
     #selector(PropertyListDocument.deleteItem(_:)),
     #selector(PropertyListDocument.pickCert(_:))]
     guard let action = item.action, selectors.contains(action) else {
     return super.validateUserInterfaceItem(item)
     }

     let treeNode: PropertyListTreeNode
     if propertyListOutlineView.numberOfSelectedRows == 0 {
     treeNode = tree.rootNode
     } else {
     treeNode = propertyListOutlineView.item(atRow: propertyListOutlineView.selectedRow) as! PropertyListTreeNode
     }

     switch action {
     case #selector(PropertyListDocument.addChild(_:)):
     return treeNode.item.isCollection
     case #selector(PropertyListDocument.addSibling(_:)), #selector(PropertyListDocument.deleteItem(_:)):
     return !treeNode.isRootNode
     case #selector(PropertyListDocument.pickCert(_:)):
     return true
     default:
     return false
     }
     }
     */
}
