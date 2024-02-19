//
//  ProfileSettingsPayloadKeysEnabled.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    // MARK: -
    // MARK: Check Any Subkey

    // if ANY payload has this subkey enabled
    func isEnabled(_ subkey: PayloadSubkey, onlyByUser: Bool, ignoreConditionals: Bool) -> Bool {
        let domainSettings = self.viewSettings(forDomainIdentifier: subkey.domainIdentifier, payloadType: subkey.payloadType) ?? [[String: Any]]()
        if domainSettings.isEmpty {
            return self.isEnabled(subkey, onlyByUser: onlyByUser, ignoreConditionals: ignoreConditionals, payloadIndex: 0)
        } else {
            for payloadIndex in domainSettings.indices where self.isEnabled(subkey, onlyByUser: onlyByUser, ignoreConditionals: ignoreConditionals, payloadIndex: payloadIndex) {
                return true
            }
        }
        return false
    }

    // MARK: -
    // MARK: Is Enabled: Subkey

    // MARK: -
    // MARK: Is Enabled: By…

    func isEnabledByRequired(_ subkey: PayloadSubkey, parentIsEnabled: Bool, onlyByUser: Bool, isRequired: Bool, payloadIndex: Int) -> Bool {
        if !onlyByUser, parentIsEnabled, isRequired {
            #if DEBUGISENABLED
            Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled: \(true) - Required", category: String(describing: self))
            #endif

            self.setCacheIsEnabled(true, forSubkey: subkey, payloadIndex: payloadIndex)
            return true
        }
        return false
    }

    // swiftlint:disable:next discouraged_optional_boolean
    func isEnabledByUser(_ subkey: PayloadSubkey, payloadIndex: Int) -> Bool? {
        guard let isEnabled = self.viewValueEnabled(forSubkey: subkey, payloadIndex: payloadIndex) else { return nil }
        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled: \(isEnabled) - User", category: String(describing: self))
        #endif

        return isEnabled
    }

    // swiftlint:disable:next discouraged_optional_boolean
    func isEnabledByDefault(_ subkey: PayloadSubkey, parentIsEnabled: Bool, onlyByUser: Bool) -> Bool? {
        guard !onlyByUser, parentIsEnabled, subkey.enabledDefault else { return nil }

        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled: \(true) - Default", category: String(describing: self))
        #endif

        return true
    }

    // swiftlint:disable:next discouraged_optional_boolean
    func isEnabledByDynamicDictionary(_ subkey: PayloadSubkey, parentIsEnabled: Bool, onlyByUser: Bool, payloadIndex: Int) -> Bool? {
        guard !onlyByUser, parentIsEnabled, subkey.parentSubkey?.type == .dictionary, (subkey.key == ManifestKeyPlaceholder.key || subkey.key == ManifestKeyPlaceholder.value) else { return nil }

        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled: \(true) - Dynamic Dictionary", category: String(describing: self))
        #endif

        self.setCacheIsEnabled(true, forSubkey: subkey, payloadIndex: payloadIndex)
        return true
    }

    // swiftlint:disable:next discouraged_optional_boolean
    func isEnabledByArrayOfDictionaries(_ subkey: PayloadSubkey, parentIsEnabled: Bool, payloadIndex: Int, arrayIndex: Int) -> Bool? {
        guard parentIsEnabled, subkey.isParentArrayOfDictionaries else { return nil }

        let isEnabled: Bool

        if arrayIndex == -1 || (arrayIndex != -1 && self.value(forSubkey: subkey, payloadIndex: payloadIndex) != nil) {
            isEnabled = true
        } else {
            isEnabled = false
        }

        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled: \(isEnabled) - Child in Array of Dictionaries", category: String(describing: self))
        #endif

        return isEnabled
    }

    func isEnabled(_ subkey: PayloadSubkey, onlyByUser: Bool, ignoreConditionals: Bool, payloadIndex: Int, arrayIndex: Int = -1) -> Bool {

        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled - Checking - onlyByUser: \(onlyByUser), ignoreConditionals: \(ignoreConditionals), payloadIndex: \(payloadIndex), arrayIndex: \(arrayIndex)", category: String(describing: self))
        #endif

        // ---------------------------------------------------------------------
        //  Check if the subkey has a cached isEnabled-value, if so return that
        // ---------------------------------------------------------------------
        if let isEnabledCache = self.cacheIsEnabled(subkey, payloadIndex: payloadIndex) { return isEnabledCache }

        // ---------------------------------------------------------------------
        //  Check if all parent subkeys are enabled
        // ---------------------------------------------------------------------
        let isEnabledParent = self.isEnabledParent(subkey, onlyByUser: onlyByUser, ignoreConditionals: ignoreConditionals, payloadIndex: payloadIndex, arrayIndex: arrayIndex)

        // ---------------------------------------------------------------------
        //  Check if the parent subkey is an array and enabled, then this subkey is automatically enabled
        // ---------------------------------------------------------------------
        guard !self.isEnabledParentAnArray(isEnabledParent, subkey: subkey, onlyByUser: onlyByUser, payloadIndex: payloadIndex) else { return true }

        // ---------------------------------------------------------------------
        //  Set the default isEnabled state
        // ---------------------------------------------------------------------
        var isEnabled = !self.disableOptionalKeys

        // ---------------------------------------------------------------------
        //  Check if the subkey is required
        // ---------------------------------------------------------------------
        let isRequired = self.isRequired(subkey: subkey, ignoreConditionals: ignoreConditionals, isEnabledOnlyByUser: onlyByUser, payloadIndex: payloadIndex)

        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isRequired: \(isRequired)", category: String(describing: self))
        #endif

        // ---------------------------------------------------------------------
        //  Check if the subkey is required, it's parent is enabled and not only keys manually enabled by the user should be returned.
        // ---------------------------------------------------------------------
        guard !isEnabledByRequired(subkey, parentIsEnabled: isEnabledParent, onlyByUser: onlyByUser, isRequired: isRequired, payloadIndex: payloadIndex) else { return true }

        // ---------------------------------------------------------------------
        //  Check if the subkey is manually enabled/disabled by the user
        // ---------------------------------------------------------------------
        if let isEnabledByUser = self.isEnabledByUser(subkey, payloadIndex: payloadIndex) {
            isEnabled = isEnabledByUser

            // ---------------------------------------------------------------------
            //  Check if the subkey is enabled by default in the manifest, it's parent is enabled and not only keys manually enabled by the user should be returned.
            // ---------------------------------------------------------------------
        } else if let isEnabledByDefault = self.isEnabledByDefault(subkey, parentIsEnabled: isEnabledParent, onlyByUser: onlyByUser) {
            isEnabled = isEnabledByDefault

            // ---------------------------------------------------------------------
            //  Check if the subkey is a dynamic dictionary, it's parent is enabled and not only keys manually enabled by the user should be returned.
            // ---------------------------------------------------------------------
        } else if let isEnabledByDynamicDictionary = self.isEnabledByDynamicDictionary(subkey, parentIsEnabled: isEnabledParent, onlyByUser: onlyByUser, payloadIndex: payloadIndex) {
            return isEnabledByDynamicDictionary

            // ---------------------------------------------------------------------
            //  Check if the subkey is a child in an array of dictionaries, and if it's parent is enabled.
            // ---------------------------------------------------------------------
        } else if let isEnabledByArrayOfDictionaries = self.isEnabledByArrayOfDictionaries(subkey, parentIsEnabled: isEnabledParent, payloadIndex: payloadIndex, arrayIndex: arrayIndex) {
            return isEnabledByArrayOfDictionaries
        }

        // ---------------------------------------------------------------------
        //  Check if key was not enabled, and if key is an array, then loop through each child subkeys and if any child is enabled this key should also be enabled
        // ---------------------------------------------------------------------

        // FIXME: Should this be typeInput aswell?
        if !isEnabled, (subkey.type != .array || subkey.rangeMax as? Int == 1) {
            isEnabled = self.isEnabled(childSubkeys: subkey.subkeys, forSubkey: subkey, ignoreConditionals: ignoreConditionals, payloadIndex: payloadIndex)
        }

        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled: \(isEnabled)", category: String(describing: self))
        #endif

        // ---------------------------------------------------------------------
        //  Check if enabled state should be cached
        // ---------------------------------------------------------------------
        if !ignoreConditionals && ( !onlyByUser || onlyByUser && !isRequired ) {
            self.setCacheIsEnabled(isEnabled, forSubkey: subkey, payloadIndex: payloadIndex)
        }

        // ---------------------------------------------------------------------
        //  Return if key is enabled
        // ---------------------------------------------------------------------
        return isEnabled
    }

    // MARK: -
    // MARK: Is Enabled: Parent

    func isEnabledParent(_ subkey: PayloadSubkey, onlyByUser: Bool, ignoreConditionals: Bool, payloadIndex: Int, arrayIndex: Int) -> Bool {
        guard !onlyByUser, let parentSubkeys = subkey.parentSubkeys else {

            #if DEBUGISENABLED
            Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabledParent: \(true)", category: String(describing: self))
            #endif

            return true
        }

        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled - Checking - Parents", category: String(describing: self))
        #endif

        // Loop through all parents
        for parentSubkey in parentSubkeys {

            #if DEBUGISENABLED
            Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled - Checking - Parent: \(parentSubkey.keyPath)", category: String(describing: self))
            #endif

            // Ignore Dictionaries in Single Dictionary Arrays
            if parentSubkey.type == .dictionary, (parentSubkey.parentSubkey?.type == .array && parentSubkey.parentSubkey?.rangeMax as? Int == 1) {

                #if DEBUGISENABLED
                Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled - IGNORING parent: \(parentSubkey.keyPath) - Dictionary in single dictionary array", category: String(describing: self))
                #endif

                continue
            } else {
                if !self.isEnabled(parentSubkey, onlyByUser: false, ignoreConditionals: ignoreConditionals, payloadIndex: payloadIndex, arrayIndex: arrayIndex) {

                    #if DEBUGISENABLED
                    Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabledParent: \(false)", category: String(describing: self))
                    #endif

                    return false
                }
            }
        }

        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabledParent: \(true)", category: String(describing: self))
        #endif

        return true
    }

    // Check if parent is an array, except if the array key has rangeMax set to 1
    func isEnabledParentAnArray(_ isEnabledParent: Bool, subkey: PayloadSubkey, onlyByUser: Bool, payloadIndex: Int) -> Bool {
        if !onlyByUser, isEnabledParent, subkey.parentSubkey?.typeInput == .array, !(subkey.parentSubkey?.rangeMax as? Int == 1) {

            #if DEBUGISENABLED
            Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled: \(true) - ParentArray", category: String(describing: self))
            #endif

            self.setCacheIsEnabled(true, forSubkey: subkey, payloadIndex: payloadIndex)
            return true
        }
        return false
    }

    // MARK: -
    // MARK: Check Child Subkeys

    func isEnabled(childSubkeys: [PayloadSubkey], forSubkey subkey: PayloadSubkey, ignoreConditionals: Bool, payloadIndex: Int) -> Bool {
        for childSubkey in childSubkeys {
            if childSubkey.type == .dictionary, subkey.rangeMax as? Int == 1 {
                for dictSubkey in subkey.subkeys {

                    #if DEBUGISENABLED
                    Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled - Checking Child Dictionary Subkey: \(dictSubkey.keyPath)", category: String(describing: self))
                    #endif

                    if self.isEnabled(dictSubkey, onlyByUser: true, ignoreConditionals: ignoreConditionals, payloadIndex: payloadIndex) {
                        #if DEBUGISENABLED
                        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled: \(true) - Child: \(childSubkey.keyPath)", category: String(describing: self))
                        #endif
                        return true
                    }
                }
            } else {

                #if DEBUGISENABLED
                Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled - Checking Child Subkey: \(childSubkey.keyPath)", category: String(describing: self))
                #endif

                if self.isEnabled(childSubkey, onlyByUser: true, ignoreConditionals: ignoreConditionals, payloadIndex: payloadIndex) {
                    #if DEBUGISENABLED
                    Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled: \(true) - Child: \(childSubkey.keyPath)", category: String(describing: self))
                    #endif
                    return true
                }
            }
        }
        return false
    }
}
