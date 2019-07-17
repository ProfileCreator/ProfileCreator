//
//  EditorTableViewCellViewCheckbox.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

class EditorTableViewCellViewCheckbox: NSTableCellView {

    // MARK: -
    // MARK: Variables

    let checkbox = NSButton()

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(cellView: PayloadCellViewTableView, keyPath: String, value: Bool, row: Int) {

        super.init(frame: NSRect.zero)

        self.checkbox.translatesAutoresizingMaskIntoConstraints = false
        self.checkbox.setButtonType(.switch)
        self.checkbox.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))
        self.checkbox.state = (value) ? .on : .off
        self.checkbox.target = cellView
        self.checkbox.action = #selector(cellView.buttonClicked(_:))
        self.checkbox.title = ""
        self.checkbox.identifier = NSUserInterfaceItemIdentifier(rawValue: keyPath)
        self.checkbox.tag = row
        self.addSubview(self.checkbox)

        // ---------------------------------------------------------------------
        //  Setup Variables
        // ---------------------------------------------------------------------
        var constraints = [NSLayoutConstraint]()

        // CenterX
        constraints.append(NSLayoutConstraint(item: self.checkbox,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerX,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // CenterY
        constraints.append(NSLayoutConstraint(item: self,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: self.checkbox,
                                              attribute: .centerY,
                                              multiplier: 1.0,
                                              constant: 0.0))

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(constraints)
    }
}
