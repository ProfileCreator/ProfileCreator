//
//  EditorTableViewCellViewTextFieldNumber.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class EditorTableViewCellViewTextFieldNumber: NSTableCellView {

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(cellView: PayloadCellViewTableView, keyPath: String, value: NSNumber?, placeholderValue: NSNumber?, type: PayloadValueType, row: Int) {

        super.init(frame: NSRect.zero)

        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byTruncatingTail
        textField.isBordered = false
        textField.isBezeled = false
        textField.bezelStyle = .squareBezel
        textField.drawsBackground = false
        textField.isEditable = true
        textField.isSelectable = true
        textField.textColor = .labelColor
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))
        textField.stringValue = value?.stringValue ?? ""
        textField.placeholderString = placeholderValue?.stringValue ?? ""
        textField.delegate = cellView
        textField.tag = row
        textField.identifier = NSUserInterfaceItemIdentifier(rawValue: keyPath)
        textField.allowsEditingTextAttributes = true
        self.addSubview(textField)
        self.textField = textField

        // ---------------------------------------------------------------------
        //  Setup Formatter
        // ---------------------------------------------------------------------
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        if type == .integer {
            numberFormatter.maximumFractionDigits = 0
        }
        textField.formatter = numberFormatter

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // CenterY
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: textField,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.3))

        // Leading
        constraints.append(NSLayoutConstraint(item: textField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 4.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: textField,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 4.0))

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }
}
