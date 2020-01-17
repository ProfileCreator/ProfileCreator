//
//  PayloadCellViewCheckbox.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewCheckbox: PayloadCellView, ProfileCreatorCellView, CheckboxCellView {

    // MARK: -
    // MARK: Instance Variables

    var checkbox: NSButton?
    var valueDefault: Any?
    var valueInverted: Bool = false

    // MARK: -
    // MARK: Initialization

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(subkey: PayloadSubkey, payloadIndex: Int, enabled: Bool, required: Bool, editor: ProfileEditor) {
        super.init(subkey: subkey, payloadIndex: payloadIndex, enabled: enabled, required: required, editor: editor)

        // ---------------------------------------------------------------------
        //  Setup Custom View Content
        // ---------------------------------------------------------------------
        self.checkbox = EditorCheckbox.noTitle(cellView: self)
        self.setupCheckbox()

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: nil)

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.valueDefault {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Set Value Inverted
        // ---------------------------------------------------------------------
        self.valueInverted = subkey.valueInverted

        // ---------------------------------------------------------------------
        //  Set Value
        // ---------------------------------------------------------------------
        var valueBool = false
        if let value = self.profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? Bool {
            valueBool = value
        } else {
            valueBool = self.bool(forValue: self.valueDefault)
        }

        self.checkbox?.state = self.state(forBool: valueBool)

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.checkbox
        self.trailingKeyView = self.checkbox

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: Value Conversion

    func bool(forValue value: Any?) -> Bool {
        if let rangeList = subkey.rangeList, rangeList.count == 2, let rangeValue = value {
            if let index = rangeList.index(ofValue: rangeValue, ofType: self.subkey.type), 0 <= index, index <= 1 {
                return index.boolValue
            }
        } else if let boolValue = value as? Bool {
            return boolValue
        }
        return false
    }

    // MARK: -
    // MARK: Value Inverted Functions

    func state(forBool bool: Bool) -> NSControl.StateValue {
        if self.valueInverted {
            return bool ? .off : .on
        } else {
            return bool ? .on : .off
        }
    }

    func bool(forState state: NSControl.StateValue) -> Bool {
        if self.valueInverted {
            return state == .on ? false : true
        } else {
            return state == .on ? true : false
        }
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.checkbox?.isEnabled = enable
    }

    // MARK: -
    // MARK: CheckboxCellView Functions

    func clicked(_ checkbox: NSButton) {

        self.profile.settings.setValue(self.bool(forState: checkbox.state), forSubkey: self.subkey, payloadIndex: self.payloadIndex)
        if self.subkey.isConditionalTarget {
            self.profileEditor.reloadTableView(updateCellViews: true)
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewCheckbox {

    private func setupCheckbox() {

        // ---------------------------------------------------------------------
        //  Add Checkbox to TableCellView
        // ---------------------------------------------------------------------
        guard let checkbox = self.checkbox else { return }
        self.addSubview(checkbox)

        // ---------------------------------------------------------------------
        //  Update leading constraints for TextField Title
        // ---------------------------------------------------------------------
        self.updateConstraints(forViewLeadingTitle: checkbox)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Leading
        self.addConstraints(forViewLeading: checkbox)

        // Width
        self.cellViewConstraints.append(NSLayoutConstraint(item: checkbox,
                                                           attribute: .width,
                                                           relatedBy: .equal,
                                                           toItem: nil,
                                                           attribute: .notAnAttribute,
                                                           multiplier: 1.0,
                                                           constant: checkbox.intrinsicContentSize.width))
    }
}
