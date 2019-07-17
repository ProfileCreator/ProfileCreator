//
//  PreferencesToolbarItemMDM.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class PreferencesMDM: PreferencesItem {

    // MARK: -
    // MARK: Variables

    let identifier: NSToolbarItem.Identifier = .preferencesMDM
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
        self.toolbarItem.label = NSLocalizedString("MDM", comment: "")
        self.toolbarItem.paletteLabel = self.toolbarItem.label
        self.toolbarItem.toolTip = self.toolbarItem.label
        self.toolbarItem.target = sender
        self.toolbarItem.action = #selector(sender.toolbarItemSelected(_:))

        // ---------------------------------------------------------------------
        //  Create the preferences view
        // ---------------------------------------------------------------------
        self.view = PreferencesMDMView()
    }
}

class PreferencesMDMView: NSView, PreferencesView {

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

        lastSubview = addTextFieldDescription(stringValue: "MDM",
                                              toView: self,
                                              lastSubview: lastSubview,
                                              lastTextField: nil,
                                              height: &self.height,
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
