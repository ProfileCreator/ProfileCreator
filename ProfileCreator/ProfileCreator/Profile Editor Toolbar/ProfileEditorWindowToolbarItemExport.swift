//
//  ProfileEditorWindowToolbarItemExport.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ProfileEditorWindowToolbarItemExport: NSObject {

    // MARK: -
    // MARK: Variables

    var toolbarItem: NSToolbarItem?

    weak var profile: Profile?

    // Items for the `toolbarItemExport`
    let exportItemContextualMenu: NSMenu = {
        let menu = NSMenu(title: "")

        let menuExportProfile = NSMenuItem(title: "Export Profile", action: #selector(exportProfile), keyEquivalent: "")
        let menuExportPlist = NSMenuItem(title: "Export Plist", action: #selector(exportPlist), keyEquivalent: "")

        menu.items = [menuExportProfile, menuExportPlist]
        return menu
    }()

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(profile: Profile, editor: ProfileEditor) {
        super.init()

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.profile = profile

        // ---------------------------------------------------------------------
        //  Create the toolbar item
        // ---------------------------------------------------------------------
        let toolbarItem = NSMenuToolbarItem(itemIdentifier: .editorExport)
        toolbarItem.toolTip = NSLocalizedString("Export profile", comment: "")
        toolbarItem.image = NSImage(named: NSImage.shareTemplateName)
        toolbarItem.isBordered = true
        toolbarItem.target = self
        toolbarItem.action = #selector(exportProfile)
        toolbarItem.isEnabled = true

        self.exportItemContextualMenu.items.forEach { $0.target = self }
        toolbarItem.showsIndicator = true
        toolbarItem.menu = self.exportItemContextualMenu

        self.toolbarItem = toolbarItem
    }

    // MARK: -
    // MARK: Menu Actions
    @objc func exportPlist() {
        guard
            let profile = self.profile,
            let windowController = profile.windowControllers.first as? ProfileEditorWindowController,
            let window = windowController.window else { return }
        ProfileController.sharedInstance.exportPlist(profile: profile, promptWindow: window)
    }

    @objc func exportProfile() {
        guard
            let profile = self.profile,
            let windowController = profile.windowControllers.first as? ProfileEditorWindowController,
            let window = windowController.window else { return }
        ProfileController.sharedInstance.export(profile: profile, promptWindow: window)
    }
}
