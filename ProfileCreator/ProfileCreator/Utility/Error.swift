//
//  Error.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

let kProfileCreatorErrorDomain = Bundle.main.bundleIdentifier ?? StringConstant.domain

enum ProfileExportError: Error {
    case unknownError(fileName: String, className: String, functionName: String)

    // Saving
    case saveError(path: String)

    // Configuration
    case configurationErrorInvalid(key: String, domain: String, type: PayloadType)

    // Signing
    case signingErrorNoIdentity
    case signingErrorGetIdentity
    case signingErrorFailed(usingCertificate: String, withError: String)

    // Payload
    case noPayload(domain: String, type: PayloadType)

    // Settings
    case settingsErrorEmptyDomain(domain: String, type: PayloadType)
    case settingsErrorEmptyKey(key: String, domain: String, type: PayloadType)
    case settingsErrorInvalid(value: Any?, key: String, domain: String, type: PayloadType)
    case settingsErrorIndexOutOfBounds(index: Int, key: String, domain: String, type: PayloadType)
}

enum ProfileImportError: Error {
    case unknownError(fileName: String, className: String, functionName: String)
    case isEncrypted
}

public enum ProfileCreatorError: Int {

    case unknown = 1
    case notAuthenticated = 2

    func userInfo() -> [String: String] {
        var localizedDescription: String = ""
        let localizedFailureReasonError: String = "" // Unused
        let localizedRecoverySuggestionError: String = "" // Unused

        switch self {
        case .unknown:
            localizedDescription = NSLocalizedString("Error.Unknown", comment: "Unknown error")
        case .notAuthenticated:
            localizedDescription = NSLocalizedString("Error.NotAuthenticated", comment: "User not authenticated")
        }

        return [
            NSLocalizedDescriptionKey: localizedDescription,
            NSLocalizedFailureReasonErrorKey: localizedFailureReasonError,
            NSLocalizedRecoverySuggestionErrorKey: localizedRecoverySuggestionError
        ]
    }
}

extension NSError {
    convenience init(type: ProfileCreatorError) {
        self.init(domain: kProfileCreatorErrorDomain, code: type.rawValue, userInfo: type.userInfo())
    }
}
