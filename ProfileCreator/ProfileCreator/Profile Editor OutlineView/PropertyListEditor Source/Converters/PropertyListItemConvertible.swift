// swiftlint:disable:next file_header
//  PropertyListItemConvertible.swift
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

/// The `PropertyListItemConversionError` enum declares errors that can occur when converting data
/// into a property list item.
enum PropertyListItemConversionError: Error, CustomStringConvertible {
    /// Indicates that a key in a dictionary was not a string.
    /// - parameter dictionary: The dictionary being converted
    /// - parameter key: The key that was not a string
    case nonStringDictionaryKey(dictionary: NSDictionary, key: Any)

    /// Indicates that the specified object was not a supported property list type
    case unsupportedObjectType(Any)

    var description: String {
        switch self {
        case let .nonStringDictionaryKey(dictionary: _, key: key):
            return "Non-string key \(key) in dictionary"
        case let .unsupportedObjectType(object):
            return "Unsupported object \(object) of type (\(type(of: object)))"
        }
    }
}

// MARK: - PropertyListItemConvertible Protocol and Extensions

/// The `PropertyListItemConvertible` protocol declares a single method that returns a property list
/// item representation of the conforming instance. This is useful for working with AppKit UI elements,
/// formatters, and Foundation’s property list serialization code. All the Foundation property list 
/// types conform to this protocol via the extensions below.
protocol PropertyListItemConvertible: NSObjectProtocol {
    /// Returns a property list item representation of the instance. 
    /// - throws: A `PropertyListItemConversionError` if the instance cannot be converted.
    func propertyListItem() throws -> PropertyListItem
}

extension NSArray: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        var array = PropertyListArray()

        for element in self {
            guard let propertyListObject = element as? PropertyListItemConvertible else {
                throw PropertyListItemConversionError.unsupportedObjectType(element as Any)
            }

            array.append(try propertyListObject.propertyListItem())
        }

        return .array(array)
    }
}

extension NSData: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        return .data(self)
    }
}

extension NSDate: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        return .date(self)
    }
}

extension NSDictionary: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        var dictionary = PropertyListDictionary()

        for (key, value) in self {
            guard let stringKey = key as? String else {
                throw PropertyListItemConversionError.nonStringDictionaryKey(dictionary: self, key: key)
            }

            guard let propertyListObject = value as? PropertyListItemConvertible else {
                throw PropertyListItemConversionError.unsupportedObjectType(value as Any)
            }

            dictionary.addKey(stringKey, value: try propertyListObject.propertyListItem())
        }
        return .dictionary(dictionary)
    }
}

extension NSNumber: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        return isBoolean ? .boolean(self) : .number(self)
    }
}

extension NSString: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        return .string(self)
    }
}
