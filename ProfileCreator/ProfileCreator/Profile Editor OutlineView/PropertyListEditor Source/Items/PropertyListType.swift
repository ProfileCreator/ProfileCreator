//
//  PropertyListType.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

// MARK: - Property List Types

/// `PropertyListType` is a simple enum that contains cases for each property list type. These are
/// primarily useful when you need the type of a `PropertyListItem` for use in an arbitrary boolean
/// expression. For example,
///
/// ```
/// extension PropertyListItem {
///     var isScalar: Bool {
///         return propertyListType != .ArrayType && propertyListType != .DictionaryType
///     }
/// }
/// ```
///
/// This type of concise expression isn’t possible with `PropertyListItem` because each of its enum
/// cases has an associated value.
enum PropertyListType {
    case array
    case boolean
    case data
    case date
    case dictionary
    case number
    case string
}

extension PropertyListType {
    /// Returns the `PropertyListType` instance that corresponds to the specified index of the
    /// type pop-up menu, or `nil` if the index doesn’t have a known type correspondence.
    /// - parameter index: The index of the type pop-up menu whose type is being returned.
    init?(typePopUpMenuItemIndex index: Int) {
        switch index {
        case 0:
            self = .array
        case 1:
            self = .dictionary
        case 3:
            self = .boolean
        case 4:
            self = .data
        case 5:
            self = .date
        case 6:
            self = .number
        case 7:
            self = .string
        default:
            return nil
        }
    }

    /// Returns the index of the type pop-up menu that the instance corresponds to.
    var typePopUpMenuItemIndex: Int {
        switch self {
        case .array:
            return 0
        case .dictionary:
            return 1
        case .boolean:
            return 3
        case .data:
            return 4
        case .date:
            return 5
        case .number:
            return 6
        case .string:
            return 7
        }
    }

}
