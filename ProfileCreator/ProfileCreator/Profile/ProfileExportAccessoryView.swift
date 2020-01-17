//
//  ProfileExportAccessoryView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class ProfileExportAccessoryView: NSView {

    // MARK: -
    // MARK: Variables

    var popUpButtonScope: NSPopUpButton?
    var popUpButtonPlatform: NSPopUpButton?
    var popUpButtonPayloadContentStyle: NSPopUpButton?
    var popUpButtonCertificate: NSPopUpButton?
    var textFieldHeaderProfileSettings = NSTextField()
    var textFieldHeaderExportOptions = NSTextField()
    var textFieldHeaderMDMInformation = NSTextField()
    var boxMessage = NSBox()

    var enabledPayloads = [Payload]()
    var availableScope = Targets.all
    var availablePlatforms = Platforms.all

    // MARK: -
    // MARK: Weak Variables

    weak var profile: Profile?
    weak var exportSettings: ProfileSettings?

    // Update Profile
    @objc public var updateProfile: Bool = false
    public let updateProfileSelector: String

    // Description
    var originalDescription: String?
    @objc public dynamic var exportDescription: String = ""
    public let exportDescriptionSelector: String

    // Description Enabled
    var originalDescriptionEnabled: Bool = false
    @objc public dynamic var exportDescriptionEnabled: Bool = true
    public let exportDescriptionEnabledSelector: String

    // Organization
    var originalOrganization: String?
    @objc public dynamic var exportOrganization: String = ""
    public let exportOrganizationSelector: String

    // Organization Enabled
    var originalOrganizationEnabled = false
    @objc public dynamic var exportOrganizationEnabled: Bool = false
    public let exportOrganizationEnabledSelector: String

    // Scope String
    @objc public var exportScope: String = ""
    public let exportScopeSelector: String

    // Platform String
    @objc public var exportPlatform: String = ""
    public let exportPlatformSelector: String

    // Message Box

    // MARK: -
    // MARK: Initialization

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(profile: Profile, exportSettings: ProfileSettings) {

        // ---------------------------------------------------------------------
        //  Initialize Key/Value Observing Selector Strings
        // ---------------------------------------------------------------------
        self.updateProfileSelector = NSStringFromSelector(#selector(getter: self.updateProfile))
        self.exportDescriptionSelector = NSStringFromSelector(#selector(getter: self.exportDescription))
        self.exportDescriptionEnabledSelector = NSStringFromSelector(#selector(getter: self.exportDescriptionEnabled))
        self.exportOrganizationSelector = NSStringFromSelector(#selector(getter: self.exportOrganization))
        self.exportOrganizationEnabledSelector = NSStringFromSelector(#selector(getter: self.exportOrganizationEnabled))
        self.exportScopeSelector = NSStringFromSelector(#selector(getter: self.exportScope))
        self.exportPlatformSelector = NSStringFromSelector(#selector(getter: self.exportPlatform))

        // ---------------------------------------------------------------------
        //  Initialize Self
        // ---------------------------------------------------------------------
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.profile = profile
        self.exportSettings = exportSettings
        self.enabledPayloads = exportSettings.payloadsEnabled()

        self.setupAvailableScope(exportSettings: exportSettings)
        self.setupAvailablePlatforms(exportSettings: exportSettings)

        var constraints = [NSLayoutConstraint]()
        var frameHeight: CGFloat = 0.0
        let centerView = NSView()
        var lastSubview: NSView?
        var lastTextField: NSView?

        // ---------------------------------------------------------------------
        //  Add Preferences
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Profile Settings", comment: ""),
                                withSeparator: true,
                                textFieldTitle: self.textFieldHeaderProfileSettings,
                                toView: centerView,
                                lastSubview: lastSubview,
                                height: &frameHeight,
                                constraints: &constraints,
                                sender: self)

        lastSubview = addTextField(label: NSLocalizedString("Display Name:", comment: ""),
                                   placeholderValue: "",
                                   controlSize: .small,
                                   bindTo: exportSettings,
                                   keyPath: exportSettings.titleSelector,
                                   toView: centerView,
                                   lastSubview: lastSubview,
                                   lastTextField: nil,
                                   height: &frameHeight,
                                   constraints: &constraints)
        lastTextField = lastSubview

        // Add header text field to leading for the content text field
        constraints.append(NSLayoutConstraint(item: self.textFieldHeaderProfileSettings,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: lastTextField,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0.0))

        lastSubview = addTextField(label: NSLocalizedString("Description:", comment: ""),
                                   placeholderValue: "",
                                   controlSize: .small,
                                   bindTo: self,
                                   bindKeyPathCheckbox: self.exportDescriptionEnabledSelector,
                                   bindKeyPathTextField: self.exportDescriptionSelector,
                                   toView: centerView,
                                   lastSubview: lastSubview,
                                   lastTextField: lastTextField,
                                   height: &frameHeight,
                                   indent: kExportPreferencesIndent,
                                   constraints: &constraints)
        lastTextField = lastSubview

        lastSubview = addTextField(label: NSLocalizedString("Organization:", comment: ""),
                                   placeholderValue: "ProfileCreator",
                                   controlSize: .small,
                                   bindTo: self,
                                   bindKeyPathCheckbox: self.exportOrganizationEnabledSelector,
                                   bindKeyPathTextField: self.exportOrganizationSelector,
                                   toView: centerView,
                                   lastSubview: lastSubview,
                                   lastTextField: lastTextField,
                                   height: &frameHeight,
                                   indent: kExportPreferencesIndent,
                                   constraints: &constraints)
        lastTextField = lastSubview

        if let popUpButtonCertificate = addPopUpButtonCertificate(label: NSLocalizedString("Sign Profile", comment: ""),
                                                                  controlSize: .regular,
                                                                  bindTo: exportSettings,
                                                                  bindKeyPathCheckbox: exportSettings.signSelector,
                                                                  bindKeyPathPopUpButton: exportSettings.signingCertificateSelector,
                                                                  toView: centerView,
                                                                  lastSubview: lastSubview,
                                                                  lastTextField: lastTextField,
                                                                  height: &frameHeight,
                                                                  indent: kExportPreferencesIndent,
                                                                  constraints: &constraints) as? NSPopUpButton {
            self.popUpButtonCertificate = popUpButtonCertificate
            lastSubview = popUpButtonCertificate
        }

        if let popUpButtonPlatform = addPopUpButton(label: NSLocalizedString("Platform", comment: ""),
                                                    titles: PayloadUtility.strings(fromPlatforms: Platforms.all),
                                                    controlSize: .regular,
                                                    bindTo: self,
                                                    bindKeyPath: self.exportPlatformSelector,
                                                    toView: centerView,
                                                    lastSubview: lastSubview,
                                                    lastTextField: lastTextField,
                                                    height: &frameHeight,
                                                    indent: kExportPreferencesIndent,
                                                    constraints: &constraints) as? NSPopUpButton {
            self.popUpButtonPlatform = popUpButtonPlatform
            lastSubview = popUpButtonPlatform
        }

        if self.availablePlatforms.contains(.macOS) {
            if let popUpButtonScope = addPopUpButton(label: NSLocalizedString("Scope", comment: ""),
                                                     titles: PayloadUtility.strings(fromTargets: Targets.all),
                                                     controlSize: .regular,
                                                     bindTo: self,
                                                     bindKeyPath: self.exportScopeSelector,
                                                     toView: centerView,
                                                     lastSubview: lastSubview,
                                                     lastTextField: lastTextField,
                                                     height: &frameHeight,
                                                     indent: kExportPreferencesIndent,
                                                     constraints: &constraints) as? NSPopUpButton {
                self.popUpButtonScope = popUpButtonScope
                lastSubview = popUpButtonScope
            }
        } else {
            self.exportScope = TargetString.system.capitalized
        }

        if self.containsManagedPreferences(exportSettings: exportSettings) {
            if let popUpButtonPayloadContentStyle = addPopUpButton(label: NSLocalizedString("Payload Content Style", comment: ""),
                                                                   titles: [PayloadContentStyle.mcx, PayloadContentStyle.profile],
                                                                   controlSize: .regular,
                                                                   bindTo: exportSettings,
                                                                   bindKeyPath: exportSettings.payloadContentStyleSelector,
                                                                   toView: centerView,
                                                                   lastSubview: lastSubview,
                                                                   lastTextField: lastTextField,
                                                                   height: &frameHeight,
                                                                   indent: kExportPreferencesIndent,
                                                                   constraints: &constraints) as? NSPopUpButton {
                self.popUpButtonPayloadContentStyle = popUpButtonPayloadContentStyle
                lastSubview = popUpButtonPayloadContentStyle
            }
        }

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Save changes to profile", comment: ""),
                                  bindTo: self,
                                  bindKeyPath: self.updateProfileSelector,
                                  toView: centerView,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &frameHeight,
                                  indent: kExportPreferencesIndent,
                                  constraints: &constraints)
        /*
         lastSubview = addHeader(title: NSLocalizedString("MDM Information", comment: ""),
         withSeparator: false,
         textFieldTitle: self.textFieldHeaderMDMInformation,
         toView: centerView,
         lastSubview: lastSubview,
         height: &frameHeight,
         constraints: &constraints,
         sender: self)
         
         // Add header text field to leading for the content text field
         constraints.append(NSLayoutConstraint(item: self.textFieldHeaderMDMInformation,
         attribute: .leading,
         relatedBy: .equal,
         toItem: lastTextField,
         attribute: .leading,
         multiplier: 1,
         constant: 0.0))
         */

        if let box = addBox(title: "",
                            toView: centerView,
                            lastSubview: lastSubview,
                            lastTextField: lastTextField,
                            height: &frameHeight,
                            indent: kExportPreferencesIndent,
                            constraints: &constraints) {
            lastSubview = box

            if let boxText = addHeader(title: NSLocalizedString("If you plan to import the exported profile into Jamf, consider signing the profile to avoid having Jamf modify it during upload.", comment: ""),
                                       withSeparator: false,
                                       toView: box,
                                       lastSubview: nil,
                                       height: &frameHeight,
                                       constraints: &constraints) as? NSTextField {

                boxText.lineBreakMode = .byWordWrapping
                boxText.preferredMaxLayoutWidth = kExportPreferencesViewWidth - (kExportPreferencesIndent + 20.0)

                // ---------------------------------------------------------------------
                //  Add constraints to last view
                // ---------------------------------------------------------------------
                // Bottom
                constraints.append(NSLayoutConstraint(item: box,
                                                      attribute: .bottom,
                                                      relatedBy: .equal,
                                                      toItem: boxText,
                                                      attribute: .bottom,
                                                      multiplier: 1,
                                                      constant: 8.0))
            }
        }

        // ---------------------------------------------------------------------
        //  Add constraints to last view
        // ---------------------------------------------------------------------
        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: lastSubview,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 12.0))

        // Width
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 685.0))

        // ---------------------------------------------------------------------
        //  Add subviews to accessory view
        // ---------------------------------------------------------------------
        self.setup(centerView: centerView, constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Set default selections
        // ---------------------------------------------------------------------
        self.setupExportDescription(exportSettings: exportSettings)
        self.setupExportOrganization(exportSettings: exportSettings)
        self.setupPopUpButtonScopeSelection(exportSettings: exportSettings)
        self.setupPlatformSelection(exportSettings: exportSettings)
        self.setupSigningCertificate(exportSettings: exportSettings)

        // ---------------------------------------------------------------------
        //  Activate layout constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        // Height
        NSLayoutConstraint.activate([NSLayoutConstraint(item: self,
                                                        attribute: .height,
                                                        relatedBy: .equal,
                                                        toItem: nil,
                                                        attribute: .notAnAttribute,
                                                        multiplier: 1,
                                                        constant: self.fittingSize.height)])
    }

    func containsManagedPreferences(exportSettings: ProfileSettings) -> Bool {
        return self.enabledPayloads.contains { $0.type == .managedPreferencesApple || $0.type == .managedPreferencesApplications || $0.type == .managedPreferencesApplicationsLocal }
    }
}

// MARK: -
// MARK: Update Accessory View

extension ProfileExportAccessoryView {

    // MARK: -
    // MARK: NSTextField Description

    func setupExportDescription(exportSettings: ProfileSettings) {
        if let profilePayloadDescription = exportSettings.value(forValueKeyPath: PayloadKey.payloadDescription,
                                                                domainIdentifier: kManifestDomainConfiguration,
                                                                payloadType: .manifestsApple,
                                                                payloadIndex: 0) as? String {
            self.originalDescription = profilePayloadDescription
            self.setValue(profilePayloadDescription, forKeyPath: self.exportDescriptionSelector)
        }

        if let profilePayloadSubkey = ProfilePayloads.shared.payloadSubkey(forKeyPath: PayloadKey.payloadDescription,
                                                                           domainIdentifier: kManifestDomainConfiguration,
                                                                           type: .manifestsApple) {
            self.setValue(exportSettings.isEnabled(profilePayloadSubkey,
                                                   onlyByUser: false,
                                                   ignoreConditionals: false,
                                                   payloadIndex: 0),
                          forKeyPath: self.exportDescriptionEnabledSelector)
            self.originalDescriptionEnabled = self.exportDescriptionEnabled
        } else {
            Log.shared.error(message: "Failed to get subkey at keyPath: \(PayloadKey.payloadDescription) for domain: \(kManifestDomainConfiguration) of type: \(PayloadType.manifestsApple)", category: String(describing: self))
        }

        guard self.originalDescription != nil, let originalDescription = self.originalDescription, !originalDescription.isEmpty else {
            self.setValue(false, forKey: self.exportDescriptionEnabledSelector)
            return
        }
    }

    // MARK: -
    // MARK: NSTextField Organization

    func setupExportOrganization(exportSettings: ProfileSettings) {
        if let profilePayloadOrganization = exportSettings.value(forValueKeyPath: PayloadKey.payloadOrganization,
                                                                 domainIdentifier: kManifestDomainConfiguration,
                                                                 payloadType: .manifestsApple,
                                                                 payloadIndex: 0) as? String {
            self.originalOrganization = profilePayloadOrganization
            self.setValue(profilePayloadOrganization, forKeyPath: self.exportOrganizationSelector)
        }

        if let profilePayloadSubkey = ProfilePayloads.shared.payloadSubkey(forKeyPath: PayloadKey.payloadOrganization,
                                                                           domainIdentifier: kManifestDomainConfiguration,
                                                                           type: .manifestsApple) {
            self.setValue(exportSettings.isEnabled(profilePayloadSubkey,
                                                   onlyByUser: false,
                                                   ignoreConditionals: false,
                                                   payloadIndex: 0),
                          forKeyPath: self.exportOrganizationEnabledSelector)
            self.originalOrganizationEnabled = self.exportOrganizationEnabled
        } else {
            Log.shared.error(message: "Failed to get subkey at keyPath: \(PayloadKey.payloadOrganization) for domain: \(kManifestDomainConfiguration) of type: \(PayloadType.manifestsApple)", category: String(describing: self))
        }
    }

    // MARK: -
    // MARK: PopUpButton Scope

    func setupAvailableScope(exportSettings: ProfileSettings) {
        var newScope = Targets.all
        self.enabledPayloads.forEach { newScope.formIntersection($0.targets) }

        if newScope == Targets.none {
            // FIXME: Correct Error
            //        Also show user error. This should be checked when creating the profile
            Log.shared.error(message: "No platforms available, this should never happen here. Fail with error", category: String(describing: self))
        }

        self.availableScope = newScope
    }

    func setupPopUpButtonScopeSelection(exportSettings: ProfileSettings) {
        if let popUpButtonScope = self.popUpButtonScope {

            popUpButtonScope.autoenablesItems = false

            // FIXME: Have to remember to capitalize the strings, that seems dangerous and easy to forget. Possibly change the input strings.

            for item in popUpButtonScope.itemArray {
                switch item.title {
                case TargetString.system.capitalized:
                    item.isEnabled = self.availableScope.contains(.system)
                case TargetString.systemManaged.capitalized:
                    item.isEnabled = self.availableScope.contains(.systemManaged)
                case TargetString.user.capitalized:
                    item.isEnabled = self.availableScope.contains(.user)
                case TargetString.userManaged.capitalized:
                    item.isEnabled = self.availableScope.contains(.userManaged)
                default:
                    if !item.title.isEmpty {
                        Log.shared.error(message: "Unknown scope item title: \(item.title)", category: String(describing: self))
                    }
                }
            }

            if
                let profileScopeString = exportSettings.value(forValueKeyPath: PayloadKey.payloadScope,
                                                              domainIdentifier: kManifestDomainConfiguration,
                                                              payloadType: .manifestsApple,
                                                              payloadIndex: 0) as? String,
                let profileScope = Targets(string: profileScopeString),
                !self.availableScope.isDisjoint(with: profileScope) {

                self.setValue(profileScopeString.capitalized, forKeyPath: self.exportScopeSelector)
            } else if self.availableScope.contains(.user) {

                self.setValue(TargetString.user.capitalized, forKeyPath: self.exportScopeSelector)
            } else if let firstTitle = popUpButtonScope.itemArray.first(where: { $0.isEnabled })?.title {

                self.setValue(firstTitle, forKeyPath: self.exportScopeSelector)
            }
        }
    }

    // MARK: -
    // MARK: PopUpButton Platform

    func setupAvailablePlatforms(exportSettings: ProfileSettings) {
        var newPlatform = Platforms.all
        self.enabledPayloads.forEach { newPlatform.formIntersection($0.platforms) }

        if newPlatform == Platforms.none {
            // FIXME: Correct Error
            //        Also show user error. This should be checked when creating the profile
            Log.shared.error(message: "No platforms available, this should never happen here. Fail with error", category: String(describing: self))
        }

        self.availablePlatforms = newPlatform
    }

    func setupPlatformSelection(exportSettings: ProfileSettings) {
        if let popUpButtonPlatform = self.popUpButtonPlatform {

            popUpButtonPlatform.autoenablesItems = false

            for item in popUpButtonPlatform.itemArray {
                switch item.title {
                case PlatformString.iOS:
                    item.isEnabled = self.availablePlatforms.contains(.iOS)
                case PlatformString.macOS:
                    item.isEnabled = self.availablePlatforms.contains(.macOS)
                case PlatformString.tvOS:
                    item.isEnabled = self.availablePlatforms.contains(.tvOS)
                default:
                    if !item.title.isEmpty {
                        Log.shared.error(message: "Unknown platform item title: \(item.title)", category: String(describing: self))
                    }
                }
            }

            if self.availablePlatforms.contains(.macOS) {
                self.setValue(PlatformString.macOS, forKeyPath: self.exportPlatformSelector)
            } else if let firstTitle = popUpButtonPlatform.itemArray.first(where: { $0.isEnabled })?.title {
                self.setValue(firstTitle, forKeyPath: self.exportPlatformSelector)
            }
        }
    }

    func setupSigningCertificate(exportSettings: ProfileSettings) {
        if exportSettings.sign == true, exportSettings.signingCertificate == nil {
            exportSettings.setValue(false, forKey: exportSettings.signSelector)
        }
    }
}

// MARK: -
// MARK: Update Profile Settings

extension ProfileExportAccessoryView {
    func updateProfileSettings() -> Bool {
        guard
            let exportSettings = self.exportSettings,
            let profile = self.profile else {
                Log.shared.error(message: "Failed to get export settings or profile to export", category: String(describing: self))
                return false
        }

        var updatedProfile = false

        if exportSettings.sign && exportSettings.signingCertificate == nil {
            if let signingCertificate = self.popUpButtonCertificate?.selectedItem?.representedObject as? Data {
                exportSettings.signingCertificate = signingCertificate
            } else {
                Log.shared.error(message: "Failed to get selected signing certificate.", category: "")
                if let window = self.window {
                    Alert().showAlert(message: NSLocalizedString("No signing certificate selected", comment: ""),
                                      informativeText: NSLocalizedString("You have selected to sign the profile but no signing certificate was found. Please select a valid signing certificate and try exporting again.", comment: ""),
                                      window: window,
                                      firstButtonTitle: ButtonTitle.ok,
                                      secondButtonTitle: nil,
                                      thirdButtonTitle: nil,
                                      firstButtonState: true,
                                      sender: nil) { _ in }
                }
                return false
            }
        }

        if self.updateProfile {

            // Sign
            if exportSettings.sign != profile.settings.sign {
                profile.settings.setValue(exportSettings.sign, forKeyPath: profile.settings.signSelector)
                updatedProfile = true
            }

            // Signing Certificate
            if exportSettings.sign, exportSettings.signingCertificate != profile.settings.signingCertificate {
                profile.settings.setValue(exportSettings.signingCertificate, forKeyPath: profile.settings.signingCertificateSelector)
                updatedProfile = true
            }
        }

        // Title
        if profile.settings.title != exportSettings.title {
            exportSettings.setValue(exportSettings.title, forValueKeyPath: PayloadKey.payloadDisplayName, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
            if self.updateProfile {
                profile.settings.setValue(exportSettings.title, forValueKeyPath: PayloadKey.payloadDisplayName, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
                updatedProfile = true
            }
        }

        // Description
        if self.exportDescriptionEnabled != self.originalDescriptionEnabled {
            exportSettings.setViewValue(enabled: self.exportDescriptionEnabled, forKeyPath: PayloadKey.payloadDescription, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
            if self.updateProfile {
                profile.settings.setViewValue(enabled: self.exportDescriptionEnabled, forKeyPath: PayloadKey.payloadDescription, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
                updatedProfile = true
            }
        }

        if self.exportDescriptionEnabled {
            exportSettings.setValue(self.exportDescription, forValueKeyPath: PayloadKey.payloadDescription, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
            if self.updateProfile, let oDescription = self.originalDescription, oDescription != self.exportDescription {
                profile.settings.setValue(self.exportDescription, forValueKeyPath: PayloadKey.payloadDescription, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
                updatedProfile = true
            }
        }

        // Organization
        if self.exportOrganizationEnabled != self.originalOrganizationEnabled {
            exportSettings.setViewValue(enabled: self.exportOrganizationEnabled, forKeyPath: PayloadKey.payloadOrganization, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
            if self.updateProfile {
                profile.settings.setViewValue(enabled: self.exportOrganizationEnabled, forKeyPath: PayloadKey.payloadOrganization, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
                updatedProfile = true
            }
        }

        if self.exportOrganizationEnabled {
            exportSettings.setValue(self.exportOrganization, forValueKeyPath: PayloadKey.payloadOrganization, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
            if self.updateProfile, let oOrganization = self.originalOrganization, oOrganization != self.exportOrganization {
                profile.settings.setValue(self.exportOrganization, forValueKeyPath: PayloadKey.payloadOrganization, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
                updatedProfile = true
            }
        }

        // Scope
        exportSettings.setValue(self.exportScope, forValueKeyPath: PayloadKey.payloadScope, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
        exportSettings.setViewValue(enabled: true, forKeyPath: PayloadKey.payloadScope, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
        if self.updateProfile {
            profile.settings.setValue(self.exportScope, forValueKeyPath: PayloadKey.payloadScope, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
            profile.settings.setViewValue(enabled: true, forKeyPath: PayloadKey.payloadScope, domainIdentifier: kManifestDomainConfiguration, payloadType: .manifestsApple, payloadIndex: 0)
            updatedProfile = true
        }

        if self.updateProfile, updatedProfile {
            profile.save(self)
        }

        return true
    }
}

extension ProfileExportAccessoryView {
    func setup(centerView: NSView, constraints: inout [NSLayoutConstraint]) {

        centerView.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(centerView)

        // Width
        constraints.append(NSLayoutConstraint(item: centerView,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: kExportPreferencesViewWidth))

        // Center X
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: centerView,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0.0))

        // Top
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: centerView,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 0.0))

        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: centerView,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 0.0))
    }
}

extension ProfileExportAccessoryView: NSOpenSavePanelDelegate {
    func panel(_ sender: Any, userEnteredFilename filename: String, confirmed okFlag: Bool) -> String? {

        if self.updateProfileSettings() {
            return filename
        } else {
            // Return nil to not leave the save panel
            return nil
        }
    }
}
