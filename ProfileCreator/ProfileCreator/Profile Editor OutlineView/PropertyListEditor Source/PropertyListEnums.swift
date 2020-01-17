//
//  PropertyListEnums.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

// MARK: - Value Constraints

/// `PropertyListValueConstraints` represent constraints for valid values on property list items. A
/// value constraint can take one of two forms: a formatter that should be used to convert to and
/// from a string representation of the value; and an array of valid values that represent all the
/// values the item can have.
enum PropertyListValueConstraint {
    /// Represents a formatter value constraint.
    case formatter(Foundation.Formatter)

    /// Represents an array of valid values.
    case valueArray([PropertyListValidValue])
}

/// `PropertyListValidValues` represent the valid values that a property list item can have.
struct PropertyListValidValue {
    /// An object representation of the value.
    let value: PropertyListItemConvertible

    /// A localized, user-presentable description of the value.
    let localizedDescription: String
}

// MARK: - Tree Node Operations

/// The `TreeNodeOperation` enum enumerates the different operations that can be taken on a tree
/// node. Because all operations on a property list item ultimately boils down to replacing an item
/// with a new one, we need some way to discern what corresponding node operation needs to take
/// place. That’s what `TreeNodeOperations` are for.
enum TreeNodeOperation {
    /// Indicates that a child node should be inserted at the specified index.
    case insertChildAt(Int)

    /// Indicates that the child node at the specified index should be removed.
    case removeChildAt(Int)

    /// Indicates that the child node at the specified index should have its children regenerated.
    case regenerateChildrenForChildAt(Int)

    /// Indicates that the node should regenerate its children.
    case regenerateChildren

    /// Returns the inverse of the specified operation. This is useful when undoing an operation.
    var inverseOperation: TreeNodeOperation {
        switch self {
        case let .insertChildAt(index):
            return .removeChildAt(index)
        case let .removeChildAt(index):
            return .insertChildAt(index)
        case .regenerateChildrenForChildAt, .regenerateChildren:
            return self
        }
    }

    /// Performs the instance’s operation on the specified tree node.
    /// - parameter treeNode: The tree node on which to perform the operation.
    func performOperation(on treeNode: PropertyListTreeNode) {
        switch self {
        case let .insertChildAt(index):
            treeNode.insertChild(at: index)
        case let .removeChildAt(index):
            treeNode.removeChild(at: index)
        case let .regenerateChildrenForChildAt(index):
            treeNode.child(at: index).regenerateChildren()
        case .regenerateChildren:
            treeNode.regenerateChildren()
        }
    }
}
