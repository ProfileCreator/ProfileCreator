// swiftlint:disable:next file_header
//  PropertyListItem.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
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

/// `PropertyListItems` represent property list types as an enum, with one case per property list
/// type. They are the primary type for modeling property lists in this application. Due to their
/// nested, value-type nature, they are not well-suited to editing in place, particularly when the
/// edit is occurring more than one level deep in the property list’s data hierarchy. As such, we
/// have defined an extension below for making edits recursively using index paths. See the
/// documentation below for more information.
enum PropertyListItem: CustomStringConvertible, Hashable {
    case array(PropertyListArray)
    case boolean(NSNumber)
    case data(NSData)
    case date(NSDate)
    case dictionary(PropertyListDictionary)
    case number(NSNumber)
    case string(NSString)

    var description: String {
        switch self {
        case let .array(array):
            return array.description
        case let .boolean(boolean):
            return boolean.boolValue.description
        case let .data(data):
            return data.description
        case let .date(date):
            return date.description
        case let .dictionary(dictionary):
            return dictionary.description
        case let .number(number):
            return number.description
        case let .string(string):
            return string.description
        }
    }

    var hashValue: Int {
        switch self {
        case let .array(array):
            return array.hashValue
        case let .boolean(boolean):
            return boolean.hashValue
        case let .data(data):
            return data.hashValue
        case let .date(date):
            return date.hashValue
        case let .dictionary(dictionary):
            return dictionary.hashValue
        case let .number(number):
            return number.hashValue
        case let .string(string):
            return string.hashValue
        }
    }

    /// Returns if the instance is an array or dictionary.
    var isCollection: Bool {
        return propertyListType == .array || propertyListType == .dictionary
    }
}

func == (lhs: PropertyListItem, rhs: PropertyListItem) -> Bool {
    switch (lhs, rhs) {
    case let (.array(left), .array(right)):
        return left == right
    case let (.boolean(left), .boolean(right)):
        return left == right
    case let (.data(left), .data(right)):
        return left == right
    case let (.date(left), .date(right)):
        return left == right
    case let (.dictionary(left), .dictionary(right)):
        return left == right
    case let (.number(left), .number(right)):
        return left == right
    case let (.string(left), .string(right)):
        return left == right
    default:
        return false
    }
}

extension PropertyListItem {
    /// Returns the property list type of the instance.
    var propertyListType: PropertyListType {
        switch self {
        case .array:
            return .array
        case .boolean:
            return .boolean
        case .data:
            return .data
        case .date:
            return .date
        case .dictionary:
            return .dictionary
        case .number:
            return .number
        case .string:
            return .string
        }
    }
}

extension PropertyListItem {
    /// Returns an value constraint for the property list item type or `nil` if there are
    /// no constraints for the item.
    var valueConstraint: PropertyListValueConstraint? {
        switch self {
        case .boolean:
            let falseTitle = NSLocalizedString("PropertyListValue.Boolean.FalseTitle", comment: "Title for Boolean false value")
            let falseValidValue = PropertyListValidValue(value: NSNumber(value: false), localizedDescription: falseTitle)
            let trueTitle = NSLocalizedString("PropertyListValue.Boolean.TrueTitle", comment: "Title for Boolean true value")
            let trueValidValue = PropertyListValidValue(value: NSNumber(value: true), localizedDescription: trueTitle)
            return .valueArray([falseValidValue, trueValidValue])
        case .data:
            return .formatter(PropertyListDataFormatter())
        case .date:
            struct SharedFormatter {
                static let dateFormatter = LenientDateFormatter()
            }

            return .formatter(SharedFormatter.dateFormatter)
        case .number:
            return .formatter(NumberFormatter.propertyList)
        default:
            return nil
        }
    }
}

// MARK: - Accessing Items with Index Paths

/// This extension adds the ability to access and change property lists using index paths. Rather
/// than editing the property list items in place, the methods in this extension return new items
/// that are the result of setting an item at particular index paths.
extension PropertyListItem {
    /// Returns the item at the specified index path relative to the instance.
    ///
    /// - parameter indexPath: The index path. Raises an assertion if any element of the index path
    ///       indexes into a scalar.
    func item(at indexPath: IndexPath) -> PropertyListItem {
        var item = self

        for index in indexPath {
            switch item {
            case let .array(array):
                item = array[index]
            case let .dictionary(dictionary):
                item = dictionary[index].value
            default:
                fatalError("non-empty indexPath for scalar type")
            }
        }

        return item
    }

