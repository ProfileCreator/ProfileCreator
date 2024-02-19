//
//  ProfileSettingsSettings.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    // MARK: -
    // MARK: - Count

    func settingsCount(forDomainIdentifier domainIdentifier: String, type: PayloadType) -> Int {
        self.settings(forDomainIdentifier: domainIdentifier, type: type)?.count ?? 0
    }

    func settingsEmptyCount(forDomainIdentifier domainIdentifier: String, type: PayloadType) -> Int {
        var emptyCount = 0
        let domainSettingsArray = self.settings(forDomainIdentifier: domainIdentifier, type: type) ?? [[String: Any]]()
        if domainSettingsArray.isEmpty {
            return 1
        } else {
            for domainSettings in domainSettingsArray where Array(Set(domainSettings.keys).subtracting([PayloadKey.payloadVersion, PayloadKey.payloadUUID])).isEmpty {
                emptyCount += 1
            }
        }

        return emptyCount
    }

    // MARK: -
    // MARK: Get

    func settings(forType type: PayloadType) -> [String: [[String: Any]]]? {
        self.settingsPayload[type.rawValue]
    }

    func settings(forPayload payload: Payload) -> [[String: Any]]? {
        self.settings(forDomainIdentifier: payload.domainIdentifier, type: payload.type)
    }

    func settings(forDomain domain: String, type: PayloadType, exact: Bool = false) -> [[[String: Any]]]? {
        guard let typeSettings = self.settings(forType: type) else { return nil }
        if exact {
            return Array(typeSettings.filter { $0.key == domain }.values)
        } else {
            return Array(typeSettings.filter { $0.key.hasPrefix(domain) }.values)
        }
    }

    func settings(forDomainIdentifier domainIdentifier: String, type: PayloadType) -> [[String: Any]]? {
        guard let typeSettings = self.settings(forType: type) else { return nil }
        return typeSettings[domainIdentifier]
    }

    func settings(forDomainIdentifier domainIdentifier: String, type: PayloadType, payloadIndex: Int) -> [String: Any]? {
        guard
            let domainSettings = self.settings(forDomainIdentifier: domainIdentifier, type: type),
            payloadIndex < domainSettings.count else { return nil }
        return domainSettings[payloadIndex]
    }

    // MARK: -
    // MARK: Set

    func setSettings(_ typeSettings: [String: [[String: Any]]], forType type: PayloadType) {
        self.settingsPayload[type.rawValue] = typeSettings
    }

    func setSettings(_ domainSettings: [[String: Any]], forPayload payload: Payload) {
        self.setSettings(domainSettings, forDomainIdentifier: payload.domainIdentifier, type: payload.type)
    }

    func setSettings(_ domainSettings: [[String: Any]], forDomainIdentifier domainIdentifier: String, type: PayloadType) {
        var typeSetting = self.settings(forType: type) ?? [String: [[String: Any]]]()
        typeSetting[domainIdentifier] = domainSettings
        self.setSettings(typeSetting, forType: type)
    }

    func setSettings(_ domainSetting: [String: Any], forDomainIdentifier domainIdentifier: String, type: PayloadType, payloadIndex: Int) {
        var domainSettings = self.settings(forDomainIdentifier: domainIdentifier, type: type) ?? [[String: Any]]()
        if payloadIndex < domainSettings.count {
            domainSettings[payloadIndex] = domainSetting
        } else {
            domainSettings.append(domainSetting)
            if domainSettings.count < payloadIndex {
                Log.shared.error(message: "Trying to set a domain setting at an out of bounds index: \(payloadIndex). Currently only: \(domainSettings.count) domain payload settings are available.", category: String(describing: self))
            }
        }
        self.setSettings(domainSettings, forDomainIdentifier: domainIdentifier, type: type)
    }

    func setSettingsDefault(forPayload payload: Payload) { // DomainIdentifier domainIdentifier: String, type: PayloadType) {
        var domainSettings = [String: Any]()
        self.initializeDomainSetting(&domainSettings, forPayload: payload)
        self.setSettings(domainSettings,
                         forDomainIdentifier: payload.domainIdentifier,
                         type: payload.type,
                         payloadIndex: self.settingsCount(forDomainIdentifier: payload.domainIdentifier, type: payload.type))
    }

    func verifySettings(_ domainSettingsArray: inout [[String: Any]], forPayload payload: Payload) {
        if domainSettingsArray.isEmpty {
            var domainSettings = [String: Any]()
            self.initializeDomainSetting(&domainSettings, forPayload: payload)
            domainSettingsArray.append(domainSettings)
        } else {
            for index in domainSettingsArray.indices {
                var domainSettings = domainSettingsArray[index]
                self.initializeDomainSetting(&domainSettings, forPayload: payload)
                domainSettingsArray[index] = domainSettings
            }
        }
    }

    // MARK: -
    // MARK: Remove

    func removeSettings(forDomainIdentifier domainIdentifier: String, type: PayloadType, payloadIndex: Int) {
        guard var domainSettings = self.settings(forDomainIdentifier: domainIdentifier, type: type) else { return }
        if payloadIndex < domainSettings.count {
            domainSettings.remove(at: payloadIndex)
        }
        self.setSettings(domainSettings, forDomainIdentifier: domainIdentifier, type: type)
    }
}
