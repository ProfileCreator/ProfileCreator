// swiftlint:disable:next file_header
//  LenientDateFormatter.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/16/2015.
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

import Cocoa

/// `LenientDateFormatter` instances read/write `NSDate` instances in a highly flexible way. Rather
/// than specifying an actual format, they use data detectors to parse dates in strings.
class LenientDateFormatter: Formatter {
    /// Returns an `NSDate` instance by parsing the specified string.
    /// - parameter string: The string to parse.
    /// - returns: The `Date` instance that was parsed or `nil` if parsing failed.
    func date(from string: String) -> Date? {
        var date: AnyObject?
        return getObjectValue(&date, for: string, errorDescription: nil) ? date as? Date : nil
    }

    override func string(for obj: Any?) -> String? {
        return DateFormatter.propertyListOutput.string(for: obj)
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
                                 for string: String,
                                 errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
            let matches = detector.matches(in: string,
                                           options: NSRegularExpression.MatchingOptions(),
                                           range: NSRange(location: 0, length: string.count))

            for match in matches where match.date != nil {
                obj?.pointee = match.date as NSDate?
                return true
            }
        } catch {
            return false
        }

        return false
    }
}
