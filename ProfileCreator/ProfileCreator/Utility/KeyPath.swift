//
//  KeyPath.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

// https://oleb.net/blog/2017/01/dictionary-key-paths/
struct KeyPath {
    var segments: [String]
    var subkey: PayloadSubkey?

    var isEmpty: Bool { segments.isEmpty }
    var path: String {
        segments.joined(separator: ".")
    }

    var next: String? {
        !segments.isEmpty ? segments[0] : nil
    }

    /// Strips off the first segment and returns a pair
    /// consisting of the first segment and the remaining key path.
    /// Returns nil if the key path has no segments.
    func headAndTail() -> (head: String, tail: KeyPath)? {
        guard !isEmpty else { return nil }
        var tail = segments
        let head = tail.removeFirst()
        return (head, KeyPath(segments: tail, subkey: subkey))
    }
}

extension KeyPath {

    // FIXME: Added reversed because I made a mistake and didn't reverse by default.
    // FIXME: So to avoid data loss for the user, it's added here as an option to check the reversed
    init(_ string: String, subkey: PayloadSubkey? = nil, reversed: Bool = true) {
        self.subkey = subkey
        if let aSubkey = subkey {
            var subkeys = [aSubkey]
            subkeys.append(contentsOf: aSubkey.parentSubkeys ?? [])
            if subkeys.contains(where: { $0.key.contains(".") }) {
                var segments = [String]()
                if reversed {
                    let lastSubkey = subkeys.remove(at: 0)
                    subkeys.append(lastSubkey)
                }
                for subkey in subkeys {
                    segments.append(subkey.key)
                }
                self.segments = segments
            } else {
                self.segments = string.components(separatedBy: ".")
            }
        } else {
            self.segments = string.components(separatedBy: ".")
        }
    }
}

extension KeyPath: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(value)
    }
    init(unicodeScalarLiteral value: String) {
        self.init(value)
    }
    init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }
}

protocol StringProtocol {
    init(string s: String)
}

extension String: StringProtocol {
    init(string s: String) {
        self = s
    }
}

extension Dictionary where Key: StringProtocol {
    subscript(keyPath keyPath: KeyPath) -> Any? {
        get {
            switch keyPath.headAndTail() {
            case nil:
                // key path is empty.
                return nil
            case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
                // Reached the end of the key path.
                let key = Key(string: head)
                return self[key]
            case let (head, remainingKeyPath)?:
                // Key path has a tail we need to traverse.
                let key = Key(string: head)
                switch self[key] {
                case let nestedDict as [Key: Any]:
                    // Next nest level is a dictionary.
                    // Start over with remaining key path.
                    let value = nestedDict[keyPath: remainingKeyPath]
                    if value is NSNull {
                        return nil
                    } else {
                        return value
                    }
                case let nestedArray as [Any]:
                    // Next nest level is an array
                    // Convert next key path segment to int

                    guard let arrayIndex = Int(remainingKeyPath.segments[0]),
                        arrayIndex <= nestedArray.count - 1,
                        let value = nestedArray[arrayIndex] as? [Key: Any] else { return nil }

                    var remainingKeyPath = remainingKeyPath
                    remainingKeyPath.segments.remove(at: 0)
                    return value[keyPath: remainingKeyPath]
                default:
                    // Next nest level isn't a dictionary.
                    // Invalid key path, abort.
                    return nil
                }
            }
        }

        set {
            switch keyPath.headAndTail() {
            case nil:
                // key path is empty.
                return
            case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
                // Reached the end of the key path.
                let key = Key(string: head)
                // FIXME: Custom fix for collection types that otherwise was saved with literal optional status and did not allow for export until after realoding from save.
                if keyPath.subkey?.type == .dictionary, let value = newValue as? [String: Any] {
                    self[key] = value as? Value
                } else if keyPath.subkey?.type == .array, let value = newValue as? [Any] {
                    self[key] = value as? Value
                } else if let value = newValue as? Value {
                    self[key] = value
                } else {
                    self[key] = newValue as? Value
                }
            case let (head, remainingKeyPath)?:
                let key = Key(string: head)
                let value: Value
                if let indexString = remainingKeyPath.next, Int(indexString) != nil {
                    // swiftlint:disable:next force_cast
                    value = self[key] ?? [Any]() as! Value
                } else {
                    // swiftlint:disable:next force_cast
                    value = self[key] ?? [Key: Any]() as! Value
                }
                switch value {
                case var nestedDict as [Key: Any]:
                    // Key path has a tail we need to traverse
                    nestedDict[keyPath: remainingKeyPath] = newValue
                    self[key] = nestedDict as? Value
                case var nestedArray as [Any]:
                    guard
                        let arrayIndex = Int(remainingKeyPath.segments[0]),
                        (arrayIndex == 0 || arrayIndex <= nestedArray.count - 1) else { return }

                    if remainingKeyPath.segments.count == 1 {
                        if nestedArray.isEmpty {
                            if arrayIndex == 0, let value = newValue {
                                nestedArray.append(value)
                            } else {
                                return
                            }
                        } else if let value = newValue {
                            nestedArray[arrayIndex] = value
                        }
                        self[key] = nestedArray as? Value
                    } else if 1 < remainingKeyPath.segments.count {
                        var remainingKeyPath = remainingKeyPath
                        remainingKeyPath.segments.remove(at: 0)

                        // let (newHead, newRemainingKeyPath) = remainingKeyPath.headAndTail()!

                        var newDict: [Key: Any]
                        if nestedArray.isEmpty {
                            newDict = [Key: Any]()
                        } else {
                            newDict = nestedArray[arrayIndex] as? [Key: Any] ?? [Key: Any]()
                        }

                        newDict[keyPath: remainingKeyPath] = newValue

                        if nestedArray.isEmpty {
                            nestedArray.append(newDict)
                        } else {
                            nestedArray[arrayIndex] = newDict
                        }

                        self[key] = nestedArray as? Value
                    } else {
                        Log.shared.error(message: "Remaining key path is empty, should not end up here. Investigate.", category: String(describing: self))
                    }
                default:
                    // Invalid keyPath
                    return
                }
            }
        }
    }
}
