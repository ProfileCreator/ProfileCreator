//
//  TableCellViewTextField.swift
//  ProfileCreator
//
//  Created by Erik Berglund.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ProfilePayloads

class PayloadCellViewTextField: PayloadCellView, ProfileCreatorCellView, NSTextFieldDelegate {

    // MARK: -
    // MARK: Instance Variables

    var textFieldInput: PayloadTextField?
    var textFieldUnit: NSTextField?
    var valueDefault: String?

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
        let textFieldInput = EditorTextField.input(defaultString: "", placeholderString: "", cellView: self)
        self.textFieldInput = textFieldInput
        self.setupTextFieldInput()

        if let valueUnit = subkey.valueUnit {
            self.textFieldUnit = EditorTextField.label(string: valueUnit,
                                                       fontWeight: .regular,
                                                       leadingItem: textFieldInput,
                                                       leadingConstant: 7.0,
                                                       trailingItem: nil,
                                                       constraints: &self.cellViewConstraints,
                                                       cellView: self)
            self.setupTextFieldUnit()
        } else {
            self.addConstraints(forViewTrailing: textFieldInput)
        }

        // ---------------------------------------------------------------------
        //  Setup Footer
        // ---------------------------------------------------------------------
        super.setupFooter(belowCustomView: textFieldInput)

        // ---------------------------------------------------------------------
        //  Set Default Value
        // ---------------------------------------------------------------------
        if let valueDefault = subkey.defaultValue(profileExport: ProfileExport(exportSettings: editor.profile.settings), parentValueKeyPath: nil, payloadIndex: payloadIndex) as? String {
            self.valueDefault = valueDefault
        }

        // ---------------------------------------------------------------------
        //  Set Placeholder Value
        // ---------------------------------------------------------------------
        self.textFieldInput?.placeholderString = self.profile.settings.placeholderString(forSubkey: subkey, isRequired: self.isRequired, payloadIndex: payloadIndex) ?? ""

        // ---------------------------------------------------------------------
        //  Set Value
        // ---------------------------------------------------------------------
        var valueString = ""
        if let value = self.profile.settings.value(forSubkey: subkey, payloadIndex: payloadIndex) as? String {
            valueString = value
        } else if let valueDefault = self.valueDefault {
            valueString = valueDefault
        }
        self.textFieldInput?.stringValue = valueString

        // ---------------------------------------------------------------------
        //  Set TextColor (red if not matching format)
        // ---------------------------------------------------------------------
        self.textFieldInput?.highlighSubstrings(for: subkey)

        // ---------------------------------------------------------------------
        //  Setup KeyView Loop Items
        // ---------------------------------------------------------------------
        self.leadingKeyView = self.textFieldInput
        self.trailingKeyView = self.textFieldInput

        // ---------------------------------------------------------------------
        //  Activate Layout Constraints
        // ---------------------------------------------------------------------
        NSLayoutConstraint.activate(self.cellViewConstraints)
    }

    // MARK: -
    // MARK: PayloadCellView Functions

    override func enable(_ enable: Bool) {
        self.isEnabled = enable
        self.textFieldInput?.isEnabled = enable
        self.textFieldInput?.isSelectable = enable
    }
}

// MARK: -
// MARK: NSControl Functions

extension PayloadCellViewTextField {

    internal func controlTextDidChange(_ obj: Notification) {

        self.isEditing = true
        if
            let userInfo = obj.userInfo,
            let fieldEditor = userInfo["NSFieldEditor"] as? NSTextView,
            let newString = fieldEditor.textStorage?.string {

            self.textFieldInput?.highlighSubstrings(for: self.subkey)

            self.profile.settings.setValue(newString, forSubkey: self.subkey, payloadIndex: self.payloadIndex)
        }
    }

    internal func controlTextDidEndEditing(_ obj: Notification) {

        if self.isEditing {
            self.isEditing = false
            if
                let userInfo = obj.userInfo,
                let fieldEditor = userInfo["NSFieldEditor"] as? NSTextView,
                let newString = fieldEditor.textStorage?.string {

                self.textFieldInput?.highlighSubstrings(for: self.subkey)

                self.profile.settings.setValue(newString, forSubkey: self.subkey, payloadIndex: self.payloadIndex)

                if self.subkey.isConditionalTarget {
                    self.profileEditor.reloadTableView(updateCellViews: true)
                }
            }
        }
    }
}

// MARK: -
// MARK: Setup NSLayoutConstraints

extension PayloadCellViewTextField {

    private func setupTextFieldInput() {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        guard let textFieldInput = self.textFieldInput else { return }
        textFieldInput.target = self
        self.addSubview(textFieldInput)

        // ---------------------------------------------------------------------
        //  Add constraints
        // ---------------------------------------------------------------------
        // Below
        self.addConstraints(forViewBelow: textFieldInput)

        // Leading
        self.addConstraints(forViewLeading: textFieldInput)
    }

    private func setupTextFieldUnit() {

        // ---------------------------------------------------------------------
        //  Add TextField to TableCellView
        // ---------------------------------------------------------------------
        guard let textFieldUnit = self.textFieldUnit else { return }

        textFieldUnit.textColor = .secondaryLabelColor
    }
}
