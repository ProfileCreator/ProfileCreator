//
//  DesignatedRequirement.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

public func SecRequirement(forURL url: URL) -> SecRequirement? {
    var osStatus = noErr
    var codeRef: SecStaticCode?

    osStatus = SecStaticCodeCreateWithPath(url as CFURL, [], &codeRef)
    guard osStatus == noErr, let code = codeRef else {
        Log.shared.error(message: "Failed to create static code with path: \(url.path)", category: String(describing: #function))
        if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
            Log.shared.error(message: osStatusError as String, category: String(describing: #function))
        }
        return nil
    }

    let flags: SecCSFlags = SecCSFlags(rawValue: 0)
    var requirementRef: SecRequirement?

    osStatus = SecCodeCopyDesignatedRequirement(code, flags, &requirementRef)
    guard osStatus == noErr, let requirement = requirementRef else {
        Log.shared.error(message: "Failed to copy designated requirement.", category: String(describing: #function))
        if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
            Log.shared.error(message: osStatusError as String, category: String(describing: #function))
        }
        return nil
    }
    return requirement
}

public func SecRequirementCopyData(forURL url: URL) -> Data? {

    guard let requirement = SecRequirement(forURL: url) else {
        return nil
    }

    var osStatus = noErr
    let flags: SecCSFlags = SecCSFlags(rawValue: 0)
    var requirementDataRef: CFData?

    osStatus = SecRequirementCopyData(requirement, flags, &requirementDataRef)
    guard osStatus == noErr, let requirementData = requirementDataRef as Data? else {
        Log.shared.error(message: "Failed to copy requirement data.", category: String(describing: #function))
        if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
            Log.shared.error(message: osStatusError as String, category: String(describing: #function))
        }
        return nil
    }

    return requirementData
}

public func SecRequirementCopyString(forURL url: URL) -> String? {

    guard let requirement = SecRequirement(forURL: url) else {
        return nil
    }

    var osStatus = noErr
    let flags: SecCSFlags = SecCSFlags(rawValue: 0)

    var requirementStringRef: CFString?
    osStatus = SecRequirementCopyString(requirement, flags, &requirementStringRef)
    guard osStatus == noErr, let requirementString = requirementStringRef as String? else {
        Log.shared.error(message: "Failed to copy requirement string.", category: String(describing: #function))
        if let osStatusError = SecCopyErrorMessageString(osStatus, nil) {
            Log.shared.error(message: osStatusError as String, category: String(describing: #function))
        }
        return nil
    }

    return requirementString
}
