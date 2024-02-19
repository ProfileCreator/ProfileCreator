//
//  ValueImportProcessorDashboardWhiteList.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

// swiftlint:disable:next inclusive_language
class ValueImportProcessorDashboardWhiteList: ValueImportProcessor {

    init() {
        super.init(identifier: "com.apple.dashboard.whiteList")
    }

    override func addValue(toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        // Verify it's a dashboard widget
        guard
            self.fileUTI == UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "wdgt" as CFString, nil)?.takeUnretainedValue() as String?,
            let fileURL = self.fileURL,
            let applicationBundle = Bundle(url: fileURL) else {
                completionHandler(nil)
                return
        }

        guard let bundleIdentifier = applicationBundle.bundleIdentifier else {
            throw ValueImportError("The file: \"\(self.fileURL?.lastPathComponent ?? "Unknown File")\" does not seem to be a valid application bundle.")
        }

        // Check if this bundle identifier is already added
        if let currentValue = toCurrentValue as? [[String: Any]], currentValue.contains(where: { $0["ID"] as? String == bundleIdentifier }) {
            completionHandler(nil)
            return
        }

        var value = [String: Any]()

        // whiteList.whiteListItem.Type
        value["Type"] = "bundleID"

        // whiteList.whiteListItem.bundleID
        value["ID"] = bundleIdentifier

        if var currentValue = toCurrentValue as? [[String: Any]] {
            currentValue.append(value)
            completionHandler(currentValue)
        } else {
            completionHandler([value])
        }
    }
}
