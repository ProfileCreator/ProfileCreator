//
//  PreferencesPayloads.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PreferencesAdvanced: PreferencesItem {

    // MARK: -
    // MARK: Variables

    let identifier: NSToolbarItem.Identifier = .preferencesAdvanced
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
        self.toolbarItem.label = NSLocalizedString("Advanced", comment: "")
        self.toolbarItem.paletteLabel = self.toolbarItem.label
        self.toolbarItem.toolTip = self.toolbarItem.label
        self.toolbarItem.target = sender
        self.toolbarItem.action = #selector(sender.toolbarItemSelected(_:))

        // ---------------------------------------------------------------------
        //  Create the preferences view
        // ---------------------------------------------------------------------
        self.view = PreferencesAdvancedView()
    }
}

class PreferencesAdvancedView: NSView, PreferencesView {

    // MARK: -
    // MARK: Variables

    var height: CGFloat = 0.0
    var buttonCheckForUpdates: NSButton?

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
        //  Add Preferences "Payload Manifests"
        // ---------------------------------------------------------------------
        lastSubview = addHeader(title: NSLocalizedString("Developer", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: nil,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addCheckbox(label: nil,
                                  title: NSLocalizedString("Show Developer menu in menu bar", comment: ""),
                                  bindTo: UserDefaults.standard,
                                  bindKeyPath: PreferenceKey.showDeveloperMenu,
                                  toView: self,
                                  lastSubview: lastSubview,
                                  lastTextField: nil,
                                  height: &self.height,
                                  indent: kPreferencesIndent,
                                  constraints: &constraints)
        (lastSubview as? NSButton)?.target = self
        (lastSubview as? NSButton)?.action = #selector(self.showDeveloperMenu(_:))

        lastSubview = addHeader(title: NSLocalizedString("Payload Identifier", comment: ""),
                                withSeparator: true,
                                toView: self,
                                lastSubview: lastSubview,
                                height: &self.height,
                                constraints: &constraints)

        lastSubview = addTextField(label: NSLocalizedString("ProfileIdentifier Format", comment: ""),
                                   placeholderValue: StringConstant.profileIdentifierFormat,
                                   bindTo: UserDefaults.standard,
                                   keyPath: PreferenceKey.defaultProfileIdentifierFormat,
                                   toView: self,
                                   lastSubview: lastSubview,
                                   lastTextField: nil,
                                   height: &self.height,
                                   constraints: &constraints)
        lastTextField = lastSubview

        lastSubview = addTextField(label: NSLocalizedString("PayloadIdentifier Format", comment: ""),
                                   placeholderValue: StringConstant.payloadIdentifierFormat,
                                   bindTo: UserDefaults.standard,
                                   keyPath: PreferenceKey.defaultPayloadIdentifierFormat,
                                   toView: self,
                                   lastSubview: lastSubview,
                                   lastTextField: lastTextField,
                                   height: &self.height,
                                   constraints: &constraints)
        lastTextField = lastSubview

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

    @objc func showDeveloperMenu(_ button: NSButton) {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.showMenuDeveloper(button.state == .on ? true : false)
    }
}
