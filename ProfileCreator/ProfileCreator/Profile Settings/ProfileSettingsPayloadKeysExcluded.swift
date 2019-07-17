//
//  ProfileSettingsPayloadKeysExcluded.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    func isExcluded(subkey: PayloadSubkey, parentValueKeyPath: String? = nil, payloadIndex: Int) -> Bool {
        if let exludedArray = self.isExcludedArray(subkey: subkey, parentValueKeyPath: parentValueKeyPath, payloadIndex: payloadIndex) {
            return !exludedArray.isEmpty
        }
        return false
    }

    func isExcludedArray(subkey: PayloadSubkey, parentValueKeyPath: String? = nil, payloadIndex: Int) -> [[String: Any]]? {
        if !subkey.excludes.isEmpty {
            return self.match(subkey: subkey, excludeConditionals: subkey.excludes, parentValueKeyPath: parentValueKeyPath, payloadIndex: payloadIndex)
        }
        return nil
    }

}
