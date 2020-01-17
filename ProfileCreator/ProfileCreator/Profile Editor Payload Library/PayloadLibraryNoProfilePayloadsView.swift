//
//  PayloadLibraryNoPayloadsView.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

struct PayloadLibraryNoProfilePayloads {

    // MARK: -
    // MARK: Variables

    let view: ViewWhite
    let textField = NSTextField()

    init(string: String, withBackground: Bool, draggingDestination: NSDraggingDestination, draggingTypes: [NSPasteboard.PasteboardType]) {

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        self.view = ViewWhite(draggingDestination: draggingDestination, draggingTypes: draggingTypes, acceptsFirstResponder: false, showBackground: withBackground)
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup View
        // ---------------------------------------------------------------------
        self.view.translatesAutoresizingMaskIntoConstraints = false

        // ---------------------------------------------------------------------
        //  Setup TextField
        // ---------------------------------------------------------------------
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.lineBreakMode = .byWordWrapping
        self.textField.isBordered = false
        self.textField.isBezeled = false
        self.textField.drawsBackground = false
        self.textField.isEditable = false
        self.textField.isSelectable = false
        self.textField.stringValue = string
        self.textField.textColor = .tertiaryLabelColor
        self.textField.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        self.textField.alignment = .center
        self.textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        self.textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setupTextField(constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Activate layout constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    private func setupTextField(constraints: inout [NSLayoutConstraint]) {

        self.view.addSubview(self.textField)

        // Leading
        constraints.append(NSLayoutConstraint(item: self.textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self.view,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 5.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self.view,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.textField,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 5.0))

        // Center Y
        constraints.append(NSLayoutConstraint(item: self.view,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.textField,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))
    }
}
