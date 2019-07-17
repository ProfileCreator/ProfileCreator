//
//  PreferencesToolbarItemGeneral.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class PreferencesGeneral: PreferencesItem {

    // MARK: -
    // MARK: Variables

    let identifier: NSToolbarItem.Identifier = .preferencesGeneral
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
        self.toolbarItem.label = NSLocalizedString("General", comment: "")
        self.toolbarItem.paletteLabel = self.toolbarItem.label
        self.toolbarItem.toolTip = self.toolbarItem.label
        self.toolbarItem.target = sender
        self.toolbarItem.action = #selector(sender.toolbarItemSelected(_:))

        // ---------------------------------------------------------------------
        //  Create the preferences view
        // ---------------------------------------------------------------------
        self.view = PreferencesGeneralView()
    }
}

class PreferencesGeneralView: NSView, PreferencesView {

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

        self.translatesAutoresizingMaskIntoConstraints = false

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()
        var lastSubview: NSView?

        // ---------------------------------------------------------------------
        //  Add Preferences "Sidebar"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Sidebar", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: nil,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Profile Count", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.mainWindowShowProfileCount,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Group Icons", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.mainWindowShowGroupIcons,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add Preferences "Contact"
        // ---------------------------------------------------------------------
        /*
        lastSubview = addHeader(title: NSLocalizedString("Contact", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: lastSubview,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addTextFieldDescription(stringValue: "If you want to contact me, the button below will open a new email adressed to me.",
                                              toView: self,
                                              lastSubview: lastSubview,
                                              lastTextField: nil,
                                              height: &self.height,
                                              constraints: &constraints)

        lastSubview = addButton(label: nil,
                                title: "Contact",
                                bindToEnabled: nil,
                                bindKeyPathEnabled: nil,
                                target: self,
                                selector: #selector(self.contact(_:)),
                                toView: self,
                                lastSubview: lastSubview,
                                lastTextField: nil,
                                height: &self.height,
                                indent: kPreferencesIndent,
                                constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Add Preferences "Support ProfileCreator Development"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Support ProfileCreator Development", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: lastSubview,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addTextFieldDescription(stringValue: "If you appreciate ProfileCreator and want to support its continued development, please consider making a donation via PayPal. If you wish to donate any other way, please send me an email using the Contact button above and we'll figure it out.",
                                              toView: self,
                                              lastSubview: lastSubview,
                                              lastTextField: nil,
                                              height: &self.height,
                                              constraints: &constraints)

        lastSubview = addButton(label: nil,
                                title: "",
                                bindToEnabled: nil,
                                bindKeyPathEnabled: nil,
                                target: self,
                                selector: #selector(self.donate(_:)),
                                toView: self,
                                lastSubview: lastSubview,
                                lastTextField: nil,
                                height: &self.height,
                                indent: kPreferencesIndent,
                                constraints: &constraints)

        if let donateButton = lastSubview as? NSButton {

            let height = donateButton.intrinsicContentSize.height

            // Baseline
            constraints.append(NSLayoutConstraint(item: donateButton,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1,
                                                  constant: height * 2))

            donateButton.bezelStyle = .texturedRounded
            donateButton.setButtonType(.toggle)
            donateButton.isBordered = false
            donateButton.isTransparent = false
            donateButton.imagePosition = .imageOnly
            donateButton.imageScaling = .scaleProportionallyDown
            donateButton.image = NSImage(named: "donatePayPal_CardInfo")

            self.height += height
        }
*/
        /* FIXME: Currently unused
         // ---------------------------------------------------------------------
         //  Add Preferences "Application Updates"
         // ---------------------------------------------------------------------
         lastSubview = addHeader(title: NSLocalizedString("Application Updates", comment: ""),
         withSeparator: true,
         toView: self,
         lastSubview: lastSubview,
         height: &self.height,
         constraints: &constraints)
         
         lastSubview = addCheckbox(label: nil,
         title: NSLocalizedString("Automatically check for updates", comment: ""),
         bindTo: UserDefaults.standard,
         bindKeyPath: PreferenceKey.applicationAutomaticallyCheckForUpdates,
         toView: self,
         lastSubview: lastSubview,
         lastTextField: nil,
         height: &self.height,
         indent: kPreferencesIndent,
         constraints: &constraints)
         
         lastSubview = addCheckbox(label: nil,
         title: NSLocalizedString("Include pre-releases", comment: ""),
         bindTo: UserDefaults.standard,
         bindKeyPath: PreferenceKey.applicationUpdatesIncludePreReleases,
         toView: self,
         lastSubview: lastSubview,
         lastTextField: nil,
         height: &self.height,
         indent: kPreferencesIndent,
         constraints: &constraints)
         
         
         // ---------------------------------------------------------------------
         //  Add Preferences "Logging"
         // ---------------------------------------------------------------------
         lastSubview = addHeader(title: NSLocalizedString("Logging", comment: ""),
         withSeparator: true,
         toView: self,
         lastSubview: lastSubview,
         height: &self.height,
         constraints: &constraints)
         */
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

    @objc func donate(_ button: NSButton) {
        guard let donateURL = URL(string: "") else { return }
        NSWorkspace.shared.open(donateURL)
    }

    @objc func contact(_ button: NSButton) {
        guard let mainURL = URL(string: "") else { return }
        NSWorkspace.shared.open(mainURL)
    }
}
