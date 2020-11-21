//
//  MainWindowWelcomeView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class MainWindowWelcomeViewController: NSObject, NSDraggingDestination {

    // MARK: -
    // MARK: Variables

    let view = ViewWhite(acceptsFirstResponder: false)
    let textFieldTitle = NSTextField()
    let textFieldInfo1 = NSTextField()
    let textFieldInfo2 = NSTextField()
    let button = NSButton()
    unowned var outlineViewController: MainWindowOutlineViewController

    // MARK: -
    // MARK: Initialization

    init(outlineViewController: MainWindowOutlineViewController) {
        self.outlineViewController = outlineViewController
        super.init()

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup View
        // ---------------------------------------------------------------------
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.registerForDraggedTypes(kMainWindowDragDropUTIs)
        self.view.draggingDestination = self

        // ---------------------------------------------------------------------
        //  Create and add TextField Title
        // ---------------------------------------------------------------------
        self.textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldTitle.lineBreakMode = .byWordWrapping
        self.textFieldTitle.isBordered = false
        self.textFieldTitle.isBezeled = false
        self.textFieldTitle.drawsBackground = false
        self.textFieldTitle.isEditable = false
        self.textFieldTitle.isSelectable = false
        self.textFieldTitle.stringValue = NSLocalizedString("Welcome to ProfileCreator", comment: "")
        self.textFieldTitle.textColor = .labelColor
        self.textFieldTitle.font = NSFont.boldSystemFont(ofSize: 28)
        self.textFieldTitle.alignment = .center
        setupTextFieldTitle(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Create and add TextField Information
        // ---------------------------------------------------------------------
        self.textFieldInfo1.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldInfo1.lineBreakMode = .byWordWrapping
        self.textFieldInfo1.isBordered = false
        self.textFieldInfo1.isBezeled = false
        self.textFieldInfo1.drawsBackground = false
        self.textFieldInfo1.isEditable = false
        self.textFieldInfo1.isSelectable = false
        self.textFieldInfo1.stringValue = NSLocalizedString("To create your first profile, click the ", comment: "")
        self.textFieldInfo1.textColor = .secondaryLabelColor
        self.textFieldInfo1.font = NSFont.systemFont(ofSize: 16)
        self.textFieldInfo1.alignment = .center
        self.setupTextFieldInfo1(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Create and add TextField Information
        // ---------------------------------------------------------------------
        self.textFieldInfo2.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldInfo2.lineBreakMode = .byWordWrapping
        self.textFieldInfo2.isBordered = false
        self.textFieldInfo2.isBezeled = false
        self.textFieldInfo2.drawsBackground = false
        self.textFieldInfo2.isEditable = false
        self.textFieldInfo2.isSelectable = false
        self.textFieldInfo2.stringValue = NSLocalizedString("Or import existing profiles using drag and drop.", comment: "")
        self.textFieldInfo2.textColor = .secondaryLabelColor
        self.textFieldInfo2.font = NSFont.systemFont(ofSize: 16)
        self.textFieldInfo2.alignment = .center
        self.setupTextFieldInfo2(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Create and add Button "+"
        // ---------------------------------------------------------------------
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.bezelStyle = .texturedRounded
        self.button.image = NSImage(named: NSImage.addTemplateName)
        self.button.target = self
        self.button.action = #selector(clicked(button:))
        self.button.imageScaling = .scaleProportionallyDown
        self.button.imagePosition = .imageOnly
        self.setupButton(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: -
    // MARK: Drag/Drop Support
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard
        guard let availableType = pasteboard.availableType(from: kMainWindowDragDropUTIs) else { return NSDragOperation() }
        if availableType == .backwardsCompatibleFileURL, pasteboard.canReadObject(forClasses: [NSURL.self], options: kMainWindowDragDropFilteringOptions) {
            return .copy
        }
        return NSDragOperation()
    }

    func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        true
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let selectedGroup = self.outlineViewController.selectedItem {
            return selectedGroup.outlineViewController.outlineView(selectedGroup.outlineViewController.outlineView, acceptDrop: sender, item: selectedGroup, childIndex: 0)
        }
        return true
    }

    // MARK: -
    // MARK: Button Actions

    @objc func clicked(button: NSButton) {
        NotificationCenter.default.post(name: .newProfile, object: self, userInfo: [NotificationKey.parentTitle: SidebarGroupTitle.library])
    }

    // MARK: -
    // MARK: Setup Layout Constraints

    private func setupTextFieldTitle(constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add subview to main view
        // ---------------------------------------------------------------------
        self.view.addSubview(self.textFieldTitle)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Center Horizontally
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self.view,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))

        // Center Vertically
        constraints.append(NSLayoutConstraint(item: self.view,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 30))
    }

    private func setupTextFieldInfo1(constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add subview to main view
        // ---------------------------------------------------------------------
        self.view.addSubview(self.textFieldInfo1)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Top
        constraints.append(NSLayoutConstraint(item: self.textFieldInfo1,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.textFieldTitle,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 13))

        // Center Horizontally
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self.textFieldInfo1,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 21))
    }

    private func setupTextFieldInfo2(constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add subview to main view
        // ---------------------------------------------------------------------
        self.view.addSubview(self.textFieldInfo2)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Top
        constraints.append(NSLayoutConstraint(item: self.textFieldInfo2,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self.textFieldInfo1,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 13))

        // Center Horizontally
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self.textFieldInfo2,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))
    }

    private func setupButton(constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add button to main view
        // ---------------------------------------------------------------------
        self.view.addSubview(self.button)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Leading
        constraints.append(NSLayoutConstraint(item: self.button,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.textFieldInfo1,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 2))

        // Baseline
        constraints.append(NSLayoutConstraint(item: self.textFieldInfo1,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.button,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0))

        // Width
        constraints.append(NSLayoutConstraint(item: self.button,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 40))
    }
}
