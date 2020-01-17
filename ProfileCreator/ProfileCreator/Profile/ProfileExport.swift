//
//  ProfileExport.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

class ProfileExport {

    // MARK: -
    // MARK: Variables

    var ignoreErrorInvalidValue = false
    var ignoreSave = false

    var currentPayloadIndex: Int = 0

    weak var profile: Profile?
    let exportSettings: ProfileSettings

    // MARK: -
    // MARK: Initialization

    private init() {
        // Never Used
        self.exportSettings = ProfileSettings()
    }

    init(exportSettings: ProfileSettings) {
        self.exportSettings = exportSettings
    }

    // MARK: -
    // MARK: Export Profile

    func export(profile: Profile, profileURL: URL) throws {
        Log.shared.info(message: "Exporting profile with identifier: \(profile.identifier) to path: \(profileURL.path)", category: String(describing: self))

        // ---------------------------------------------------------------------
        //  Store the passed profile
        // ---------------------------------------------------------------------
        self.profile = profile

        // ---------------------------------------------------------------------
        //  Reset the caches for export
        // ---------------------------------------------------------------------
        self.exportSettings.resetCache()

        // ---------------------------------------------------------------------
        //  Create an empty profileContent dictionary to add keys to
        // ---------------------------------------------------------------------
        var profileContent = [String: Any]()

        // ---------------------------------------------------------------------
        //  Get the profile root content
        // ---------------------------------------------------------------------
        profileContent = try self.profileContent()

        // ---------------------------------------------------------------------
        //  Get the profile payload content
        // ---------------------------------------------------------------------
        profileContent[PayloadKey.payloadContent] = try self.payloadContent()

        #if DEBUG
        Log.shared.debug(message: "Profile Content to Export: \(profileContent)")
        #endif
        Log.shared.info(message: "Sign Profile: \(self.exportSettings.sign)", category: String(describing: self))

        if self.exportSettings.sign {
            guard let signingCertificate = self.exportSettings.signingCertificate else {
                throw ProfileExportError.signingErrorNoIdentity
            }

            if let data = try ProfileSigning.sign(profileContent, usingSigningCertificate: signingCertificate) {
                try data.write(to: profileURL, options: .atomic)
            }
        } else {
            if #available(OSX 10.13, *) {
                try NSDictionary(dictionary: profileContent).write(to: profileURL)
            } else {
                if !NSDictionary(dictionary: profileContent).write(to: profileURL, atomically: true) {
                    throw ProfileExportError.saveError(path: profileURL.path)
                }
            }
        }
    }

    func exportPlist(profile: Profile, folderURL: URL) throws {
        Log.shared.info(message: "Exporting profile with identifier: \(profile.identifier) as plists to path: \(folderURL.path)", category: String(describing: self))

        // ---------------------------------------------------------------------
        //  Store the passed profile
        // ---------------------------------------------------------------------
        self.profile = profile

        // ---------------------------------------------------------------------
        //  Reset the caches for export
        // ---------------------------------------------------------------------
        self.exportSettings.resetCache()

        // ---------------------------------------------------------------------
        //  Loop through each payload and export all enabled settings
        // ---------------------------------------------------------------------
        let payloads = Set<Payload>(self.exportSettings.payloadsEnabled())
        for payload in payloads {

            let domainIdentifier = payload.domainIdentifier
            let fileName: String
            if payloads.filter({ $0.domain == payload.domain }).count != 1 {
                fileName = domainIdentifier
            } else {
                fileName = payload.domain
            }

            for index in 0..<self.exportSettings.payloadSettingsEnabled(forDomainIdentifier: domainIdentifier, type: payload.type).count {
                let payloadContent = try self.content(forPayload: payload, payloadIndex: index).filter { !kPayloadSubkeys.contains($0.key) }

                var plistURL = folderURL.appendingPathComponent(fileName).appendingPathExtension("plist")
                var plistURLCounter = 0
                while FileManager.default.fileExists(atPath: plistURL.path) {
                    plistURLCounter += 1
                    plistURL = folderURL.appendingPathComponent(fileName + "-" + String(plistURLCounter)).appendingPathExtension("plist")
                }

                if #available(OSX 10.13, *) {
                    try NSDictionary(dictionary: payloadContent).write(to: plistURL)
                } else {
                    if !NSDictionary(dictionary: payloadContent).write(to: plistURL, atomically: true) {
                        throw ProfileExportError.saveError(path: plistURL.path)
                    }
                }
            }
        }
    }

    // MARK: -
    // MARK: Generate Profile Content

    private func profileContent() throws -> [String: Any] {
        Log.shared.log(message: "Generating profile content for profile with identifier: \(self.exportSettings.identifier)", category: String(describing: self))

        // ---------------------------------------------------------------------
        //  Create an empty profileContent dictionary to add keys to
        // ---------------------------------------------------------------------
        var profileContent = [String: Any]()

        // ---------------------------------------------------------------------
        //  Get the General manifest payload source
        // ---------------------------------------------------------------------
        if let payload = ProfilePayloads.shared.payload(forDomainIdentifier: kManifestDomainConfiguration, type: .manifestsApple) {
            profileContent = try self.content(forPayload: payload, payloadIndex: 0)
        } else {
            throw ProfileExportError.noPayload(domain: kManifestDomainConfiguration, type: .manifestsApple)
        }

        // ---------------------------------------------------------------------
        //  Verify Required Settings and return if correct
        // ---------------------------------------------------------------------
        return try self.verifyProfileContent(profileContent)
    }

    private func verifyProfileContent(_ profileContent: [String: Any]) throws -> [String: Any] {

        // PayloadType
        // ---------------------------------------------------------------------
        // Currently the only supported value is "Configuration"
        guard let payloadType = profileContent[PayloadKey.payloadType] as? String, payloadType == kManifestDomainConfiguration else {
            throw ProfileExportError.settingsErrorInvalid(value: profileContent[PayloadKey.payloadType],
                                                          key: PayloadKey.payloadType,
                                                          domain: kManifestDomainConfiguration,
                                                          type: .manifestsApple)
        }

        // PayloadVersion
        // ---------------------------------------------------------------------
        // Version of the profile format, currently the only supported value is 1
        guard let payloadVersion = profileContent[PayloadKey.payloadVersion] as? Int, payloadVersion == 1 else {
            throw ProfileExportError.settingsErrorInvalid(value: profileContent[PayloadKey.payloadVersion],
                                                          key: PayloadKey.payloadVersion,
                                                          domain: kManifestDomainConfiguration,
                                                          type: .manifestsApple)
        }

        // PayloadIdentifier
        // ---------------------------------------------------------------------
        // A non-empty identifier has to be set
        guard let payloadIdentifier = profileContent[PayloadKey.payloadIdentifier] as? String, !payloadIdentifier.isEmpty else {
            throw ProfileExportError.settingsErrorInvalid(value: profileContent[PayloadKey.payloadIdentifier],
                                                          key: PayloadKey.payloadIdentifier,
                                                          domain: kManifestDomainConfiguration,
                                                          type: .manifestsApple)
        }

        // PayloadUUID
        // ---------------------------------------------------------------------
        // A non-empty UUID has to be set
        guard let payloadUUID = profileContent[PayloadKey.payloadUUID] as? String, !payloadUUID.isEmpty else {
            throw ProfileExportError.settingsErrorInvalid(value: profileContent[PayloadKey.payloadUUID],
                                                          key: PayloadKey.payloadUUID,
                                                          domain: kManifestDomainConfiguration,
                                                          type: .manifestsApple)
        }

        return profileContent
    }

    // MARK: -
    // MARK: Generate Payload Content

    private func payloadContent() throws -> [[String: Any]] {
        var payloadContent = [[String: Any]]()

        for payload in Set<Payload>(self.exportSettings.payloadsEnabled()) {
            for index in 0..<self.exportSettings.payloadSettingsEnabled(forDomainIdentifier: payload.domainIdentifier, type: payload.type).count {
                let content = try self.content(forPayload: payload, payloadIndex: index)
                if payload.subdomain != nil, let existingPayloadTypeIndex = payloadContent.firstIndex(where: { $0[PayloadKey.payloadType] as? String == content[PayloadKey.payloadType] as? String }) {
                    let updatedPayloadTypeContent = payloadContent[existingPayloadTypeIndex].merging(content) { first, _ in first }
                    payloadContent[existingPayloadTypeIndex] = updatedPayloadTypeContent
                } else {
                    payloadContent.append(content)
                }
            }
        }

        return payloadContent
    }

    // MARK: -
    // MARK: Generate Content

    func content(forPayload payload: Payload, payloadIndex: Int) throws -> [String: Any] {

        Log.shared.debug(message: "Exporting index: \(payloadIndex) of payload with domainIdentifier: \(payload.domainIdentifier)", category: String(describing: self))

        var payloadContent = [String: Any]()

        if payload.type == .custom {
            if let payloadCustom = payload as? PayloadCustom {
                if
                    let payloadCustomContents = payloadCustom.payloadContent,
                    payloadIndex < payloadCustomContents.count {
                    payloadContent = payloadCustomContents[payloadIndex]
                } else {
                    // FIXME: Logs
                }
            } // FIXME: Logs
        } else {

            var nestedRequiredSubkeys = [PayloadSubkey]()
            for subkey in payload.subkeys {

                if !self.shouldExport(subkey: subkey, payloadIndex: payloadIndex) {
                    Log.shared.debug(message: "KeyPath: \(subkey.keyPath) NOT exported.", category: String(describing: self))
                    nestedRequiredSubkeys += subkey.allSubkeys.filter { $0.require == .alwaysNested }
                    continue
                }

                Log.shared.debug(message: "KeyPath: \(subkey.keyPath) exporting…", category: String(describing: self))

                if let subkeyValue = try self.value(forSubkey: subkey, parentValueKeyPath: nil, payloadIndex: payloadIndex) {
                    payloadContent[subkey.key] = subkeyValue
                } else {
                    Log.shared.debug(message: "No value returned for payload key: \(subkey.keyPath)", category: String(describing: self))
                }
            }
        }

        payloadContent.removeValue(forKey: PayloadKey.payloadEnabled)

        if !payloadContent.isEmpty {
            self.updateManagedPreferences(domain: payload.domain, type: payload.type, payloadContent: &payloadContent)
        }

        return payloadContent
    }

    func valueKeyPath(forSubkey subkey: PayloadSubkey, parentValueKeyPath: String?) -> String {
        if let parentKeyPath = parentValueKeyPath {
            return parentKeyPath + ".\(subkey.key)"
        } else {
            return subkey.key
        }
    }

    func value(forArraySubkey subkey: PayloadSubkey, parentValueKeyPath: String?, payloadIndex: Int) throws -> [Any]? {
        Log.shared.info(message: "Get value for array subkey with keyPath: \(subkey.keyPath)", category: String(describing: self))

        if subkey.typeInput != .array {
            return try self.value(forValueSubkey: subkey, parentValueKeyPath: parentValueKeyPath, payloadIndex: payloadIndex) as? [Any]
        }

        var valueKeyPath = self.valueKeyPath(forSubkey: subkey, parentValueKeyPath: parentValueKeyPath)

        guard
            let arrayContentSubkey = subkey.subkeys.first,
            let arrayValue = self.exportSettings.value(forValueKeyPath: valueKeyPath,
                                                       subkey: subkey,
                                                       domainIdentifier: subkey.domainIdentifier,
                                                       payloadType: subkey.payloadType,
                                                       payloadIndex: payloadIndex) as? [Any] else {
                                                        if let valueDefault = subkey.valueDefault as? [Any] {
                                                            return valueDefault
                                                        } else {
                                                            Log.shared.error(message: "No array value returned for payload key: \(subkey.keyPath)", category: String(describing: self))
                                                            return PayloadUtility.emptyValue(valueType: subkey.type) as? [Any]
                                                        }
        }

        if arrayContentSubkey.type == .dictionary {
            var arrayContentValue = [[String: Any]]()
            let valueKeyPathArray = valueKeyPath
            for index in 0..<arrayValue.count {
                valueKeyPath = valueKeyPathArray + ".\(index)"
                var arrayContentValueItem = [String: Any]()
                for arrayContentChildSubkey in arrayContentSubkey.subkeys {

                    if !self.shouldExport(subkey: arrayContentChildSubkey, parentValueKeyPath: valueKeyPath, payloadIndex: payloadIndex) {
                        Log.shared.debug(message: "KeyPath: \(arrayContentChildSubkey.keyPath) NOT exported.", category: String(describing: self))
                        continue
                    }

                    Log.shared.debug(message: "KeyPath: \(arrayContentChildSubkey.keyPath) exporting…", category: String(describing: self))

                    if let value = try self.value(forSubkey: arrayContentChildSubkey, parentValueKeyPath: valueKeyPath, payloadIndex: payloadIndex) {
                        arrayContentValueItem[arrayContentChildSubkey.key] = value
                    }
                }
                arrayContentValue.append(arrayContentValueItem)
            }
            return arrayContentValue
        } else {
            return arrayValue
        }
    }

    func value(forDictionarySubkey subkey: PayloadSubkey, parentValueKeyPath: String?, payloadIndex: Int) throws -> [String: Any]? {
        Log.shared.info(message: "Get value for dictionary subkey with keyPath: \(subkey.keyPath)", category: String(describing: self))

        let valueKeyPath = self.valueKeyPath(forSubkey: subkey, parentValueKeyPath: parentValueKeyPath)
        var value = [String: Any]()

        var nestedRequiredSubkeys = [PayloadSubkey]()
        for subkey in subkey.subkeys {
            if !self.shouldExport(subkey: subkey, parentValueKeyPath: parentValueKeyPath, payloadIndex: payloadIndex) {
                nestedRequiredSubkeys += subkey.allSubkeys.filter { $0.require == .alwaysNested }
                continue
            }

            if let subkeyValue = try self.value(forSubkey: subkey, parentValueKeyPath: valueKeyPath, payloadIndex: payloadIndex) {
                value[subkey.key] = subkeyValue
            } else if let valueDefault = subkey.valueDefault {
                // FIXME: THIS HAVE NEVER BEEN TESTED!!!
                value[subkey.key] = valueDefault
            } else {
                Log.shared.error(message: "No dictinoary value returned for payload key: \(subkey.keyPath)", category: String(describing: self))
            }
        }

        return value
    }

    func valueIsEmpty(_ value: Any?, type: PayloadValueType) -> Bool {

        if value == nil { return true }

        let type = PayloadUtility.valueType(value: value, type: type)
        switch type {
        case .array:
            if let valueArray = value as? [Any] {
                return valueArray.isEmpty
            }
        case .string:
            if let valueString = value as? String {
                return valueString.isEmpty
            }
        case .dictionary:
            if let valueDictionary = value as? [String: Any] {
                return valueDictionary.isEmpty
            }
        case .bool,
             .data,
             .date,
             .float,
             .integer:
            return false
        default:
            return false
        }
        return false
    }

    func value(forValueSubkey subkey: PayloadSubkey, parentValueKeyPath: String?, payloadIndex: Int) throws -> Any? {
        Log.shared.info(message: "Get value for subkey with keyPath: \(subkey.keyPath)", category: String(describing: self))

        let valueKeyPath = self.valueKeyPath(forSubkey: subkey, parentValueKeyPath: parentValueKeyPath)
        var value: Any?
        if subkey.valueCopy != nil {
            value = subkey.copyValue(profileExport: self, parentValueKeyPath: parentValueKeyPath, payloadIndex: payloadIndex)
        } else {
            value = self.exportSettings.value(forValueKeyPath: valueKeyPath, subkey: subkey, domainIdentifier: subkey.domainIdentifier, payloadType: subkey.payloadType, payloadIndex: payloadIndex)
        }

        // value == nil
        // Changed to this to catch empty strings, arrays and dictionaries
        if self.valueIsEmpty(value, type: subkey.typeInput) {
            if let valueDefault = subkey.defaultValue(profileExport: self, parentValueKeyPath: parentValueKeyPath, payloadIndex: payloadIndex) {
                value = valueDefault
            } else {
                if subkey.type == .array {
                    value = PayloadUtility.emptyValue(valueType: subkey.type)
                } else {
                    value = PayloadUtility.emptyValue(valueType: subkey.typeInput)
                }
            }

            // ---------------------------------------------------------------------
            //  If this is the PayloadIdentifier value, then the root payload identifier should be prepended
            // ---------------------------------------------------------------------
            /*
             if
             subkey.key == PayloadKey.payloadIdentifier,
             let payloadIdentifier = self.payloadIdentifierDefault(forDomainIdentifier: subkey.domainIdentifier, type: subkey.payloadType, payloadIndex: payloadIndex) {
             value = payloadIdentifier
             self.exportSettings.setValue(payloadIdentifier, forSubkey: subkey, payloadIndex: payloadIndex)
             }
             */
        }

        value = try PayloadValueProcessors.shared.process(inputValue: value, forSubkey: subkey)
        value = try self.verify(value, forSubkey: subkey, payloadIndex: payloadIndex)

        return value
    }

    func value(forSubkey subkey: PayloadSubkey, parentValueKeyPath: String?, payloadIndex: Int) throws -> Any? {
        if subkey.type == .array {
            return try self.value(forArraySubkey: subkey, parentValueKeyPath: parentValueKeyPath, payloadIndex: payloadIndex)
        } else if subkey.type == .dictionary, !subkey.subkeys.contains(where: { $0.key == ManifestKeyPlaceholder.key }) {
            return try self.value(forDictionarySubkey: subkey, parentValueKeyPath: parentValueKeyPath, payloadIndex: payloadIndex)
        } else {
            return try self.value(forValueSubkey: subkey, parentValueKeyPath: parentValueKeyPath, payloadIndex: payloadIndex)
        }
    }

    func updateManagedPreferences(domain: String, type: PayloadType, payloadContent: inout [String: Any]) {

        // ---------------------------------------------------------------------
        //  Verify the type is a managed preference
        // ---------------------------------------------------------------------
        if self.exportSettings.payloadContentStyle == PayloadContentStyle.mcx
            && (type == .managedPreferencesApple ||
                type == .managedPreferencesApplications ||
                type == .managedPreferencesApplicationsLocal) {

            // ---------------------------------------------------------------------
            //  Get all payload content keys that's not part of the default payload keys (manifestSubkeysIgnored).
            // ---------------------------------------------------------------------
            let mcxPreferenceSettingsDict = [ PayloadKey.mcxPreferenceSettings: payloadContent.filter { !kPayloadSubkeys.contains($0.key) } ]

            // ---------------------------------------------------------------------
            //  Set the keys in an array for the key "Forced".
            //  FIXME: There might be places where another management option than Forced can be used, then this should be a setting.
            // ---------------------------------------------------------------------
            let forced = ["Forced": [ mcxPreferenceSettingsDict ] ]

            // ---------------------------------------------------------------------
            //  Set the forced Dictionary in a new dictionary for the key of the domain
            // ---------------------------------------------------------------------
            let domainDict = [ domain: forced ]

            // ---------------------------------------------------------------------
            //  Remove all keys that's not part of the default payload keys (manifestSubkeysIgnored).
            // ---------------------------------------------------------------------
            payloadContent = payloadContent.filter { kPayloadSubkeys.contains($0.key) }

            // ---------------------------------------------------------------------
            //  Add the wrapped payload keys dictionary to the key PayloadContent
            // ---------------------------------------------------------------------
            payloadContent[PayloadKey.payloadContent] = domainDict

            // ---------------------------------------------------------------------
            //  Set the PayloadType to com.apple.ManagedClient.preferences
            // ---------------------------------------------------------------------
            payloadContent[PayloadKey.payloadType] = "com.apple.ManagedClient.preferences"

        } else if let payloadType = payloadContent[PayloadKey.payloadType] as? String, payloadType == "com.apple.ManagedClient.preferences" {
            payloadContent[PayloadKey.payloadType] = domain
        }
    }

    /*
     func payloadIdentifierDefault(forDomainIdentifier domainIdentifier: String, type: PayloadType, payloadIndex: Int) -> String? {
     
     var payloadIdentifier = UserDefaults.standard.string(forKey: PreferenceKey.defaultPayloadIdentifierFormat) ?? StringConstant.payloadIdentifierFormat
     
     // "%ROOTID%"
     if let profileIdentifier = self.exportSettings.value(forValueKeyPath: PayloadKey.payloadIdentifier, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0) as? String {
     payloadIdentifier = payloadIdentifier.replacingOccurrences(of: "%ROOTID%", with: profileIdentifier)
     }
     
     // "%TYPE%"
     if let payloadTypeSubkey = ProfilePayloads.shared.payloadSubkey(forKeyPath: PayloadKey.payloadType, domainIdentifier: domainIdentifier, type: type), let payloadType = payloadTypeSubkey.valueDefault as? String {
     payloadIdentifier = payloadIdentifier.replacingOccurrences(of: "%TYPE%", with: payloadType)
     }
     
     // "%UUID%"
     if let payloadUUID = self.exportSettings.value(forValueKeyPath: PayloadKey.payloadUUID, domainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex) as? String {
     payloadIdentifier = payloadIdentifier.replacingOccurrences(of: "%UUID%", with: payloadUUID)
     }
     
     
     // ---------------------------------------------------------------------
     //  Set the passed identifier as the base identifier to return
     // ---------------------------------------------------------------------
     // var payloadIdentifier = identifier
     
     // ---------------------------------------------------------------------
     //  Get the payloads UUID and append to the base identifier
     // ---------------------------------------------------------------------
     //if let payloadUUID = self.exportSettings.value(forValueKeyPath: PayloadKey.payloadUUID, domainIdentifier: domainIdentifier, payloadType: type, payloadIndex: payloadIndex) as? String {
     //    payloadIdentifier += ".\(payloadUUID)"
     //}
     
     // ---------------------------------------------------------------------
     //  Get the profiles payload identifier and append to the base identifier
     // ---------------------------------------------------------------------
     //if let profileIdentifier = self.exportSettings.value(forValueKeyPath: PayloadKey.payloadIdentifier, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0) as? String {
     //    payloadIdentifier = profileIdentifier + ".\(payloadIdentifier)"
     //}
     
     return payloadIdentifier
     }
     */

    func verify(_ value: Any?, forSubkey subkey: PayloadSubkey, payloadIndex: Int) throws -> Any? {

        // ---------------------------------------------------------------------
        //  If variable ignoreErrorInvalidValue is set to true, don't verify the value
        // ---------------------------------------------------------------------
        // FIXME: This is just a quick solution for dynamic dictionaries, should probably do a more robust thing that doesn't have to check for this when exporting every key and value
        if self.ignoreErrorInvalidValue { return value }
        if subkey.key == ManifestKeyPlaceholder.value { return nil }

        // ---------------------------------------------------------------------
        //  Create the error to return if any check fails
        // ---------------------------------------------------------------------
        let errorInvalid = ProfileExportError.settingsErrorInvalid(value: value, key: subkey.key, domain: subkey.domain, type: subkey.payloadType)

        // ---------------------------------------------------------------------
        //  Verify the value type matches the defined type in the subkey
        // ---------------------------------------------------------------------
        if PayloadUtility.valueType(value: value, type: subkey.type) != subkey.type { throw errorInvalid }

        // ---------------------------------------------------------------------
        //  Get if this subkey is required
        // ---------------------------------------------------------------------
        let isRequired = self.exportSettings.isRequired(subkey: subkey, ignoreConditionals: false, payloadIndex: payloadIndex) ? true : false

        // ---------------------------------------------------------------------
        //  Do a value check for the specific value type
        // ---------------------------------------------------------------------
        switch subkey.type {
        case .string:
            guard let valueString = value as? String else {
                throw errorInvalid
            }

            if isRequired, valueString.isEmpty {
                throw errorInvalid
            } else if let format = subkey.format, !valueString.matches(format) {
                // FIXME: Correct Error
                throw errorInvalid
            }
        case .integer:
            guard let valueInt = value as? Int else {
                throw errorInvalid
            }

            if let rangeMin = subkey.rangeMin as? Int, valueInt < rangeMin {
                throw errorInvalid
            }

            if let rangeMax = subkey.rangeMax as? Int, rangeMax < valueInt {
                throw errorInvalid
            }
        case .float:
            guard value is Float else {
                throw errorInvalid
            }
        case .bool:
            guard value is Bool else {
                throw errorInvalid
            }
        default:
            Log.shared.error(message: "Value check for type: \(subkey.type) is not defined", category: String(describing: self))
        }

        return value
    }

    private func shouldExport(subkey: PayloadSubkey, parentValueKeyPath: String? = nil, payloadIndex: Int) -> Bool {

        // ---------------------------------------------------------------------
        //  Do not export segmented controls, they are only a UI setting
        // ---------------------------------------------------------------------
        if subkey.excluded || subkey.segments != nil { return false }

        // ---------------------------------------------------------------------
        //  Do not export subkeys unavailable for the selected platform
        // ---------------------------------------------------------------------
        if !self.exportSettings.isAvailableForSelectedPlatform(subkey: subkey) { return false }

        // ---------------------------------------------------------------------
        //  Do not export excluded subkeys
        // ---------------------------------------------------------------------
        if self.exportSettings.isExcluded(subkey: subkey, parentValueKeyPath: parentValueKeyPath, payloadIndex: payloadIndex) { return false }

        // ---------------------------------------------------------------------
        //  Do not export disabled subkeys
        // ---------------------------------------------------------------------
        if !self.exportSettings.isEnabled(subkey, onlyByUser: false, ignoreConditionals: false, payloadIndex: payloadIndex) { return false }

        // ---------------------------------------------------------------------
        //  Do not export dynamic dictionary keys ( only check the {value} )
        // ---------------------------------------------------------------------
        if subkey.key == ManifestKeyPlaceholder.key { return false }

        // ---------------------------------------------------------------------
        //  Check if the subkey is a single dictionary in an array
        // ---------------------------------------------------------------------
        // FIXME: This SHOULD return true from the isEnabled function, I think. Using here to fix the issue for now.
        // It looks like it works when determining if it should be added to the view, but not here when exporting.
        // But it can't really, unless a special case, because we have to check only by user enabled keys,
        // and when only a required key is enabled then it won't show there.
        if subkey.type == .dictionary, (subkey.parentSubkey?.type == .array && subkey.parentSubkey?.rangeMax as? Int == 1) {
            return true
        }

        // FIXME: Need to add the following checks aswell
        // FIXME: * profile.isAvailableForSelectedScope
        // FIXME: * profile.isAvailableForSelectedVersion (app OR os)

        return true
    }
}
