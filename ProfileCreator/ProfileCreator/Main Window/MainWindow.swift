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
    var toolbarItemAdd: MainWindowToolbarItemAdd?
    var toolbarItemExport: MainWindowToolbarItemExport?
    var toolbarItemTitle: MainWindowToolbarItemTitle?

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
        self.toolbar.sizeMode = .regular
        self.toolbar.displayMode = .iconOnly
        self.toolbar.delegate = self

        // ---------------------------------------------------------------------
        // Add toolbar to window
        // ---------------------------------------------------------------------
        self.window?.toolbar = self.toolbar
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
                self.toolbarItemAdd = MainWindowToolbarItemAdd()
            }

            if let toolbarView = self.toolbarItemAdd {
                return toolbarView.toolbarItem
            }
        case .mainWindowExport:
            if self.toolbarItemExport == nil {
                self.toolbarItemExport = MainWindowToolbarItemExport()
            }

            if let toolbarView = self.toolbarItemExport {
                return toolbarView.toolbarItem
            }
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
}
