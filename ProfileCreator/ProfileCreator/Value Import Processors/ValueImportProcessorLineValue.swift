//
//  ValueImportProcessorDirectory.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class ValueImportProcessorLineValue: ValueImportProcessor {

    init() {
        super.init(identifier: kUTTypePlainText as String)
    }

    override func addValue(toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        // Text
        guard
            let fileUTI = self.fileUTI,
            let fileURL = self.fileURL,
            NSWorkspace.shared.type(fileUTI, conformsToType: kUTTypePlainText as String),
            let subSubkey = subkey?.subkeys.first else { completionHandler(nil); return }

        var regexString = ""
        let valueSubkey: PayloadSubkey

        if subSubkey.type == .dictionary {
            guard let subSubSubkey = subSubkey.subkeys.first, let regex = subSubSubkey.format else {
                completionHandler(nil); return
            }
            valueSubkey = subSubSubkey
            regexString = regex
        } else {
            guard let regex = subSubkey.format else { completionHandler(nil); return }
            valueSubkey = subSubkey
            regexString = regex
        }

        guard !regexString.isEmpty else { completionHandler(nil); return }

        regexString = regexString.deletingPrefix("^")
        regexString = regexString.deletingSuffix("$")

        var newValue = [Any]()

        do {
            let fileContent = try String(contentsOfFile: fileURL.path, encoding: .utf8)
            for line in fileContent.components(separatedBy: CharacterSet.newlines) {
                let regex = try NSRegularExpression(pattern: regexString, options: [])
                let regexMatches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
                if let match = regexMatches.first, let matchValue = line.substring(with: match.range) {
                    switch subSubkey.type {
                    case .dictionary:
                        newValue.append([valueSubkey.key: String(matchValue)])
                    case .string:
                        newValue.append(String(matchValue))
                    default:
                        Log.shared.error(message: "Unhandled type: \(valueSubkey.type)", category: String(describing: self))
                        completionHandler(nil)
                        return
                    }
                }
            }
        } catch {
            completionHandler(nil)
            return
        }

        guard var currentValue = toCurrentValue, !currentValue.isEmpty else {
            completionHandler(newValue)
            return
        }

        switch subSubkey.type {
        case .dictionary:
            switch valueSubkey.type {
            case .string:
                // FIXME: Do this with generics
                if var sourceA = currentValue as? [[String: String]], let newA = newValue as? [[String: String]] {
                    sourceA.mergeElements(newElements: newA)
                    currentValue = sourceA
                }
            default:
                Log.shared.error(message: "Unhandled type: \(valueSubkey.type)", category: String(describing: self))
                completionHandler(nil)
                return
            }

        case .string:
            if var sourceA = currentValue as? [String], let newA = newValue as? [String] {
                sourceA.mergeElements(newElements: newA)
                currentValue = sourceA
            }
        default:
            Log.shared.error(message: "Unhandled type: \(valueSubkey.type)", category: String(describing: self))
        }

        completionHandler(currentValue)
    }
}
