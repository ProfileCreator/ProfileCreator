//
//  PreferencesViewProfileDefaults.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PreferencesProfileDefaults: PreferencesItem {

    // MARK: -
    // MARK: Variables

    let identifier: NSToolbarItem.Identifier = .preferencesProfileDefaults
    let toolbarItem: NSToolbarItem
    let view: PreferencesView

    // MARK: -
    // MARK: Initialization

    init(sender: PreferencesWindowController) {

        // ---------------------------------------------------------------------
        //  Create the toolbar item
        // ---------------------------------------------------------------------
        self.toolbarItem = NSToolbarItem(itemIdentifier: identifier)
        self.toolbarItem.image = NSImage(named: NSImage.preferencesGeneralName)
        self.toolbarItem.label = NSLocalizedString("Profile Defaults", comment: "")
        self.toolbarItem.paletteLabel = self.toolbarItem.label
        self.toolbarItem.toolTip = self.toolbarItem.label
        self.toolbarItem.target = sender
        self.toolbarItem.action = #selector(sender.toolbarItemSelected(_:))

        // ---------------------------------------------------------------------
        //  Create the preferences view
        // ---------------------------------------------------------------------
        self.view = PreferencesProfileDefaultsView()
    }
}

class PreferencesProfileDefaultsView: NSView, PreferencesView {

    // MARK: -
    // MARK: Variables

    var height: CGFloat = 0.0

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()
        var lastSubview: NSView?
        var lastTextField: NSView?

        // ---------------------------------------------------------------------
        //  Add Preferences "Default Profile Settings"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Default Profile Settings", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: nil,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addTextField(label: NSLocalizedString("Organization Name", comment: ""),
                                   placeholderValue: "ProfileCreator",
                                   bindTo: UserDefaults.standard,
                                   keyPath: PreferenceKey.defaultOrganization,
                                   toView: self,
                                   lastSubview: lastSubview,
                                   lastTextField: nil,
                                   height: &self.height,
                                   constraints: &constraints)
        lastTextField = lastSubview

        lastSubview = addTextField(label: NSLocalizedString("Organization Identifier", comment: ""),
                                   placeholderValue: StringConstant.domain,
                                   bindTo: UserDefaults.standard,
                                   keyPath: PreferenceKey.defaultOrganizationIdentifier,
                                   toView: self,
                                   lastSubview: lastSubview,
                                   lastTextField: lastTextField,
                                   height: &self.height,
                                   constraints: &constraints)
        lastTextField = lastSubview

        lastSubview = addCheckbox(label: NSLocalizedString("Disable Optional Keys", comment: ""),
                                  title: "",
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.disableOptionalKeys,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addPopUpButton(label: NSLocalizedString("Distribution", comment: ""),
                                     titles: [DistributionString.any, DistributionString.manual, DistributionString.push],
                                     bindTo: UserDefaults.standard,
                                     bindKeyPath: PreferenceKey.distributionMethod,
                                     toView: self,
                                     lastSubview: lastSubview,
                                     lastTextField: lastTextField,
                                     height: &self.height,
                                     indent: kPreferencesIndent,
                                     constraints: &constraints)

        lastSubview = addPopUpButtonCertificate(label: NSLocalizedString("Sign Profile", comment: ""),
                                                controlSize: .regular,
                                                bindTo: UserDefaults.standard,
                                                bindKeyPathCheckbox: PreferenceKey.signProfile,
                                                bindKeyPathPopUpButton: PreferenceKey.signingCertificate,
                                                toView: self,
                                                lastSubview: lastSubview,
                                                lastTextField: lastTextField,
                                                height: &self.height,
                                                indent: kPreferencesIndent,
                                                constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Include Certificates from System Keychain", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.signingCertificateSearchSystemKeychain,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Untrusted Certificates", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.signingCertificateShowUntrusted,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Expired Certificates", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.signingCertificateShowExpired,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add Preferences "Managed Preferences Profile Settings"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Default Managed Preferences Settings", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: lastSubview,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addPopUpButton(label: NSLocalizedString("PayloadContent Style", comment: ""),
                                     titles: [PayloadContentStyle.mcx, PayloadContentStyle.profile],
                                     bindTo: UserDefaults.standard,
                                     bindKeyPath: PreferenceKey.payloadContentStyle,
                                     toView: self,
                                     lastSubview: lastSubview,
                                     lastTextField: lastTextField,
                                     height: &self.height,
                                     indent: kPreferencesIndent,
                                     constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add Preferences "Default Profile Display Settings"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Default Profile Display Settings", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: lastSubview,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addCheckbox(label: NSLocalizedString("Show Payload Keys", comment: ""),
                                  title: NSLocalizedString("Hidden", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.showHiddenKeys,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Customized", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.showCustomizedKeys,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Disabled", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.showDisabledKeys,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Supervised", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.showSupervisedKeys,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("User Approved", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.showUserApprovedKeys,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: NSLocalizedString("Show Platform", comment: ""),
                                  title: PlatformString.iOS,
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.platformIOS,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: PlatformString.macOS,
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.platformMacOS,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: PlatformString.tvOS,
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.platformTvOS,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: NSLocalizedString("Show Scope", comment: ""),
                                  title: NSLocalizedString("User", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.scopeUser,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("System", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.scopeSystem,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add constraints to last view
        // ---------------------------------------------------------------------
        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .greaterThanOrEqual,
                                              toItem: lastSubview,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 20))

        self.height += 20.0

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }
}
