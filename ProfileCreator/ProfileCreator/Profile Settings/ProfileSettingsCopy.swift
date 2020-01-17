//
//  ProfileSettingsCopy.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

// MARK: -
// MARK: NSCopying Functions

extension ProfileSettings: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        do {
            return try ProfileSettings(withSettings: self.currentSettings())
        } catch {
            Log.shared.error(message: "Copying profile settings failed with error: \(error)", category: String(describing: self))
            return ProfileSettings()
        }
    }
}
