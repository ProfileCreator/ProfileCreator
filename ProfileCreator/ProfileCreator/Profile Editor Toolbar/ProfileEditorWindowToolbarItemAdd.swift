//
//  MainWindowToolbarItems.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class ProfileEditorWindowToolbarItemAdd: NSObject {

    // MARK: -
    // MARK: Variables

    weak var profile: Profile?
    weak var profileEditor: ProfileEditor?

    var selectedPayloadPlaceholder: PayloadPlaceholder?
    var toolbarItem: NSToolbarItem?

    // Items for the `toolbarItemAdd`
    let addItemContextualMenu: NSMenu = {
        let menu = NSMenu(title: "")

        let menuAddPayload = NSMenuItem(title: "Add Payload", action: #selector(addPayload), keyEquivalent: "")
        let menuAddPayloadKey = NSMenuItem(title: "Add Payload Key", action: #selector(addPayloadKey), keyEquivalent: "")

        menu.items = [menuAddPayload, menuAddPayloadKey]
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
        self.profileEditor = editor

        // ---------------------------------------------------------------------
        //  Create the actual toolbar item
        // ---------------------------------------------------------------------
        let toolbarItem = NSMenuToolbarItem(itemIdentifier: .editorAdd)
        toolbarItem.toolTip = NSLocalizedString("Add payloads", comment: "")
        toolbarItem.image = NSImage(named: NSImage.addTemplateName)
        toolbarItem.isBordered = true
        toolbarItem.target = self
        toolbarItem.action = #selector(addPayload)
        toolbarItem.isEnabled = false

        // TODO: Fix adding payload keys
        toolbarItem.showsIndicator = false
        // self.addItemContextualMenu.items.forEach { $0.target = self }
        // toolbarItem.showsIndicator = true
        // toolbarItem.menu = self.addItemContextualMenu

        self.toolbarItem = toolbarItem

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        self.profileEditor?.addObserver(self, forKeyPath: editor.selectedPayloadPlaceholderUpdatedSelector, options: .new, context: nil)
    }

    deinit {
        if let editor = self.profileEditor {
            editor.removeObserver(self, forKeyPath: editor.selectedPayloadPlaceholderUpdatedSelector, context: nil)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let editor = self.profileEditor else { return }
        if keyPath == editor.selectedPayloadPlaceholderUpdatedSelector {
            self.selectedPayloadPlaceholder = editor.selectedPayloadPlaceholder
        } else {
            Log.shared.error(message: "ERROR", category: String(describing: self))
        }

        self.toolbarItem?.isEnabled = !(self.selectedPayloadPlaceholder?.payload.unique ?? false)
    }

    @objc func addPayload() {
        if
            let selectedPayloadPlaceholder = self.selectedPayloadPlaceholder,
            !selectedPayloadPlaceholder.payload.unique {
            self.profileEditor?.addTab(addSettings: true)
        }
    }

    @objc func addPayloadKey() {
        if
            let selectedPayloadPlaceholder = self.selectedPayloadPlaceholder {
            self.profileEditor?.addKey(forPayloadPlaceholder: selectedPayloadPlaceholder)
        }
    }
}
