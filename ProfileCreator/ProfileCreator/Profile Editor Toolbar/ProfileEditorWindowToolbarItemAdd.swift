//
//  MainWindowToolbarItems.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class ProfileEditorWindowToolbarItemAdd: NSView {

    // MARK: -
    // MARK: Variables

    public weak var profile: Profile?

    let textFieldTitle = NSTextField()

    let toolbarItem: NSToolbarItem
    let disclosureTriangle: NSImageView

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(profile: Profile, editor: ProfileEditor) {

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.profile = profile

        // ---------------------------------------------------------------------
        //  Create the size of the toolbar item
        // ---------------------------------------------------------------------
        let rect = NSRect(x: 0, y: 0, width: 40, height: 32)

        // ---------------------------------------------------------------------
        //  Create the actual toolbar item
        // ---------------------------------------------------------------------
        self.toolbarItem = NSToolbarItem(itemIdentifier: .editorAdd)
        self.toolbarItem.toolTip = NSLocalizedString("Add payloads or keys", comment: "")
        self.toolbarItem.minSize = rect.size
        self.toolbarItem.maxSize = rect.size

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
        self.addSubview(ProfileEditorWindowToolbarItemAddButton(frame: rect, editor: editor))

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

class ProfileEditorWindowToolbarItemAddButton: NSButton {

    // MARK: -
    // MARK: Variables

    let buttonMenu = NSMenu()
    let menuDelay = 0.2

    var trackingArea: NSTrackingArea?
    var mouseIsDown = false
    var menuWasShownForLastMouseDown = false
    var mouseDownUniquenessCounter = 0

    weak var profileEditor: ProfileEditor?
    var selectedPayloadPlaceholder: PayloadPlaceholder?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame frameRect: NSRect, editor: ProfileEditor) {

        self.profileEditor = editor
        self.selectedPayloadPlaceholder = editor.selectedPayloadPlaceholder

        super.init(frame: frameRect)

        // ---------------------------------------------------------------------
        //  Setup Notification Observers
        // ---------------------------------------------------------------------
        editor.addObserver(self, forKeyPath: editor.selectedPayloadPlaceholderUpdatedSelector, options: .new, context: nil)

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
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if let selectedPayloadPlaceholder = self.selectedPayloadPlaceholder {
            switch menuItem.identifier {
            case NSUserInterfaceItemIdentifier.editorMenuItemAddPayload:
                return !selectedPayloadPlaceholder.payload.unique
            case NSUserInterfaceItemIdentifier.editorMenuItemAddPayloadKey:
                return selectedPayloadPlaceholder.payloadType != .manifestsApple
            default:
                return true
            }
        }
        return true
    }

    func setupButtonMenu() {
        self.buttonMenu.delegate = self

        // ---------------------------------------------------------------------
        //  Add item: "Add Payload"
        // ---------------------------------------------------------------------
        let menuItemAddPayload = NSMenuItem()
        menuItemAddPayload.title = NSLocalizedString("Add Payload", comment: "")
        menuItemAddPayload.identifier = .editorMenuItemAddPayload
        menuItemAddPayload.isEnabled = true
        // menuItemAddPayload.target = self
        // menuItemAddPayload.action = #selector(self.addPayload(menuItem:))
        self.buttonMenu.addItem(menuItemAddPayload)

        // ---------------------------------------------------------------------
        //  Add item: "Add Payload Key"
        // ---------------------------------------------------------------------
        let menuItemAddPayloadKey = NSMenuItem()
        menuItemAddPayloadKey.title = NSLocalizedString("Add Payload Key", comment: "")
        menuItemAddPayloadKey.identifier = .editorMenuItemAddPayloadKey
        menuItemAddPayloadKey.isEnabled = true
        // menuItemAddPayloadKey.target = self
        // menuItemAddPayloadKey.action = #selector(self.addPayloadKey(menuItem:))
        self.buttonMenu.addItem(menuItemAddPayloadKey)
    }

    // MARK: -
    // MARK: Button/Menu Actions

    @objc func clicked(button: NSButton) {
        if
            let selectedPayloadPlaceholder = self.selectedPayloadPlaceholder,
            !selectedPayloadPlaceholder.payload.unique {
            self.profileEditor?.addTab(addSettings: true)
        }
    }

    @objc func addPayload(menuItem: NSMenuItem?) {
        if
            let selectedPayloadPlaceholder = self.selectedPayloadPlaceholder,
            !selectedPayloadPlaceholder.payload.unique {
            self.profileEditor?.addTab(addSettings: true)
        }
    }

    @objc func addPayloadKey(menuItem: NSMenuItem?) {
        if
            let selectedPayloadPlaceholder = self.selectedPayloadPlaceholder {
            self.profileEditor?.addKey(forPayloadPlaceholder: selectedPayloadPlaceholder)
        }
    }

    // MARK: -
    // MARK: NSControl/NSResponder Methods

    override func mouseEntered(with event: NSEvent) {
        if let parent = self.superview, let toolbarItemAdd = parent as? ProfileEditorWindowToolbarItemAdd {
            toolbarItemAdd.disclosureTriangle(show: true)
        }
    }

    override func mouseExited(with event: NSEvent) {
        if !self.mouseIsDown {
            if let parent = self.superview, let toolbarItemAdd = parent as? ProfileEditorWindowToolbarItemAdd {
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

extension ProfileEditorWindowToolbarItemAddButton: NSMenuDelegate {

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
        if let parent = self.superview, let toolbarItemAdd = parent as? ProfileEditorWindowToolbarItemAdd {
            toolbarItemAdd.disclosureTriangle(show: false)
        }
    }
}
