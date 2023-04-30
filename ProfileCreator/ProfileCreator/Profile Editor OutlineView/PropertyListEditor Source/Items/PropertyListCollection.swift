// swiftlint:disable:next file_header
//  PropertyListCollection.swift
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

/// The `PropertyListCollection` protocol defines a set of properties and methods that all property
/// collections provide. It is primarily useful for providing default behavior using a protocol
/// extension.
protocol PropertyListCollection: CustomStringConvertible, Hashable {
    /// The type of element the instance contains.
    associatedtype ElementType: CustomStringConvertible, Hashable

    /// The elements in the instance
    var elements: [ElementType] { get }

    /// The number of elements in the instance
    var count: Int { get }

    subscript(index: Int) -> ElementType { get set }

    /// Adds the specified element to the end of the instance.
    /// - parameter element: The element to add
    mutating func append(_ element: ElementType)

    /// Inserts the specified element at the specified index in the instance.
    /// - parameter element: The element to insert
    /// - parameter index: The index at which to insert the element. Raises an assertion if beyond
    ///       the bounds of the instance.
    mutating func insert(_ element: ElementType, at index: Int)

    /// Moves the element from the specified index to the new index.
    /// - parameter oldIndex: The index of the element being moved. Raises an assertion if beyond
    ///       the bounds of the instance.
    /// - parameter newIndex: The index to which to move the element. Raises an assertion if beyond
    ///       the bounds of the instance.
    mutating func moveElement(at oldIndex: Int, to newIndex: Int)

    /// Removes the element at the specified index.
    /// - parameter index: The index of the element being removed. Raises an assertion if beyond
    ///       the bounds of the instance.
    /// - returns: The element that was removed.
    @discardableResult mutating func remove(at index: Int) -> ElementType
}

extension PropertyListCollection {
    var description: String {
        let elementDescriptions = elements.map { $0.description }
        return "[" + elementDescriptions.joined(separator: ", ") + "]"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
    }

    var count: Int {
        elements.count
    }

    subscript(index: Int) -> ElementType {
        get {
            elements[index]
        }

        set {
            remove(at: index)
            insert(newValue, at: index)
        }
    }

    mutating func append(_ element: ElementType) {
        insert(element, at: count)
    }

    mutating func moveElement(at oldIndex: Int, to newIndex: Int) {
        let element = self[oldIndex]
        remove(at: oldIndex)
        insert(element, at: newIndex)
    }
}

func == <CollectionType: PropertyListCollection>(lhs: CollectionType, rhs: CollectionType) -> Bool {
    lhs.elements == rhs.elements
}