    /// Returns a copy of the instance in which the item at `indexPath` is set to `newItem`.
    /// - parameter newItem: The new item to set at the specified index path relative to the instance
    /// - parameter indexPath: The index path. Raises an assertion if any element of the index path
    ///       indexes into a scalar.
    func setting(_ newItem: PropertyListItem, at indexPath: IndexPath) -> PropertyListItem {
        return (indexPath as NSIndexPath).length > 0 ? setting(newItem, at: indexPath, indexPosition: 0) : newItem
    }

    /// A private method that actually implements `setting(_:at:)` by setting the
    /// item at the index position inside the index path. It is called recursively starting from
    /// index position 0 and continuing until the entire index path is traversed.
    ///
    /// - parameter newItem: The new item to set at the specified index path relative to the instance
    /// - parameter indexPath: The index path. Raises an assertion if any element of the index path
    ///       indexes into a scalar.
    /// - parameter indexPosition: The position in the index path to get the current index
    private func setting(_ newItem: PropertyListItem, at indexPath: IndexPath, indexPosition: Int) -> PropertyListItem {
        if indexPosition == indexPath.count {
            return newItem
        }

        let index = indexPath[indexPosition]

        switch self {
        case var .array(array):
            let element = array[index]
            let newElement = element.setting(newItem, at: indexPath, indexPosition: indexPosition + 1)
            array[index] = newElement
            return .array(array)
        case var .dictionary(dictionary):
            let value = dictionary[index].value
            let newValue = value.setting(newItem, at: indexPath, indexPosition: indexPosition + 1)
            dictionary.setValue(newValue, at: index)
            return .dictionary(dictionary)
        default:
            fatalError("non-empty indexPath for scalar type")
        }
    }
}

// MARK: - Converting Between Property List Types

extension PropertyListItem {
    /// Returns a default property list item of the specified type.
    /// - parameter type: The property list type of the new item.
    init(propertyListType: PropertyListType) {
        switch propertyListType {
        case .array:
            self = .array(PropertyListArray())
        case .boolean:
            self = .boolean(false)
        case .data:
            self = .data(Data() as NSData)
        case .date:
            self = .date(Date() as NSDate)
        case .dictionary:
            self = .dictionary(PropertyListDictionary())
        case .number:
            self = .number(NSNumber(value: 0))
        case .string:
            let string = NSLocalizedString("PropertyListDocument.ItemForAddingStringValue", comment: "Default value when adding a new item")
            self = .string(string as NSString)
        }
    }

    /// Returns a new property list item by converting the instance to the specified type.
    /// - parameter type: The type of property list item to convert the instance to.
    func converting(to type: PropertyListType) -> PropertyListItem {
        if propertyListType == type {
            return self
        }

        let defaultItem = PropertyListItem(propertyListType: type)

        switch self {
        case let .array(array):
            if type == .dictionary {
                var dictionary = PropertyListDictionary()

                for element in array.elements {
                    dictionary.addKey(dictionary.unusedKey(), value: element)
                }

                return .dictionary(dictionary)
            }

            return defaultItem
        case let .boolean(boolean):
            switch type {
            case .number:
                return .number(boolean.boolValue ? 1 : 0)
            case .string:
                return .string(description as NSString)
            default:
                return defaultItem
            }
        case let .date(date):
            return type == .number ? .number(date.timeIntervalSince1970 as NSNumber) : defaultItem
        case let .dictionary(dictionary):
            if type == .array {
                var array = PropertyListArray()

                for element in dictionary.elements {
                    array.append(element.value)
                }

                return .array(array)
            }

            return defaultItem
        case let .number(number):
            switch type {
            case .boolean:
                return .boolean(number.boolValue as NSNumber)
            case .date:
                return .date(Date(timeIntervalSince1970: number.doubleValue) as NSDate)
            case .string:
                return .string(number.description as NSString)
            default:
                return defaultItem
            }
        case let .string(string):
            switch type {
            case .boolean:
                return .boolean((string.caseInsensitiveCompare("YES") == .orderedSame || string.caseInsensitiveCompare("true") == .orderedSame) as NSNumber)
            case .data:
                if let data = PropertyListDataFormatter().data(from: string as String) {
                    return .data(data as NSData)
                }

                return defaultItem
            case .date:
                if let date = LenientDateFormatter().date(from: string as String) {
                    return .date(date as NSDate)
                }

                return defaultItem
            case .number:
                if let number = NumberFormatter.propertyList.number(from: string as String) {
                    return .number(number)
                }

                return defaultItem
            default:
                return defaultItem
            }
        default:
            return defaultItem
        }
    }
}
