//
//  ProfileSettingsOptionSets.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    func isAvailableForSelectedPlatform(subkey: PayloadSubkey) -> Bool {
        !subkey.platforms.isDisjoint(with: self.platforms)
    }

    func updateDistributionMethod() {
        let selectedDistributionMethod = Distribution(string: self.distributionMethodString)
        if self.distributionMethod != selectedDistributionMethod {
            #if DEBUG
            if self.distributionMethod != Distribution.none {
                Log.shared.debug(message: "Updating selected distribution method to: \(PayloadUtility.string(fromDistribution: selectedDistributionMethod, separator: ", ")) for profile with identifier: \(self.identifier)", category: String(describing: self))
            }
            #endif

            self.distributionMethod = selectedDistributionMethod
            self.resetCache()
            self.setValue(!self.distributionMethodUpdated, forKeyPath: self.distributionMethodUpdatedSelector)
        }
    }

    func updatePlatforms() {
        var selectedPlatforms: Platforms = []
        if self.platformIOS { selectedPlatforms.insert(.iOS) }
        if self.platformMacOS { selectedPlatforms.insert(.macOS) }
        if self.platformTvOS { selectedPlatforms.insert(.tvOS) }
        if self.platforms != selectedPlatforms {
            #if DEBUG
            if self.platforms != Platforms.none {
                Log.shared.debug(message: "Updating selected platforms to: \(PayloadUtility.string(fromPlatforms: selectedPlatforms, separator: ", ")) for profile with identifier: \(self.identifier)", category: String(describing: self))
            }
            #endif

            self.platforms = selectedPlatforms
            self.resetCache()
            self.setValue(!self.platformsUpdated, forKeyPath: self.platformsUpdatedSelector)
        }
    }

    func updateScope() {
        var selectedScope: Targets = []
        if self.scopeUser { selectedScope.insert(.user) }
        if self.scopeUserManaged { selectedScope.insert(.userManaged) }
        if self.scopeSystem { selectedScope.insert(.system) }
        if self.scopeSystemManaged { selectedScope.insert(.systemManaged) }
        if self.scope != selectedScope {
            #if DEBUG
            if self.scope != Targets.none {
                Log.shared.debug(message: "Updating selected scope to: \(PayloadUtility.string(fromTargets: selectedScope, separator: ", ")) for profile with identifier: \(self.identifier)", category: String(describing: self))
            }
            #endif

            self.scope = selectedScope
            self.resetCache()
            self.setValue(!self.scopeUpdated, forKeyPath: self.scopeUpdatedSelector)
        }
    }
}
