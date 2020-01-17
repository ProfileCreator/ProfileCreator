//
//  EditorTableViewCellViewPopUpButton.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class EditorTableViewCellViewPopUpButton: NSTableCellView {

    // MARK: -
    // MARK: Variables

    let popUpButton = NSPopUpButton()

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(cellView: EditorTableViewProtocol, keyPath: String, value aValue: Any?, subkey: PayloadSubkey, row: Int) {
        super.init(frame: NSRect.zero)

        var titles = [String]()
        if let rangeListTitles = subkey.rangeListTitles {
            titles = rangeListTitles
        } else if let rangeList = subkey.rangeList {
            for value in rangeList {
                titles.append(String(describing: value))
            }
        }

        self.popUpButton.translatesAutoresizingMaskIntoConstraints = false
        self.popUpButton.controlSize = .small
        self.popUpButton.target = cellView
        if subkey.valueUnique {
            self.popUpButton.autoenablesItems = true
            let menu = NSMenu()
            for title in titles {
                let menuItem = NSMenuItem()
                menuItem.title = title
                menuItem.identifier = NSUserInterfaceItemIdentifier(rawValue: keyPath)
                menuItem.tag = row
                menuItem.action = #selector(cellView.select(_:))
                menuItem.target = cellView
                menu.addItem(menuItem)
            }
            self.popUpButton.menu = menu
        } else {
            self.popUpButton.autoenablesItems = false
            self.popUpButton.action = #selector(cellView.selected(_:))
            self.popUpButton.addItems(withTitles: titles)
        }
        //
        self.popUpButton.identifier = NSUserInterfaceItemIdentifier(rawValue: keyPath)
        self.popUpButton.tag = row
        self.addSubview(self.popUpButton)

        // ---------------------------------------------------------------------
        //  Get Value
        // ---------------------------------------------------------------------
        let value: Any?
        if let userValue = aValue {
            value = userValue
        } else if let valueDefault = subkey.defaultValue() {
            value = valueDefault
        } else {
            value = self.popUpButton.itemTitles.first
        }

        // ---------------------------------------------------------------------
        //  Select Value
        // ---------------------------------------------------------------------
        if let selectedValue = value, let title = PayloadUtility.title(forRangeListValue: selectedValue, subkey: subkey), self.popUpButton.itemTitles.contains(title) {
            self.popUpButton.selectItem(withTitle: title)
        }

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // CenterY
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.popUpButton,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.4))

        // Leading
        constraints.append(NSLayoutConstraint(item: self.popUpButton,
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
                                              toItem: self.popUpButton,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 3.0))

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }
}
