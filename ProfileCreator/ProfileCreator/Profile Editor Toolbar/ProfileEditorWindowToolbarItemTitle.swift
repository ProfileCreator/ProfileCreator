//
//  ProfileEditorToolbarItemTitle.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class ProfileEditorWindowToolbarItemTitle: NSView {

    // MARK: -
    // MARK: Variables

    public weak var profile: Profile?

    let toolbarItemHeight: CGFloat = 32.0
    let textFieldTitle = NSTextField()

    let toolbarItem: NSToolbarItem
    var selectionTitle: String?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(profile: Profile) {

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.profile = profile
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Create the text field
        // ---------------------------------------------------------------------
        self.textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldTitle.isBordered = false
        self.textFieldTitle.isBezeled = false
        self.textFieldTitle.drawsBackground = false
        self.textFieldTitle.isEditable = false
        self.textFieldTitle.font = NSFont.systemFont(ofSize: 18, weight: .light)
        self.textFieldTitle.textColor = .labelColor
        self.textFieldTitle.alignment = .center
        self.textFieldTitle.lineBreakMode = .byTruncatingTail
        self.textFieldTitle.stringValue = profile.settings.title

        // ---------------------------------------------------------------------
        //  Create the initial size of the toolbar item
        // ---------------------------------------------------------------------
        let frame = NSRect(x: 0.0, y: 0.0, width: self.textFieldTitle.intrinsicContentSize.width, height: self.toolbarItemHeight)

        // ---------------------------------------------------------------------
        //  Create the actual toolbar item
        // ---------------------------------------------------------------------
        self.toolbarItem = NSToolbarItem(itemIdentifier: .editorTitle)

        // ---------------------------------------------------------------------
        //  Initialize self after the class variables have been instantiated
        // ---------------------------------------------------------------------
        super.init(frame: frame)

        // ---------------------------------------------------------------------
        //  Add constraints to text field
        // ---------------------------------------------------------------------
        setupTextFieldTitle(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)

        // ---------------------------------------------------------------------
        //  Set the toolbar item view
        // ---------------------------------------------------------------------
        self.toolbarItem.view = self

        // ---------------------------------------------------------------------
        //  Setup key/value observer for the profile title
        // ---------------------------------------------------------------------
        profile.settings.addObserver(self, forKeyPath: profile.settings.titleSelector, options: .new, context: nil)
    }

    deinit {
        guard let profile = self.profile else { return }
        profile.settings.removeObserver(self, forKeyPath: profile.settings.titleSelector, context: nil)
    }

    // MARK: -
    // MARK: Instance Functions

    func updateTitle() {
        guard let profile = self.profile else { return }

        self.textFieldTitle.stringValue = profile.settings.title

        let frame = NSRect(x: 0.0, y: 0.0, width: self.textFieldTitle.intrinsicContentSize.width, height: self.toolbarItemHeight)
        self.frame = frame
    }

    // MARK: -
    // MARK: Notification Functions

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let profile = self.profile else { return }
        if keyPath == profile.settings.titleSelector { self.updateTitle() }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension ProfileEditorWindowToolbarItemTitle {

    func setupTextFieldTitle(constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(self.textFieldTitle)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------

        // Leading
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0))

        // Center Vertically
        constraints.append(NSLayoutConstraint(item: self.textFieldTitle,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0))
    }
}
