//
//  ValueImportProcessorKernelExtensionPolicyTeamIdentifiers.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

class ValueImportProcessorKernelExtensionPolicyTeamIdentifiers: ValueImportProcessor {

    init() {
        super.init(identifier: "com.apple.syspolicy.kernel-extension-policy.AllowedTeamIdentifiers")
    }

     override func addValue(toCurrentValue: [Any]?, cellView: PayloadCellView, completionHandler: @escaping (_ value: Any?) -> Void) throws {

        // Verify it's a kext bundle
        guard
            let fileExtension = self.fileURL?.pathExtension,
            let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeUnretainedValue() as String?,
            let kextUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "kext" as CFString, nil)?.takeUnretainedValue() as String?,
            fileUTI == kextUTI else {
                throw ValueImportError("Only kernel extensions (.kext) are allowed in this payload.")
        }

        guard
            let fileURL = self.fileURL,
            let kextBundle = Bundle(url: fileURL) else {
                throw ValueImportError("The file: \"\(self.fileURL?.lastPathComponent ?? "Unknown File")\" does not seem to be a valid kernel extension.")
        }

        guard let teamIdentifier = kextBundle.teamIdentifier else {
            throw ValueImportError("The kernel extension: \"\(kextBundle.bundleDisplayName ?? kextBundle.bundleURL.lastPathComponent)\" does not seem to be signed. No Team Identifier could be found.")
        }

        if var currentValue = toCurrentValue as? [String] {
            if !currentValue.contains(teamIdentifier) {
                currentValue.append(teamIdentifier)
            }
            completionHandler(currentValue)
        } else {
            completionHandler([teamIdentifier])
        }
    }
}
