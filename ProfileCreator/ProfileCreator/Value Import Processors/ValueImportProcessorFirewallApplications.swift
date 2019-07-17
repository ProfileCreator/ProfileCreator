//
//  ValueImportProcessorFirewallApplications.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ValueImportProcessorFirewallApplications: ValueImportProcessor {

    init() {
        super.init(identifier: "com.apple.security.firewall.Applications")
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

        var value = [String: Any]()

        // Applications.ApplicationItem.Allowed
        value["Allowed"] = false

        // Applications.ApplicationItem.BundleID
        value["BundleID"] = bundleIdentifier

        // Applications.ApplicationItem.Name
        value["Name"] = applicationBundle.bundleDisplayName ?? applicationBundle.bundleName ?? ""

        if var currentValue = toCurrentValue as? [[String: Any]] {
            if !currentValue.contains(where: { $0["BundleID"] as? String == bundleIdentifier }) {
                currentValue.append(value)
            }
            completionHandler(currentValue)
        } else {
            completionHandler([value])
        }
    }
}
