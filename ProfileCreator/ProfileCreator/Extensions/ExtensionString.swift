//
//  ExtensionString.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

extension String {
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }

    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }

    var doubleValue: Double? {
        let numberFormatter = NumberFormatter()
        numberFormatter.decimalSeparator = "."
        if let result = numberFormatter.number(from: self) {
            return result.doubleValue
        } else {
            numberFormatter.decimalSeparator = ","
            if let result = numberFormatter.number(from: self) {
                return result.doubleValue
            }
        }
        return nil
    }

    var floatValue: Float? {
        let numberFormatter = NumberFormatter()
        numberFormatter.decimalSeparator = "."
        if let result = numberFormatter.number(from: self) {
            return result.floatValue
        } else {
            numberFormatter.decimalSeparator = ","
            if let result = numberFormatter.number(from: self) {
                return result.floatValue
            }
        }
        return nil
    }
}
