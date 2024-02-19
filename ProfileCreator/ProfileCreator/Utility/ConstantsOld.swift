//
//  Constants.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

struct TypeName {
    static let profile = "Profile"
}

struct FileExtension {
    static let group = "pfcgrp"
    static let profile = "pfcconf"
}

// This needs to be renamed after more items are added, to make it easier to understand and use.
struct StringConstant {
    static let domain = "com.willyu.ProfileCreator"
    static let defaultProfileName = "Untitled"
    static let githubURL = "https://github.com/WillYu91/ProfileCreator"
    static let noPayloads = NSLocalizedString("No Payloads", comment: "")
    static let noMatch = NSLocalizedString("No Match", comment: "")
    static let payloadIdentifierFormat = "%ROOTID%.%TYPE%.%UUID%"
    static let profileIdentifierFormat = "%ORGID%.%UUID%"
}

struct PayloadContentStyle {
    static let mcx = "MCX"
    static let profile = "Profile"
    static let plist = "Plist"
}

struct ProfileLibraryFileNameFormat {
    static let payloadUUID = "PayloadUUID"
    static let payloadIdentifier = "PayloadIdentifier"
}

struct SidebarGroupTitle {
    static let allProfiles = "All Profiles"
    static let library = "Library"
    static let jamf = "Jamf"
}

public func valueIsEqual(payloadValueType: PayloadValueType, a: Any, b: Any) -> Bool {
    switch payloadValueType {
    case .bool:
        return isEqual(type: Bool.self, a: a, b: b)
    case .data:
        return isEqual(type: Data.self, a: a, b: b)
    case .date:
        return isEqual(type: Date.self, a: a, b: b)
    case .float:
        return isEqual(type: Float.self, a: a, b: b)
    case .integer:
        return isEqual(type: Int.self, a: a, b: b)
    case .string:
        return isEqual(type: String.self, a: a, b: b)
    default:
        return false
    }
}

func isEqual<T: Equatable>(type: T.Type, a: Any, b: Any) -> Bool {
    guard let a = a as? T, let b = b as? T else { return false }
    return a == b
}
