//
//  TableCellViewTextField.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewDictionary: PayloadCellView, ProfileCreatorCellView {

    // MARK: -
    // MARK: Instance Variables

    var valueDefault: [String: Any]?

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {
        super.init(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: editor)

        // ---------------------------------------------------------------------
        //  Create and add vertical separator bottom
        // ---------------------------------------------------------------------
        let separatorBottom = NSBox(frame: NSRect(x: 250.0, y: 15.0, width: kPreferencesWindowWidth - (20.0 + 20.0), height: 250.0))
        separatorBottom.translatesAutoresizingMaskIntoConstraints = false
        separatorBottom.boxType = .separator
        self.setup(separatorBottom: separatorBottom)

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: nil)

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.valueDefault as? [String: Any] {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = nil
        self.trailingKeyView = nil

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: NSCopying Functions

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = PayloadCellViewDictionary(subkey: self.subkey, payloadIndex: self.payloadIndex, enabled: self.isEnabled, required: self.isRequired, editor: self.profileEditor)
        return copy
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewDictionary {

    private func setup(separatorBottom: NSBox) {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        self.addSubview(separatorBottom)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Leading
        self.addConstraints(forViewLeading: separatorBottom)

        // Trailing
        self.addConstraints(forViewTrailing: separatorBottom)

        // Top
        let textField: NSTextField
        if let textFieldFooter = self.textFieldFooter {
            textField = textFieldFooter
        } else if let textFieldDescription = self.textFieldDescription {
            textField = textFieldDescription
        } else if let textFieldTitle = self.textFieldTitle {
            textField = textFieldTitle
        } else {
            return
        }

        self.cellViewConstraints.append(NSLayoutConstraint(item: separatorBottom,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: textField,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 10.0))

        self.updateHeight(10 + separatorBottom.intrinsicContentSize.height)
    }
}
