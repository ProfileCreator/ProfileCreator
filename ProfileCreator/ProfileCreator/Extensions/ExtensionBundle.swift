//
//  ExtensionBundle.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

extension Bundle {
    var bundleVersion: String? {
        if let bundleVersion = self.infoDictionary?["CFBundleVersion"] as? String {
            return bundleVersion
        } else { return nil }
    }

    var bundleDisplayName: String? {
        if let bundleDisplayName = self.infoDictionary?["CFBundleDisplayName"] as? String {
            return bundleDisplayName
        } else { return nil }
    }

    var bundleName: String? {
        if let bundleDisplayName = self.infoDictionary?["CFBundleName"] as? String {
            return bundleDisplayName
        } else { return nil }
    }

    var teamIdentifier: String? {
        var osStatus = noErr
        var codeRef: SecStaticCode?

        osStatus = SecStaticCodeCreateWithPath(self.bundleURL as CFURL, [], &codeRef)
        guard osStatus == noErr, let code = codeRef else {
            Log.shared.error(message: "Failed to create static code with path: \(self.bundleURL.path)", category: String(describing: self))
            if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
                Log.shared.error(message: osStatusError as String, category: String(describing: self))
            }
            return nil
        }

        let flags: SecCSFlags = SecCSFlags(rawValue: kSecCSSigningInformation)
        var codeInfoRef: CFDictionary?

        osStatus = SecCodeCopySigningInformation(code, flags, &codeInfoRef)
        guard osStatus == noErr, let codeInfo = codeInfoRef as? [String: Any] else {
            Log.shared.error(message: "Failed to copy code signing information.", category: String(describing: self))
            if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
                Log.shared.error(message: osStatusError as String, category: String(describing: self))
            }
            return nil
        }

        guard let teamIdentifier = codeInfo[kSecCodeInfoTeamIdentifier as String] as? String else {
            Log.shared.error(message: "Found no entry for \(kSecCodeInfoTeamIdentifier) in code signing info dictionary.", category: String(describing: self))
            return nil
        }

        return teamIdentifier
    }

    var designatedCodeRequirementData: Data? {
        SecRequirementCopyData(forURL: self.bundleURL)
    }

    var designatedCodeRequirementString: String? {
        SecRequirementCopyString(forURL: self.bundleURL)
    }
}
