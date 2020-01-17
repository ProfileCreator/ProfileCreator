//
//  ProfileSettingsCache.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    // MARK: -
    // MARK: Is Enabled

    // swiftlint:disable:next discouraged_optional_boolean
    func cacheIsEnabled(_ subkey: PayloadSubkey, payloadIndex: Int) -> Bool? {
        guard let cacheEnabled = self.cachedEnabled[subkey.keyPath], let isEnabled = cacheEnabled[payloadIndex] else { return nil }

        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled: \(isEnabled) - Cache", category: String(describing: self))
        #endif

        return isEnabled
    }

    func setCacheIsEnabled(_ enabled: Bool, forSubkey subkey: PayloadSubkey, payloadIndex: Int) {
        var cacheSubkey = self.cachedEnabled[subkey.keyPath] ?? [Int: Bool]()
        cacheSubkey[payloadIndex] = enabled

        #if DEBUGISENABLED
        Log.shared.debug(message: "Subkey: \(subkey.keyPath) isEnabled: \(enabled) - Setting Cache", category: String(describing: self))
        #endif

        self.cachedEnabled[subkey.keyPath] = cacheSubkey
    }

}
