//
//  CoreExtensions.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

// MARK: -
// MARK: Dictionary

extension Dictionary {

    // https://gist.github.com/LoganWright/fef555b38c3438565793#gistcomment-2341687
    mutating public func setValue(value: Any, forKeyPath keyPath: String) {
        var keys = keyPath.components(separatedBy: ".")
        guard let first = keys.first as? Key else {
            Log.shared.error(message: "Unable to use string as key on type: \(Key.self)", category: "")
            return
        }
        keys.remove(at: 0)
        if keys.isEmpty, let settable = value as? Value {
            self[first] = settable
        } else {
            let rejoined = keys.joined(separator: ".")
            var subdict: [NSObject: AnyObject] = [:]
            if let sub = self[first] as? [NSObject: AnyObject] {
                subdict = sub
            }
            subdict.setValue(value: value, forKeyPath: rejoined)
            if let settable = subdict as? Value {
                self[first] = settable
            } else {
                Log.shared.error(message: "Unable to set value: \(subdict) to dictionary of type: \(type(of: self))", category: "")
            }
        }
    }

    mutating public func removeValue(forKeyPath keyPath: String) {
        var keys = keyPath.components(separatedBy: ".")
        guard let first = keys.first as? Key else {
            Log.shared.error(message: "Unable to use string as key on type: \(Key.self)", category: "")
            return
        }
        keys.remove(at: 0)
        if keys.isEmpty {
            self.removeValue(forKey: first)
        } else {
            let rejoined = keys.joined(separator: ".")
            var subdict: [NSObject: AnyObject] = [:]
            if let sub = self[first] as? [NSObject: AnyObject] {
                subdict = sub
            }
            subdict.removeValue(forKeyPath: rejoined)
            /*
            if let settable = subdict as? Value {
                self[first] = settable
            } else {
                Log.shared.error(message: "Unable to set value: \(subdict) to dictionary of type: \(type(of: self))", category: "")
            }
 */
        }
    }

    // https://gist.github.com/LoganWright/fef555b38c3438565793#gistcomment-2341687
    public func valueForKeyPath(keyPath: String) -> Any? {
        var keys = keyPath.components(separatedBy: ".")
        guard let first = keys.first as? Key else {
            Log.shared.error(message: "Unable to use string as key on type: \(Key.self)", category: "")
            return nil
        }
        guard let value = self[first] else {
            return nil
        }
        keys.remove(at: 0)
        if !keys.isEmpty, let subDict = value as? [NSObject: AnyObject] {
            let rejoined = keys.joined(separator: ".")
            return subDict.valueForKeyPath(keyPath: rejoined)
        }
        return value
    }
}

// MARK: -
// MARK: Array

extension Array where Element: Equatable {
    func indexes(ofItems items: [Element]) -> IndexSet? {
        return IndexSet(self.enumerated().compactMap { items.contains($0.element) ? $0.offset : nil })
    }
}

extension Array {

    // From: https://stackoverflow.com/a/33948261
    func objectsAtIndexes(indexes: IndexSet) -> [Element] {
        let elements: [Element] = indexes.map { idx in
            if idx < self.count {
                return self[idx]
            }
            return nil
        }.compactMap { $0 }
        return elements
    }
}

// MARK: -
// MARK: Date

extension Date {
    func midnight() -> Date? {
        if
            let sourceTimeZone = NSTimeZone(abbreviation: "GMT") {
            let destinationTimeZone = NSTimeZone.system
            let interval = TimeInterval(destinationTimeZone.secondsFromGMT(for: self) - sourceTimeZone.secondsFromGMT(for: self))
            let dateInSystemTimeZone = Date(timeInterval: interval, since: self)
            var components = Calendar.current.dateComponents([.year, .month, .day], from: dateInSystemTimeZone)
            components.hour = 0
            components.minute = 0
            components.second = 0
            return Calendar.current.date(from: components)
        }
        return self
    }
}

// MARK: -
// MARK: ==

// Compare Dictionaries
public func == (lhs: [AnyHashable: Any], rhs: [AnyHashable: Any] ) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

public func != (lhs: [AnyHashable: Any], rhs: [AnyHashable: Any] ) -> Bool {
    return !NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

// Compare Dictionaries - This SHOULD be covered by the above AnyHashable but apparently not
public func == (lhs: [String: Any], rhs: [String: Any] ) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

public func != (lhs: [String: Any], rhs: [String: Any] ) -> Bool {
    return !NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

// MARK: -
// MARK: String

extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) == range(of: self)
    }
}

// MARK: -
// MARK: NSMutableAttributedString

extension NSMutableAttributedString {
    public func setAsLink(textToFind: String, linkURL: String) -> Bool {
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(.link, value: linkURL, range: foundRange)
            return true
        }
        return false
    }
}

// MARK: -
// MARK: NSView

// Get all nested subviews
extension NSView {
    func allSubviews() -> [NSView] {
        var subviews = [NSView]()

        for subview in self.subviews {
            subviews += subview.allSubviews() as [NSView]
            subviews.append(subview)
        }

        return subviews
    }
}

// MARK: -
// MARK: NSPasteboard.PasteboardType

extension NSPasteboard.PasteboardType {

    static let backwardsCompatibleFileURL: NSPasteboard.PasteboardType = {

        if #available(OSX 10.13, *) {
            return NSPasteboard.PasteboardType.fileURL
        } else {
            return NSPasteboard.PasteboardType(kUTTypeFileURL as String)
        }

    } ()

}
