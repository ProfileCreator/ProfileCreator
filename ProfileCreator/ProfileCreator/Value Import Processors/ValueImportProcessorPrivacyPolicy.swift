//
//  ValueImportProcessorPrivacyPolicy.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ValueImportProcessorPrivacyPolicy: ValueImportProcessor {

    init() {
        super.init(identifier: "com.apple.TCC.configuration-profile-policy.services")
    }

    override func addValue(toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        guard let fileURL = self.fileURL else {
            completionHandler(nil)
            return
        }

        var value = [String: Any]()

        // whiteList.whiteListItem.appStore
        value["StaticCode"] = false

        // whiteList.whiteListItem.disabled
        value["Allowed"] = true

        if let fileUTI = self.fileUTI, NSWorkspace.shared.type(fileUTI, conformsToType: kUTTypeApplicationBundle as String) {

            guard
                let applicationBundle = Bundle(url: fileURL),
                let bundleIdentifier = applicationBundle.bundleIdentifier else {
                throw ValueImportError("The file: \"\(self.fileURL?.lastPathComponent ?? "Unknown File")\" does not seem to be a valid application bundle.")
            }

            // Check if this bundle identifier is already added
            if let currentValue = toCurrentValue as? [[String: Any]], currentValue.contains(where: { $0["Identifier"] as? String == bundleIdentifier }) {
                completionHandler(nil)
                return
            }

            guard let designatedCodeRequirement = applicationBundle.designatedCodeRequirementString else {
                throw ValueImportError("The file: \"\(self.fileURL?.lastPathComponent ?? "Unknown File")\" did not have a designated code requirement for it's code signature, and cannot be used.")
            }

            value["IdentifierType"] = "bundleID"
            value["Identifier"] = bundleIdentifier
            value["CodeRequirement"] = designatedCodeRequirement

        } else {

            // Check if this path is already added
            if let currentValue = toCurrentValue as? [[String: Any]], currentValue.contains(where: { $0["Identifier"] as? String == fileURL.path }) {
                completionHandler(nil)
                return
            }

            guard let designatedCodeRequirement = SecRequirementCopyString(forURL: fileURL) else {
                throw ValueImportError("The file: \"\(self.fileURL?.lastPathComponent ?? "Unknown File")\" did not have a designated code requirement for it's code signature, and cannot be used.")
            }

            value["IdentifierType"] = "path"
            value["Identifier"] = fileURL.path
            value["CodeRequirement"] = designatedCodeRequirement
        }

        if var currentValue = toCurrentValue as? [[String: Any]] {
            currentValue.append(value)
            completionHandler(currentValue)
        } else {
            completionHandler([value])
        }
    }
}
