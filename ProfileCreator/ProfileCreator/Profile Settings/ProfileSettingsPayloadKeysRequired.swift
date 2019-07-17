//
//  ProfileSettingsPayloadKeysRequired.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    func isRequired(subkey: PayloadSubkey, ignoreConditionals: Bool, isEnabledOnlyByUser: Bool = false, payloadIndex: Int) -> Bool {

        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isRequired - Checking - isEnabledOnlyByUser: \(isEnabledOnlyByUser), ignoreConditionals: \(ignoreConditionals), payloadIndex: \(payloadIndex)", category: String(describing: self))
        #endif

        if subkey.require == .always || subkey.require == .alwaysNested {
            #if DEBUGISENABLED
            Log.shared.debug(message: "Subkey: \(subkey.keyPath) isRequired: \(true) - \(subkey.require)", category: String(describing: self))
            #endif
            return true
        }

        let isDistributionMethodPush = self.distributionMethodString == DistributionString.push

        if isDistributionMethodPush, subkey.require == .push {
            #if DEBUGISENABLED
            Log.shared.debug(message: "Subkey: \(subkey.keyPath) isRequired: \(true) - \(subkey.require)", category: String(describing: self))
            #endif
            return true
        }

        if !ignoreConditionals {
            let requiredConditionals = subkey.conditionals.compactMap { !($0.require == .push && self.distributionMethod == .manual) ? $0 : nil }
            if !requiredConditionals.isEmpty {

                #if DEBUGISENABLED
                Log.shared.debug(message: "Subkey: \(subkey.keyPath) isRequired - Checking - Conditionals: \(requiredConditionals.count)", category: String(describing: self))
                #endif

                if self.match(subkey: subkey, sourceConditionals: requiredConditionals, isEnabledOnlyByUser: isEnabledOnlyByUser, payloadIndex: payloadIndex) != nil {

                    #if DEBUGISENABLED
                    Log.shared.debug(message: "Subkey: \(subkey.keyPath) isRequired: \(true) - Conditionals", category: String(describing: self))
                    #endif

                    return true
                }
            }
        }

        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isRequired: \(false)", category: String(describing: self))
        #endif

        return false
    }

}
