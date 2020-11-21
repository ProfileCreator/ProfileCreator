//
//  ProfileSettingsValues.swift
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

    func value(forSubkey subkey: PayloadSubkey, payloadIndex: Int) -> Any? {
        if let value = self.value(forValueKeyPath: subkey.valueKeyPath, subkey: subkey, domainIdentifier: subkey.domainIdentifier, payloadType: subkey.payloadType, payloadIndex: payloadIndex) {
            do {
                if subkey.valueProcessor != nil || subkey.typeInput != subkey.type {
                    if let valueProcessed = try PayloadValueProcessors.shared.process(savedValue: value, forSubkey: subkey) {
                        return valueProcessed
                    }
                }
            } catch {
                Log.shared.error(message: "Failed to process value: \(value)", category: String(describing: self))
            }
            return value
        }
        return nil
    }

    func value(forValueKeyPath valueKeyPath: String, subkey: PayloadSubkey? = nil, domainIdentifier: String, payloadType type: PayloadType, payloadIndex: Int) -> Any? {
        if domainIdentifier == kManifestDomainConfiguration {
            return self.profileValue(forKey: valueKeyPath)
        } else {
            if
                let domainIdentifierSettings = self.settings(forDomainIdentifier: domainIdentifier, type: type, payloadIndex: payloadIndex),
                let value = domainIdentifierSettings[keyPath: KeyPath(valueKeyPath, subkey: subkey)] ?? domainIdentifierSettings[keyPath: KeyPath(valueKeyPath, subkey: subkey, reversed: false)] {
                return value
            } else if
                subkey?.payload?.subdomain != nil,
                let domain = subkey?.domain,
                let domainSettings = self.settings(forDomainIdentifier: domain, type: type, payloadIndex: payloadIndex),
                let value = domainSettings[keyPath: KeyPath(valueKeyPath, subkey: subkey)] ?? domainSettings[keyPath: KeyPath(valueKeyPath, subkey: subkey, reversed: false)] {
                return value
            }
        }
        return nil
    }

    private func profileValue(forKey key: String) -> Any? {
        self.settingsProfile[key]
    }

    // MARK: -
    // MARK: Set

    func setValue(_ value: Any, forSubkey subkey: PayloadSubkey, payloadIndex: Int) {
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) valueKeyPath: \(subkey.valueKeyPath)", category: String(describing: self))
        do {
            if subkey.valueProcessor != nil || subkey.typeInput != subkey.type {
                if let valueProcessed = try PayloadValueProcessors.shared.process(inputValue: value, forSubkey: subkey) {
                    self.setPayloadValue(valueProcessed, forValueKeyPath: subkey.valueKeyPath, subkey: subkey, domainIdentifier: subkey.domainIdentifier, payloadType: subkey.payloadType, payloadIndex: payloadIndex)
                    return
                }
            }
        } catch {
            Log.shared.error(message: "Failed to process value: \(value)", category: String(describing: self))
        }
        self.setPayloadValue(value, forValueKeyPath: subkey.valueKeyPath, subkey: subkey, domainIdentifier: subkey.domainIdentifier, payloadType: subkey.payloadType, payloadIndex: payloadIndex)
    }

    func setValue(_ value: Any, forValueKeyPath valueKeyPath: String, subkey payloadSubkey: PayloadSubkey? = nil, domainIdentifier: String, payloadType type: PayloadType, payloadIndex: Int) {
        if let subkey = payloadSubkey {
            do {
                if subkey.valueProcessor != nil || subkey.typeInput != subkey.type {
                    if let valueProcessed = try PayloadValueProcessors.shared.process(inputValue: value, forSubkey: subkey) {
                        self.setPayloadValue(valueProcessed, forValueKeyPath: valueKeyPath, subkey: subkey, domainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex)
                        return
                    }
                }
            } catch {
                Log.shared.error(message: "Failed to process value: \(value)", category: String(describing: self))
            }
        }
        self.setPayloadValue(value, forValueKeyPath: valueKeyPath, subkey: payloadSubkey, domainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex)
    }

    private func setPayloadValue(_ value: Any, forValueKeyPath valueKeyPath: String, subkey: PayloadSubkey? = nil, domainIdentifier: String, payloadType type: PayloadType, payloadIndex: Int) {
        Log.shared.debug(message: "KeyPath: \(valueKeyPath) SET value: \(value)", category: String(describing: self))
        if domainIdentifier == kManifestDomainConfiguration {
            self.setProfileValue(value, forKey: valueKeyPath)
        } else {
            var domainSettings = self.settings(forDomainIdentifier: domainIdentifier, type: type, payloadIndex: payloadIndex) ?? [String: Any]()
            if let sKey = subkey, sKey.type == .dictionary, let newValue = value as? [String: Any] {
                domainSettings[keyPath: KeyPath(valueKeyPath, subkey: subkey)] = newValue
            } else {
                domainSettings[keyPath: KeyPath(valueKeyPath, subkey: subkey)] = value
            }
            self.setSettings(domainSettings, forDomainIdentifier: domainIdentifier, type: type, payloadIndex: payloadIndex)
        }
    }

    private func setProfileValue(_ value: Any, forKey key: String) {
        // This is an ugly hack, that results in setting the payloadDisplayName twice to activate KVO on the self.title variable that is actually computed.
        // This should be able
        if key == PayloadKey.payloadDisplayName, let title = value as? String, title != self.title {
            self.settingsProfile[key] = value
            self.setValue(title, forKey: self.titleSelector)
        } else {
            self.settingsProfile[key] = value
        }
    }
}
