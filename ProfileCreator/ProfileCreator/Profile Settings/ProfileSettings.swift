//
//  ProfileSettings.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import ProfilePayloads

class ProfileSettings: NSObject {

    // MARK: -
    // MARK: Computed Variables

    public var identifier: UUID {
        guard
            let identifierString = self.value(forValueKeyPath: PayloadKey.payloadUUID, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0) as? String,
            let identifier = UUID(uuidString: identifierString) else {
                let identifier = UUID()
                self.setValue(identifier.uuidString, forValueKeyPath: PayloadKey.payloadUUID, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
                return identifier
        }
        return identifier
    }

    @objc public dynamic var title: String {
        get {
            guard let displayName = self.value(forValueKeyPath: PayloadKey.payloadDisplayName, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0) as? String else {
                return StringConstant.defaultProfileName
            }
            return displayName
        }

        set {
            self.setValue(newValue, forValueKeyPath: PayloadKey.payloadDisplayName, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
        }
    }

    // MARK: -
    // MARK: Cached Variables

    internal var cachedConditionals = [String: Any]()
    internal var cachedEnabled = [String: [Int: Bool]]()
    internal var cachedPayloadContent = [String: [Int: [String: Any]]]()

    // MARK: -
    // MARK: Settings Variables

    internal var settingsSaved = [String: Any]()

    public var settingsEditor: [String: Any]
    public var settingsPayload: [String: [String: [[String: Any]]]]
    public var settingsProfile: [String: Any]
    public var settingsView: [String: [String: [[String: Any]]]]

    // MARK: -
    // MARK: Format Version Variables

    public var formatVersion: Int = kSaveFormatVersion

    // MARK: -
    // MARK: Import Variables

    public var importErrors = [String: Any]()

    // MARK: -
    // MARK: OptionSets

    public var distributionMethod: Distribution = []
    public var platforms: Platforms = []
    public var scope: Targets = []

    // MARK: -
    // MARK: Key/Value Observing Variables

    // MARK: -
    // MARK: Distribution Method

    // Distribution Method
    @objc public var distributionMethodString = DistributionString.any
    public let distributionMethodStringSelector = NSStringFromSelector(#selector(getter: ProfileSettings.distributionMethodString))

    // Distribution Method Updated
    @objc public var distributionMethodUpdated = false
    public let distributionMethodUpdatedSelector = NSStringFromSelector(#selector(getter: ProfileSettings.distributionMethodUpdated))

    // MARK: -
    // MARK: Payload Keys

    // Disable Optional Keys
    @objc public var disableOptionalKeys = false
    public let disableOptionalKeysSelector = NSStringFromSelector(#selector(getter: ProfileSettings.disableOptionalKeys))

    // Show Supervised Keys
    @objc public var showSupervisedKeys = true
    public let showSupervisedKeysSelector = NSStringFromSelector(#selector(getter: ProfileSettings.showSupervisedKeys))

    // Show User Approved Keys
    @objc public var showUserApprovedKeys = true
    public let showUserApprovedKeysSelector = NSStringFromSelector(#selector(getter: ProfileSettings.showUserApprovedKeys))

    // Show Customized Keys
    @objc public var showCustomizedKeys = true
    public let showCustomizedKeysSelector = NSStringFromSelector(#selector(getter: ProfileSettings.showCustomizedKeys))

    // Show Disabled Keys
    @objc public var showDisabledKeys = true
    public let showDisabledKeysSelector = NSStringFromSelector(#selector(getter: ProfileSettings.showDisabledKeys))

    // Show Hidden Keys
    @objc public var showHiddenKeys = true
    public let showHiddenKeysSelector = NSStringFromSelector(#selector(getter: ProfileSettings.showHiddenKeys))

    // MARK: -
    // MARK: Platform

    // Platform iOS
    @objc public var platformIOS = true
    public let platformIOSSelector = NSStringFromSelector(#selector(getter: ProfileSettings.platformIOS))

    // Platform macOS
    @objc public var platformMacOS = true
    public let platformMacOSSelector = NSStringFromSelector(#selector(getter: ProfileSettings.platformMacOS))

    // Platform tvOS
    @objc public var platformTvOS = true
    public let platformTvOSSelector = NSStringFromSelector(#selector(getter: ProfileSettings.platformTvOS))

    // Platform Updated
    @objc public var platformsUpdated = false
    public let platformsUpdatedSelector = NSStringFromSelector(#selector(getter: ProfileSettings.platformsUpdated))

    // MARK: -
    // MARK: Profile

    // MARK: -
    // MARK: Settings

    // Settings Restored
    @objc public var settingsRestored = false
    public let settingsRestoredSelector = NSStringFromSelector(#selector(getter: ProfileSettings.settingsRestored))

    // MARK: -
    // MARK: Scope

    // Scope User
    @objc public var scopeUser = false
    public let scopeUserSelector = NSStringFromSelector(#selector(getter: ProfileSettings.scopeUser))

    // Scope User Managed
    @objc public var scopeUserManaged = false
    public let scopeUserManagedSelector = NSStringFromSelector(#selector(getter: ProfileSettings.scopeUserManaged))

    // Scope System
    @objc public var scopeSystem = false
    public let scopeSystemSelector = NSStringFromSelector(#selector(getter: ProfileSettings.scopeSystem))

    // Scope System Managed
    @objc public var scopeSystemManaged = false
    public let scopeSystemManagedSelector = NSStringFromSelector(#selector(getter: ProfileSettings.scopeSystemManaged))

    // Scope Updated
    @objc public var scopeUpdated = false
    public let scopeUpdatedSelector = NSStringFromSelector(#selector(getter: ProfileSettings.scopeUpdated))

    // Title
    // @objc public dynamic var title = ""
    public let titleSelector = NSStringFromSelector(#selector(getter: ProfileSettings.title))

    // MARK: -
    // MARK: Signing

    // Sign
    @objc public var sign = false
    public let signSelector = NSStringFromSelector(#selector(getter: ProfileSettings.sign))

    // Signing Certificate
    @objc public var signingCertificate: Data?
    public let signingCertificateSelector = NSStringFromSelector(#selector(getter: ProfileSettings.signingCertificate))

    // MARK: -
    // MARK: Export

    @objc public var payloadContentStyle = PayloadContentStyle.profile
    public let payloadContentStyleSelector = NSStringFromSelector(#selector(getter: ProfileSettings.payloadContentStyle))

    // MARK: -
    // MARK: Weak Variables

    weak var conditionSubkey: PayloadSubkey?
    weak var profile: Profile?

    // MARK: -
    // MARK: Init

    override init() {

        self.settingsProfile = ProfileSettings.profileSettingsDefault()
        self.settingsPayload = ProfileSettings.payloadSettingsDefault()
        self.settingsEditor = ProfileSettings.editorSettingsDefault()
        self.settingsView = ProfileSettings.viewSettingsDefault()

        super.init()

        // Shared Initializer
        self.initialize()
    }

    init(withSettings settings: [String: Any]) throws {

        self.settingsProfile = try ProfileSettings.profileSettings(forSettings: settings)
        self.settingsPayload = try ProfileSettings.payloadSettings(forSettings: settings)
        self.settingsEditor = try ProfileSettings.editorSettings(forSettings: settings)
        self.settingsView = try ProfileSettings.viewSettings(forSettings: settings)

        super.init()

        // Shared Initializer
        self.initialize()
    }

    init(withMobileconfig mobileconfig: [String: Any]) throws {

        self.settingsProfile = try ProfileSettings.profileSettings(forMobileconfig: mobileconfig)
        self.settingsEditor = try ProfileSettings.editorSettings(forMobileconfig: mobileconfig)

        var settingsPayload = [String: [String: [[String: Any]]]]()
        var settingsView = [String: [String: [[String: Any]]]]()
        try ProfileSettings.initialize(settings: &settingsPayload, viewSettings: &settingsView, forMobileconfig: mobileconfig, importErrors: &self.importErrors)

        self.settingsPayload = settingsPayload
        self.settingsView = settingsView

        // self.settingsPayload = try ProfileSettings.payloadSettings(forMobileconfig: mobileconfig, importErrors: &self.importErrors)
        // self.settingsView = try ProfileSettings.viewSettings(forMobileconfig: mobileconfig, payloadSettings: self.settingsPayload, importErrors: &self.importErrors)

        super.init()

        // Shared Initializer
        self.initialize()
    }

    // MARK: -
    // MARK: Initalization

    func initialize() {
        self.initializeEditorSettings()
        self.initializeObservers()
    }

    internal func initializeEditorSettings() {

        // Distribution
        // Distribution Method
        if let distributionMethodString = self.settingsEditor[PreferenceKey.distributionMethod] as? String {
            self.distributionMethodString = distributionMethodString
        } else { self.distributionMethodString = DistributionString.any }

        // Payload Keys
        // Disable Optional Keys
        if let disableOptionalKeys = self.settingsEditor[PreferenceKey.disableOptionalKeys] as? Bool {
            self.disableOptionalKeys = disableOptionalKeys
        } else { self.disableOptionalKeys = false }

        // Show User Approved Keys
        if let showUserApprovedKeys = self.settingsEditor[PreferenceKey.showUserApprovedKeys] as? Bool {
            self.showUserApprovedKeys = showUserApprovedKeys
        } else { self.showUserApprovedKeys = false }

        // Show Supervised Keys
        if let showSupervisedKeys = self.settingsEditor[PreferenceKey.showSupervisedKeys] as? Bool {
            self.showSupervisedKeys = showSupervisedKeys
        } else { self.showSupervisedKeys = false }

        // Show Customized Keys
        if let showCustomizedKeys = self.settingsEditor[PreferenceKey.showCustomizedKeys] as? Bool {
            self.showCustomizedKeys = showCustomizedKeys
        } else { self.showCustomizedKeys = false }

        // Show Disabled Keys
        if let showDisabledKeys = self.settingsEditor[PreferenceKey.showDisabledKeys] as? Bool {
            self.showDisabledKeys = showDisabledKeys
        } else { self.showDisabledKeys = false }

        // Show Hidden Keys
        if let showHiddenKeys = self.settingsEditor[PreferenceKey.showHiddenKeys] as? Bool {
            self.showHiddenKeys = showHiddenKeys
        } else { self.showHiddenKeys = false }

        // Platform
        // Platform iOS
        if let platformIOS = self.settingsEditor[PreferenceKey.platformIOS] as? Bool {
            self.platformIOS = platformIOS
        } else { self.platformIOS = true }

        // Platform macOS
        if let platformMacOS = self.settingsEditor[PreferenceKey.platformMacOS] as? Bool {
            self.platformMacOS = platformMacOS
        } else { self.platformMacOS = true }

        // Platform tvOS
        if let platformTvOS = self.settingsEditor[PreferenceKey.platformTvOS] as? Bool {
            self.platformTvOS = platformTvOS
        } else { self.platformTvOS = true }

        // Scope
        // Scope User
        if let scopeUser = self.settingsEditor[PreferenceKey.scopeUser] as? Bool {
            self.scopeUser = scopeUser
        } else { self.scopeUser = true }

        // Scope User Managed
        if let scopeUserManaged = self.settingsEditor[PreferenceKey.scopeUserManaged] as? Bool {
            self.scopeUserManaged = scopeUserManaged
        } else { self.scopeUserManaged = true }

        // Scope System
        if let scopeSystem = self.settingsEditor[PreferenceKey.scopeSystem] as? Bool {
            self.scopeSystem = scopeSystem
        } else { self.scopeSystem = true }

        // Scope System Managed
        if let scopeSystemManaged = self.settingsEditor[PreferenceKey.scopeSystemManaged] as? Bool {
            self.scopeSystemManaged = scopeSystemManaged
        } else { self.scopeSystemManaged = true }

        // Signing
        // Sign
        if let sign = self.settingsEditor[PreferenceKey.signProfile] as? Bool {
            self.sign = sign
        } else { self.sign = false }

        // Signing Certificate
        if let signingCertificate = self.settingsEditor[PreferenceKey.signingCertificate] as? Data {
            self.signingCertificate = signingCertificate
        } else { self.signingCertificate = nil }

        // Export
        if let payloadContentStyle = self.settingsEditor[PreferenceKey.payloadContentStyle] as? String {
            self.payloadContentStyle = payloadContentStyle
        } else { self.payloadContentStyle = PayloadContentStyle.profile }

        // Update OptionSets
        // Update Distribution Method
        self.updateDistributionMethod()

        // Update Platforms
        self.updatePlatforms()

        // Update Scope
        self.updateScope()
    }

    private func initializeObservers() {

        // Distribution Method
        self.addObserver(self, forKeyPath: self.distributionMethodStringSelector, options: .new, context: nil)

        // Platform
        self.addObserver(self, forKeyPath: self.platformIOSSelector, options: .new, context: nil)
        self.addObserver(self, forKeyPath: self.platformMacOSSelector, options: .new, context: nil)
        self.addObserver(self, forKeyPath: self.platformTvOSSelector, options: .new, context: nil)

        // Scope
        self.addObserver(self, forKeyPath: self.scopeUserSelector, options: .new, context: nil)
        self.addObserver(self, forKeyPath: self.scopeUserManagedSelector, options: .new, context: nil)
        self.addObserver(self, forKeyPath: self.scopeSystemSelector, options: .new, context: nil)
        self.addObserver(self, forKeyPath: self.scopeSystemManagedSelector, options: .new, context: nil)
    }

    // MARK: -
    // MARK: De-Initalization

    deinit {

        // Distribution Method
        self.removeObserver(self, forKeyPath: self.distributionMethodStringSelector, context: nil)

        // Platform
        self.removeObserver(self, forKeyPath: self.platformIOSSelector, context: nil)
        self.removeObserver(self, forKeyPath: self.platformMacOSSelector, context: nil)
        self.removeObserver(self, forKeyPath: self.platformTvOSSelector, context: nil)

        // Scope
        self.removeObserver(self, forKeyPath: self.scopeUserSelector, context: nil)
        self.removeObserver(self, forKeyPath: self.scopeUserManagedSelector, context: nil)
        self.removeObserver(self, forKeyPath: self.scopeSystemSelector, context: nil)
        self.removeObserver(self, forKeyPath: self.scopeSystemManagedSelector, context: nil)
    }

    // MARK: -
    // MARK: Key/Value Observing Functions

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath ?? "" {
        case self.distributionMethodStringSelector:
            self.updateDistributionMethod()

        case self.platformIOSSelector,
             self.platformMacOSSelector,
             self.platformTvOSSelector:
            self.updatePlatforms()

        case self.scopeUserSelector,
             self.scopeUserManagedSelector,
             self.scopeSystemSelector,
             self.scopeSystemManagedSelector:
            self.updateScope()

        default:
            Log.shared.error(message: "Unknown keyPath: \(keyPath ?? "")", category: String(describing: self))
        }
    }

    // MARK: -
    // MARK: Cache Functions

    func resetCache() {
        self.cachedEnabled = [String: [Int: Bool]]()
        self.cachedConditionals = [String: Any]()
        self.cachedPayloadContent = [String: [Int: [String: Any]]]()
    }

    func updatePayloadSelection(selected: Bool, payload: Payload) {

        // ---------------------------------------------------------------------
        //  Get the current domain settings or create an empty set if they doesn't exist
        // ---------------------------------------------------------------------
        var domainSettings = self.settings(forPayload: payload) ?? [[String: Any]]()

        // ---------------------------------------------------------------------
        //  Verify the domain has the required settings
        // ---------------------------------------------------------------------
        self.verifySettings(&domainSettings, forPayload: payload)

        // ---------------------------------------------------------------------
        //  Save the the changes to the current settings
        // ---------------------------------------------------------------------
        self.setSettings(domainSettings, forPayload: payload)

        // ---------------------------------------------------------------------
        //  Set the new value
        // ---------------------------------------------------------------------
        self.setPayloadEnabled(selected, payload: payload)
    }
}
