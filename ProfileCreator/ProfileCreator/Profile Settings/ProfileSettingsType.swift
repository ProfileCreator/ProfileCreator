//
//  ProfileSettingsType.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    class func payloadType(forPayloadSettings payloadSettings: [String: Any]) -> PayloadType {
        guard var domain = payloadSettings[PayloadKey.payloadType] as? String else {
            Log.shared.error(message: "Payload with content: \(payloadSettings) is missing required key: \"PayloadType\".", category: String(describing: self))
            return .custom
        }

        if domain == kManifestDomainConfiguration {
            domain = kManifestDomainConfiguration
        }

        return self.payloadType(forDomain: domain)
    }

    class func payloadType(forDomain domain: String) -> PayloadType {
        guard let types = ProfilePayloads.shared.payloadTypes(forDomain: domain) else {
            Log.shared.error(message: "Unknown PayloadType: \(domain), this content will be ignored.", category: String(describing: self))
            return .custom
        }

        if types.count == 1, let type = types.first {
            return type
        } else {

            // FIXME: Need to compare the actual keys to see which one it most likely is...
            // let domainKeys = Set(payloadSettings.keys)
            // let keys = Array(domainKeys.subtracting(kPayloadSubkeys))
            // FIXME: Just return manifestApple until this is implemented.
            return .manifestsApple
        }
    }

}
