//
//  ProfileSettingsViewValues.swift
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

    func viewValue(forSubkey subkey: PayloadSubkey, payloadIndex: Int) -> Any? {
        return self.viewValue(forKeyPath: subkey.keyPath, domainIdentifier: subkey.domainIdentifier, payloadType: subkey.payloadType, payloadIndex: payloadIndex)
    }

    func viewValue(forKeyPath keyPath: String, domainIdentifier: String, payloadType type: PayloadType, payloadIndex: Int) -> Any? {
        guard let viewDomainSettings = self.viewSettings(forDomainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex) else { return nil }
        return viewDomainSettings[keyPath: KeyPath(keyPath)]
    }

    func viewValue(forKey key: String, subkey: PayloadSubkey, payloadIndex: Int) -> Any? {
        return self.viewValue(forKey: key, keyPath: subkey.keyPath, domainIdentifier: subkey.domainIdentifier, payloadType: subkey.payloadType, payloadIndex: payloadIndex)
    }

    func viewValue(forKey key: String, keyPath: String, domainIdentifier: String, payloadType type: PayloadType, payloadIndex: Int) -> Any? {
        guard let viewKeySettings = self.viewSettings(forKeyPath: keyPath, domainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex) else { return nil }
        return viewKeySettings[key]
    }

    // MARK: -
    // MARK: Set

    func setViewValue(_ value: Any, forSubkey subkey: PayloadSubkey, payloadIndex: Int) {
        self.setViewValue(value, forKeyPath: subkey.keyPath, domainIdentifier: subkey.domainIdentifier, payloadType: subkey.payloadType, payloadIndex: payloadIndex)
    }

    func setViewValue(_ value: Any, forKeyPath keyPath: String, domainIdentifier: String, payloadType type: PayloadType, payloadIndex: Int) {
        var viewDomainSettings = self.viewSettings(forDomainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex) ?? [String: Any]()
        viewDomainSettings[keyPath] = value
        self.setViewSettings(viewDomainSettings, forDomainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex)
    }

    func setViewValue(_ value: Any, forKey key: String, subkey: PayloadSubkey, payloadIndex: Int) {
        self.setViewValue(value, forKey: key, keyPath: subkey.keyPath, domainIdentifier: subkey.domainIdentifier, payloadType: subkey.payloadType, payloadIndex: payloadIndex)
    }

    func setViewValue(_ value: Any, forKey key: String, keyPath: String, domainIdentifier: String, payloadType type: PayloadType, payloadIndex: Int) {
        var viewKeySettings = self.viewSettings(forKeyPath: keyPath, domainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex) ?? [String: Any]()
        viewKeySettings[key] = value
        self.setViewSettings(viewKeySettings, forKeyPath: keyPath, domainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex)
    }

    // MARK: -
    // MARK: Enabled

    // swiftlint:disable:next discouraged_optional_boolean
    func viewValueEnabled(forSubkey subkey: PayloadSubkey, payloadIndex: Int) -> Bool? {
        return self.viewValueEnabled(forKeyPath: subkey.keyPath, domainIdentifier: subkey.domainIdentifier, payloadType: subkey.payloadType, payloadIndex: payloadIndex)
    }

    // swiftlint:disable:next discouraged_optional_boolean
    func viewValueEnabled(forKeyPath keyPath: String, domainIdentifier: String, payloadType: PayloadType, payloadIndex: Int) -> Bool? {
        return self.viewValue(forKey: SettingsKey.enabled, keyPath: keyPath, domainIdentifier: domainIdentifier, payloadType: payloadType, payloadIndex: payloadIndex) as? Bool
    }

    func setViewValue(enabled: Bool, forSubkey subkey: PayloadSubkey, payloadIndex: Int) {
        self.setViewValue(enabled: enabled, forKeyPath: subkey.keyPath, domainIdentifier: subkey.domainIdentifier, payloadType: subkey.payloadType, payloadIndex: payloadIndex)
    }

    func setViewValue(enabled: Bool, forKeyPath keyPath: String, domainIdentifier: String, payloadType: PayloadType, payloadIndex: Int) {
        self.setViewValue(enabled, forKey: SettingsKey.enabled, keyPath: keyPath, domainIdentifier: domainIdentifier, payloadType: payloadType, payloadIndex: payloadIndex)
    }

    // MARK: -
    // MARK: Hash

    func viewValueHash(forDomainIdentifier domainIdentifier: String, payloadType: PayloadType, payloadIndex: Int) -> Int? {
        return self.viewValue(forKeyPath: SettingsKey.hash, domainIdentifier: domainIdentifier, payloadType: payloadType, payloadIndex: payloadIndex) as? Int
    }

    func setViewValue(hash: Int, forDomainIdentifier domainIdentifier: String, payloadType: PayloadType, payloadIndex: Int) {
        self.setViewValue(hash, forKeyPath: SettingsKey.hash, domainIdentifier: domainIdentifier, payloadType: payloadType, payloadIndex: payloadIndex)
    }

    // MARK: -
    // MARK: PayloadIndex

    /*
    func getPayloadIndex(domain: String, type: PayloadType) -> Int {
        let viewDomainSettings = self.getViewDomainSettings(domain: domain, type: type)
        if let payloadIndex = viewDomainSettings[SettingsKey.payloadIndex] as? Int {
            return payloadIndex
        } else { return 0 }
    }

    func setPayloadIndex(index: Int, domain: String, type: PayloadType) {
        #if DEBUGSETTINGS
        Log.shared.debug(message: "Setting payload index: \(index) for domain: \(domain) of type: \(type)", category: String(describing: self))
        #endif

        var viewDomainSettings = self.getViewDomainSettings(domain: domain, type: type)
        viewDomainSettings[SettingsKey.payloadIndex] = index
        self.setViewDomainSettings(settings: viewDomainSettings, domain: domain, type: type)
    }
 */

    func viewValuePayloadIndex(forDomainIdentifier domainIdentifier: String, payloadType type: PayloadType) -> Int {
        guard
            let viewDomainSettings = self.viewSettings(forDomainIdentifier: domainIdentifier, payloadType: type),
            let index = viewDomainSettings.index(where: { $0[SettingsKey.payloadIndexSelected] as? Bool == true }) else {
                return 0
        }
        return index < 0 ? 0 : index
    }

    func setViewValue(payloadIndex: Int, forDomainIdentifier domainIdentifier: String, payloadType type: PayloadType) {

        let viewDomainSettings = self.viewSettings(forDomainIdentifier: domainIdentifier, payloadType: type) ?? [[String: Any]]()
        var newDomainSettings = [[String: Any]]()

        if viewDomainSettings.isEmpty {
            for index in 0...payloadIndex {
                if index == payloadIndex {
                    newDomainSettings.append([SettingsKey.payloadIndexSelected: true])
                } else {
                    newDomainSettings.append([String: Any]())
                }
            }
        } else {
            for (index, var domainSettings) in viewDomainSettings.enumerated() {
                if index == payloadIndex {
                    domainSettings[SettingsKey.payloadIndexSelected] = true
                } else {
                    domainSettings.removeValue(forKey: SettingsKey.payloadIndexSelected)
                }
                newDomainSettings.append(domainSettings)
            }

            if viewDomainSettings.count == payloadIndex {
                newDomainSettings.append([SettingsKey.payloadIndexSelected: true])
            }
        }

        self.setViewSettings(newDomainSettings, forDomainIdentifier: domainIdentifier, payloadType: type)
    }
}
