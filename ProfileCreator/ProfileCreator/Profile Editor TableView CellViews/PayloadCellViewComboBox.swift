//
//  PayloadCellViewPopUpButton.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewComboBox: PayloadCellView, ProfileCreatorCellView {

    // MARK: -
    // MARK: Instance Variables

    var comboBox: NSComboBox?
    var textFieldUnit: NSTextField?
    var valueDefault: Any?

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
        var titles = [String]()
        if let rangeListTitles = subkey.rangeListTitles {
            titles = rangeListTitles
        } else if let rangeList = subkey.rangeList {
            rangeList.forEach { titles.append(String(describing: $0)) }
        }
        let comboBox = EditorComboBox.withTitles(titles: titles, cellView: self)
        self.comboBox = comboBox
        self.setupComboBox()

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: comboBox)

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.defaultValue() {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Setup Unit if it is set
        // ---------------------------------------------------------------------
        if let valueUnit = subkey.valueUnit {
            self.textFieldUnit = EditorTextField.label(string: valueUnit,
                                                       fontWeight: .regular,
                                                       leadingItem: comboBox,
                                                       leadingConstant: 7.0,
                                                       trailingItem: nil,
                                                       constraints: &self.cellViewConstraints,
                                                       cellView: self)
            self.setupTextFieldUnit()
        }

        // ---------------------------------------------------------------------
        //  Get Value
        // ---------------------------------------------------------------------
        let value: Any?
        if let valueUser = self.profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) {
            value = valueUser
        } else if let valueDefault = self.valueDefault {
            value = valueDefault
        } else {
            value = comboBox.objectValues.first
        }

        // ---------------------------------------------------------------------
        //  Select Value
        // ---------------------------------------------------------------------
        if
            let selectedValue = value,
            let title = PayloadUtility.title(forRangeListValue: selectedValue, subkey: subkey),
            comboBox.objectValues.containsAny(value: title, ofType: .string) {
            comboBox.stringValue = title
            comboBox.objectValue = selectedValue
        } else {
            comboBox.objectValue = value
        }

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = comboBox
        self.trailingKeyView = comboBox

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.comboBox?.isEnabled = enable
    }
}

    // MARK: -
    // MARK: NSComboBoxDelegate Functions

extension PayloadCellViewComboBox: NSComboBoxDelegate {

    func comboBoxSelectionDidChange(_ notification: Notification) {
        if let comboBox = notification.object as? NSComboBox, let selectedValue = comboBox.objectValueOfSelectedItem {
            if
                comboBox.objectValues.contains(value: selectedValue, ofType: self.subkey.type),
                let selectedTitle = selectedValue as? String,
                let value = PayloadUtility.value(forRangeListTitle: selectedTitle, subkey: self.subkey) {
                self.profile.settings.setValue(value, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            } else {
                self.profile.settings.setValue(selectedValue, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            }
            comboBox.objectValue = selectedValue
            comboBox.highlighSubstrings(for: self.subkey)
            if self.subkey.isConditionalTarget {
                self.profileEditor.reloadTableView(updateCellViews: true)
            }
        }
    }
}

// MARK: -
// MARK: NSControl Functions

extension PayloadCellViewComboBox {

    func controlTextDidChange(_ notification: Notification) {
        if let comboBox = notification.object as? NSComboBox, let selectedValue = comboBox.objectValue {
            if
                comboBox.objectValues.contains(value: selectedValue, ofType: self.subkey.type),
                let selectedTitle = selectedValue as? String,
                let value = PayloadUtility.value(forRangeListTitle: selectedTitle, subkey: self.subkey) {
                self.profile.settings.setValue(value, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            } else {
                self.profile.settings.setValue(selectedValue, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            }
            comboBox.highlighSubstrings(for: self.subkey)
        }
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        if let comboBox = notification.object as? NSComboBox, let selectedValue = comboBox.objectValue {
            if
                comboBox.objectValues.contains(value: selectedValue, ofType: self.subkey.type),
                let selectedTitle = selectedValue as? String,
                let value = PayloadUtility.value(forRangeListTitle: selectedTitle, subkey: self.subkey) {
                self.profile.settings.setValue(value, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            } else {
                self.profile.settings.setValue(selectedValue, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
            }
            comboBox.highlighSubstrings(for: self.subkey)
            if self.subkey.isConditionalTarget {
                self.profileEditor.reloadTableView(updateCellViews: true)
            }
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewComboBox {

    private func setupComboBox() {

        // ---------------------------------------------------------------------
        //  Add PopUpButton to TableCellView
        // ---------------------------------------------------------------------
        guard let comboBox = self.comboBox else { return }
        self.addSubview(comboBox)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Below
        self.addConstraints(forViewBelow: comboBox)

        // Leading
        self.addConstraints(forViewLeading: comboBox)

        // Trailing
        self.addConstraints(forViewTrailing: comboBox)
    }

    private func setupTextFieldUnit() {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        guard let textFieldUnit = self.textFieldUnit, let popUpButton = self.comboBox else { return }

        textFieldUnit.textColor = .secondaryLabelColor

        popUpButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
}
