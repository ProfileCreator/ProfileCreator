//
//  MainWindowController.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

    // MARK: -
    // MARK: Variables

    let splitView = MainWindowSplitView(frame: NSRect.zero)

    let toolbar = NSToolbar(identifier: "MainWindowToolbar")
    let toolbarItemIdentifiers: [NSToolbarItem.Identifier] = [.mainWindowAdd,
                                                              .mainWindowExport,
                                                              NSToolbarItem.Identifier.flexibleSpace,
                                                              .mainWindowTitle]
    var toolbarItemAdd: NSMenuToolbarItem?
    var toolbarItemExport: NSMenuToolbarItem?
    var toolbarItemTitle: MainWindowToolbarItemTitle?

    // Items for the `toolbarItemAdd`
    let addItemContextualMenu: NSMenu = {
        let menu = NSMenu(title: "")

        let menuNewProfile = NSMenuItem(title: "New Payload", action: #selector(newProfile), keyEquivalent: "")
        let menuNewGroup = NSMenuItem(title: "New Group", action: #selector(newGroup), keyEquivalent: "")

        menu.items = [menuNewProfile, menuNewGroup]
        return menu
    }()

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

    init() {

        // ---------------------------------------------------------------------
        //  Setup main window
        // ---------------------------------------------------------------------
        let rect = NSRect(x: 0, y: 0, width: 750, height: 550)
        let styleMask = NSWindow.StyleMask(rawValue: (
            NSWindow.StyleMask.fullSizeContentView.rawValue |
                NSWindow.StyleMask.titled.rawValue |
                NSWindow.StyleMask.unifiedTitleAndToolbar.rawValue |
                NSWindow.StyleMask.closable.rawValue |
                NSWindow.StyleMask.miniaturizable.rawValue |
                NSWindow.StyleMask.resizable.rawValue
        ))
        let window = NSWindow(contentRect: rect, styleMask: styleMask, backing: NSWindow.BackingStoreType.buffered, defer: false)
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.isRestorable = true
        window.identifier = NSUserInterfaceItemIdentifier(rawValue: "ProfileCreatorMainWindow-ID")
        window.setFrameAutosaveName("ProfileCreatorMainWindow-AS")
        window.contentMinSize = NSSize(width: 600, height: 400)
        window.toolbarStyle = .unifiedCompact
        window.center()

        // ---------------------------------------------------------------------
        //  Add splitview as window content view
        // ---------------------------------------------------------------------
        window.contentView = self.splitView

        // ---------------------------------------------------------------------
        //  Initialize self after the class variables have been instantiated
        // ---------------------------------------------------------------------
        super.init(window: window)

        // ---------------------------------------------------------------------
        //  Setup toolbar
        // ---------------------------------------------------------------------
        self.toolbar.isVisible = true
        self.toolbar.showsBaselineSeparator = true
        self.toolbar.allowsUserCustomization = false
        self.toolbar.autosavesConfiguration = false
        self.toolbar.displayMode = .iconOnly
        self.toolbar.delegate = self

        // ---------------------------------------------------------------------
        // Add toolbar to window
        // ---------------------------------------------------------------------
        self.window?.toolbar = self.toolbar

        // ---------------------------------------------------------------------
        // Setup Notification Observers
        // ---------------------------------------------------------------------
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeProfileSelection(_:)), name: .didChangeProfileSelection, object: nil)
    }
}

// MARK: -
// MARK: NSToolbarDelegate

extension MainWindowController: NSToolbarDelegate {

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        self.toolbarItemIdentifiers
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        self.toolbarItemIdentifiers
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if let toolbarItem = toolbarItem(identifier: itemIdentifier) {
            return toolbarItem
        }
        return nil
    }

    func toolbarItem(identifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        switch identifier {
        case .mainWindowAdd:
            if self.toolbarItemAdd == nil {
                let toolbarItem = NSMenuToolbarItem(itemIdentifier: .mainWindowAdd)
                toolbarItem.showsIndicator = true
                toolbarItem.isBordered = true
                toolbarItem.target = self
                toolbarItem.action = #selector(newProfile)
                toolbarItem.menu = self.addItemContextualMenu
                toolbarItem.image = NSImage(named: NSImage.addTemplateName)

                self.toolbarItemAdd = toolbarItem
            }

            return self.toolbarItemAdd

        case .mainWindowExport:
            if self.toolbarItemExport == nil {
                let toolbarItem = NSMenuToolbarItem(itemIdentifier: .mainWindowExport)

                toolbarItem.showsIndicator = true
                toolbarItem.isBordered = true
                toolbarItem.target = self
                toolbarItem.action = #selector(exportProfile)
                toolbarItem.menu = self.exportItemContextualMenu
                toolbarItem.image = NSImage(named: NSImage.shareTemplateName)
                toolbarItem.isEnabled = false

                self.toolbarItemExport = toolbarItem
            }

            return self.toolbarItemExport
        case .mainWindowTitle:
            if self.toolbarItemTitle == nil {
                self.toolbarItemTitle = MainWindowToolbarItemTitle()
            }

            if let toolbarView = self.toolbarItemTitle {
                return toolbarView.toolbarItem
            }
        default:
            Log.shared.error(message: "Unknown NSToolbarItem.Identifier: \(identifier)", category: String(describing: self))
        }
        return nil
    }

    // MARK: -
    // MARK: `toolbarAddItem` actions
    @objc func newProfile() {
        NotificationCenter.default.post(name: .newProfile, object: self, userInfo: [NotificationKey.parentTitle: SidebarGroupTitle.library])
    }

    @objc func newGroup() {
        NotificationCenter.default.post(name: .addGroup, object: self, userInfo: [NotificationKey.parentTitle: SidebarGroupTitle.library])
    }

    @objc func newGroupJSS() {
        NotificationCenter.default.post(name: .addGroup, object: self, userInfo: [NotificationKey.parentTitle: SidebarGroupTitle.jamf])
    }

    // MARK: -
    // MARK: `toolbarExportItem` actions
    @objc func exportPlist() {
        guard let mainWindowController = self.window?.windowController as? MainWindowController else { return }
        let mainWindowTableViewController = mainWindowController.splitView.tableViewController
        if let identifiers = mainWindowTableViewController.profileIdentifiers(atIndexes: mainWindowTableViewController.tableView.selectedRowIndexes) {
            ProfileController.sharedInstance.exportPlists(withIdentifiers: identifiers, promptWindow: mainWindowController.window)
        }
    }

    @objc func exportProfile() {
        guard let mainWindowController = self.window?.windowController as? MainWindowController else { return }
        let mainWindowTableViewController = mainWindowController.splitView.tableViewController
        if let identifiers = mainWindowTableViewController.profileIdentifiers(atIndexes: mainWindowTableViewController.tableView.selectedRowIndexes) {
            ProfileController.sharedInstance.exportProfiles(withIdentifiers: identifiers, promptWindow: mainWindowController.window)
        }
    }

    // MARK: -
    // MARK: Observers
    @objc func didChangeProfileSelection(_ notification: NSNotification?) {
        if let selectedIndexes = notification?.userInfo?[NotificationKey.indexSet] as? IndexSet, selectedIndexes.count == 1 {
            self.toolbarItemExport?.isEnabled = true
        } else {
            self.toolbarItemExport?.isEnabled = false
        }
    }
}
