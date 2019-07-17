//
//  PayloadCellViewPopUpButton.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewPopUpButton: PayloadCellView, ProfileCreatorCellView, PopUpButtonCellView {

    // MARK: -
    // MARK: Instance Variables

    var popUpButton: NSPopUpButton?
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
        self.popUpButton = EditorPopUpButton.withTitles(titles: titles, cellView: self)
        self.setupPopUpButton()

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: self.popUpButton)

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
            self.textFieldUnit = EditorTextField.label(string: valueUnit, fontWeight: .regular, leadingItem: self.popUpButton, leadingConstant: 7.0, trailingItem: nil, constraints: &self.cellViewConstraints, cellView: self)
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
            value = self.popUpButton?.itemTitles.first
        }

        // ---------------------------------------------------------------------
        //  Select Value
        // ---------------------------------------------------------------------
        if let selectedValue = value, let title = PayloadUtility.title(forRangeListValue: selectedValue, subkey: subkey), self.popUpButton!.itemTitles.contains(title) {
            self.popUpButton!.selectItem(withTitle: title)
        }

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.popUpButton
        self.trailingKeyView = self.popUpButton

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.popUpButton?.isEnabled = enable
    }

    // MARK: -
    // MARK: PopUpButton Functions

    func selected(_ popUpButton: NSPopUpButton) {
        if
            let selectedTitle = popUpButton.titleOfSelectedItem,
            let selectedValue = PayloadUtility.value(forRangeListTitle: selectedTitle, subkey: self.subkey) {

            // self.profile.settings.updatePayloadSettings(value: selectedValue, subkey: self.subkey, payloadIndex: self.payloadIndex)
            self.profile.settings.setValue(selectedValue, forSubkey: self.subkey, payloadIndex: self.payloadIndex)

            if self.subkey.isConditionalTarget {
                self.profileEditor.reloadTableView(updateCellViews: true)
            }
        } else {
            Log.shared.error(message: "Subkey: \(self.subkey.keyPath) Failed to get value for selected title: \(String(describing: popUpButton.titleOfSelectedItem)) ", category: String(describing: self))
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewPopUpButton {

    private func setupPopUpButton() {

        // ---------------------------------------------------------------------
        //  Add PopUpButton to TableCellView
        // ---------------------------------------------------------------------
        guard let popUpButton = self.popUpButton else { return }
        self.addSubview(popUpButton)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Below
        self.addConstraints(forViewBelow: popUpButton)

        // Leading
        self.addConstraints(forViewLeading: popUpButton)

        // Trailing
        self.cellViewConstraints.append(NSLayoutConstraint(item: self,
                                                           attribute: .trailing,
                                                           relatedBy: .greaterThanOrEqual,
                                                           toItem: popUpButton,
                                                           attribute: .trailing,
                                                           multiplier: 1.0,
                                                           constant: 8.0))
    }

    private func setupTextFieldUnit() {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        guard let textFieldUnit = self.textFieldUnit, let popUpButton = self.popUpButton else { return }

        textFieldUnit.textColor = .secondaryLabelColor

        popUpButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
}
