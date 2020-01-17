//
//  ProfileSettingsCurrent.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

extension ProfileSettings {

    // MARK: -
    // MARK: Current Settings

    func currentSettings() -> [String: Any] {
        var currentSettings = [String: Any]()
        currentSettings[SettingsKey.profileSettings] = self.settingsProfile
        currentSettings[SettingsKey.payloadSettings] = self.settingsPayload
        currentSettings[SettingsKey.viewSettings] = self.settingsView
        currentSettings[SettingsKey.editorSettings] = self.currentEditorSettings()
        currentSettings[SettingsKey.saveFormatVersion] = kSaveFormatVersion
        return currentSettings
    }

    func currentEditorSettings() -> [String: Any] {
        var editorSettings = [String: Any]()

        // Distribution Method
        editorSettings[PreferenceKey.distributionMethod] = self.distributionMethodString

        // Payload Keys
        editorSettings[PreferenceKey.disableOptionalKeys] = self.disableOptionalKeys
        editorSettings[PreferenceKey.showUserApprovedKeys] = self.showUserApprovedKeys
        editorSettings[PreferenceKey.showSupervisedKeys] = self.showSupervisedKeys
        editorSettings[PreferenceKey.showDisabledKeys] = self.showDisabledKeys
        editorSettings[PreferenceKey.showCustomizedKeys] = self.showCustomizedKeys
        editorSettings[PreferenceKey.showHiddenKeys] = self.showHiddenKeys

        // Platforms
        editorSettings[PreferenceKey.platformIOS] = self.platformIOS
        editorSettings[PreferenceKey.platformMacOS] = self.platformMacOS
        editorSettings[PreferenceKey.platformTvOS] = self.platformTvOS

        // Scope
        editorSettings[PreferenceKey.scopeUser] = self.scopeUser
        editorSettings[PreferenceKey.scopeUserManaged] = self.scopeUserManaged
        editorSettings[PreferenceKey.scopeSystem] = self.scopeSystem
        editorSettings[PreferenceKey.scopeSystemManaged] = self.scopeSystemManaged

        // Signing
        editorSettings[PreferenceKey.signProfile] = self.sign
        editorSettings[PreferenceKey.signingCertificate] = self.signingCertificate

        // Export
        editorSettings[PreferenceKey.payloadContentStyle] = self.payloadContentStyle

        return editorSettings
    }

}
