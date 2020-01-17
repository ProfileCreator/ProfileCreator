//
//  ValueImportProcessorKernelExtensionPolicyKernelExtensions.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class ValueImportProcessorKernelExtensionPolicyKernelExtensions: ValueImportProcessor {

    init() {
        super.init(identifier: "com.apple.syspolicy.kernel-extension-policy.AllowedKernelExtensions")
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

        var value = [String: Any]()
        var bundleIdentifiers = [String]()

        guard let teamIdentifier = kextBundle.teamIdentifier else {
            throw ValueImportError("The kernel extension: \"\(kextBundle.bundleDisplayName ?? kextBundle.bundleURL.lastPathComponent)\" does not seem to be signed. No team identifier could be found.")
        }

        guard let bundleIdentifier = kextBundle.bundleIdentifier else {
            throw ValueImportError("The kernel extension: \"\(kextBundle.bundleDisplayName ?? kextBundle.bundleURL.lastPathComponent)\" does not seem to be a valid kernel extension. No bundle identifier could be found.")
        }

        if let currentValue = toCurrentValue as? [[String: Any]] {
            if let existingDict = currentValue.first(where: { $0[ManifestKeyPlaceholder.key] as? String == teamIdentifier }) {
                value = existingDict
                bundleIdentifiers = existingDict[ManifestKeyPlaceholder.value] as? [String] ?? [String]()
            }
        }

        if value.isEmpty {
            value[ManifestKeyPlaceholder.key] = teamIdentifier
        }

        if !bundleIdentifiers.contains(bundleIdentifier) {
            bundleIdentifiers.append(bundleIdentifier)
        }

        value[ManifestKeyPlaceholder.value] = bundleIdentifiers

        if var currentValue = toCurrentValue as? [[String: Any]] {
            if let index = currentValue.firstIndex(where: { $0[ManifestKeyPlaceholder.key] as? String == value[ManifestKeyPlaceholder.key] as? String }) {
                currentValue[index] = value
            } else {
                currentValue.append(value)
            }
            completionHandler(currentValue)
        } else {
            completionHandler([value])
        }
    }
}
