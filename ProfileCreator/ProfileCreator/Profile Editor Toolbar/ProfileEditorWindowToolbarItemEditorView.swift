//
//  MainWindowToolbarItemExport.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ProfileEditorWindowToolbarItemView: NSObject {

    // MARK: -
    // MARK: Variables

    weak var profile: Profile?
    weak var profileEditor: ProfileEditor?

    var toolbarItem: NSToolbarItem?

    let toolBarPickerImages: [NSImage?] = [NSImage(systemSymbolName: "list.bullet", accessibilityDescription: nil), NSImage(systemSymbolName: "terminal", accessibilityDescription: nil)]

    // MARK: -
    // MARK: Initialization

    init(profile: Profile, profileEditor: ProfileEditor) {
        super.init()

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.profile = profile
        self.profileEditor = profileEditor

        // ---------------------------------------------------------------------
        //  Create the actual toolbar item
        // ---------------------------------------------------------------------

        // Strip optionals (there should be none)
        let images = self.toolBarPickerImages.compactMap { $0 }

        let toolbarItem = NSToolbarItemGroup(itemIdentifier: .editorView, images: images, selectionMode: .selectOne, labels: nil, target: self, action: #selector(self.toolbarPickerDidSelectItem(_:)))
        toolbarItem.controlRepresentation = .automatic
        toolbarItem.label = "View"
        toolbarItem.toolTip = NSLocalizedString("View", comment: "")
        toolbarItem.selectedIndex = 0
        toolbarItem.isEnabled = true

        self.toolbarItem = toolbarItem
    }

    @objc func toolbarPickerDidSelectItem(_ sender: Any) {
        if let profileEditor = self.profileEditor, let toolbarItem = self.toolbarItem as? NSToolbarItemGroup {
            if toolbarItem.selectedIndex == 0 {
                profileEditor.select(view: EditorViewTag.profileCreator.rawValue)
            } else if toolbarItem.selectedIndex == 1 {
                profileEditor.select(view: EditorViewTag.source.rawValue)
            }
        }
    }
}
