//
//  MainWindowToolbarItems.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class MainWindowToolbarItemAdd: NSView {

    // MARK: -
    // MARK: Variables

    let toolbarItem: NSToolbarItem
    let disclosureTriangle: NSImageView

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {

        // ---------------------------------------------------------------------
        //  Create the size of the toolbar item
        // ---------------------------------------------------------------------
        let rect = NSRect(x: 0, y: 0, width: 40, height: 32)

        // ---------------------------------------------------------------------
        //  Create the actual toolbar item
        // ---------------------------------------------------------------------
        self.toolbarItem = NSToolbarItem(itemIdentifier: .mainWindowAdd)
        self.toolbarItem.toolTip = NSLocalizedString("Add profile or library group", comment: "")

        // ---------------------------------------------------------------------
        //  Create the disclosure triangle overlay
        // ---------------------------------------------------------------------
        self.disclosureTriangle = NSImageView()
        self.disclosureTriangle.translatesAutoresizingMaskIntoConstraints = false
        self.disclosureTriangle.image = NSImage(named: "ArrowDown")
        self.disclosureTriangle.imageScaling = .scaleProportionallyUpOrDown
        self.disclosureTriangle.isHidden = true

        // ---------------------------------------------------------------------
        //  Initialize self after the class variables have been instantiated
        // ---------------------------------------------------------------------
        super.init(frame: rect)

        // ---------------------------------------------------------------------
        //  Add the button to the toolbar item view
        // ---------------------------------------------------------------------
        self.addSubview(MainWindowToolbarItemAddButton(frame: rect))

        // ---------------------------------------------------------------------
        //  Add disclosure triangle to the toolbar item view
        // ---------------------------------------------------------------------
        self.addSubview(self.disclosureTriangle)

        // ---------------------------------------------------------------------
        //  Setup the disclosure triangle constraints
        // ---------------------------------------------------------------------
        addConstraintsForDisclosureTriangle()

        // ---------------------------------------------------------------------
        //  Set the toolbar item view
        // ---------------------------------------------------------------------
        self.toolbarItem.view = self
    }

    func disclosureTriangle(show: Bool) {
        self.disclosureTriangle.isHidden = !show
    }

    func addConstraintsForDisclosureTriangle() {
        var constraints = [NSLayoutConstraint]()

        // Width
        constraints.append(NSLayoutConstraint(item: self.disclosureTriangle,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 9))

        // Height == Width
        constraints.append(NSLayoutConstraint(item: self.disclosureTriangle,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: self.disclosureTriangle,
                                              attribute: .width,
                                              multiplier: 1,
                                              constant: 0))

        // Bottom
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self.disclosureTriangle,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 6))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.disclosureTriangle,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 3))

        NSLayoutConstraint.activate(constraints)
    }
}

class MainWindowToolbarItemAddButton: NSButton {

    // MARK: -
    // MARK: Variables

    let buttonMenu = NSMenu()
    let menuDelay = 0.2

    var trackingArea: NSTrackingArea?
    var mouseIsDown = false
    var menuWasShownForLastMouseDown = false
    var mouseDownUniquenessCounter = 0

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        // ---------------------------------------------------------------------
        //  Setup Self (Toolbar Item)
        // ---------------------------------------------------------------------
        self.bezelStyle = .texturedRounded
        self.image = NSImage(named: NSImage.addTemplateName)
        self.target = self
        self.action = #selector(self.clicked(button:))
        self.imageScaling = .scaleProportionallyDown
        self.imagePosition = .imageOnly

