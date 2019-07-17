// swiftlint:disable:next file_header
//  PropertyListObjectConvertible.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/24/2015.
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

/// The `PropertyListItemConvertible` protocol declares a single method that returns a property list
/// object representation of the conforming instance. Via the extensions below, it serves as a way
/// to convert from PropertyListItems to the Foundation property list objects that they represent.
/// This is useful for working with AppKit UI elements, formatters, and Foundation’s property list
/// serialization code.
protocol PropertyListObjectConvertible {
    /// Returns a property list object representation of the instance. The object returned should be
    /// a Foundation property list object.
    var propertyListObjectValue: Any { get }
}

extension PropertyListItem: PropertyListObjectConvertible {
    var propertyListObjectValue: Any {
        switch self {
        case let .array(array):
            return array.propertyListObjectValue
        case let .boolean(value):
            return value
        case let .data(value):
            return value
        case let .date(value):
            return value
        case let .dictionary(dictionary):
            return dictionary.propertyListObjectValue
        case let .number(value):
            return value
        case let .string(value):
            return value
        }
    }
}

extension PropertyListArray: PropertyListObjectConvertible {
    var propertyListObjectValue: Any {
        return elements.map { $0.propertyListObjectValue } as NSArray
    }
}

extension PropertyListDictionary: PropertyListObjectConvertible {
    var propertyListObjectValue: Any {
        let dictionary = NSMutableDictionary()

        for element in elements {
            dictionary[element.key] = element.value.propertyListObjectValue
        }

        return dictionary.copy()
    }
}
