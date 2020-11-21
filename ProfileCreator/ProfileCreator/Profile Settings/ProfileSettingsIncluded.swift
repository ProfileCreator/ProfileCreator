//
//  ProfileSettingsIncluded.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    func isIncludedInProfile(payload: Payload) -> Bool {
        self.isIncludedInProfile(domainIdentifier: payload.domainIdentifier, type: payload.type)
    }

    func isIncludedInProfile(domainIdentifier: String, type: PayloadType) -> Bool {
        !self.payloadSettingsEnabled(forDomainIdentifier: domainIdentifier, type: type).isEmpty
    }

}
