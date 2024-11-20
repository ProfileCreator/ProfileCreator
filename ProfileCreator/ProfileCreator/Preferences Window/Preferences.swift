//
//  Preferences.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

protocol PreferencesItem: AnyObject {
    var identifier: NSToolbarItem.Identifier { get }
    var toolbarItem: NSToolbarItem { get }
    var view: PreferencesView { get }
}

protocol PreferencesView: AnyObject {
    var height: CGFloat { get }
}

class PreferencesWindowController: NSWindowController {

    // MARK: -
    // MARK: Variables

    let toolbar = NSToolbar(identifier: "PreferencesWindowToolbar")
    let toolbarItemIdentifiers: [NSToolbarItem.Identifier] = [.preferencesGeneral,
                                                              .preferencesLibrary,
                                                              .preferencesEditor,
                                                              .preferencesProfileDefaults,
                                                              .preferencesPayloads,
                                                              // .preferencesMDM,
                                                              .preferencesAdvanced,
                                                              NSToolbarItem.Identifier.flexibleSpace]

    var preferencesGeneral: PreferencesGeneral?
    var preferencesEditor: PreferencesEditor?
    var preferencesLibrary: PreferencesLibrary?
    var preferencesMDM: PreferencesMDM?
    var preferencesProfileDefaults: PreferencesProfileDefaults?
    var preferencesPayloads: PreferencesPayloads?
    var preferencesAdvanced: PreferencesAdvanced?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {

        // ---------------------------------------------------------------------
        //  Setup preferences window
        // ---------------------------------------------------------------------
        let rect = NSRect(x: 0, y: 0, width: kPreferencesWindowWidth, height: 200)
        let styleMask = NSWindow.StyleMask(rawValue: (
            NSWindow.StyleMask.titled.rawValue |
                NSWindow.StyleMask.closable.rawValue |
                NSWindow.StyleMask.miniaturizable.rawValue
        ))
        let window = NSWindow(contentRect: rect,
                              styleMask: styleMask,
                              backing: NSWindow.BackingStoreType.buffered,
                              defer: false)
        window.isReleasedWhenClosed = false
        window.isRestorable = true
        window.center()

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
        self.toolbar.displayMode = .iconAndLabel
        self.toolbar.delegate = self

        // ---------------------------------------------------------------------
        // Add toolbar to window
        // ---------------------------------------------------------------------
        self.window?.toolbar = self.toolbar

        // ---------------------------------------------------------------------
        // Show "General" Preferences
        // ---------------------------------------------------------------------
        self.showPreferencesView(identifier: .preferencesGeneral)
    }

    // MARK: -
    // MARK: Public Functions

    @objc public func toolbarItemSelected(_ toolbarItem: NSToolbarItem) {
        self.showPreferencesView(identifier: toolbarItem.itemIdentifier)
    }

    // MARK: -
    // MARK: Private Functions

    private func showPreferencesView(identifier: NSToolbarItem.Identifier) {
        if let window = self.window, let preferencesItem = preferencesItem(identifier: identifier) {

            // -----------------------------------------------------------------
            //  Update window title
            // -----------------------------------------------------------------
            window.title = preferencesItem.toolbarItem.label

            // -----------------------------------------------------------------
            //  Remove current view and animate the transition to the new view
            // -----------------------------------------------------------------
            if let windowContentView = window.contentView {
                windowContentView.removeFromSuperview()

                // -----------------------------------------------------------------
                //  Get new view height and current window frame
                // -----------------------------------------------------------------
                let viewFrameHeight = preferencesItem.view.height
                var windowFrame = window.frame

                // -----------------------------------------------------------------
                //  Calculate new frame size
                // -----------------------------------------------------------------
                windowFrame.origin.y += (windowContentView.frame.size.height - viewFrameHeight)
                windowFrame.size.height = ((windowFrame.size.height - windowContentView.frame.size.height) + viewFrameHeight)

                // -----------------------------------------------------------------
                //  Update window frame with animation
                // -----------------------------------------------------------------
                window.setFrame(windowFrame, display: true, animate: true)
            }

            // -----------------------------------------------------------------
            //  Add then new view
            // -----------------------------------------------------------------
            // FIXME: view is already nsview, should fix this
            if let view = preferencesItem.view as? NSView {
                window.contentView = view
            }

            // -----------------------------------------------------------------
            //  Add constraint to set window width
            // -----------------------------------------------------------------
            NSLayoutConstraint.activate([NSLayoutConstraint(item: window.contentView ?? preferencesItem.view,
                                                            attribute: .width,
                                                            relatedBy: .equal,
                                                            toItem: nil,
                                                            attribute: .notAnAttribute,
                                                            multiplier: 1.0,
                                                            constant: kPreferencesWindowWidth) ])
        }
    }

    private func preferencesItem(identifier: NSToolbarItem.Identifier) -> PreferencesItem? {
        switch identifier {
        case .preferencesGeneral:
            if self.preferencesGeneral == nil { self.preferencesGeneral = PreferencesGeneral(sender: self) }
            return self.preferencesGeneral
        case .preferencesLibrary:
            if self.preferencesLibrary == nil { self.preferencesLibrary = PreferencesLibrary(sender: self) }
            return self.preferencesLibrary
        case .preferencesMDM:
            if self.preferencesMDM == nil { self.preferencesMDM = PreferencesMDM(sender: self) }
            return self.preferencesMDM
        case .preferencesEditor:
            if self.preferencesEditor == nil { self.preferencesEditor = PreferencesEditor(sender: self) }
            return self.preferencesEditor
        case .preferencesProfileDefaults:
            if self.preferencesProfileDefaults == nil { self.preferencesProfileDefaults = PreferencesProfileDefaults(sender: self) }
            return self.preferencesProfileDefaults
        case .preferencesPayloads:
            if self.preferencesPayloads == nil { self.preferencesPayloads = PreferencesPayloads(sender: self) }
            return self.preferencesPayloads
        case .preferencesAdvanced:
            if self.preferencesAdvanced == nil { self.preferencesAdvanced = PreferencesAdvanced(sender: self) }
            return self.preferencesAdvanced
        default:
            return nil
        }
    }
}

// MARK: -
// MARK: NSToolbarDelegate

extension PreferencesWindowController: NSToolbarDelegate {

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        self.toolbarItemIdentifiers
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        self.toolbarItemIdentifiers
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if let preferencesItem = preferencesItem(identifier: itemIdentifier) {
            return preferencesItem.toolbarItem
        }
        return nil
    }
}
