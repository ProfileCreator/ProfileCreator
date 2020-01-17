//
//  ProfileSettingsViewSettings.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    // MARK: -
    // MARK: Get

    func viewSettings(forPayloadType type: PayloadType) -> [String: [[String: Any]]]? {
        return self.settingsView[type.rawValue]
    }

    func viewSettings(forDomainIdentifier domainIdentifier: String, payloadType type: PayloadType) -> [[String: Any]]? {
        guard let typeSettings = self.viewSettings(forPayloadType: type) else { return nil }
        return typeSettings[domainIdentifier]
    }

    func viewSettings(forDomainIdentifier domainIdentifier: String, payloadType type: PayloadType, payloadIndex: Int) -> [String: Any]? {
        guard
            let domainSettings = self.viewSettings(forDomainIdentifier: domainIdentifier, payloadType: type),
            payloadIndex < domainSettings.count else { return nil }
        return domainSettings[payloadIndex]
    }

    func viewSettings(forKeyPath keyPath: String, domainIdentifier: String, payloadType type: PayloadType, payloadIndex: Int) -> [String: Any]? {
        guard let domainSettings = self.viewSettings(forDomainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex) else { return nil }
        return domainSettings[keyPath] as? [String: Any]
    }

    // MARK: -
    // MARK: Set

    func setViewSettings(_ typeSettings: [String: [[String: Any]]], forPayloadType type: PayloadType) {
        self.settingsView[type.rawValue] = typeSettings
    }

    func setViewSettings(_ domainSettings: [[String: Any]], forDomainIdentifier domainIdentifier: String, payloadType type: PayloadType) {
        var typeSetting = self.viewSettings(forPayloadType: type) ?? [String: [[String: Any]]]()
        typeSetting[domainIdentifier] = domainSettings
        self.setViewSettings(typeSetting, forPayloadType: type)
    }

    func setViewSettings(_ domainSetting: [String: Any], forDomainIdentifier domainIdentifier: String, payloadType type: PayloadType, payloadIndex: Int) {
        var domainSettings = self.viewSettings(forDomainIdentifier: domainIdentifier, payloadType: type) ?? [[String: Any]]()
        if payloadIndex < domainSettings.count {
            domainSettings[payloadIndex] = domainSetting
        } else {
            domainSettings.append(domainSetting)
            if domainSettings.count < payloadIndex {
                Log.shared.error(message: "Trying to set a domain setting at an out of bounds index: \(payloadIndex). Currently only: \(domainSettings.count) domain payload settings are available.", category: String(describing: self))
            }
        }
        self.setViewSettings(domainSettings, forDomainIdentifier: domainIdentifier, payloadType: type)
    }

    func setViewSettings(_ keySetting: [String: Any], forKeyPath keyPath: String, domainIdentifier: String, payloadType type: PayloadType, payloadIndex: Int) {
        var domainSettings = self.viewSettings(forDomainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex) ?? [String: Any]()
        domainSettings[keyPath] = keySetting
        self.setViewSettings(domainSettings, forDomainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex)
    }
}
