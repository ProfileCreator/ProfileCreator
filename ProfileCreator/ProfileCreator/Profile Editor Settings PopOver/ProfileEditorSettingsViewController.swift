//
//  ProfileEditorSettingsPopOver.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class ProfileEditorSettingsViewController: NSViewController {

    // MARK: -
    // MARK: Variables

    weak var profile: Profile?
    weak var editorSettings: ProfileEditorSettings?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: -
    // MARK: NSViewController Overrides

    override func loadView() {
        if let profile = self.profile {
            self.view = ProfileEditorSettingsView(profile: profile)
        } else { self.view = NSView() }
    }
}

class ProfileEditorSettingsView: NSView {

    // MARK: -
    // MARK: Variables

    weak var profile: Profile?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(profile: Profile) {
        super.init(frame: NSRect.zero)

        self.translatesAutoresizingMaskIntoConstraints = false

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.profile = profile
        var constraints = [NSLayoutConstraint]()
        var frameHeight: CGFloat = 0.0
        var lastSubview: NSView?
        var lastTextField: NSView?

        // ---------------------------------------------------------------------
        //  Add Preferences "Profile Settings"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: "Profile Settings",
                                withSeparator: true,
                                toView: self,
                                lastSubview: nil,
                                height: &frameHeight,
                                constraints: &constraints)

        lastSubview = addCheckbox(label: "Disable Optional Keys",
                                  title: "",
                                  bindTo: profile.settings,
                                  bindKeyPath: profile.settings.disableOptionalKeysSelector,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &frameHeight,
                                  indent: kEditorPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addPopUpButton(label: "Distribution",
                                     titles: [DistributionString.any, DistributionString.manual, DistributionString.push],
                                     bindTo: profile.settings,
                                     bindKeyPath: profile.settings.distributionMethodStringSelector,
                                     toView: self,
                                     lastSubview: lastSubview,
                                     lastTextField: lastSubview,
                                     height: &frameHeight,
                                     indent: kEditorPreferencesIndent,
                                     constraints: &constraints)
        lastTextField = lastSubview

        lastSubview = addPopUpButtonCertificate(label: "Sign Profile",
                                                bindTo: profile.settings,
                                                bindKeyPathCheckbox: profile.settings.signSelector,
                                                bindKeyPathPopUpButton: profile.settings.signingCertificateSelector,
                                                toView: self,
                                                lastSubview: lastSubview,
                                                lastTextField: lastTextField,
                                                height: &frameHeight,
                                                indent: kEditorPreferencesIndent,
                                                constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add Preferences "Managed Preferences Profile Settings"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: "Managed Preferences Settings",
                                withSeparator: true,
                                toView: self,
                                lastSubview: lastSubview,
                                height: &frameHeight,
                                constraints: &constraints)

        lastSubview = addPopUpButton(label: "PayloadContent Style",
                                     titles: [PayloadContentStyle.mcx, PayloadContentStyle.profile],
                                     bindTo: profile.settings,
                                     bindKeyPath: profile.settings.payloadContentStyleSelector,
                                     toView: self,
                                     lastSubview: lastSubview,
                                     lastTextField: lastTextField,
                                     height: &frameHeight,
                                     indent: kEditorPreferencesIndent,
                                     constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add Preferences "Profile Display Settings"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: "Profile Display Settings",
                                withSeparator: true,
                                toView: self,
                                lastSubview: lastSubview,
                                height: &frameHeight,
                                constraints: &constraints)

        lastSubview = addCheckbox(label: "Show Payload Keys",
                                  title: "Hidden",
                                  bindTo: profile.settings,
                                  bindKeyPath: profile.settings.showHiddenKeysSelector,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastTextField,
                                  height: &frameHeight,
                                  indent: kEditorPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: "Customized",
                                  bindTo: profile.settings,
                                  bindKeyPath: profile.settings.showCustomizedKeysSelector,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastSubview,
                                  height: &frameHeight,
                                  indent: kEditorPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: "Disabled",
                                  bindTo: profile.settings,
                                  bindKeyPath: profile.settings.showDisabledKeysSelector,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastSubview,
                                  height: &frameHeight,
                                  indent: kEditorPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: "Supervised",
                                  bindTo: profile.settings,
                                  bindKeyPath: profile.settings.showSupervisedKeysSelector,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastSubview,
                                  height: &frameHeight,
                                  indent: kEditorPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: "User Approved",
                                  bindTo: profile.settings,
                                  bindKeyPath: profile.settings.showUserApprovedKeysSelector,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastSubview,
                                  height: &frameHeight,
                                  indent: kEditorPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: "Show Platform",
                                  title: "iOS",
                                  bindTo: profile.settings,
                                  bindKeyPath: profile.settings.platformIOSSelector,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastSubview,
                                  height: &frameHeight,
                                  indent: kEditorPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: "macOS",
                                  bindTo: profile.settings,
                                  bindKeyPath: profile.settings.platformMacOSSelector,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastSubview,
                                  height: &frameHeight,
                                  indent: kEditorPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: "tvOS",
                                  bindTo: profile.settings,
                                  bindKeyPath: profile.settings.platformTvOSSelector,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastSubview,
                                  height: &frameHeight,
                                  indent: kEditorPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: "Show Scope",
                                  title: "User",
                                  bindTo: profile.settings,
                                  bindKeyPath: profile.settings.scopeUserSelector,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastSubview,
                                  height: &frameHeight,
                                  indent: kEditorPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: "System",
                                  bindTo: profile.settings,
                                  bindKeyPath: profile.settings.scopeSystemSelector,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: lastSubview,
                                  height: &frameHeight,
                                  indent: kEditorPreferencesIndent,
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

        frameHeight += 20.0

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        // ---------------------------------------------------------------------
        //  Set the view frame for use when switching between preference views
        // ---------------------------------------------------------------------
        self.frame = NSRect(x: 0.0, y: 0.0, width: kEditorPreferencesWindowWidth, height: frameHeight)
    }
}
