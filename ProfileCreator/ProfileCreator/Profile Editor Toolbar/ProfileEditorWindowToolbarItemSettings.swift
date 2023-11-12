//
//  MainWindowToolbarItemExport.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ProfileEditorWindowToolbarItemSettings: NSView {

    // MARK: -
    // MARK: Variables

    public weak var profile: Profile?
    public weak var profileEditorSettings: ProfileEditorSettings?

    let toolbarItem: NSToolbarItem

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(profile: Profile, profileEditorSettings: ProfileEditorSettings) {

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.profile = profile
        self.profileEditorSettings = profileEditorSettings

        // ---------------------------------------------------------------------
        //  Create the size of the toolbar item
        // ---------------------------------------------------------------------
        let rect = NSRect(x: 0, y: -5, width: 40, height: 32)

        // ---------------------------------------------------------------------
        //  Create the actual toolbar item
        // ---------------------------------------------------------------------
        self.toolbarItem = NSToolbarItem(itemIdentifier: .editorSettings)
        self.toolbarItem.toolTip = NSLocalizedString("Settings", comment: "")

        // ---------------------------------------------------------------------
        //  Initialize self after the class variables have been instantiated
        // ---------------------------------------------------------------------
        super.init(frame: rect)

        // ---------------------------------------------------------------------
        //  Create the button instance and add it to the toolbar item view
        // ---------------------------------------------------------------------
        self.addSubview(ProfileEditorWindowToolbarItemSettingsButton(frame: rect, profileEditorSettings: profileEditorSettings))

        // ---------------------------------------------------------------------
        //  Set the toolbar item view
        // ---------------------------------------------------------------------
        self.toolbarItem.view = self
    }
}

class ProfileEditorWindowToolbarItemSettingsButton: NSButton {

    // MARK: -
    // MARK: Variables

    public weak var profileEditorSettings: ProfileEditorSettings?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame frameRect: NSRect, profileEditorSettings: ProfileEditorSettings) {
        super.init(frame: frameRect)

        self.profileEditorSettings = profileEditorSettings

        // ---------------------------------------------------------------------
        //  Setup Self (Toolbar Item)
        // ---------------------------------------------------------------------
        self.bezelStyle = .texturedRounded
        self.image = NSImage(named: NSImage.actionTemplateName)
        self.target = self
        self.action = #selector(self.clicked(button:))
        self.imageScaling = .scaleProportionallyDown
        self.imagePosition = .imageOnly
    }

    // MARK: -
    // MARK: Button/Menu Actions

    @objc func clicked(button: NSButton) {
        if let profileEditorSettings = self.profileEditorSettings {
            profileEditorSettings.profileWindow = self.window
            profileEditorSettings.popOver.show(relativeTo: self.bounds, of: self, preferredEdge: .maxY)
        }
    }
}
