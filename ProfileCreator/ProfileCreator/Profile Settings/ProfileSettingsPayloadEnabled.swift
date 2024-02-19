//
//  ProfileSettingsPayloadEnabled.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    func payloadSettingsEnabledCount() -> Int {
        self.payloadSettingsEnabled().count
    }

    func isEnabled(_ payload: Payload) -> Bool {
        self.payloadsEnabled().contains { $0.domain == payload.domain }
    }

    // MARK: -
    // MARK: Get

    func payloadsEnabled() -> [Payload] {
        var payloadsEnabled = [Payload]()
        for (typeString, typeSettings) in self.settingsPayload {
            guard let type = PayloadType(rawValue: typeString) else { continue }
            for (domainIdentifier, domainSettings) in typeSettings {
                /*
                if type == .custom, let payload = ProfilePayloads.shared.customManifest(forDomain: domain, ofType: type, payloadContent: domainSettings) {
                    payloadsEnabled.append(payload)
                } else {
 */
                    for domainSetting in domainSettings where domainSetting[PayloadKey.payloadEnabled] as? Bool == true {
                        if let payload = ProfilePayloads.shared.payload(forDomainIdentifier: domainIdentifier, type: type) {
                            payloadsEnabled.append(payload)
                        }
                    }
                // }
            }
        }
        return payloadsEnabled
    }

    func payloadSettingsEnabled() -> [[String: Any]] {
        var payloadSettingsEnabled = [[String: Any]]()
        for typeSettings in self.settingsPayload.values {
            for domainSettings in typeSettings.values {
                for domainSetting in domainSettings where domainSetting[PayloadKey.payloadEnabled] as? Bool == true {
                    payloadSettingsEnabled.append(domainSetting)
                }
            }
        }
        return payloadSettingsEnabled
    }

    func payloadSettingsEnabled(forType type: PayloadType) -> [[String: Any]] {
        var payloadSettingsEnabled = [[String: Any]]()
        guard let typeSettings = self.settings(forType: type) else { return payloadSettingsEnabled }
        for domainSettings in typeSettings.values {
            for domainSetting in domainSettings where domainSetting[PayloadKey.payloadEnabled] as? Bool == true {
                payloadSettingsEnabled.append(domainSetting)
            }
        }
        return payloadSettingsEnabled
    }

    func payloadSettingsEnabled(forDomainIdentifier domainIdentifier: String, type: PayloadType) -> [[String: Any]] {
        var payloadSettingsEnabled = [[String: Any]]()
        guard let domainSettings = self.settings(forDomainIdentifier: domainIdentifier, type: type) else { return payloadSettingsEnabled }
        for domainSetting in domainSettings where domainSetting[PayloadKey.payloadEnabled] as? Bool == true {
            payloadSettingsEnabled.append(domainSetting)
        }
        return payloadSettingsEnabled
    }

    // MARK: -
    // MARK: Set

    func setPayloadEnabled(_ enabled: Bool, payload: Payload) {
        self.setPayloadEnabled(enabled, forDomainIdentifier: payload.domainIdentifier, type: payload.type)
    }

    func setPayloadEnabled(_ enabled: Bool, forDomainIdentifier domainIdentifier: String, type: PayloadType) {
        let domainSettings = self.settings(forDomainIdentifier: domainIdentifier, type: type) ?? [[String: Any]]()
        var newDomainSettings = [[String: Any]]()
        for var domainSetting in domainSettings {
            domainSetting[PayloadKey.payloadEnabled] = enabled
            newDomainSettings.append(domainSetting)
        }
        self.setSettings(newDomainSettings, forDomainIdentifier: domainIdentifier, type: type)
    }
}
