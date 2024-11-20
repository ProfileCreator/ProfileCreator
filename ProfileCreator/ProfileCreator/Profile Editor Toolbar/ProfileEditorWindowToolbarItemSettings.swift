//
//  MainWindowToolbarItemExport.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ProfileEditorWindowToolbarItemSettings: NSObject {

    // MARK: -
    // MARK: Variables

    weak var profile: Profile?
    weak var profileEditorSettings: ProfileEditorSettings?

    var toolbarItem: NSToolbarItem?

    // MARK: -
    // MARK: Initialization
    init(profile: Profile, profileEditorSettings: ProfileEditorSettings) {
        super.init()

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.profile = profile
        self.profileEditorSettings = profileEditorSettings
        self.toolbarItem = NSToolbarItem(itemIdentifier: .editorSettings)

        // ---------------------------------------------------------------------
        //  Create the actual toolbar item
        // ---------------------------------------------------------------------
        let toolbarItem = NSToolbarItem(itemIdentifier: .editorSettings)
        toolbarItem.toolTip = NSLocalizedString("Settings", comment: "")
        toolbarItem.image = NSImage(named: NSImage.actionTemplateName)
        toolbarItem.isBordered = true
        toolbarItem.target = self
        toolbarItem.action = #selector(settingsClicked)
        toolbarItem.isEnabled = false

        self.toolbarItem = toolbarItem
    }

    @objc func settingsClicked() {
        if let profileEditorSettings = self.profileEditorSettings {
            guard let toolbarItem = self.toolbarItem else { return }

            if #available(macOS 14.0, *) {
                profileEditorSettings.popOver.show(relativeTo: toolbarItem)
            } else {
                guard let itemViewer = toolbarItem.value(forKey: "_itemViewer") as? NSView else {
                      return
                }

                profileEditorSettings.popOver.show(relativeTo: itemViewer.bounds, of: itemViewer, preferredEdge: .minY)
            }
        }
    }
}
