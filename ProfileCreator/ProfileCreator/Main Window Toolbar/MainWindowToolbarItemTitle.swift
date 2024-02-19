//
//  MainWindowToolbarItemTitle.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class MainWindowToolbarItemTitle: NSView {

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

    init() {

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Create the text field
        // ---------------------------------------------------------------------
        self.textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        self.textFieldTitle.isBordered = false
        self.textFieldTitle.isBezeled = false
        self.textFieldTitle.drawsBackground = false
        self.textFieldTitle.isEditable = false
        self.textFieldTitle.font = NSFont.systemFont(ofSize: 14, weight: .light)
        self.textFieldTitle.textColor = .tertiaryLabelColor
        self.textFieldTitle.alignment = .left
        self.textFieldTitle.lineBreakMode = .byTruncatingTail

        var titleString = NSLocalizedString("Profile Creator", comment: "")
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            titleString += " \(version)"
            /*
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                titleString += "-\(build)"
            }
            */
        }
        self.textFieldTitle.stringValue = titleString

        // ---------------------------------------------------------------------
        //  Create the initial size of the toolbar item
        // ---------------------------------------------------------------------
        let frame = NSRect(x: 0.0, y: 0.0, width: self.textFieldTitle.intrinsicContentSize.width, height: self.toolbarItemHeight)

        // ---------------------------------------------------------------------
        //  Create the actual toolbar item
        // ---------------------------------------------------------------------
        self.toolbarItem = NSToolbarItem(itemIdentifier: .mainWindowTitle)

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
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension MainWindowToolbarItemTitle {

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
