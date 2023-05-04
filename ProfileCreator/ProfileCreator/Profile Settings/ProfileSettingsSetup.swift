//
//  ProfileSettingsSetup.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    // MARK: -
    // MARK: Profile Settings

    class func profileSettingsDefault(forUUID uuid: UUID = UUID()) -> [String: Any] {
        let defaultOrganizationName = UserDefaults.standard.string(forKey: PreferenceKey.defaultOrganization) ?? "ProfileCreator"
        let defaultProfileIdentifier = self.profileIdentifierDefault(forUUID: uuid)
        return [
            PayloadKey.payloadDisplayName: StringConstant.defaultProfileName,
            PayloadKey.payloadIdentifier: defaultProfileIdentifier,
            PayloadKey.payloadOrganization: defaultOrganizationName,
            PayloadKey.payloadScope: TargetString.user,
            PayloadKey.payloadType: kManifestDomainConfiguration,
            PayloadKey.payloadUUID: uuid.uuidString,
            PayloadKey.payloadVersion: 1
        ]
    }

    class func profileIdentifierDefault(forUUID uuid: UUID = UUID()) -> String {
        let defaultOrganizationIdentifier = UserDefaults.standard.string(forKey: PreferenceKey.defaultOrganizationIdentifier) ?? "com.willyu.ProfileCreator"
        var defaultIdentifier = UserDefaults.standard.string(forKey: PreferenceKey.defaultProfileIdentifierFormat) ?? StringConstant.profileIdentifierFormat
        defaultIdentifier = defaultIdentifier.replacingOccurrences(of: "%ORGID%", with: defaultOrganizationIdentifier)
        defaultIdentifier = defaultIdentifier.replacingOccurrences(of: "%UUID%", with: uuid.uuidString)
        return defaultIdentifier
    }

    class func profileSettings(forMobileconfig mobileconfig: [String: Any]) throws -> [String: Any] {
        let profileSettings = mobileconfig.filter { $0.key != PayloadKey.payloadContent }
        // FIXME: Add check to verify required keys are present, else set defaults
        return profileSettings
    }

    class func profileSettings(forSettings settings: [String: Any]) throws -> [String: Any] {
        guard let profileSettings = settings[SettingsKey.profileSettings] as? [String: Any] else {
            // FIXME: Correct Error - Profile Import
            throw NSError(domain: "test", code: 1, userInfo: nil)
        }
        // FIXME: Add check to verify required keys are present, else set defaults
        return profileSettings
    }

    // MARK: -
    // MARK: Payload Settings

    class func payloadSettingsDefault() -> [String: [String: [[String: Any]]]] {
        [String: [String: [[String: Any]]]]()
    }

    class func payloadSettings(forMobileconfig mobileconfig: [String: Any], importErrors: inout [String: Any]) throws -> [String: [String: [[String: Any]]]] {
        var settings = [String: [String: [[String: Any]]]]()

        guard let payloadContent = mobileconfig[PayloadKey.payloadContent] as? [[String: Any]] else {
            // FIXME: Correct Error - Profile Import
            throw NSError(domain: "test", code: 1, userInfo: nil)
        }

        for var payloadSetting in payloadContent {

            let type = ProfileSettings.payloadType(forPayloadSettings: payloadSetting)

            guard let domain = payloadSetting[PayloadKey.payloadType] as? String else {
                var payloadTypeMissing = importErrors[ImportErrorKey.payloadTypeMissing] as? [String] ?? [String]()
                payloadTypeMissing.append(payloadSetting[PayloadKey.payloadDisplayName] as? String ?? "<No PayloadDisplayName>")
                importErrors[ImportErrorKey.payloadTypeMissing] = payloadTypeMissing
                continue
            }

            guard type != .custom else {
                self.addCustomPayloadSetting(payloadSetting, toSettings: &settings, importErrors: &importErrors)
                continue
            }

            if domain == kManifestDomainConfiguration {
                continue
            }
            /*
            else if domain == kManifestDomainAppleRoot || domain == kManifestDomainApplePEM {
                domain = kManifestDomainApplePKCS1
            }
            */
            var typeSettings = settings[type.rawValue] ?? [String: [[String: Any]]]()
            var domainSettings = typeSettings[domain] ?? [[String: Any]]()

            // TO BE REMOVED
            payloadSetting[PayloadKey.payloadEnabled] = true

            self.addCustomPayloadKeys(forDomain: domain, payloadSetting: &payloadSetting)

            domainSettings.append(payloadSetting)
            typeSettings[domain] = domainSettings
            settings[type.rawValue] = typeSettings
        }

        return settings
    }

    class func addCustomPayloadSettingMCX(_ setting: [String: Any], toSettings settings: inout [String: [String: [[String: Any]]]], importErrors: inout [String: Any]) {
        guard var customPayloadContent = setting[PayloadKey.payloadContent] as? [String: [String: [[String: [String: Any]]]]] else { return }
        if let payloadContent = setting[PayloadKey.payloadContent] as? [String: [String: [[String: [String: Any]]]]] {
            for (domain, payloadSetting) in payloadContent {

                let type = ProfileSettings.payloadType(forDomain: domain)

                guard type != .custom else {
                    continue
                }

                for (_, frequencyArray) in payloadSetting {
                    for var customDomainSettings in frequencyArray.flatMap({ $0.values }) {

                        customDomainSettings.merge(setting.filter { $0.key != PayloadKey.payloadContent }) { first, _ in first }

                        var typeSettings = settings[type.rawValue] ?? [String: [[String: Any]]]()
                        var domainSettings = typeSettings[domain] ?? [[String: Any]]()

                        customDomainSettings[PayloadKey.payloadEnabled] = true
                        self.addCustomPayloadKeys(forDomain: domain, payloadSetting: &customDomainSettings)

                        domainSettings.append(customDomainSettings)
                        typeSettings[domain] = domainSettings
                        settings[type.rawValue] = typeSettings

                        customPayloadContent.removeValue(forKey: domain)
                    }
                }
            }
        }

        if !customPayloadContent.isEmpty {
            var payloadTypeCustom = importErrors[ImportErrorKey.payloadTypeCustom] as? [String] ?? [String]()
            if let payloadContent = setting[PayloadKey.payloadContent] as? [String: [String: [[String: [String: Any]]]]] {
                for domain in payloadContent.keys {
                    payloadTypeCustom.append(domain)
                }
            }

            importErrors[ImportErrorKey.payloadTypeCustom] = payloadTypeCustom
        }
    }

    class func addCustomPayloadSetting(_ setting: [String: Any], toSettings settings: inout [String: [String: [[String: Any]]]], importErrors: inout [String: Any]) {

        // Get the current payload type.
        guard let payloadType = setting[PayloadKey.payloadType] as? String else {
            var payloadTypeMissing = importErrors[ImportErrorKey.payloadTypeMissing] as? [String] ?? [String]()
            payloadTypeMissing.append(setting[PayloadKey.payloadDisplayName] as? String ?? "<No PayloadDisplayName>")
            importErrors[ImportErrorKey.payloadTypeMissing] = payloadTypeMissing
            return
        }

        if payloadType == "com.apple.ManagedClient.preferences" {
            self.addCustomPayloadSettingMCX(setting, toSettings: &settings, importErrors: &importErrors)
        } else {
            var customDomainSettings = setting

            var typeSettings = settings[PayloadType.custom.rawValue] ?? [String: [[String: Any]]]()
            var domainSettings = typeSettings[payloadType] ?? [[String: Any]]()

            customDomainSettings[PayloadKey.payloadEnabled] = true
            self.addCustomPayloadKeys(forDomain: payloadType, payloadSetting: &customDomainSettings)

            domainSettings.append(customDomainSettings)
            typeSettings[payloadType] = domainSettings
            settings[PayloadType.custom.rawValue] = typeSettings

            var payloadTypeCustom = importErrors[ImportErrorKey.payloadTypeCustom] as? [String] ?? [String]()
            if let payloadType = setting[PayloadKey.payloadType] as? String {
                payloadTypeCustom.append(payloadType)
            }
            importErrors[ImportErrorKey.payloadTypeCustom] = payloadTypeCustom
        }
    }

    class func addCustomPayloadKeys(forDomain domain: String, payloadSetting: inout [String: Any]) {
        switch domain {
        case kManifestDomainAppleWiFi:
            guard let isHotspot = payloadSetting["IsHotspot"] as? Bool, isHotspot else {
                payloadSetting["Interface"] = "BuiltInWireless"
                return
            }
            if let domainName = payloadSetting["DomainName"] as? String, !domainName.isEmpty {
                payloadSetting["Interface"] = "Hotspot2"
            } else {
                payloadSetting["Interface"] = "Hotspot"
            }
        default:
            return
        }
    }

    class func payloadSettings(forSettings settings: [String: Any]) throws -> [String: [String: [[String: Any]]]] {
        guard let payloadSettings = settings[SettingsKey.payloadSettings] as? [String: [String: [[String: Any]]]] else {
            // FIXME: Correct Error - Profile Import
            throw NSError(domain: "test", code: 1, userInfo: nil)
        }
        return payloadSettings
    }

    // MARK: -
    // MARK: Domain Settings

    func initializeDomainSetting(_ domainSettings: inout [String: Any], forPayload payload: Payload) {

        // Verify PayloadUUID
        if domainSettings[PayloadKey.payloadUUID] == nil {
            if
                payload.subdomain != nil,
                let existingDomainSettingsArray = self.settings(forDomain: payload.domain, type: payload.type, exact: true),
                let existingDomainSettings = existingDomainSettingsArray.first(where: { $0.contains(where: { $0.keys.contains(PayloadKey.payloadUUID) }) })?.first,
                let existingPayloadUUID = existingDomainSettings[PayloadKey.payloadUUID] as? String {
                domainSettings[PayloadKey.payloadUUID] = existingPayloadUUID
            } else {
                domainSettings[PayloadKey.payloadUUID] = UUID().uuidString
            }
        }

        // Verify PayloadVersion
        if domainSettings[PayloadKey.payloadVersion] == nil { domainSettings[PayloadKey.payloadVersion] = 1 }

        // Verify PayloadIdentifier
        if domainSettings[PayloadKey.payloadIdentifier] == nil {
            var payloadIdentifier = UserDefaults.standard.string(forKey: PreferenceKey.defaultPayloadIdentifierFormat) ?? StringConstant.payloadIdentifierFormat

            // "%ROOTID%"
            if let profileIdentifier = self.value(forValueKeyPath: PayloadKey.payloadIdentifier, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0) as? String {
                payloadIdentifier = payloadIdentifier.replacingOccurrences(of: "%ROOTID%", with: profileIdentifier)
            }

            // "%TYPE%"
            if
                let payloadTypeSubkey = ProfilePayloads.shared.payloadSubkey(forKeyPath: PayloadKey.payloadType, domainIdentifier: payload.domainIdentifier, type: payload.type),
                let payloadType = payloadTypeSubkey.valueDefault as? String {
                payloadIdentifier = payloadIdentifier.replacingOccurrences(of: "%TYPE%", with: payloadType)
            }

            // "%UUID%"
            payloadIdentifier = payloadIdentifier.replacingOccurrences(of: "%UUID%", with: domainSettings[PayloadKey.payloadUUID] as? String ?? UUID().uuidString)

            // "%NAME%"
            if
                let payloadDisplayNameSubkey = ProfilePayloads.shared.payloadSubkey(forKeyPath: PayloadKey.payloadDisplayName, domainIdentifier: payload.domainIdentifier, type: payload.type),
                let payloadDisplayName = payloadDisplayNameSubkey.valueDefault as? String {
                payloadIdentifier = payloadIdentifier.replacingOccurrences(of: "%NAME%", with: payloadDisplayName.replacingOccurrences(of: " ", with: "_"))
            }

            domainSettings[PayloadKey.payloadIdentifier] = payloadIdentifier
        }
    }

    func updateUUIDs() {

        let profileUUID = UUID()
        self.setValue(profileUUID, forValueKeyPath: PayloadKey.payloadUUID, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
        let currentProfileIdentifier = self.value(forValueKeyPath: PayloadKey.payloadIdentifier, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0) as? String ?? ProfileSettings.profileIdentifierDefault(forUUID: profileUUID)
        let newProfileIdentifier = currentProfileIdentifier.replacingOccurrences(of: ".[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$", with: profileUUID.uuidString, options: .regularExpression, range: nil)
        self.setValue(newProfileIdentifier, forValueKeyPath: PayloadKey.payloadIdentifier, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)

        var newSettingsPayload = [String: [String: [[String: Any]]]]()
        for (typeString, typeSettings) in self.settingsPayload {
            guard let payloadType = PayloadType(rawValue: typeString) else { continue }

            var newTypeSetting = [String: [[String: Any]]]()
            for (domainIdentifier, domainSettings) in typeSettings {
                guard !(payloadType == .manifestsApple && domainIdentifier == kManifestDomainConfiguration) else { continue }
                guard !(payloadType == .custom && ProfilePayloads.shared.customManifest(forDomainIdentifier: domainIdentifier, ofType: payloadType, payloadContent: domainSettings) != nil) else { continue }
                guard let subkey = ProfilePayloads.shared.payloadSubkey(forKeyPath: PayloadKey.payloadIdentifier, domainIdentifier: domainIdentifier, type: payloadType) else {
                    Log.shared.error(message: "Failed to get payload subkey for keyPath: \(PayloadKey.payloadIdentifier) identifier: \(identifier) of type: \(payloadType)", category: String(describing: self))
                    continue
                }

                var newDomainSettings = [[String: Any]]()
                for (index, var domainSetting) in domainSettings.enumerated() {

                    guard let payloadIdentifier = self.value(forSubkey: subkey, payloadIndex: index) as? String ?? subkey.valueDefault as? String else {
                        Log.shared.error(message: "Failed to get value for PayloadIdentifier", category: String(describing: self))
                        continue
                    }

                    let newUUID = UUID()
                    domainSetting[PayloadKey.payloadUUID] = newUUID.uuidString
                    domainSetting[PayloadKey.payloadIdentifier] = payloadIdentifier + ".\(newUUID.uuidString)"
                    newDomainSettings.append(domainSetting)
                }
                newTypeSetting[domainIdentifier] = newDomainSettings
            }
            newSettingsPayload[typeString] = newTypeSetting
        }
        self.settingsPayload = newSettingsPayload
    }

    // MARK: -
    // MARK: Editor Settings

    class func editorSettingsDefault() -> [String: Any] {
        var editorSettings = [ PreferenceKey.signProfile: UserDefaults.standard.bool(forKey: PreferenceKey.signProfile),
                                PreferenceKey.distributionMethod: UserDefaults.standard.string(forKey: PreferenceKey.distributionMethod) ?? DistributionString.any,
                                PreferenceKey.disableOptionalKeys: UserDefaults.standard.bool(forKey: PreferenceKey.disableOptionalKeys),
                                PreferenceKey.showUserApprovedKeys: UserDefaults.standard.bool(forKey: PreferenceKey.showUserApprovedKeys),
                                PreferenceKey.showDisabledKeys: UserDefaults.standard.bool(forKey: PreferenceKey.showDisabledKeys),
                                PreferenceKey.showCustomizedKeys: UserDefaults.standard.bool(forKey: PreferenceKey.showCustomizedKeys),
                                PreferenceKey.showHiddenKeys: UserDefaults.standard.bool(forKey: PreferenceKey.showHiddenKeys),
                                PreferenceKey.showSupervisedKeys: UserDefaults.standard.bool(forKey: PreferenceKey.showSupervisedKeys),
                                PreferenceKey.platformMacOS: UserDefaults.standard.bool(forKey: PreferenceKey.platformMacOS),
                                PreferenceKey.platformIOS: UserDefaults.standard.bool(forKey: PreferenceKey.platformIOS),
                                PreferenceKey.platformTvOS: UserDefaults.standard.bool(forKey: PreferenceKey.platformTvOS),
                                PreferenceKey.scopeUser: UserDefaults.standard.bool(forKey: PreferenceKey.scopeUser),
                                PreferenceKey.scopeSystem: UserDefaults.standard.bool(forKey: PreferenceKey.scopeSystem) ] as [String: Any]

        if let signingCertificatePersistantRef = UserDefaults.standard.data(forKey: PreferenceKey.signingCertificate) {
            editorSettings[PreferenceKey.signingCertificate] = signingCertificatePersistantRef
        }

        return editorSettings
    }

    class func editorSettings(forMobileconfig mobileconfig: [String: Any]) throws -> [String: Any] {
        self.editorSettingsDefault()
    }

    class func editorSettings(forSettings settings: [String: Any]) throws -> [String: Any] {
        // FIXME: Should we check that every setting is included, and add defaults if not?
        return settings[SettingsKey.editorSettings] as? [String: Any] ?? self.editorSettingsDefault()
    }

    // MARK: -
    // MARK: View Settings

    class func viewSettingsDefault() -> [String: [String: [[String: Any]]]] {
        [String: [String: [[String: Any]]]]()
    }

    class func initialize(settings: inout [String: [String: [[String: Any]]]],
                          viewSettings: inout [String: [String: [[String: Any]]]],
                          forMobileconfig mobileconfig: [String: Any],
                          importErrors: inout [String: Any]) throws {

        // Temporary, this could be handled directly here. It's just left as I was redoing these functions to support subdomain imports.
        let payloadSettings = try self.payloadSettings(forMobileconfig: mobileconfig, importErrors: &importErrors)

        // var viewSettings = [String: [String: [[String: Any]]]]()

        for (typeString, typeValue) in payloadSettings {
            guard let type = PayloadType(rawValue: typeString)  else {
                Log.shared.error(message: "Failed to get type from typeString: \(typeString)", category: String(describing: self))
                continue
            }

            guard type != .custom else {
                settings[typeString] = typeValue
                continue
            }

            var typeSettings = [String: [[String: Any]]]()
            var viewTypeSettings = [String: [[String: Any]]]()

            for (domain, domainValue) in typeValue {
                for payloadSetting in domainValue {

                    /*
                    if domain == kManifestDomainAppleRoot || domain == kManifestDomainApplePEM {
                        domain = kManifestDomainApplePKCS1
                    }
                    */

                    var newDomainSettings = [String: [String: Any]]()
                    var newViewDomainSettings = [String: [String: Any]]()
                    self.initializeSettings(forDomain: domain,
                                            domainSetting: &newDomainSettings,
                                            viewDomainSetting: &newViewDomainSettings,
                                            forPayloadSetting: payloadSetting,
                                            type: type,
                                            importErrors: &importErrors)

                    // Add Settings
                    for (newDomain, var newDomainSetting) in newDomainSettings {
                        var domainSettings = typeSettings[newDomain] ?? [[String: Any]]()

                        // Verify all keys exist
                        for payloadKey in kPayloadSubkeys {
                            self.verifyValueExists(forKey: payloadKey, from: payloadSetting, to: &newDomainSetting)
                        }

                        domainSettings.append(newDomainSetting)
                        typeSettings[newDomain] = domainSettings
                    }
                    settings[typeString] = typeSettings

                    // Add View Settings
                    for (newViewDomain, newViewDomainSetting) in newViewDomainSettings {
                        var domainSettings = viewTypeSettings[newViewDomain] ?? [[String: Any]]()
                        domainSettings.append(newViewDomainSetting)
                        viewTypeSettings[newViewDomain] = domainSettings
                    }
                    viewSettings[typeString] = viewTypeSettings
                }
            }
        }
    }

    class func verifyValueExists(forKey key: String, from fromDict: [String: Any], to toDict: inout [String: Any]) {
        if toDict[key] == nil, let value = fromDict[key] { toDict[key] = value }
    }

    class func initializeSettings(forDomain domain: String,
                                  domainSetting: inout [String: [String: Any]],
                                  viewDomainSetting: inout [String: [String: Any]],
                                  forPayloadSetting payloadSetting: [String: Any],
                                  type: PayloadType,
                                  parentSubkey: PayloadSubkey? = nil,
                                  parentKeyPath: String = "",
                                  importErrors: inout [String: Any]) {

        for (key, value) in payloadSetting {

            // ---------------------------------------------------------------------
            //  Get the keyPath for the current key
            // ---------------------------------------------------------------------
            let keyPath = parentKeyPath.isEmpty ? key : parentKeyPath + "." + key

            // ---------------------------------------------------------------------
            //  Get the subkey instance for the keyPath
            // ---------------------------------------------------------------------
            var subkeys: [PayloadSubkey]
            if let aSubkeys = ProfilePayloads.shared.payloadSubkeys(forKeyPath: keyPath, domain: domain, type: type) {
                subkeys = aSubkeys
            } else if let pSubkey = parentSubkey, pSubkey.type == .dictionary, pSubkey.subkeys.contains(where: { $0.key == ManifestKeyPlaceholder.key }) {
                continue
            } else {
                if kPayloadSubkeys.contains(key) || kPayloadSubkeysIgnored.contains(key) || kPayloadKeysIgnored.contains(key) || kPayloadKeyPrefixesIgnored.contains(where: { key.hasPrefix($0) }) {
                    Log.shared.debug(message: "Ignoring payload key in mobileconfig: \(key)", category: String(describing: self))
                } else {
                    Log.shared.debug(message: "Unknown KeyPath for domain: \(domain)", category: String(describing: self))
                    var payloadKeyMissing = importErrors[ImportErrorKey.payloadKeyMissing] as? [String: [String]] ?? [String: [String]]()
                    var payloadKeyMissingDomain = payloadKeyMissing[domain] ?? [String]()
                    payloadKeyMissingDomain.append(keyPath)
                    payloadKeyMissing[domain] = payloadKeyMissingDomain
                    importErrors[ImportErrorKey.payloadKeyMissing] = payloadKeyMissing
                }
                continue
            }

            for subkey in subkeys {
                var newDomainSetting = domainSetting[subkey.domainIdentifier] ?? [String: Any]()
                if newDomainSetting.isEmpty {
                    newDomainSetting[PayloadKey.payloadEnabled] = true
                }
                if subkey.type == .dictionary, let newValue = value as? [String: Any] {
                    newDomainSetting[keyPath: KeyPath(keyPath, subkey: subkey)] = newValue
                } else {
                    newDomainSetting[keyPath: KeyPath(keyPath, subkey: subkey)] = value
                }
                domainSetting[subkey.domainIdentifier] = newDomainSetting

                // ---------------------------------------------------------------------
                //  Ignore payload subkeys and keys on the ignored subkeys list
                // ---------------------------------------------------------------------
                if kPayloadSubkeys.contains(key) || kPayloadSubkeysIgnored.contains(key) { continue }

                // ---------------------------------------------------------------------
                //  Set the keyPath as enabled if it's not already required
                // ---------------------------------------------------------------------
                if subkey.require != .always && subkey.require != .alwaysNested {
                    var domainSetting = viewDomainSetting[subkey.domainIdentifier] ?? [String: Any]()
                    domainSetting[keyPath] = [SettingsKey.enabled: true]
                    viewDomainSetting[subkey.domainIdentifier] = domainSetting
                }

                if subkey.type == .array && !subkey.subkeys.isEmpty,
                    let elementSubkey = subkey.subkeys.first,
                    (elementSubkey.type == .dictionary || elementSubkey.type == .array),
                    let valueArray = value as? [Any] {

                    self.initializeSettingsArray(forDomain: domain,
                                                 domainSetting: &domainSetting,
                                                 viewDomainSetting: &viewDomainSetting,
                                                 forElementSubkey: elementSubkey,
                                                 payloadSettings: valueArray,
                                                 type: type,
                                                 parentSubkey: subkey,
                                                 parentKeyPath: keyPath,
                                                 importErrors: &importErrors)

                } else if subkey.type == .dictionary && !subkey.subkeys.isEmpty, let valueDictionary = value as? [String: Any] {
                    self.initializeSettings(forDomain: domain,
                                            domainSetting: &domainSetting,
                                            viewDomainSetting: &viewDomainSetting,
                                            forPayloadSetting: valueDictionary,
                                            type: type,
                                            parentSubkey: subkey,
                                            parentKeyPath: keyPath,
                                            importErrors: &importErrors)
                }
            }
        }
    }

    class func initializeSettingsArray(forDomain domain: String,
                                       domainSetting: inout [String: [String: Any]],
                                       viewDomainSetting: inout [String: [String: Any]],
                                       forElementSubkey subkey: PayloadSubkey,
                                       payloadSettings: [Any],
                                       type: PayloadType,
                                       parentSubkey: PayloadSubkey?,
                                       parentKeyPath: String = "",
                                       importErrors: inout [String: Any]) {

        for payloadSetting in payloadSettings {
            if subkey.type == .array && !subkey.subkeys.isEmpty, let elementSubkey = subkey.subkeys.first, let valueArray = payloadSetting as? [Any] {
                self.initializeSettingsArray(forDomain: domain,
                                             domainSetting: &domainSetting,
                                             viewDomainSetting: &viewDomainSetting,
                                             forElementSubkey: elementSubkey,
                                             payloadSettings: valueArray,
                                             type: type,
                                             parentSubkey: parentSubkey,
                                             parentKeyPath: subkey.keyPath,
                                             importErrors: &importErrors)

            } else if subkey.type == .dictionary, let valueDictionary = payloadSetting as? [String: Any] {
                self.initializeSettings(forDomain: domain,
                                        domainSetting: &domainSetting,
                                        viewDomainSetting: &viewDomainSetting,
                                        forPayloadSetting: valueDictionary,
                                        type: type,
                                        parentSubkey: parentSubkey,
                                        parentKeyPath: subkey.keyPath,
                                        importErrors: &importErrors)
            } else {
                Log.shared.debug(message: "Failed to find a match when searching for domain settings using setting: \(payloadSetting)", category: String(describing: self))
            }
        }
    }

    class func viewSettings(forSettings settings: [String: Any]) throws -> [String: [String: [[String: Any]]]] {
        settings[SettingsKey.viewSettings] as? [String: [String: [[String: Any]]]] ?? self.viewSettingsDefault()
    }

    // MARK: -
    // MARK: Saved Settings

    func restoreSettings(_ settings: [String: Any], forUnsupportedVersion fromatVersion: Int) {
        switch formatVersion {
        case 0:
            if let identifierString = settings[SettingsKey.identifier] as? String, let identifier = UUID(uuidString: identifierString) {
                var settingsProfile = ProfileSettings.profileSettingsDefault(forUUID: identifier)

                if let title = settings[SettingsKey.title] as? String {
                    settingsProfile[PayloadKey.payloadDisplayName] = title
                }

                self.settingsProfile = settingsProfile
            }

            if let payloadSettings = settings[SettingsKey.payloadSettings] as? [String: [String: [[String: Any]]]] {
                self.settingsPayload = payloadSettings
            }
        default:
            Log.shared.error(message: "Unhandled unsuported version: \(formatVersion)", category: String(describing: self))
        }
    }

    func restoreSettingsSaved(_ settingsSaved: [String: Any]?) {

        // ---------------------------------------------------------------------
        //  Initiate the passed settings
        // ---------------------------------------------------------------------
        let settings = settingsSaved ?? self.settingsSaved
        self.settingsSaved = settings

        // ---------------------------------------------------------------------
        //  Update the format version
        // ---------------------------------------------------------------------
        self.formatVersion = settings[SettingsKey.saveFormatVersion] as? Int ?? 0

        guard kSaveFormatVersionMin <= self.formatVersion else {
            self.restoreSettings(settings, forUnsupportedVersion: self.formatVersion)
            return
        }

        // ---------------------------------------------------------------------
        //  Update the current profile settings
        // ---------------------------------------------------------------------
        self.settingsProfile = settings[SettingsKey.profileSettings] as? [String: Any] ?? [String: Any]()

        // ---------------------------------------------------------------------
        //  Update the current payload settings
        // ---------------------------------------------------------------------
        self.settingsPayload = settings[SettingsKey.payloadSettings] as? [String: [String: [[String: Any]]]] ?? [String: [String: [[String: Any]]]]()

        // ---------------------------------------------------------------------
        //  Update the current viewSettings
        // ---------------------------------------------------------------------
        self.settingsView = settings[SettingsKey.viewSettings] as? [String: [String: [[String: Any]]]] ?? [String: [String: [[String: Any]]]]()

        // ---------------------------------------------------------------------
        //  Update the current editorSettings
        // ---------------------------------------------------------------------
        self.settingsEditor = settings[SettingsKey.editorSettings] as? [String: Any] ?? [String: Any]()
        self.initializeEditorSettings()

        // ---------------------------------------------------------------------
        //  Reset the cache
        // ---------------------------------------------------------------------
        self.resetCache()

        // ---------------------------------------------------------------------
        //  Update the settingsRestored to allow observers to reload their data
        // ---------------------------------------------------------------------
        self.setValue(!self.settingsRestored, forKeyPath: self.settingsRestoredSelector)
    }
}
