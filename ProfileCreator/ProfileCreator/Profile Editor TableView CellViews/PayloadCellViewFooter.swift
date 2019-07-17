//
//  PayloadCellViewPadding.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewFooter: NSTableCellView, ProfileCreatorCellView {

    // MARK: -
    // MARK: PayloadCellView Variables

    var height: CGFloat = 0.0
    let separator = NSBox(frame: NSRect(x: 250.0, y: 15.0, width: kPreferencesWindowWidth - (20.0 + 20.0), height: 250.0))
    var textFieldRow1 = NSTextField()
    var textFieldRow2: NSTextField?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(row1: String, row2 row2String: String?) {
        super.init(frame: NSRect.zero)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // ---------------------------------------------------------------------
        //  Create and add vertical separator
        // ---------------------------------------------------------------------
        self.setup(separator: self.separator, constraints: &constraints)

        // ---------------------------------------------------------------------
        //  Setup Static View Content
        // ---------------------------------------------------------------------
        // Row 1
        self.setup(row: self.textFieldRow1, lastRow: nil, constraints: &constraints)
        self.textFieldRow1.stringValue = row1

        // Row 2
        if let row2 = row2String {
            self.textFieldRow2 = NSTextField()
            self.setup(row: self.textFieldRow2!, lastRow: self.textFieldRow1, constraints: &constraints)
            self.textFieldRow2?.stringValue = row2
        }

        // ---------------------------------------------------------------------
        //  Add spacing to bottom
        // ---------------------------------------------------------------------
        self.updateHeight(34.0)

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }

    func updateHeight(_ height: CGFloat) {
        self.height += height
    }

    // MARK: -
    // MARK: Setup Layout Constraints

    private func setup(row: NSTextField, lastRow: NSTextField?, constraints: inout [NSLayoutConstraint]) {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(row)

        row.translatesAutoresizingMaskIntoConstraints = false
        row.lineBreakMode = .byWordWrapping
        row.isBordered = false
        row.isBezeled = false
        row.drawsBackground = false
        row.isEditable = false
        row.isSelectable = false
        row.textColor = .tertiaryLabelColor
        row.preferredMaxLayoutWidth = kEditorTableViewColumnPayloadWidth
        row.alignment = .center
        row.font = NSFont.systemFont(ofSize: 10, weight: .light)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Top
        if let lastRowTextField = lastRow {
            constraints.append(NSLayoutConstraint(item: row,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: lastRowTextField,
                                                  attribute: .bottom,
                                                  multiplier: 1.0,
                                                  constant: 2.0))
            self.updateHeight(8 + row.intrinsicContentSize.height)
        } else {
            constraints.append(NSLayoutConstraint(item: row,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: self.separator,
                                                  attribute: .top,
                                                  multiplier: 1.0,
                                                  constant: 8.0))
            self.updateHeight(16 + row.intrinsicContentSize.height)
        }

        // Leading
        constraints.append(NSLayoutConstraint(item: row,
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
                                              toItem: row,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 8.0))
    }

    private func setup(separator: NSBox, constraints: inout [NSLayoutConstraint]) {

        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.boxType = .separator

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(separator)

        constraints.append(NSLayoutConstraint(item: separator,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 16.0))

        // Leading
        constraints.append(NSLayoutConstraint(item: separator,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 8.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: separator,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 8.0))

    }
}