        // ---------------------------------------------------------------------
        //  Setup the button menu
        // ---------------------------------------------------------------------
        setupButtonMenu()
    }

    func setupButtonMenu() {
        self.buttonMenu.delegate = self

        // ---------------------------------------------------------------------
        //  Add item: "New Profile"
        // ---------------------------------------------------------------------
        let menuItemNewProfile = NSMenuItem()
        menuItemNewProfile.title = NSLocalizedString("New Profile", comment: "")
        menuItemNewProfile.isEnabled = true
        menuItemNewProfile.target = self
        menuItemNewProfile.action = #selector(newProfile(menuItem:))
        self.buttonMenu.addItem(menuItemNewProfile)

        // ---------------------------------------------------------------------
        //  Add item: "New Group"
        // ---------------------------------------------------------------------
        let menuItemNewGroup = NSMenuItem()
        menuItemNewGroup.title = NSLocalizedString("New Group", comment: "")
        menuItemNewGroup.isEnabled = true
        menuItemNewGroup.target = self
        menuItemNewGroup.action = #selector(newGroup(menuItem:))
        self.buttonMenu.addItem(menuItemNewGroup)

        // ---------------------------------------------------------------------
        //  Add item: "New Group JSS"
        // ---------------------------------------------------------------------
        /* Not available yet
         let menuItemNewGroupJSS = NSMenuItem()
         menuItemNewGroupJSS.title = NSLocalizedString("New Group JSS", comment: "")
         menuItemNewGroupJSS.isEnabled = true
         menuItemNewGroupJSS.target = self
         menuItemNewGroupJSS.action = #selector(newGroupJSS(menuItem:))
         self.buttonMenu.addItem(menuItemNewGroupJSS)
         */
    }

    // MARK: -
    // MARK: Button/Menu Actions

    @objc func clicked(button: NSButton) {

        // ---------------------------------------------------------------------
        //  If only button was clicked, call 'newProfile'
        // ---------------------------------------------------------------------
        self.newProfile(menuItem: nil)
    }

    @objc func newProfile(menuItem: NSMenuItem?) {
        NotificationCenter.default.post(name: .newProfile, object: self, userInfo: [NotificationKey.parentTitle: SidebarGroupTitle.library])
    }

    @objc func newGroup(menuItem: NSMenuItem?) {
        NotificationCenter.default.post(name: .addGroup, object: self, userInfo: [NotificationKey.parentTitle: SidebarGroupTitle.library])
    }

    @objc func newGroupJSS(menuItem: NSMenuItem?) {
        NotificationCenter.default.post(name: .addGroup, object: self, userInfo: [NotificationKey.parentTitle: SidebarGroupTitle.jamf])
    }

    // MARK: -
    // MARK: NSControl/NSResponder Methods

    override func mouseEntered(with event: NSEvent) {
        if let parent = self.superview, let toolbarItemAdd = parent as? MainWindowToolbarItemAdd {
            toolbarItemAdd.disclosureTriangle(show: true)
        }
    }

    override func mouseExited(with event: NSEvent) {
        if !self.mouseIsDown {
            if let parent = self.superview, let toolbarItemAdd = parent as? MainWindowToolbarItemAdd {
                toolbarItemAdd.disclosureTriangle(show: false)
            }
        }
    }

    override func mouseDown(with event: NSEvent) {

        // ---------------------------------------------------------------------
        //  Reset mouse variables
        // ---------------------------------------------------------------------
        self.mouseIsDown = true
        self.menuWasShownForLastMouseDown = false
        self.mouseDownUniquenessCounter += 1
        let mouseDownUniquenessCounterCopy = self.mouseDownUniquenessCounter

        // ---------------------------------------------------------------------
        //  Show the button is being pressed
        // ---------------------------------------------------------------------
        self.highlight(true)

        // ---------------------------------------------------------------------
        //  Wait 'menuDelay' before showing the context menu
        //  If button has been released before time runs out, it's considered a normal button press
        // ---------------------------------------------------------------------
        DispatchQueue.main.asyncAfter(deadline: .now() + self.menuDelay) {
            if self.mouseIsDown && mouseDownUniquenessCounterCopy == self.mouseDownUniquenessCounter {
                self.menuWasShownForLastMouseDown = true
                guard let menuOrigin = self.superview?.convert(NSPoint(x: self.frame.origin.x + self.frame.size.width - 16,
                                                                       y: self.frame.origin.y + 2), to: nil) else {
                                                                        return
                }

                guard let event = NSEvent.mouseEvent(with: event.type,
                                                     location: menuOrigin,
                                                     modifierFlags: event.modifierFlags,
                                                     timestamp: event.timestamp,
                                                     windowNumber: event.windowNumber,
                                                     context: nil,
                                                     eventNumber: event.eventNumber,
                                                     clickCount: event.clickCount,
                                                     pressure: event.pressure) else {
                                                        return
                }

                NSMenu.popUpContextMenu(self.buttonMenu, with: event, for: self)
            }
        }
    }

    override func mouseUp(with event: NSEvent) {

        // ---------------------------------------------------------------------
        //  Reset mouse variables
        // ---------------------------------------------------------------------
        self.mouseIsDown = false

        if !self.menuWasShownForLastMouseDown {
            if let parent = self.superview, let toolbarItemAdd = parent as? MainWindowToolbarItemAdd {
                toolbarItemAdd.disclosureTriangle(show: false)
            }

            self.sendAction(self.action, to: self.target)
        }

        // ---------------------------------------------------------------------
        //  Hide the button is being pressed
        // ---------------------------------------------------------------------
        self.highlight(false)
    }

    // MARK: -
    // MARK: NSView Methods

    override func updateTrackingAreas() {

        // ---------------------------------------------------------------------
        //  Remove previous tracking area if it was set
        // ---------------------------------------------------------------------
        if let trackingArea = self.trackingArea {
            self.removeTrackingArea(trackingArea)
        }

        // ---------------------------------------------------------------------
        //  Create a new tracking area
        // ---------------------------------------------------------------------
        let trackingOptions = NSTrackingArea.Options(rawValue: (NSTrackingArea.Options.mouseEnteredAndExited.rawValue | NSTrackingArea.Options.activeAlways.rawValue))
        self.trackingArea = NSTrackingArea(rect: self.bounds, options: trackingOptions, owner: self, userInfo: nil)

        // ---------------------------------------------------------------------
        //  Add the new tracking area to the button
        // ---------------------------------------------------------------------
        self.addTrackingArea(self.trackingArea!)
    }
}

// MARK: -
// MARK: NSMenuDelegate

extension MainWindowToolbarItemAddButton: NSMenuDelegate {

    func menuDidClose(_ menu: NSMenu) {

        // ---------------------------------------------------------------------
        //  Reset mouse variables
        // ---------------------------------------------------------------------
        self.mouseIsDown = false
        self.menuWasShownForLastMouseDown = false
        self.mouseDownUniquenessCounter = 0

        // ---------------------------------------------------------------------
        //  Turn of highlighting and disclosure triangle when the menu closes
        // ---------------------------------------------------------------------
        self.highlight(false)
        if let parent = self.superview, let toolbarItemAdd = parent as? MainWindowToolbarItemAdd {
            toolbarItemAdd.disclosureTriangle(show: false)
        }
    }
}
