// swiftlint:disable:next file_header
//  PropertyListDictionary.swift
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

/// `PropertyListKeyValuePairs` represent key/value pairs in a property list dictionary. Each pair has
/// a key (a string) and a value (a property list item).
struct PropertyListKeyValuePair: CustomStringConvertible, Hashable {
    /// The instance’s key.
    let key: String

    /// The instance’s value.
    let value: PropertyListItem

    var description: String {
        return "\"\(key)\": \(value)"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(value)
    }

    /// Returns a new key/value pair instance with the specified key and the value of the instance.
    /// - parameter key: The key of the new instance.
    /// - returns: A copy of the instance with the specified key and the value of the instance.
    func settingKey(_ key: String) -> PropertyListKeyValuePair {
        return PropertyListKeyValuePair(key: key, value: value)
    }

    /// Returns a new key/value pair instance with the key of the instance and the specified value.
    /// - parameter value: The value of the new instance.
    /// - returns: A copy of the instance with the key of the instance and the specified value.
    func settingValue(_ value: PropertyListItem) -> PropertyListKeyValuePair {
        return PropertyListKeyValuePair(key: key, value: value)
    }
}

func == (lhs: PropertyListKeyValuePair, rhs: PropertyListKeyValuePair) -> Bool {
    return lhs.key == rhs.key && lhs.value == rhs.value
}

/// `PropertyListDictionaries` represent dictionaries of property list items. Each element in a
/// dictionary is a key/value pair whose key is a string and whose value is a property list item. In
/// addition to the standard `PropertyListCollection` methods for manipulating its elements,
/// `PropertyListDictionary` also provides convenience methods for inserting key/value pairs by
/// passing in keys and values as parameters.
struct PropertyListDictionary: PropertyListCollection {
    typealias ElementType = PropertyListKeyValuePair

    private(set) var elements: [PropertyListKeyValuePair] = []

    /// The set of current keys used in the instance.
    private var keySet = Set<String>()

    /// Returns whether the instance contains a key/value pair with the specified key.
    /// - parameter key: The key whose membership in the instance’s key set is being checked.
    /// - returns: Whether the key is in the instance’s key set.
    func containsKey(_ key: String) -> Bool {
        return keySet.contains(key)
    }

    mutating func insert(_ element: ElementType, at index: Int) {
        assert(!keySet.contains(element.key), "dictionary already contains key \"\(element.key)\"")
        keySet.insert(element.key)
        elements.insert(element, at: index)
    }

    @discardableResult mutating func remove(at index: Int) -> ElementType {
        let element = elements[index]
        keySet.remove(element.key)
        return elements.remove(at: index)
    }

    // MARK: - Key-Value Pair Methods

    /// Adds a key/value pair with the specified key and value to the end of the instance.
    /// - parameter key: The key being added to the instance.
    /// - parameter value: The value being added to the instance.
    mutating func addKey(_ key: String, value: PropertyListItem) {
        insertKey(key, value: value, at: count)
    }

    /// Inserts a key/value pair with the specified key and value at the specified index of the
    /// instance.
    /// - parameter key: The key of the key/value pair being inserted into the instance.
    /// - parameter value: The value of the key/value pair being inserted into the instance.
    mutating func insertKey(_ key: String, value: PropertyListItem, at index: Int) {
        insert(PropertyListKeyValuePair(key: key, value: value), at: index)
    }

    /// Replaces the key/value pair at the specified index with the specified key and value.
    /// - parameter key: The key of the key/value pair being inserted into the instance.
    /// - parameter value: The value of the key/value pair being inserted into the instance.
    /// - parameter index: The index at which the new key/value pair is being set.
    mutating func setKey(_ key: String, value: PropertyListItem, at index: Int) {
        self[index] = PropertyListKeyValuePair(key: key, value: value)
    }

    /// Replaces the key of the key/value pair at the specified index.
    /// - parameter key: The key of the key/value pair being set on the instance.
    /// - parameter index: The index at which the new key/value pair is being set.
    mutating func setKey(_ key: String, at index: Int) {
        self[index] = self[index].settingKey(key)
    }

    /// Replaces the value of the key/value pair at the specified index.
    /// - parameter value: The value of the key/value pair being set on the instance.
    /// - parameter index: The index at which the new key/value pair is being set.
    mutating func setValue(_ value: PropertyListItem, at index: Int) {
        self[index] = self[index].settingValue(value)
    }
}

// MARK: - Generating Unused Dictionary Keys

extension PropertyListDictionary {
    /// Returns a key that the instance does not contain.
    func unusedKey() -> String {
        let formatString = NSLocalizedString("PropertyListDocument.KeyForAddingFormat",
                                             comment: "Format string for key generated when adding a dictionary item")

        var key: String
        var counter: Int = 1
        repeat {
            key = NSString.localizedStringWithFormat(formatString as NSString, counter) as String
            counter += 1
        } while containsKey(key)

        return key
    }
}
