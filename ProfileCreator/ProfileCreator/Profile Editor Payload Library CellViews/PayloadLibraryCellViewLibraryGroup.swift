//
//  PayloadLibraryCellViewLibrary.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadLibraryCellViewGroup: NSTableCellView, PayloadLibraryCellView {

    // MARK: -
    // MARK: PayloadLibraryCellView Variables

    var row = -1
    var isMovable = false

    var textFieldTitle: NSTextField?
    var textFieldDescription: NSTextField?
    var imageViewIcon: NSImageView?
    var constraintImageViewLeading: NSLayoutConstraint?
    var buttonToggle: NSButton?
    var buttonToggleIndent: CGFloat = 0.0
    weak var placeholder: PayloadPlaceholder?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(title: String) {
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Setup Static View Content
        // ---------------------------------------------------------------------
        self.setupTextField(title: title, constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    private func setupTextField(title: String, constraints: inout [NSLayoutConstraint]) {

        let textFieldTitle = NSTextField()

        textFieldTitle.translatesAutoresizingMaskIntoConstraints = false
        textFieldTitle.lineBreakMode = .byWordWrapping
        textFieldTitle.isBordered = false
        textFieldTitle.isBezeled = false
        textFieldTitle.drawsBackground = false
        textFieldTitle.isEditable = false
        textFieldTitle.isSelectable = false
        textFieldTitle.textColor = .labelColor
        textFieldTitle.alignment = .center
        textFieldTitle.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        textFieldTitle.stringValue = title
        self.textFieldTitle = textFieldTitle

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(textFieldTitle)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // CenterY
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // CenterX
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerX,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: textFieldTitle,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 8.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textFieldTitle,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))
    }
}
