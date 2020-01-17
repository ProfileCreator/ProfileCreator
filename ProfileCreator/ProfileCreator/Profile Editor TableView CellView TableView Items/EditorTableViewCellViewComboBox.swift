//
//  EditorTableViewCellViewPopUpButton.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class EditorTableViewCellViewComboBox: NSTableCellView {

    // MARK: -
    // MARK: Variables

    let comboBox = NSComboBox()

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(cellView: EditorTableViewProtocol & NSComboBoxDelegate, keyPath: String, value aValue: Any?, subkey: PayloadSubkey, row: Int) {
        super.init(frame: NSRect.zero)

        var titles = [String]()
        if let rangeListTitles = subkey.rangeListTitles {
            titles = rangeListTitles
        } else if let rangeList = subkey.rangeList {
            for value in rangeList {
                titles.append(String(describing: value))
            }
        }

        self.comboBox.translatesAutoresizingMaskIntoConstraints = false
        self.comboBox.controlSize = .small
        self.comboBox.delegate = cellView
        self.comboBox.target = cellView
        self.comboBox.addItems(withObjectValues: titles)
        self.comboBox.identifier = NSUserInterfaceItemIdentifier(rawValue: keyPath)
        self.comboBox.tag = row
        self.addSubview(self.comboBox)

        // ---------------------------------------------------------------------
        //  Get Value
        // ---------------------------------------------------------------------
        let value: Any?
        if let userValue = aValue {
            value = userValue
        } else if let valueDefault = subkey.defaultValue() {
            value = valueDefault
        } else {
            value = self.comboBox.objectValues.first
        }

        // ---------------------------------------------------------------------
        //  Select Value
        // ---------------------------------------------------------------------
        if
            let selectedValue = value,
            let title = PayloadUtility.title(forRangeListValue: selectedValue, subkey: subkey),
            comboBox.objectValues.contains(value: selectedValue, ofType: .string) {
            comboBox.objectValue = title
        } else {
            comboBox.objectValue = value
        }

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // CenterY
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.comboBox,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.7))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.comboBox,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 2.0))

        // Trailing
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self.comboBox,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 3.0))

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }
}
