//
//  DictionaryKeys.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

// MARK: -
// MARK: FileInfoKey
// MARK: -

struct FileInfoKey {
    static let fileAttributes = "FileAttributes"
    static let fileInfoView = "FileInfoView"
    static let fileURL = "FileURL"
    static let fileUTI = "FileUTI"
}

// MARK: -
// MARK: FileInfoViewKey
// MARK: -

struct FileInfoViewKey {
    static let title = "Title"
    static let topLabel = "TopLabel"
    static let topContent = "TopContent"
    static let topError = "TopError"
    static let centerLabel = "CenterLabel"
    static let centerContent = "CenterContent"
    static let centerError = "CenterError"
    static let bottomLabel = "BottomLabel"
    static let bottomContent = "BottomContent"
    static let bottomError = "BottomError"
    static let message = "Message"
    static let iconPath = "IconPath"
}

// MARK: -
// MARK: ImportErrorKey
// MARK: -

struct ImportErrorKey {
    static let payloadTypeMissing = "PayloadTypeMissing"
    static let payloadTypeCustom = "payloadTypeCustom"
    static let payloadKeyMissing = "PayloadKeyMissing"
}

// MARK: -
// MARK: NotificationKey
// MARK: -

struct NotificationKey {
    static let group = "Group"
    static let identifier = "Identifier"
    static let identifiers = "Identifiers"
    static let indexSet = "IndexSet"
    static let parentTitle = "ParentTitle"
    static let payloadSelected = "payloadSelected"
    static let payloadPlaceholder = "PayloadPlaceholder"
}

// MARK: -
// MARK: PreferenceKey
// MARK: -

struct PreferenceKey {

    // Developer
    static let showDeveloperMenu = "ShowDeveloperMenu"

    // Default Values
    static let defaultOrganization = "DefaultOrganization"
    static let defaultOrganizationIdentifier = "DefaultOrganizationIdentifier"
    static let defaultPayloadIdentifierFormat = "DefaultPayloadIdentifierFormat"
    static let defaultProfileIdentifierFormat = "DefaultProfileIdentifierFormat"

    // Main Window
    static let mainWindowShowProfileCount = "MainWindowShowProfileCount"
    static let mainWindowShowGroupIcons = "MainWindowShowGroupIcons"

    // Payload Editor
    static let payloadEditorShowDisabledKeysSeparator = "PayloadEditorShowDisabledKeysSeparator"
    static let payloadEditorShowKeyAsTitle = "PayloadEditorShowKeyAsTitle"
    static let payloadEditorShowSegmentedControls = "PayloadEditorShowSegmentedControls"
    static let payloadEditorSyntaxHighlightTheme = "PayloadEditorSyntaxHighlightTheme"
    static let payloadEditorSyntaxHighlightBackgroundColor = "PayloadEditorSyntaxHighlightBackgroundColor"

    // Profile Library
    static let profileLibraryPath = "ProfileLibraryPath"
    static let profileLibraryGroupPath = "ProfileLibraryGroupPath"
    static let profileLibraryFileNameFormat = "ProfileLibraryFileNameFormat"

    // Payload Library
    static let payloadLibraryShowCustom = "PayloadLibraryShowCustom"
    static let payloadLibraryShowDomainsApple = "PayloadLibraryShowDomainsApple"
    static let payloadLibraryShowManagedPreferencesApple = "PayloadLibraryShowManagedPreferencesApple"
    static let payloadLibraryShowManagedPreferencesApplications = "PayloadLibraryShowManagedPreferencesApplications"
    static let payloadLibraryShowManagedPreferencesApplicationsLocal = "PayloadLibraryShowManagedPreferencesApplicationsLocal"
    static let payloadLibraryShowDomainAsTitle = "PayloadLibraryShowDomainAsTitle"
    static let payloadLibraryShowApplicationsFolderOnly = "PayloadLibraryShowApplicationsFolderOnly"

    // Distribution Method
    static let distributionMethod = "DistributionMethod"

    // Platform
    static let platformIOS = "PlatformIOS"
    static let platformMacOS = "PlatformMacOS"
    static let platformTvOS = "PlatformTvOS"

    // Scope
    static let scopeUser = "ScopeUser"
    static let scopeUserManaged = "ScopeUserManaged"
    static let scopeSystem = "ScopeSystem"
    static let scopeSystemManaged = "ScopeSystemManaged"

    // Sign
    static let signProfile = "SignProfile"
    static let signingCertificate = "SigningCertificate"
    static let signingCertificateShowExpired = "SigningCertificateShowExpired"
    static let signingCertificateShowUntrusted = "SigningCertificateShowUntrusted"
    static let signingCertificateSearchSystemKeychain = "SigningCertificateSearchSystemKeychain"

    // Payload Manifests
    static let payloadManifestsAutomaticallyCheckForUpdates = "PayloadManifestsAutomaticallyCheckForUpdates"
    static let payloadManifestsAutomaticallyDownloadUpdates = "PayloadManifestsAutomaticallyDownloadUpdates"
    static let payloadManifestsUpdatesLastCheck = "PayloadManifestsUpdatesLastCheck"
    static let payloadManifestsUpdatesAvailable = "PayloadManifestsUpdatesAvailable"

    // Application
    static let applicationAutomaticallyCheckForUpdates = "ApplicationAutomaticallyCheckForUpdates"
    static let applicationUpdatesIncludePreReleases = "ApplicationUpdatesIncludePreReleases"
    static let applicationUpdatesLastCheck = "ApplicationUpdatesLastCheck"
    static let applicationUpdatesAvailable = "ApplicationUpdatesAvailable"

    // Payload Keys
    static let disableOptionalKeys = "DisableOptionalKeys"
    static let showCustomizedKeys = "ShowCustomizedKeys"
    static let showUserApprovedKeys = "ShowUserApprovedKeys"
    static let showSupervisedKeys = "ShowSupervisedKeys"
    static let showDisabledKeys = "ShowDisabledKeys"
    static let showHiddenKeys = "ShowHiddenKeys"

    // Export
    static let payloadContentStyle = "PayloadContentStyle"
}

// MARK: -
// MARK: SettingsKey
// MARK: -

struct SettingsKey {
    static let editorSettings = "EditorSettings"
    static let enabled = "Enabled"
    static let fileInfo = "FileInfo"
    static let hash = "Hash"
    static let identifier = "Identifier"
    static let identifiers = "Identifiers"
    static let jssURL = "JSSURL"
    static let jssUsername = "JSSUsername"
    // static let payloadIndex = "PayloadIndex"
    static let payloadIndexSelected = "PayloadIndexSelected"
    static let payloadSettings = "PayloadSettings"
    static let profileSettings = "ProfileSettings"
    static let selected = "Selected"
    static let settings = "Settings"
    static let sign = "Sign"
    static let title = "Title"
    static let viewSettings = "ViewSettings"
    static let value = "Value"
    static let saveFormatVersion = "PFCConfVersion"
}
