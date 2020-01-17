//
//  ValueImportProcessorASAMApplications.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ValueImportProcessorASAMApplications: ValueImportProcessor {

    init() {
        super.init(identifier: "com.apple.asam.AllowedApplications")
    }

    override func addValue(toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        // Verify it's an application bundle
        guard
            let fileUTI = self.fileUTI,
            NSWorkspace.shared.type(fileUTI, conformsToType: kUTTypeApplicationBundle as String),
            let fileURL = self.fileURL,
            let applicationBundle = Bundle(url: fileURL) else {
                completionHandler(nil)
                return
        }

        guard let bundleIdentifier = applicationBundle.bundleIdentifier else {
            throw ValueImportError("The file: \"\(self.fileURL?.lastPathComponent ?? "Unknown File")\" does not seem to be a valid application bundle.")
        }

        var value = [String: String]()

        // AllowedApplications.AllowedApplicationsItem.BundleIdentifier
        value["BundleIdentifier"] = bundleIdentifier

        // AllowedApplications.AllowedApplicationsItem.TeamIdentifier
        value["TeamIdentifier"] = applicationBundle.teamIdentifier ?? ""

        if var currentValue = toCurrentValue as? [[String: String]] {
            if !currentValue.contains(value) {
                currentValue.append(value)
            }
            completionHandler(currentValue)
        } else {
            completionHandler([value])
        }
    }
}
