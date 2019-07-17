//
//  ValueImportProcessorDirectory.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ValueImportProcessorDirectory: ValueImportProcessor {

    init() {
        super.init(identifier: "public.folder")
    }

    override func addValue(toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        // Verify it's a folder
        guard
            let fileUTI = self.fileUTI,
            NSWorkspace.shared.type(fileUTI, conformsToType: kUTTypeFolder as String),
            let fileURL = self.fileURL,
            let subSubkey = self.subkey?.subkeys.first else {
                completionHandler(nil)
                return
        }

        guard var currentValue = toCurrentValue, !currentValue.isEmpty else {
            completionHandler([fileURL.path])
            return
        }

        if !currentValue.containsAny(value: fileURL.path, ofType: subSubkey.type) {
            currentValue.append(fileURL.path)
        }

        completionHandler(currentValue)
    }
}
